# 1) Extract only valid VAR=VALUE lines

# This command copies the 'blob' to the clipboard
   base64 -i ~/Downloads/github-ci-key.json | tr -d '\n' | pbcopy
 - then paste into GCP_SA_KEY=... in ~/.bee_secrets/supabase.env

# Commmands to set 'blob' to env variable and login to GCP

grep -E '^[A-Z0-9_]+=.*' ~/.bee_secrets/supabase.env > /tmp/env_clean

set -a
source /tmp/env_clean
set +a 

echo "GCP_SA_KEY length: ${#GCP_SA_KEY}"

echo "$GCP_SA_KEY" | base64 -d > /tmp/sa.json
head -n 3 /tmp/sa.json 

gcloud auth activate-service-account --key-file=/tmp/sa.json --quiet

gcloud auth list --filter=status:ACTIVE