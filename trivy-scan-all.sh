#!/usr/bin/env bash
# Trivy batch scanner — scans all subdirectories at the given root.
# Place this script at the root of your monorepo/projects folder.
#
# Usage: ./trivy-scan-all.sh [options]
#
# Options:
#   --root DIR        Root directory containing repos (default: current directory)
#   --severity LIST   Comma-separated severity levels (default: CRITICAL,HIGH,MEDIUM)
#   --output-dir DIR  Output directory (default: ./trivy-reports)
#   --skip DIR        Subdirectory name(s) to skip (repeatable, e.g. --skip node_modules --skip .git)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCAN_SCRIPT="${SCRIPT_DIR}/trivy-scan.sh"

ROOT_DIR="$(pwd)"
SEVERITY="CRITICAL,HIGH,MEDIUM"
OUTPUT_DIR="trivy-reports"
SKIP=()
FAILED=()

usage() {
  echo "Usage: $0 [--root DIR] [--severity LIST] [--output-dir DIR] [--skip NAME]..."
  echo ""
  echo "Options:"
  echo "  --root DIR        Root directory containing repos (default: current directory)"
  echo "  --severity LIST   Comma-separated severity levels (default: CRITICAL,HIGH,MEDIUM)"
  echo "  --output-dir DIR  Output directory (default: ./trivy-reports)"
  echo "  --skip DIR        Subdirectory name(s) to skip (repeatable)"
  echo "  -h, --help        Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)       ROOT_DIR="$2"; shift 2 ;;
    --severity)   SEVERITY="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --skip)       SKIP+=("$2"); shift 2 ;;
    -h|--help)    usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "Error: $ROOT_DIR is not a valid directory"
  exit 1
fi

should_skip() {
  local name="$1"
  for s in "${SKIP[@]}"; do
    [[ "$name" == "$s" ]] && return 0
  done
  return 1
}

# Collect all immediate subdirectories
PROJECTS=()
for dir in "$ROOT_DIR"/*/; do
  dir="${dir%/}"
  name=$(basename "$dir")
  if should_skip "$name"; then
    continue
  fi
  PROJECTS+=("$dir")
done

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  echo "No subdirectories found in $ROOT_DIR"
  exit 1
fi

TOTAL=${#PROJECTS[@]}
CURRENT=0

echo "============================================"
echo " Batch scanning $TOTAL project(s) in $ROOT_DIR"
echo "============================================"
echo ""

for project in "${PROJECTS[@]}"; do
  CURRENT=$((CURRENT + 1))
  name=$(basename "$project")

  echo "--------------------------------------------------"
  echo "[$CURRENT/$TOTAL] Scanning: $name"
  echo "--------------------------------------------------"

  if bash "$SCAN_SCRIPT" \
       --repo-path "$project" \
       --reponame "$name" \
       --severity "$SEVERITY" \
       --output-dir "$OUTPUT_DIR" 2>&1; then
    echo "  ✓ $name completed"
  else
    echo "  ✗ $name failed"
    FAILED+=("$name")
  fi
  echo ""
done

echo "============================================"
echo " Scan complete: $((TOTAL - ${#FAILED[@]}))/$TOTAL succeeded"
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo " Failures: ${FAILED[*]}"
fi
echo " Reports saved to: $(pwd)/${OUTPUT_DIR}"
echo "============================================"

[[ ${#FAILED[@]} -eq 0 ]] && exit 0 || exit 1
