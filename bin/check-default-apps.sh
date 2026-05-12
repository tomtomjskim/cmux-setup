#!/usr/bin/env bash
# check-default-apps.sh
# 자주 보는 확장자들이 어떤 앱에 매핑되어 있는지 한 번에 점검.
# set-cursor-default.sh 의 부작용을 진단하고 원복하기 위해.
#
# 사용:
#   ./check-default-apps.sh                  # 진단
#   ./check-default-apps.sh --revert-web     # html/htm/xml/svg 을 기본 브라우저로 되돌리기
#
# 환경변수:
#   BROWSER_APP="Safari"|"Google Chrome"|"Arc"|"Brave Browser"  (revert 대상 앱)

set -euo pipefail

need() { command -v "$1" >/dev/null || { echo "[x] '$1' 미설치"; exit 127; }; }
need duti

# ─── macOS 기본 브라우저 자동 감지 ──────────────────────────────
# LaunchServices secure.plist 에서 https URL scheme handler 의 bundle id 추출.
# 못 찾으면 Safari fallback.
detect_default_browser() {
  local plist="${HOME}/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
  local bid app
  if [[ -f "$plist" ]] && command -v python3 >/dev/null 2>&1; then
    bid=$(PLIST_PATH="$plist" python3 - <<'PY' 2>/dev/null || true
import os, plistlib, sys
try:
    with open(os.environ["PLIST_PATH"], "rb") as f:
        p = plistlib.load(f)
    for h in p.get("LSHandlers", []):
        if h.get("LSHandlerURLScheme") == "https" and h.get("LSHandlerRoleAll"):
            print(h["LSHandlerRoleAll"]); sys.exit(0)
except Exception:
    pass
PY
)
  fi
  if [[ -n "${bid:-}" ]]; then
    app=$(osascript -e "name of application id \"$bid\"" 2>/dev/null || true)
    [[ -n "$app" ]] && { printf "%s" "$app"; return 0; }
  fi
  printf "Safari"
}

BROWSER_APP="${BROWSER_APP:-$(detect_default_browser)}"

# ─── 진단 ────────────────────────────────────────────────────────
diagnose() {
  echo "── 코드 편집용 확장자 (Cursor 권장) ──"
  for e in ts tsx js jsx py rb go rs php json md yaml sql; do
    printf "  .%-6s → %s\n" "$e" "$(duti -x "$e" 2>/dev/null | head -1 || echo '미설정')"
  done

  echo
  echo "── 브라우저/뷰어 영역 확장자 (Cursor 가 잡혔으면 부작용) ──"
  for e in html htm xml svg pdf png jpg; do
    out=$(duti -x "$e" 2>/dev/null | head -1 || true)
    flag=""
    [[ "$out" == *"Cursor"* ]] && flag="  ← ⚠ Cursor 가 잡고 있음"
    printf "  .%-6s → %-30s%s\n" "$e" "${out:-미설정}" "$flag"
  done

  echo
  echo "── 명령 안내 ──"
  echo "  ./check-default-apps.sh --revert-web        # html/htm/xml/svg → \$BROWSER_APP 으로 되돌리기"
  echo "  BROWSER_APP='Google Chrome' ./check-default-apps.sh --revert-web"
}

# ─── 원복 ────────────────────────────────────────────────────────
revert_web() {
  local bid
  if ! bid=$(osascript -e "id of app \"$BROWSER_APP\"" 2>/dev/null); then
    echo "[x] 브라우저 앱을 찾을 수 없습니다: $BROWSER_APP" >&2
    echo "    BROWSER_APP 환경변수로 정확한 앱 이름을 지정하세요." >&2
    exit 1
  fi
  echo "[i] $BROWSER_APP ($bid) 로 되돌리는 중..."
  for e in html htm xml svg; do
    if duti -s "$bid" ".$e" all 2>/dev/null; then
      printf "  [+] .%-6s → %s\n" "$e" "$BROWSER_APP"
    else
      printf "  [!] .%-6s 실패\n" "$e"
    fi
  done
  echo "[✓] 완료"
}

case "${1:-}" in
  --revert-web)   revert_web ;;
  ""|--diagnose)  diagnose ;;
  -h|--help)
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *) echo "[x] 알 수 없는 옵션: $1"; exit 2 ;;
esac
