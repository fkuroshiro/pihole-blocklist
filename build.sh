#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/sources.txt"
WHITELIST_FILE="$SCRIPT_DIR/whitelist.txt"
OUTPUT_FILE="$SCRIPT_DIR/hosts.txt"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

echo "Fetching source lists..."
i=0
while IFS= read -r url; do
  # skip comments and blank lines
  [[ "$url" =~ ^#.*$ || -z "$url" ]] && continue
  i=$((i+1))
  echo "  [$i] $url"
  curl -fsSL --retry 3 -A "Mozilla/5.0 (compatible; pihole-blocklist-builder/1.0)" "$url" -o "$TMP_DIR/list_$i.txt" || echo "    WARNING: failed to fetch $url"
done < "$SOURCES_FILE"

echo "Merging and normalizing..."
# Extract domain from hosts-format (0.0.0.0 domain) or plain domain lists,
# strip comments/blank lines, lowercase, dedupe.
cat "$TMP_DIR"/list_*.txt 2>/dev/null \
  | sed -E 's/^0\.0\.0\.0[[:space:]]+//; s/^127\.0\.0\.1[[:space:]]+//' \
  | sed -E 's/#.*$//' \
  | tr '[:upper:]' '[:lower:]' \
  | awk 'NF' \
  | sort -u > "$TMP_DIR/merged.txt"

echo "Applying whitelist..."
grep -vFf <(grep -vE '^#|^$' "$WHITELIST_FILE") "$TMP_DIR/merged.txt" > "$TMP_DIR/filtered.txt" || cp "$TMP_DIR/merged.txt" "$TMP_DIR/filtered.txt"

echo "Writing final hosts.txt..."
{
  echo "# Custom Pi-hole blocklist"
  echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "# Domain count: $(wc -l < "$TMP_DIR/filtered.txt")"
  echo ""
  sed 's/^/0.0.0.0 /' "$TMP_DIR/filtered.txt"
} > "$OUTPUT_FILE"

echo "Done. $(wc -l < "$TMP_DIR/filtered.txt") domains written to hosts.txt"
