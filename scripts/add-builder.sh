#!/usr/bin/env bash
# add-builder.sh — 向 follow-builders 添加新的 AI Builder
# 用法:
#   ./add-builder.sh x "Name" handle          — 添加 X 账号
#   ./add-builder.sh podcast "Name" rssUrl ytUrl — 添加播客
#   ./add-builder.sh blog "Name" indexUrl      — 添加博客
set -uo pipefail

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

TYPE="$1"; shift
NAME="$1"; shift

case "$TYPE" in
  x|twitter)
    HANDLE="$1"; shift
    # 检查是否已存在
    if jq -e --arg h "$HANDLE" '.x_accounts[] | select(.handle == $h)' "$CONFIG" &>/dev/null; then
      echo "⚠️  x.com/$HANDLE 已存在，跳过"
      exit 0
    fi
    jq --arg name "$NAME" --arg handle "$HANDLE" \
      '.x_accounts += [{"name": $name, "handle": $handle}]' \
      "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
    echo "✅ 添加 X builder: $NAME (x.com/$HANDLE)"
    ;;
  podcast)
    RSS_URL="$1"; shift
    YT_URL="$1"; shift
    if jq -e --arg n "$NAME" '.podcasts[] | select(.name == $n)' "$CONFIG" &>/dev/null; then
      echo "⚠️  Podcast \"$NAME\" 已存在，跳过"
      exit 0
    fi
    jq --arg name "$NAME" --arg rss "$RSS_URL" --arg url "$YT_URL" \
      '.podcasts += [{"name": $name, "rssUrl": $rss, "url": $url}]' \
      "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
    echo "✅ 添加 Podcast: $NAME"
    ;;
  blog)
    INDEX_URL="$1"; shift
    if jq -e --arg n "$NAME" '.blogs[] | select(.name == $n)' "$CONFIG" &>/dev/null; then
      echo "⚠️  Blog \"$NAME\" 已存在，跳过"
      exit 0
    fi
    jq --arg name "$NAME" --arg url "$INDEX_URL" \
      '.blogs += [{"name": $name, "type": "scrape", "indexUrl": $url, "articleBaseUrl": ($url + "/"), "fetchMethod": "http"}]' \
      "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
    echo "✅ 添加 Blog: $NAME ($INDEX_URL)"
    ;;
  *)
    echo "❌ 未知类型: $TYPE" >&2
    echo "用法:" >&2
    echo "  $0 x \"Name\" handle" >&2
    echo "  $0 podcast \"Name\" rssUrl youtubeUrl" >&2
    echo "  $0 blog \"Name\" indexUrl" >&2
    exit 1
    ;;
esac

# 自动更新 README 中的数量
POD=$(jq '.podcasts | length' "$CONFIG")
BLG=$(jq '.blogs | length' "$CONFIG")
XAC=$(jq '.x_accounts | length' "$CONFIG")
echo ""
echo "📊 当前合计: $((POD + BLG + XAC)) builders（$POD podcasts + $BLG blogs + $XAC 𝕏）"
