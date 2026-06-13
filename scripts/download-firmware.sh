#!/usr/bin/env bash
# Download firmware artifacts from GitHub Actions
# Usage: ./download-firmware.sh [layout]

set -e

LAYOUT="${1:-optimot}"
FIRMWARE_DIR="firmware"

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
RESET='\033[0m'

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error:${RESET} GitHub CLI (gh) is not installed."
    echo "Install it: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${RED}Error:${RESET} Not authenticated with GitHub CLI."
    echo "Run: ${BOLD}gh auth login${RESET}"
    exit 1
fi

echo -e "${CYAN}==>${RESET} Checking GitHub Actions status..."

# Get the latest run
RUN_DATA=$(gh run list --limit 1 --json status,conclusion,databaseId,headBranch 2>/dev/null || echo "[]")

if [ "$RUN_DATA" = "[]" ] || [ -z "$RUN_DATA" ]; then
    echo -e "${RED}Error:${RESET} No workflow runs found."
    exit 1
fi

STATUS=$(echo "$RUN_DATA" | jq -r '.[0].status')
CONCLUSION=$(echo "$RUN_DATA" | jq -r '.[0].conclusion')
RUN_ID=$(echo "$RUN_DATA" | jq -r '.[0].databaseId')
BRANCH=$(echo "$RUN_DATA" | jq -r '.[0].headBranch')

echo -e "${CYAN}==>${RESET} Latest run: #${RUN_ID} on branch ${BOLD}${BRANCH}${RESET}"
echo -e "${CYAN}==>${RESET} Status: ${BOLD}${STATUS}${RESET}"

# Wait if run is in progress
if [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; then
    echo -e "${YELLOW}==>${RESET} Build is ${STATUS}... waiting for completion."
    echo -e "${CYAN}==>${RESET} Watching run #${RUN_ID}..."
    gh run watch "$RUN_ID"
    
    # Refresh status after watch completes
    RUN_DATA=$(gh run view "$RUN_ID" --json status,conclusion 2>/dev/null || echo "{}")
    STATUS=$(echo "$RUN_DATA" | jq -r '.status')
    CONCLUSION=$(echo "$RUN_DATA" | jq -r '.conclusion')
fi

# Check if run succeeded
if [ "$STATUS" = "completed" ] && [ "$CONCLUSION" = "success" ]; then
    echo -e "${GREEN}==>${RESET} Build succeeded!"
else
    echo -e "${RED}Error:${RESET} Build ${CONCLUSION:-$STATUS}"
    exit 1
fi

# Download artifacts
echo -e "${CYAN}==>${RESET} Downloading artifacts from run #${RUN_ID}..."
TEMP_DIR=$(mktemp -d)
gh run download "$RUN_ID" --dir "$TEMP_DIR"

# Create firmware directory
mkdir -p "$FIRMWARE_DIR"

# Move .uf2 files to firmware directory with layout prefix
echo -e "${CYAN}==>${RESET} Organizing firmware files..."
for uf2 in "$TEMP_DIR"/*/*.uf2; do
    if [ -f "$uf2" ]; then
        filename=$(basename "$uf2")
        # Determine if left or right
        if [[ "$filename" == *"left"* ]]; then
            dest="${FIRMWARE_DIR}/${LAYOUT}_corne_left.uf2"
        elif [[ "$filename" == *"right"* ]]; then
            dest="${FIRMWARE_DIR}/${LAYOUT}_corne_right.uf2"
        else
            dest="${FIRMWARE_DIR}/${LAYOUT}_${filename}"
        fi
        cp "$uf2" "$dest"
        echo -e "${GREEN}==>${RESET} Saved: ${CYAN}${dest}${RESET}"
    fi
done

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${GREEN}==> Download complete for layout: ${LAYOUT}${RESET}"
echo -e "${GREEN}==> Left firmware : ${CYAN}${FIRMWARE_DIR}/${LAYOUT}_corne_left.uf2${RESET}"
echo -e "${GREEN}==> Right firmware: ${CYAN}${FIRMWARE_DIR}/${LAYOUT}_corne_right.uf2${RESET}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════${RESET}"
