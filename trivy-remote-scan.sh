#!/usr/bin/env bash
# Trivy remote repository scanner
# Clones a remote repo (main branch, shallow), scans it, and cleans up.
#
# Usage: ./trivy-remote-scan.sh --url https://github.com/user/repo.git [options]
#
# Options:
#   --url URL         Remote repository URL (required)
#   --branch NAME     Branch to scan (default: main)
#   --severity LIST   Comma-separated severity levels (default: CRITICAL,HIGH,MEDIUM)
#   --output-dir DIR  Output directory (default: ./trivy-reports)
#   --no-cleanup      Keep the cloned repo after scanning
#   --image NAME      Docker image name to scan (optional, enables image scan)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCAN_SCRIPT="${SCRIPT_DIR}/trivy-scan.sh"

REPO_URL=""
BRANCH="main"
SEVERITY="CRITICAL,HIGH,MEDIUM"
OUTPUT_DIR="trivy-reports"
CLEANUP=true
IMAGE_NAME=""
TEMP_DIR=""

usage() {
  echo "Usage: $0 --url URL [--branch NAME] [--severity LIST] [--output-dir DIR] [--no-cleanup] [--image NAME]"
  echo ""
  echo "Options:"
  echo "  --url URL         Remote repository URL (required)"
  echo "  --branch NAME     Branch to scan (default: main)"
  echo "  --severity LIST   Comma-separated severity levels (default: CRITICAL,HIGH,MEDIUM)"
  echo "  --output-dir DIR  Output directory (default: ./trivy-reports)"
  echo "  --no-cleanup      Keep the cloned repo after scanning"
  echo "  --image NAME      Docker image name to scan (optional)"
  echo "  -h, --help        Show this help"
  exit 0
}

cleanup() {
  if [[ "$CLEANUP" == true && -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)        REPO_URL="$2"; shift 2 ;;
    --branch)     BRANCH="$2"; shift 2 ;;
    --severity)   SEVERITY="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --no-cleanup) CLEANUP=false; shift ;;
    --image)      IMAGE_NAME="$2"; shift 2 ;;
    -h|--help)    usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$REPO_URL" ]]; then
  echo "Error: --url is required"
  usage
fi

if ! command -v git &>/dev/null; then
  echo "Error: git is not installed"
  exit 1
fi

REPONAME=$(basename "$REPO_URL" .git)
TEMP_DIR=$(mktemp -d "/tmp/trivy-clone-${REPONAME}-XXXXX")

echo "=== Cloning $REPO_URL (branch: $BRANCH) ==="
git clone --depth 1 --branch "$BRANCH" --single-branch "$REPO_URL" "$TEMP_DIR" 2>&1

SCAN_ARGS=(
  --repo-path "$TEMP_DIR"
  --reponame "$REPONAME"
  --severity "$SEVERITY"
  --output-dir "$OUTPUT_DIR"
)
if [[ -n "$IMAGE_NAME" ]]; then
  SCAN_ARGS+=(--image "$IMAGE_NAME")
fi

bash "$SCAN_SCRIPT" "${SCAN_ARGS[@]}"

if [[ "$CLEANUP" == true ]]; then
  echo ""
  echo "=== Cleaning up clone ==="
fi
