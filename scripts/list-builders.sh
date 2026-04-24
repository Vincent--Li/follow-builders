#!/usr/bin/env bash
# list-builders.sh — 列出 follow-builders 收集的所有 AI Builder
# 用法: ./list-builders.sh [filter]
#   filter: "podcasts" | "blogs" | "x" | "all"（默认 all）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${SCRIPT_DIR}/../config/default-sources.json"

if [ ! -f "$CONFIG" ]; then
  echo "❌ 找不到配置文件: $CONFIG" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "❌ 需要 jq，请先安装: sudo apt install jq" >&2
  exit 1
fi

FILTER="${1:-all}"

show_podcasts() {
  local count
  count=$(jq '.podcasts | length' "$CONFIG")
  echo ""
  echo "🎙️  Podcasts ($count)"
  echo "─────────────────────────────────────────────"
  jq -r '.podcasts[] | "  • \(.name)\n    RSS: \(.rssUrl)\n    YouTube: \(.url)"' "$CONFIG"
}

show_blogs() {
  local count
  count=$(jq '.blogs | length' "$CONFIG")
  echo ""
  echo "📝 Blogs ($count)"
  echo "─────────────────────────────────────────────"
  jq -r '.blogs[] | "  • \(.name)\n    Type: \(.type)\n    URL: \(.indexUrl)"' "$CONFIG"
}

show_x() {
  local count
  count=$(jq '.x_accounts | length' "$CONFIG")
  echo ""
  echo "𝕏 Builders ($count)"
  echo "─────────────────────────────────────────────"
  jq -r '.x_accounts[] | "  • \(.name)  →  x.com/\(.handle)"' "$CONFIG"
}

echo "╔══════════════════════════════════════════════╗"
echo "║     Follow Builders — Not Influencers        ║"
echo "╚══════════════════════════════════════════════╝"
echo "Config: $CONFIG"

case "$FILTER" in
  podcasts) show_podcasts ;;
  blogs)    show_blogs ;;
  x|twitter) show_x ;;
  all)
    show_podcasts
    show_blogs
    show_x
    ;;
  *)
    echo "❌ 未知过滤: $FILTER" >&2
    echo "用法: $0 [podcasts|blogs|x|all]" >&2
    exit 1
    ;;
esac

# 汇总
POD=$(jq '.podcasts | length' "$CONFIG")
BLG=$(jq '.blogs | length' "$CONFIG")
XAC=$(jq '.x_accounts | length' "$CONFIG")
TOTAL=$((POD + BLG + XAC))
echo ""
echo "─────────────────────────────────────────────"
echo "📊 合计: $TOTAL builders（$POD podcasts + $BLG blogs + $XAC 𝕏 accounts）"
echo "─────────────────────────────────────────────"
