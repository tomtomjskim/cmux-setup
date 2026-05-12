#!/usr/bin/env bash
# cmux-setup.sh — cmux 워크스페이스 + 패널 레이아웃 자동 세팅.
#
# 사용법:
#   cmx <path>                       # 디폴트 레이아웃, port 80
#   cmx <path> 8081                  # 두 번째 인자가 숫자 → port, 브라우저=http://localhost:8081
#   cmx <path> http://app.local:90   # 두 번째 인자가 URL → 그 URL 사용
#   cmx <path> 80 --v-simple         # 레이아웃 옵션
#
# 옵션:
#   --v-default | --layout=default   디폴트 레이아웃 (3단)
#   --v-simple  | --layout=simple    단순 레이아웃 (터미널 | 브라우저)
#   --v-4split  | --layout=4split    이전 디폴트 (dev / test / claude / 브라우저)
#
# 디버그:
#   CMX_DEBUG=1 cmx ~/dev/myApp
#
# 프로젝트별 영구화: <project>/.cmux.conf
#   PORT, BROWSER_URL, DEV_CMD, TEST_CMD, CLAUDE_CMD, CODEX_CMD, LAYOUT
#
# 레이아웃 정의:
#   default (3단):
#     [왼쪽 컬럼]            [중간 컬럼]          [오른쪽]
#     ┌─ claude (top)  ─┐   ┌─ t1 (top)   ─┐   ┌─ browser ─┐
#     │                 │   ├─ t2 (mid)   ─┤   │           │
#     └─ codex  (bot)  ─┘   └─ t3 (bot)   ─┘   └───────────┘
#   simple: 왼쪽 터미널 (DEV_CMD) | 오른쪽 브라우저
#   4split: 왼쪽 dev / 오른쪽 상 test / 오른쪽 하 claude / 하단 브라우저

set -euo pipefail

# ─── 도움말 ────────────────────────────────────────────────────────
print_help() {
  cat <<'HELP'
cmx — cmux 워크스페이스 + 패널 레이아웃 자동 세팅

사용법:
  cmx <path>                       # 디폴트 레이아웃, port 80
  cmx <path> 8081                  # 두 번째 인자가 숫자 → port, 브라우저=http://localhost:8081
  cmx <path> http://app.local:90   # 두 번째 인자가 URL → 그 URL 사용
  cmx <path> 80 --v-simple         # 레이아웃 옵션

옵션:
  --v-default | --layout=default   디폴트 레이아웃 (3단)
  --v-simple  | --layout=simple    단순 레이아웃 (터미널 | 브라우저)
  --v-4split  | --layout=4split    4분할 (dev / test / claude / 브라우저)

디버그:
  CMX_DEBUG=1 cmx <path>

프로젝트별 영구화: <project>/.cmux.conf
  PORT, BROWSER_URL, DEV_CMD, TEST_CMD, CLAUDE_CMD, CODEX_CMD, LAYOUT
HELP
}

# ─── 옵션 파싱 ─────────────────────────────────────────────────────
LAYOUT_ARG=""
POSITIONAL=()
while (( $# > 0 )); do
  case "$1" in
    --v-default|--layout=default) LAYOUT_ARG="default" ;;
    --v-simple|--layout=simple)   LAYOUT_ARG="simple" ;;
    --v-4split|--layout=4split)   LAYOUT_ARG="4split" ;;
    --layout)
      [[ $# -ge 2 ]] || { echo "[x] --layout 옵션은 값이 필요합니다 (default|simple|4split)" >&2; exit 2; }
      shift; LAYOUT_ARG="$1"
      ;;
    -h|--help)
      print_help
      exit 0 ;;
    -*)
      echo "[x] 알 수 없는 옵션: $1" >&2; exit 2 ;;
    *)
      POSITIONAL+=("$1") ;;
  esac
  shift
