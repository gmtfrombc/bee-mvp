## Backend and Integration
bash scripts/run_ci_locally.sh -j build --verbose | tee build3.log **use this one mostly**
act -j build -W .github/workflows/ci.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 --container-architecture linux/amd64 --env ACT=false --env SKIP_UPLOAD_ARTIFACTS=true --env SKIP_TERRAFORM=true --secret-file .secrets --quiet  **use this one if you want more detail**

## Flutter CI

act -j test -W .github/workflows/flutter-ci.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 --container-architecture linux/amd64 --env ACT=true --secret-file .secrets --quiet

## Coach Epic CI


## JITAI Model CI


## LightGBM Export CI


## Migrations deploy
