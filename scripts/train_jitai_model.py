import argparse
import json
import os

import pandas as pd  # type: ignore
from sklearn.linear_model import LogisticRegression  # type: ignore
from sklearn.metrics import roc_auc_score  # type: ignore
from sklearn.model_selection import train_test_split  # type: ignore

FEATURES = [
    "sleep_score",
    "avg_hr",
    "steps",
    "heart_rate",
    "resting_heart_rate",
    "stress_level",
    "patient_hash",
]


def _hash_patient_id(pid: str) -> float:
    """Quick deterministic hash → float 0-1 (matches Deno/TS patientHash)."""
    if not isinstance(pid, str):
        pid = str(pid or "")
    h = 0
    for ch in pid:
        h = (h * 31 + ord(ch)) & 0xFFFFFFFF
    return (h % 1000) / 1000.0


def load_ndjson(path: str) -> pd.DataFrame:
    """Load newline-delimited JSON into a DataFrame."""
    records = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            if not line.strip():
                continue
            obj = json.loads(line)
            records.append(obj)
    if not records:
        raise ValueError("no records loaded from NDJSON – aborting")
    return pd.DataFrame.from_records(records)


def prepare_data(df: pd.DataFrame) -> pd.DataFrame:
    # Outcome: engaged (1) vs otherwise (0)
    df = df.copy()
    df["label"] = (df["outcome"] == "engaged").astype(int)
    # Derive patient_hash then fill missing numeric features
    if "patient_id" in df.columns:
        df["patient_hash"] = df["patient_id"].apply(_hash_patient_id)
    else:
        df["patient_hash"] = 0.0
    # Fill missing numeric features with column mean
    for col in FEATURES:
        if col not in df.columns:
            df[col] = 0.0
        df[col] = pd.to_numeric(df[col], errors="coerce")
        # Avoid chained-assignment warning (and future pandas 3.0 breakage)
        df[col] = df[col].fillna(df[col].mean())
    return df


def train(df: pd.DataFrame):
    X = df[FEATURES]
    y = df["label"]
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=42, stratify=y
    )
    model = LogisticRegression(max_iter=200)
    model.fit(X_train, y_train)
    probas = model.predict_proba(X_test)[:, 1]
    auc = roc_auc_score(y_test, probas)
    return model, auc


def export_model(model: LogisticRegression, output_path: str):
    coef = {feat: float(w) for feat, w in zip(FEATURES, model.coef_[0])}
    artefact = {
        "intercept": float(model.intercept_[0]),
        "coeff": coef,
        "threshold": 0.5,
    }
    with open(output_path, "w", encoding="utf-8") as fh:
        json.dump(artefact, fh)
    print(f"Model artefact written to {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Train JITAI logistic model")
    parser.add_argument("ndjson_path", help="Path to training NDJSON file")
    parser.add_argument(
        "--output", default="jitai_model.json", help="Path for JSON artefact"
    )
    parser.add_argument(
        "--min_auc",
        type=float,
        default=0.6,
        help="Minimum acceptable ROC-AUC (set 0 to bypass gate)",
    )
    args = parser.parse_args()

    df = load_ndjson(args.ndjson_path)
    df = prepare_data(df)
    model, auc = train(df)
    print(f"ROC-AUC: {auc:.4f}")

    if args.min_auc and auc < args.min_auc:
        print(f"AUC below threshold ({args.min_auc:.2f}) – failing")
        exit(1)

    export_model(model, args.output)

    # Export AUC for CI consumption
    os.environ["JITAI_AUC"] = str(auc)


if __name__ == "__main__":
    main()
