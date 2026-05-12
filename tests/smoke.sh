#!/usr/bin/env bash
# tests/smoke.sh
# 단위 + 통합 테스트. cmux 가 없어도 동작.
# install.sh 가 마지막에 호출해 부트스트랩 정상 여부를 점검한다.
#
# CI 등에서는 통합 모드가 mock cmux 로 실제 스크립트를 호출해 호출 시퀀스를 검증.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0; FAIL=0

assert() {
  local desc="$1" expect="$2" actual="$3"
  if [[ "$expect" == "$actual" ]]; then
    printf "  [+] %s\n" "$desc"; PASS=$((PASS+1))
  else
    printf "  [x] %s\n      expect: %s\n      actual: %s\n" "$desc" "$expect" "$actual"
    FAIL=$((FAIL+1))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    printf "  [+] %s\n" "$desc"; PASS=$((PASS+1))
  else
    printf "  [x] %s\n      needle: %s\n      hay   : %s\n" "$desc" "$needle" "$haystack"
    FAIL=$((FAIL+1))
  fi
}

echo "── 1. syntax check ──"
for f in install.sh bin/cmux-setup.sh bin/set-cursor-default.sh bin/check-default-apps.sh tests/smoke.sh shell/aliases.zsh; do
  if bash -n "$REPO_DIR/$f" 2>/dev/null; then
    echo "  [+] $f"
    PASS=$((PASS+1))
  else
    echo "  [x] $f — bash 문법 오류"
    FAIL=$((FAIL+1))
  fi
done

echo
echo "── 2. 인자 자동 판별 (port / URL) ──"
sim_arg() {
  local arg2="$1" want_port="$2" want_url="$3"
  local PORT=80 BROWSER_URL=""
  if [[ -n "$arg2" ]]; then
    if [[ "$arg2" =~ ^[0-9]+$ ]]; then
      PORT="$arg2"; BROWSER_URL="http://localhost:${PORT}"
    elif [[ "$arg2" =~ ^[A-Za-z][A-Za-z0-9+.-]*://.+ ]]; then
      BROWSER_URL="$arg2"
      if [[ "$arg2" =~ :([0-9]+)(/|$) ]]; then PORT="${BASH_REMATCH[1]}"; fi
    else
      BROWSER_URL="http://${arg2}"
      if [[ "$arg2" =~ :([0-9]+)(/|$) ]]; then PORT="${BASH_REMATCH[1]}"; fi
    fi
  fi
  [[ -z "$BROWSER_URL" ]] && BROWSER_URL="http://localhost:${PORT}"
  assert "arg2='$arg2'" "port=$want_port url=$want_url" "port=$PORT url=$BROWSER_URL"
}
sim_arg ""                     80   "http://localhost:80"
sim_arg "8081"                 8081 "http://localhost:8081"
sim_arg "http://app.local"     80   "http://app.local"
sim_arg "HTTPS://APP.LOCAL"    80   "HTTPS://APP.LOCAL"
sim_arg "http://app.local:9090" 9090 "http://app.local:9090"
sim_arg "app.local:7000"       7000 "http://app.local:7000"

echo
echo "── 3. 옵션 파싱 (--v-*) ──"
sim_layout() {
  local LAYOUT_ARG="" POSITIONAL=()
  for a in "$@"; do
    case "$a" in
      --v-default|--layout=default) LAYOUT_ARG="default" ;;
      --v-simple|--layout=simple)   LAYOUT_ARG="simple" ;;
      --v-4split|--layout=4split)   LAYOUT_ARG="4split" ;;
      *) POSITIONAL+=("$a") ;;
    esac
  done
  printf "%s" "${LAYOUT_ARG:-default}"
}
assert "default 옵션 없으면 default" "default" "$(sim_layout ~/work/x 80)"
assert "--v-simple"                    "simple"  "$(sim_layout ~/work/x 80 --v-simple)"
assert "--v-4split 위치 자유"          "4split"  "$(sim_layout --v-4split ~/work/x)"

echo
echo "── 4. extract_ref 로직 ──"
extract_ref() {
  printf "%s" "$1" | grep -oE '(workspace|surface|panel|pane|tab):[0-9]+' | head -1 || true
}
assert "OK workspace:7"   "workspace:7" "$(extract_ref 'OK workspace:7')"
assert "OK surface:3"     "surface:3"   "$(extract_ref 'OK surface:3')"
assert "Error: foo"       ""            "$(extract_ref 'Error: foo')"
assert "rate limit: 429"  ""            "$(extract_ref 'rate limit: 429')"
assert "panel:5 만 픽업"  "panel:5"     "$(extract_ref 'OK panel:5 created at port:80')"

echo
echo "── 5. .cmux.conf 화이트리스트 파서 ──"
TMP_CONF=$(mktemp)
cat > "$TMP_CONF" <<'CONF'
PORT=8081
BROWSER_URL="http://app.local"
LAYOUT=simple
# 주석은 무시
EVIL=$(rm -rf /tmp/should-not-run)
DEV_CMD="npm run dev"
CONF

# load_conf 본체만 떼와서 시뮬
load_conf_test() {
  local conf="$1" line key val raw allowed_key ok
  local allowed=(PORT BROWSER_URL DEV_CMD TEST_CMD CLAUDE_CMD CODEX_CMD LAYOUT)
  PORT=80 BROWSER_URL="" DEV_CMD="" LAYOUT="default" EVIL=""
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
      [[ -n "$ok" ]] && printf -v "$key" '%s' "$val"
    fi
  done < "$conf"
}
load_conf_test "$TMP_CONF" 2>/dev/null
assert "PORT 파싱"          "8081"                "$PORT"
assert "BROWSER_URL 따옴표"  "http://app.local"    "$BROWSER_URL"
assert "DEV_CMD 따옴표"      "npm run dev"         "$DEV_CMD"
assert "LAYOUT"              "simple"              "$LAYOUT"
assert "EVIL 키 무시"        ""                    "$EVIL"
assert "EVIL 파일 미생성"    "no"                  "$([[ -e /tmp/should-not-run ]] && echo yes || echo no)"
rm -f "$TMP_CONF"