done
if (( ${#POSITIONAL[@]} > 0 )); then set -- "${POSITIONAL[@]}"; else set --; fi

ARG_WORKDIR="${1:-.}"
ARG_2="${2:-}"        # port(숫자) 또는 URL

# ─── 경로 ──────────────────────────────────────────────────────────
WORKDIR="${ARG_WORKDIR/#\~/$HOME}"
[[ -d "$WORKDIR" ]] || { echo "[x] 디렉토리 없음: $WORKDIR" >&2; exit 2; }
WORKDIR="$(cd "$WORKDIR" && pwd)"
PROJECT_NAME="$(basename "$WORKDIR")"

# ─── 기본값 + .cmux.conf ──────────────────────────────────────────
PORT=80
BROWSER_URL=""
DEV_CMD=""
TEST_CMD=""
CLAUDE_CMD="claude"
CODEX_CMD="codex"
LAYOUT="default"

# .cmux.conf 안전 파서 — 화이트리스트 KEY=VALUE 만 수용.
# `source` 를 쓰면 임의 코드 실행 경로가 되므로 사용 금지.
load_conf() {
  local conf="$1" line key val raw allowed_key ok
  local allowed=(PORT BROWSER_URL DEV_CMD TEST_CMD CLAUDE_CMD CODEX_CMD LAYOUT)
  while IFS= read -r line || [[ -n "$line" ]]; do
    raw="$line"
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      [[ "$val" =~ ^\"(.*)\"$ ]] && val="${BASH_REMATCH[1]}"
      [[ "$val" =~ ^\'(.*)\'$ ]] && val="${BASH_REMATCH[1]}"
      ok=""
      for allowed_key in "${allowed[@]}"; do
        [[ "$key" == "$allowed_key" ]] && { ok=1; break; }
      done
      if [[ -n "$ok" ]]; then
        printf -v "$key" '%s' "$val"
      else
        echo "[!] .cmux.conf: 허용되지 않은 키 무시 — $key" >&2
      fi
    else
      echo "[!] .cmux.conf: 형식 오류 라인 무시 — $raw" >&2
    fi
  done < "$conf"
}

CONF="${WORKDIR}/.cmux.conf"
if [[ -f "$CONF" ]]; then
  load_conf "$CONF"
  echo "[i] .cmux.conf 로드: $CONF"
fi

# 옵션이 .cmux.conf 의 LAYOUT 보다 우선
[[ -n "$LAYOUT_ARG" ]] && LAYOUT="$LAYOUT_ARG"

# ─── 2번째 인자 자동 판별 (port / URL) ───────────────────────────
if [[ -n "$ARG_2" ]]; then
  if [[ "$ARG_2" =~ ^[0-9]+$ ]]; then
    PORT="$ARG_2"
    BROWSER_URL="http://localhost:${PORT}"
  elif [[ "$ARG_2" =~ ^[A-Za-z][A-Za-z0-9+.-]*://.+ ]]; then
    BROWSER_URL="$ARG_2"
    if [[ "$ARG_2" =~ :([0-9]+)(/|$) ]]; then PORT="${BASH_REMATCH[1]}"; fi
  else
    # 스킴 없는 host[:port] 형태로 가정
    BROWSER_URL="http://${ARG_2}"
    if [[ "$ARG_2" =~ :([0-9]+)(/|$) ]]; then PORT="${BASH_REMATCH[1]}"; fi
  fi
fi
[[ -z "$BROWSER_URL" ]] && BROWSER_URL="http://localhost:${PORT}"

# ─── 사전 점검 ─────────────────────────────────────────────────────
command -v cmux >/dev/null || { echo "[x] cmux 미설치 — https://cmux.com" >&2; exit 127; }
SOCK="${CMUX_SOCKET_PATH:-/tmp/cmux.sock}"
if [[ -z "${CMX_SKIP_SOCKET_CHECK:-}" ]]; then
  if [[ ! -S "$SOCK" ]] || ! cmux ping >/dev/null 2>&1; then
    echo "[x] cmux 소켓 없음 — cmux GUI 를 먼저 실행하세요 (Spotlight → cmux)" >&2
    exit 1
  fi
fi

DEBUG="${CMX_DEBUG:-}"

# ─── 도구 사전 점검 (warn-only) ────────────────────────────────────
warn_if_missing() {
  local label="$1" cmd="$2" first
  [[ -z "$cmd" ]] && return 0
  first="${cmd%% *}"
  command -v "$first" >/dev/null 2>&1 || \
    echo "[!] $label 의 첫 토큰 '$first' 이(가) PATH 에 없음 — pane 에서 실패할 수 있음" >&2
}

# ─── cmux 호출 헬퍼 ────────────────────────────────────────────────
cmx_call() {
  local out rc
  if ! out=$(cmux "$@" 2>&1); then
    rc=$?
    echo "[x] cmux $* 실패 (rc=$rc):" >&2
    echo "$out" | sed 's/^/    /' >&2
    exit 3
  fi
  if [[ -n "$DEBUG" ]]; then
    echo "[dbg] cmux $* ↓" >&2
    echo "$out" | sed 's/^/      /' >&2
  fi
  grep -qi '^error' <<<"$out" && { echo "[x] cmux 에러: $out" >&2; exit 3; }
  printf "%s" "$out"
}
extract_ref() {
  local ref
  ref=$(printf "%s" "$1" | grep -oE '(workspace|surface|panel|pane|tab):[0-9]+' | head -1 || true)
  [[ -n "$ref" ]] || { echo "[x] ref 추출 실패: $1" >&2; exit 3; }
  printf "%s" "$ref"
}

new_ws() {
  local cwd="$1" cmd="${2:-}"
  if [[ -n "$cmd" ]]; then
    extract_ref "$(cmx_call new-workspace --cwd "$cwd" --command "$cmd")"
  else
    extract_ref "$(cmx_call new-workspace --cwd "$cwd")"
  fi
}
split_to() {
  # split_to <ws> <base_surface> <direction>
  extract_ref "$(cmx_call new-split "$3" --workspace "$1" --surface "$2")"
}
rename_tab() { cmx_call rename-tab --workspace "$1" --surface "$2" "$3" >/dev/null; }
send_cmd()   { cmx_call send --workspace "$1" --surface "$2" "${3}"$'\n' >/dev/null; }
add_browser() {
  # add_browser <ws> <focus_surface> <direction> <url>
  cmux focus-panel --workspace "$1" --panel "$2" >/dev/null 2>&1 || true
  cmux new-pane --workspace "$1" --type browser --direction "$3" --url "$4" >/dev/null
}
first_surface() { extract_ref "$(cmx_call list-panels --workspace "$1")"; }

# ─── 레이아웃 함수들 ───────────────────────────────────────────────
layout_default() {
  local ws LT LB MT MM MB
  ws=$(new_ws "$WORKDIR")
  cmux rename-workspace --workspace "$ws" "$PROJECT_NAME" >/dev/null
  cmux select-workspace --workspace "$ws" >/dev/null 2>&1 || true

  LT=$(first_surface "$ws")

  # ─── 컬럼을 먼저 다 만든다 (nested split 한계 회피) ─────────────
  # 1) LT 우측에 중간 컬럼 MT 생성
  MT=$(split_to "$ws" "$LT" right)
  # 2) MT 우측에 브라우저 pane 즉시 추가 — 이래야 트리상 [LT | [MT | BR]]
  add_browser "$ws" "$MT" right "$BROWSER_URL"

  # ─── 각 컬럼 내부 행 분할 ──────────────────────────────────────
  # 왼쪽: claude(위) / codex(아래)
  rename_tab "$ws" "$LT" "claude"
  send_cmd "$ws" "$LT" "$CLAUDE_CMD"
  LB=$(split_to "$ws" "$LT" down)
  rename_tab "$ws" "$LB" "codex"
  send_cmd "$ws" "$LB" "$CODEX_CMD"

  # 중간: t1 / t2 / t3
  rename_tab "$ws" "$MT" "t1"
  MM=$(split_to "$ws" "$MT" down)
  rename_tab "$ws" "$MM" "t2"
  MB=$(split_to "$ws" "$MM" down)
  rename_tab "$ws" "$MB" "t3"

  # ─── 비율 조정 시도 (cmux 한계: 정밀 지정 API 없음, 셀 단위 resize) ─
  # 기본 50:50 분할이라 [LT:50 | [MT:25 | BR:25]] 로 시작.
  # 목표 35:35:30 을 위해 LT 를 좁히고 BR 을 늘린다.
  # resize-pane 단위는 셀이라 정밀 비율은 GUI 드래그 권장.
  local AMT="${CMX_RESIZE_AMT:-15}"
  cmux resize-pane --workspace "$ws" --pane "$LT" -L --amount "$AMT" >/dev/null 2>&1 || true
  cmux resize-pane --workspace "$ws" --pane "$MT" -L --amount "$AMT" >/dev/null 2>&1 || true

  echo "[✓] $PROJECT_NAME — layout=default (3단) · $BROWSER_URL"
  echo "    └ 비율은 cmux GUI 에서 divider 드래그로 조정 후 자동 저장됩니다."
  cmux set-status --workspace "$ws" port "$PORT" >/dev/null 2>&1 || true
  cmux notify --title "cmux: $PROJECT_NAME" --subtitle "default" \
    --body "claude+codex | t1/t2/t3 | $BROWSER_URL" >/dev/null
}

layout_simple() {
  local ws s1
  if [[ -n "$DEV_CMD" ]]; then
    ws=$(new_ws "$WORKDIR" "$DEV_CMD")
  else
    ws=$(new_ws "$WORKDIR")
  fi
  cmux rename-workspace --workspace "$ws" "$PROJECT_NAME" >/dev/null
  cmux select-workspace --workspace "$ws" >/dev/null 2>&1 || true
  s1=$(first_surface "$ws")
  rename_tab "$ws" "$s1" "shell"
  add_browser "$ws" "$s1" right "$BROWSER_URL"

  echo "[✓] $PROJECT_NAME — layout=simple · $BROWSER_URL"
  cmux set-status --workspace "$ws" port "$PORT" >/dev/null 2>&1 || true
  cmux notify --title "cmux: $PROJECT_NAME" --subtitle "simple" \
    --body "터미널 | $BROWSER_URL" >/dev/null
}

layout_4split() {
  local ws DEV TEST CC
  if [[ -n "$DEV_CMD" ]]; then
    ws=$(new_ws "$WORKDIR" "$DEV_CMD")
  else
    ws=$(new_ws "$WORKDIR")
  fi
  cmux rename-workspace --workspace "$ws" "$PROJECT_NAME" >/dev/null
  cmux select-workspace --workspace "$ws" >/dev/null 2>&1 || true
  DEV=$(first_surface "$ws")
  TEST=$(split_to "$ws" "$DEV" right)
  rename_tab "$ws" "$TEST" "test"
  [[ -n "$TEST_CMD" ]] && send_cmd "$ws" "$TEST" "$TEST_CMD"
  CC=$(split_to "$ws" "$TEST" down)
  rename_tab "$ws" "$CC" "claude"
  send_cmd "$ws" "$CC" "$CLAUDE_CMD"
  add_browser "$ws" "$CC" down "$BROWSER_URL"

  echo "[✓] $PROJECT_NAME — layout=4split · $BROWSER_URL"
  cmux set-status --workspace "$ws" port "$PORT" >/dev/null 2>&1 || true
  cmux notify --title "cmux: $PROJECT_NAME" --subtitle "4split" \
    --body "dev/test/claude/$BROWSER_URL" >/dev/null
}

# ─── 디스패치 ──────────────────────────────────────────────────────
echo "[i] 프로젝트: $PROJECT_NAME"
echo "[i] 경로    : $WORKDIR"
echo "[i] 포트    : $PORT"
echo "[i] 브라우저: $BROWSER_URL"
echo "[i] 레이아웃: $LAYOUT"
[[ -n "$DEBUG" ]] && echo "[i] 디버그 모드 ON"

case "$LAYOUT" in
  default|3col|3)
    warn_if_missing CLAUDE_CMD "$CLAUDE_CMD"
    warn_if_missing CODEX_CMD  "$CODEX_CMD"
    layout_default ;;
  simple|2col)
    [[ -n "$DEV_CMD" ]] && warn_if_missing DEV_CMD "$DEV_CMD"
    layout_simple ;;
  4split|legacy)
    [[ -n "$DEV_CMD" ]]  && warn_if_missing DEV_CMD  "$DEV_CMD"
    [[ -n "$TEST_CMD" ]] && warn_if_missing TEST_CMD "$TEST_CMD"
    warn_if_missing CLAUDE_CMD "$CLAUDE_CMD"
    layout_4split ;;
  *) echo "[x] 알 수 없는 layout: $LAYOUT  (사용 가능: default|simple|4split)" >&2; exit 2 ;;
esac
