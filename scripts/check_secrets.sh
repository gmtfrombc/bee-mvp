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
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    armv6l) arch="armv6" ;;
    armv7l) arch="armv7" ;;
  esac

  # Construct expected asset pattern (e.g. linux_amd64.tar.gz or darwin_arm64.tar.gz)
  local pattern="${os}_${arch}.tar.gz"

  # Fetch latest release download URL matching the pattern
  local latest_url
  latest_url=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | \
    jq -r --arg pattern "$pattern" '.assets[] | select(.name|test($pattern)) | .browser_download_url' | head -n 1)

  if [[ -z "$latest_url" ]]; then
    echo -e "${RED}❌ Could not find a gitleaks binary via GitHub API for ${os}/${arch}.${RESET}"

    # -- Deterministic fallback -------------------------------------------------
    # The GitHub API occasionally rate-limits anonymous requests on CI runners,
    # which results in an empty download URL.  Instead of failing the entire
    # workflow we pin to a known-good version (updated periodically).  This
    # keeps the secrets scan running even when the API is flaky.

    local fallback_version="8.27.2"
    local fallback_url="https://github.com/gitleaks/gitleaks/releases/download/v${fallback_version}/gitleaks_${fallback_version}_${os}_${arch}.tar.gz"

    echo -e "${GREEN}📦 Falling back to pinned gitleaks v${fallback_version}...${RESET}"

    if curl --silent --head --fail "$fallback_url" >/dev/null; then
      curl -sSL "$fallback_url" -o /tmp/gitleaks.tar.gz
      tar -xf /tmp/gitleaks.tar.gz -C /tmp
      sudo install -m 755 /tmp/gitleaks /usr/local/bin/gitleaks
    else
      echo -e "${RED}No compatible gitleaks binary found at $fallback_url.${RESET}"
      if [[ "$os" == "darwin" ]]; then
        # Homebrew fallback for macOS (rarely needed in CI but handy for devs)
        brew install gitleaks || { echo -e "${RED}Failed to install gitleaks via Homebrew${RESET}"; exit 1; }
      else
        echo -e "${RED}No additional fallback available – exiting.${RESET}"
        exit 1
      fi
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