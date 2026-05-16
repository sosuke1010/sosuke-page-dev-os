#!/usr/bin/env bash
# lint-no-absolute-paths.sh
#
# 「リポ内のコード・設定・ドキュメントに /Users/<user>/Development/... の
# ハードコード絶対パスを書かない」というルールを L4 (CI) で強制する linter。
#
# - 検出パターン: /Users/<username>/Development/
#   ※ username 部分は英数 / _ / - のみ許可（"..." のような placeholder は
#     プレースホルダとして許容するため、ドットは含めない）。
# - 除外: node_modules / .git / build outputs などツール出力ディレクトリ。
# - 例外: リポ root の .lint-no-absolute-paths.ignore (gitignore 構文) を
#   置けば、その glob にマッチするファイルはスキャン対象外になる。
#
# Usage:
#   bash scripts/lint-no-absolute-paths.sh             # 自リポを scan
#   bash scripts/lint-no-absolute-paths.sh /path/to    # 指定リポを scan
#
# Exit code:
#   0 — 違反なし
#   1 — 違反検出
#   2 — 実行環境の問題（ripgrep 未インストール等）

set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

PATTERN='/Users/[A-Za-z0-9_-]+/Development/'

if ! command -v rg >/dev/null 2>&1; then
  echo "error: ripgrep (rg) が見つかりません。'brew install ripgrep' で導入してください。" >&2
  exit 2
fi

RG_ARGS=(
  --no-messages
  -n
  --color=never
  --hidden
  --glob '!**/.git/**'
  --glob '!**/.git'
  --glob '!**/node_modules/**'
  --glob '!**/.next/**'
  --glob '!**/.turbo/**'
  --glob '!**/dist/**'
  --glob '!**/build/**'
  --glob '!**/__pycache__/**'
  --glob '!**/.venv/**'
  --glob '!**/venv/**'
  --glob '!**/coverage/**'
  --glob '!**/.cursor/plans/**'
  --glob '!**/docs/postmortem/**'
  --glob '!**/.env.local'
  --glob '!**/.env'
)

IGNORE_FILE="$TARGET_DIR/.lint-no-absolute-paths.ignore"
if [ -f "$IGNORE_FILE" ]; then
  RG_ARGS+=(--ignore-file "$IGNORE_FILE")
fi

MATCHES=$(rg "${RG_ARGS[@]}" "$PATTERN" "$TARGET_DIR" 2>/dev/null || true)

if [ -z "$MATCHES" ]; then
  echo "OK: ハードコード絶対パスは検出されませんでした ($TARGET_DIR)"
  exit 0
fi

cat <<EOF >&2
NG: '/Users/<user>/Development/' のハードコードを検出しました。
スクリプト/設定/ドキュメントに絶対パスを書かないでください。

修正方針:
  - シェル script   → SCRIPT_DIR="\$(cd "\$(dirname "\$0")/.." && pwd)" などで相対計算
  - ドキュメント例  → "~/Development/..." と書く（チルダで始める）
  - 設定ファイル   → 環境変数 or 設置時に書き換わる SSOT を参照
  - どうしても例外  → .lint-no-absolute-paths.ignore で該当ファイルを除外

検出箇所:
EOF

echo "$MATCHES" >&2
exit 1