echo
echo "── 6. 통합: mock cmux 로 실제 cmux-setup.sh 호출 ──"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# mock cmux: 모든 호출을 로그에 기록하고 적절한 ref 반환
cat >"$TMP/cmux" <<'MOCK'
#!/usr/bin/env bash
echo "$@" >> "${CMUX_LOG:-/dev/null}"
case "${1:-}" in
  ping)              echo "PONG"; exit 0 ;;
  new-workspace)     echo "OK workspace:1" ;;
  new-split)         echo "OK surface:2" ;;
  list-panels)       echo "OK surface:9" ;;
  rename-tab|rename-workspace|select-workspace|focus-panel|new-pane|set-status|notify|send|resize-pane)
                     echo "OK" ;;
  *)                 echo "OK" ;;
esac
MOCK
chmod +x "$TMP/cmux"

# claude/codex 도 stub (warn_if_missing 통과용)
for stub in claude codex; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/$stub"
  chmod +x "$TMP/$stub"
done

CMUX_LOG="$TMP/calls.log"
WORKDIR="$TMP/sample"; mkdir -p "$WORKDIR"

run_cmx() {
  PATH="$TMP:$PATH" \
    CMX_SKIP_SOCKET_CHECK=1 \
    CMUX_LOG="$CMUX_LOG" \
    "$REPO_DIR/bin/cmux-setup.sh" "$@" 2>&1
}

: > "$CMUX_LOG"
out=$(run_cmx "$WORKDIR" --v-simple)
assert_contains "simple: new-workspace 호출됨"      "new-workspace" "$(cat "$CMUX_LOG")"
assert_contains "simple: 브라우저 pane 추가됨"       "type browser"  "$(cat "$CMUX_LOG")"
assert_contains "simple: 출력에 layout=simple 포함"  "layout=simple" "$out"

: > "$CMUX_LOG"
out=$(run_cmx "$WORKDIR" 8080 --v-default)
assert_contains "default: send 로 claude 자동 실행" "send"          "$(cat "$CMUX_LOG")"
assert_contains "default: 포트 8080 표기"            "포트    : 8080" "$out"

: > "$CMUX_LOG"
out=$(run_cmx "$WORKDIR" --v-4split)
assert_contains "4split: rename-tab claude"  "claude" "$(cat "$CMUX_LOG")"

# .cmux.conf 가 source 되지 않는지 확인
cat > "$WORKDIR/.cmux.conf" <<'EVIL'
PORT=9999
BROWSER_URL=http://from-conf.local
EVIL_CMD=$(touch "$WORKDIR/PWNED")
EVIL
: > "$CMUX_LOG"
out=$(run_cmx "$WORKDIR")
assert "악성 .cmux.conf 가 파일 생성 못함"        "no" "$([[ -e "$WORKDIR/PWNED" ]] && echo yes || echo no)"
assert_contains ".cmux.conf 의 PORT=9999 적용"    "포트    : 9999" "$out"
assert_contains ".cmux.conf 의 BROWSER_URL 적용"  "from-conf.local" "$out"

# --layout 인자 누락 시 명확한 에러
rc_out=$(run_cmx "$WORKDIR" --layout 2>&1 || true)
assert_contains "--layout 인자 누락 메시지"        "값이 필요" "$rc_out"

# 알 수 없는 layout (값으로 전달되어 디스패치 단계에서 거부)
rc_out=$(run_cmx "$WORKDIR" --layout ghost 2>&1 || true)
assert_contains "알 수 없는 layout 거부"           "알 수 없는 layout" "$rc_out"

echo
echo "── 7. 파일 존재 ──"
for f in README.md LICENSE install.sh \
         bin/cmux-setup.sh bin/set-cursor-default.sh bin/check-default-apps.sh \
         shell/aliases.zsh shell/aliases.local.zsh.example \
         templates/cmux.conf.example \
         docs/usage.md docs/layouts.md docs/shortcuts.md docs/default-apps.md docs/troubleshooting.md docs/setup-prompt.md; do
  if [[ -e "$REPO_DIR/$f" ]]; then
    echo "  [+] $f"
    PASS=$((PASS+1))
  else
    echo "  [x] $f 누락"
    FAIL=$((FAIL+1))
  fi
done

echo
echo "── 8. 클라이언트명 sweep (퍼블릭 위생) ──"
# 과거 커밋에 있던 회사/클라이언트 추정 단어가 다시 들어오면 차단
sweep_terms=(frecto tosstoss "tosstoss/" "dna/real" "db-mcp" tom221101)
sweep_excludes='tests/smoke.sh|\.git/'
for term in "${sweep_terms[@]}"; do
  hits=$(grep -RInE "$term" "$REPO_DIR" 2>/dev/null | grep -vE "$sweep_excludes" || true)
  if [[ -z "$hits" ]]; then
    echo "  [+] no '$term'"
    PASS=$((PASS+1))
  else
    echo "  [x] '$term' 노출:"
    echo "$hits" | sed 's/^/      /'
    FAIL=$((FAIL+1))
  fi
done

echo
echo "── 결과 ──"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
exit $(( FAIL > 0 ? 1 : 0 ))
