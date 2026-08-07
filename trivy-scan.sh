#!/usr/bin/env bash
# Trivy vulnerability scanner
# Usage: ./trivy-scan.sh --repo-path /path/to/repo [options]
#
# Options:
#   --repo-path PATH  Path to the repository to scan (required)
#   --reponame NAME   Repository name used in report filenames (default: basename of repo-path)
#   --image NAME      Docker image name to scan (optional, enables image scan)
#   --severity LIST   Comma-separated severity levels (default: CRITICAL,HIGH,MEDIUM)
#   --output-dir DIR  Output directory (default: ./trivy-reports)

set -euo pipefail

REPO_PATH=""
REPONAME=""
IMAGE_NAME=""
SEVERITY="CRITICAL,HIGH,MEDIUM"
OUTPUT_DIR="trivy-reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

usage() {
  echo "Usage: $0 --repo-path PATH [--reponame NAME] [--image NAME] [--severity LIST] [--output-dir DIR]"
  echo ""
  echo "Options:"
  echo "  --repo-path PATH  Path to the repository to scan (required)"
  echo "  --reponame NAME   Repository name used in report filenames (default: basename of repo-path)"
  echo "  --image NAME      Docker image name to scan (optional)"
  echo "  --severity LIST   Comma-separated severity levels (default: CRITICAL,HIGH,MEDIUM)"
  echo "  --output-dir DIR  Output directory (default: ./trivy-reports)"
  echo "  -h, --help        Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-path) REPO_PATH="$2"; shift 2 ;;
    --reponame) REPONAME="$2"; shift 2 ;;
    --image) IMAGE_NAME="$2"; shift 2 ;;
    --severity) SEVERITY="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$REPO_PATH" ]]; then
  echo "Error: --repo-path is required"
  usage
fi

if [[ -z "$REPONAME" ]]; then
  REPONAME=$(basename "$REPO_PATH")
fi

if [[ ! -d "$REPO_PATH" ]]; then
  echo "Error: $REPO_PATH is not a valid directory"
  exit 1
fi

if ! command -v trivy &>/dev/null; then
  echo "Error: trivy is not installed."
  echo "Install it via: brew install trivy"
  exit 1
fi

OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}"
mkdir -p "$OUTPUT_DIR"

# =============================================================================
# Filesystem scan
# =============================================================================
run_fs_scan() {
  local json_file="${OUTPUT_DIR}/trivy-fs-${REPONAME}-${TIMESTAMP}.json"
  local txt_file="${OUTPUT_DIR}/trivy-fs-${REPONAME}-${TIMESTAMP}.txt"

  echo "=== Scanning filesystem: $REPO_PATH ==="
  trivy fs \
    --scanners vuln \
    --severity "$SEVERITY" \
    --format json \
    --output "$json_file" \
    "$REPO_PATH"

  echo ""
  echo "=== Generating plain-text table ==="
  trivy fs \
    --scanners vuln \
    --severity "$SEVERITY" \
    --format table \
    "$REPO_PATH" | tee "$txt_file"

  echo ""
  echo "=== Reports ==="
  echo "  JSON : $json_file"
  echo "  Text : $txt_file"
}

# =============================================================================
# Docker image scan
# =============================================================================
run_image_scan() {
  local json_file="${OUTPUT_DIR}/trivy-image-${REPONAME}-${TIMESTAMP}.json"
  local txt_file="${OUTPUT_DIR}/trivy-image-${REPONAME}-${TIMESTAMP}.txt"

  echo "=== Scanning Docker image: $IMAGE_NAME ==="
  trivy image \
    --scanners vuln \
    --severity "$SEVERITY" \
    --format json \
    --output "$json_file" \
    "$IMAGE_NAME"

  echo ""
  echo "=== Generating plain-text table ==="
  trivy image \
    --scanners vuln \
    --severity "$SEVERITY" \
    --format table \
    "$IMAGE_NAME" | tee "$txt_file"

  echo ""
  echo "=== Reports ==="
  echo "  JSON : $json_file"
  echo "  Text : $txt_file"
}

run_fs_scan
if [[ -n "$IMAGE_NAME" ]]; then
  echo ""
  run_image_scan
fi
