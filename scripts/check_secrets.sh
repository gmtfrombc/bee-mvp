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

  # Map GOOS/GOARCH names used by the release assets
  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  local arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
  esac

  # Construct expected asset pattern (e.g. linux_amd64.tar.gz or darwin_arm64.tar.gz)
  local pattern="${os}_${arch}.tar.gz"

  # Fetch latest release download URL matching the pattern
  local latest_url
  latest_url=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | \
    jq -r --arg pattern "$pattern" '.assets[] | select(.name|test($pattern)) | .browser_download_url' | head -n 1)

  if [[ -z "$latest_url" ]]; then
    echo -e "${RED}❌ Could not find a gitleaks binary for ${os}/${arch}. Attempting fallback installation...${RESET}"
    if [[ "$os" == "darwin" ]]; then
      # Homebrew fallback for macOS
      brew install gitleaks || { echo -e "${RED}Failed to install gitleaks via Homebrew${RESET}"; exit 1; }
    else
      echo -e "${RED}No compatible gitleaks binary found and no fallback available.${RESET}"
      exit 1
    fi
  else
    curl -sSL "$latest_url" -o /tmp/gitleaks.tar.gz
    tar -xf /tmp/gitleaks.tar.gz -C /tmp
    sudo install -m 755 /tmp/gitleaks /usr/local/bin/gitleaks
  fi

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