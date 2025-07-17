#!/usr/bin/env bash
# Measure confetti overlay frame timings in profile mode.
# Usage: ./make_perf_confetti.sh --device-id <ID>

set -euo pipefail

DEVICE_ID=${1:-""}

if [[ -z "$DEVICE_ID" ]]; then
  echo "Usage: $0 --device-id <ID>" >&2
  exit 1
fi

flutter run --profile --device-id "$DEVICE_ID" --dart-define=ENABLE_CONFETTI_TEST=true \
  | tee perf_timeline.log

flutter pub global run devtools parse-perf perf_timeline.log --output perf_summary.json

python scripts/perf/assert_frame_time.py perf_summary.json 16 