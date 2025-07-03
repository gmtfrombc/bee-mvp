#!/usr/bin/env bash
# scripts/check_secrets.sh
# Scans the repository for plaintext secrets using gitleaks. Fails CI if any leak is found.
# Usage: ./scripts/check_secrets.sh

set -euo pipefail

# ANSI colors for readability
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

function install_gitleaks() {
  echo -e "${GREEN}🔍 Installing gitleaks...${RESET}"
  local latest_url
  latest_url=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | \
    grep "browser_download_url" | \
    grep "$(uname -s)_$(uname -m).tar.gz" | \
    cut -d '"' -f 4)
  curl -sSL "$latest_url" -o /tmp/gitleaks.tar.gz
  tar -xf /tmp/gitleaks.tar.gz -C /tmp
  sudo mv /tmp/gitleaks /usr/local/bin/
  gitleaks version
}

if ! command -v gitleaks &>/dev/null; then
  install_gitleaks
fi

echo -e "${GREEN}🚀 Running gitleaks scan...${RESET}"

# Run scan and exit non-zero on findings
if gitleaks detect --source . --no-banner --exit-code 1; then
  echo -e "${GREEN}✅ No secrets found.${RESET}"
else
  echo -e "${RED}❌ Potential secrets detected. Failing the build.${RESET}"
  exit 1
fi 