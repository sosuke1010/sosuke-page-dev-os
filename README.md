# sosuke-page-dev-os

`sosuke.page` 関連リポ（my-handbook / hero-video-ingest / mac-event-collector / door-ble-logger / vlog-recorder / ...）で共有する dev tooling 一式。

「個人プロジェクト群の開発 OS 的レイヤー」として、各リポを横断する CI lint や規約周辺のスクリプトをここに集める。AI 規約自体は `cursor-rules-base/` 側で管理し、ここはあくまで「実行される側」のコードを持つ。

## レイヤー位置づけ

```
cursor-rules-base/      ── AI 規約・原則・ドキュメント雛形（横展開）
sosuke-page-dev-os/     ── sosuke.page 群で共有する CI lint / scripts
  ├─ my-handbook        ── consumer
  ├─ hero-video-ingest  ── consumer
  ├─ mac-event-collector── consumer
  ├─ door-ble-logger    ── consumer
  └─ vlog-recorder      ── consumer
```

## 含まれるもの

### `scripts/lint-no-absolute-paths.sh`

「リポ内のコード・設定・ドキュメントに `/Users/<user>/Development/...` のハードコード絶対パスを書かない」を CI で強制する linter。

**起こり得たバグ:** フォルダを移動した瞬間に script / symlink / 設定がいっせいに死ぬ。3 回踏んだのでルール化（→ `mac-event-collector/docs/postmortem/2026-05-16-...`）。

**使い方:**

```bash
# 自リポを scan
bash scripts/lint-no-absolute-paths.sh

# 指定リポを scan
bash scripts/lint-no-absolute-paths.sh /path/to/repo
```

Postmortem は事故当時のパスを事実として保存する監査記録なので、`docs/postmortem/**` は標準で除外する。
それ以外で例外を出したい場合は、対象リポの root に `.lint-no-absolute-paths.ignore` を置く（`.gitignore` と同じ glob 構文）。

### `templates/github-actions/lint-no-absolute-paths.yml`

各 consumer repo に置く CI ワークフローのテンプレート。`.github/workflows/lint-no-absolute-paths.yml` にコピーすると、PR / push で自動 lint が走る。

## consumer 側のセットアップ

1. テンプレを repo にコピー:

   ```bash
   mkdir -p .github/workflows
   cp ../sosuke-page-dev-os/templates/github-actions/lint-no-absolute-paths.yml \
      .github/workflows/lint-no-absolute-paths.yml
   ```

2. 必要なら `.lint-no-absolute-paths.ignore` で個別ファイルを除外:

   ```gitignore
   # historical archive
   docs/archive/**
   # legacy worktree pointers handled by git itself
   .git
   ```

3. commit & push → PR で lint が走る。違反があれば fail。

## 必要環境

- ripgrep (`rg`) — `brew install ripgrep` または apt
- GitHub-hosted runner (`ubuntu-latest`) には標準で導入済み

## なぜ別リポか

- `cursor-rules-base/` は AI 向け規約（汎用、複数プロジェクト共有）が中心で、開発以外のタスクでも読まれる。実行可能な CI script は scope が違う。
- 各 consumer に script を直置きすると 5 リポ × N 規約で drift する。SSOT を分けるのが筋。
- 「sosuke.page 群でしか共有しない」スコープなので、新規 repo として分離。

詳細: `docs/adr/` 参照（追って整備）。
