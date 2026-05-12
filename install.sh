#!/usr/bin/env bash
# install.sh — cmux-setup 부트스트랩
#
# 사용:
#   git clone https://github.com/tomtomjskim/cmux-setup <REPO_DIR>
#   <REPO_DIR>/install.sh
#
#   <REPO_DIR>/install.sh uninstall   # ~/.zshrc 통합 라인 제거
#
# 두 번 실행해도 안전 (idempotent).

set -euo pipefail

# ─── 색상 ────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YLW=$'\033[33m'
  C_CYN=$'\033[36m'; C_DIM=$'\033[2m';  C_RST=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YLW=""; C_CYN=""; C_DIM=""; C_RST=""
fi
log()   { printf "%s[i]%s %s\n" "$C_CYN" "$C_RST" "$*"; }
ok()    { printf "%s[+]%s %s\n" "$C_GRN" "$C_RST" "$*"; }
warn()  { printf "%s[!]%s %s\n" "$C_YLW" "$C_RST" "$*"; }
err()   { printf "%s[x]%s %s\n" "$C_RED" "$C_RST" "$*" 1>&2; }
step()  { printf "\n%s── %s%s\n" "$C_DIM" "$*" "$C_RST"; }

# ─── 리포 경로 (이 스크립트 위치 기준) ──────────────────────────
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

ZSHRC="$HOME/.zshrc"
MARK_BEGIN="# >>> cmux-setup >>>"
MARK_END="# <<< cmux-setup <<<"

# ─── uninstall ────────────────────────────────────────────────────
if [[ "${1:-}" == "uninstall" ]]; then
  step "cmux-setup 제거"
  if [[ ! -f "$ZSHRC" ]]; then
    ok "~/.zshrc 가 없어 제거할 것 없음"
    exit 0
  fi
  if grep -Fq "$MARK_BEGIN" "$ZSHRC"; then
    BACKUP="${ZSHRC}.bak.$(date +%s)"
    cp "$ZSHRC" "$BACKUP"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0 == b {skip=1; next}
      $0 == e {skip=0; next}
      !skip
    ' "$BACKUP" > "$ZSHRC"
    ok "~/.zshrc 의 cmux-setup 블록 제거"
    log "백업: $BACKUP"
  else
    # 구버전 호환: 단일 라인 형태도 정리
    if grep -Fq 'cmux-setup/shell/aliases.zsh' "$ZSHRC"; then
      BACKUP="${ZSHRC}.bak.$(date +%s)"
      cp "$ZSHRC" "$BACKUP"
      grep -vF 'cmux-setup/shell/aliases.zsh' "$BACKUP" | grep -vF '# cmux-setup' > "$ZSHRC"
      ok "구버전 cmux-setup 라인 제거"
      log "백업: $BACKUP"
    else
      ok "~/.zshrc 에 cmux-setup 통합 흔적 없음"
    fi
  fi
  echo
  log "다음 단계:"
  log "  1) 새 zsh 셸 열거나 'source ~/.zshrc'"
  log "  2) (선택) 리포 디렉토리도 지우려면: rm -rf \"$REPO_DIR\""
  exit 0
fi

step "cmux-setup 부트스트랩"
log  "리포 위치: $REPO_DIR"

# ─── 1) OS 체크 ─────────────────────────────────────────────────
step "1/6  OS 체크"
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "macOS 전용입니다 (cmux 자체가 macOS 앱). 현재: $(uname -s)"
  exit 1
fi
ok "macOS 확인"

# ─── 2) Homebrew ────────────────────────────────────────────────
step "2/6  Homebrew 점검"
if command -v brew >/dev/null 2>&1; then
  ok "brew $(brew --version | head -1)"
else
  warn "Homebrew 미설치 — 일부 의존성을 자동 설치하지 못합니다."
  warn "설치: https://brew.sh 에서 1줄 명령 실행 후 install.sh 다시 실행 권장."
fi

# ─── 3) cmux.app ────────────────────────────────────────────────
step "3/6  cmux.app 점검"
if [[ -d /Applications/cmux.app ]] || [[ -d "$HOME/Applications/cmux.app" ]]; then
  ok "cmux.app 설치됨"
elif mdfind "kMDItemCFBundleIdentifier == 'com.manaflow.cmux'" 2>/dev/null | grep -q .; then
  ok "cmux.app 설치됨 (Spotlight)"
elif command -v cmux >/dev/null 2>&1; then
  ok "cmux CLI 사용 가능"
else
  warn "cmux.app 을 찾지 못했습니다."
  warn "다음 중 하나로 설치:"
  warn "  • brew install --cask manaflow/cmux/cmux   (가능한 경우)"
  warn "  • 또는 https://cmux.com 에서 DMG 다운로드"
  warn "설치 후 한 번 실행해 /usr/local/bin/cmux 가 등록되도록 하세요."
fi

# ─── 4) 선택 의존성: duti ───────────────────────────────────────
step "4/6  duti (코드 파일 기본 앱 변경용, 선택)"
if command -v duti >/dev/null 2>&1; then
  ok "duti 설치됨"
else
  if command -v brew >/dev/null 2>&1; then
    if [[ "${AUTO_INSTALL_DUTI:-}" == "1" ]]; then
      ans="y"
    elif [[ ! -t 0 ]]; then
      ans="n"
    else
      printf "%s[?]%s duti 를 brew 로 지금 설치할까요? [y/N]: " "$C_CYN" "$C_RST"
      read -r ans
    fi
    if [[ "$ans" =~ ^[yY]$ ]]; then
      brew install duti && ok "duti 설치 완료" || warn "duti 설치 실패 — set-cursor-default 만 영향"
    else
      log "duti 설치 건너뜀 — 나중에 'brew install duti' 로 가능"
    fi
  else
    warn "duti 미설치 — Cursor 일괄 연결 기능을 쓰려면 'brew install duti'"
  fi
fi

# ─── 5) ~/.zshrc 통합 ────────────────────────────────────────────
step "5/6  ~/.zshrc 통합"
if [[ ! -f "$ZSHRC" ]]; then
  touch "$ZSHRC"
  log "~/.zshrc 가 없어서 생성"
fi

# 구버전 (단일 라인 형태) 자동 정리
if ! grep -Fq "$MARK_BEGIN" "$ZSHRC" && grep -Fq 'cmux-setup/shell/aliases.zsh' "$ZSHRC"; then
  BACKUP="${ZSHRC}.bak.$(date +%s)"
  cp "$ZSHRC" "$BACKUP"
  grep -vF 'cmux-setup/shell/aliases.zsh' "$BACKUP" | grep -vxF '# cmux-setup' > "$ZSHRC"
  log "구버전 cmux-setup 라인 정리 (백업: $BACKUP)"
fi

if grep -Fq "$MARK_BEGIN" "$ZSHRC"; then
  ok "이미 ~/.zshrc 에 통합됨 (블록 마커 발견)"
else
  {
    echo ""
    echo "$MARK_BEGIN"
    echo "export CMUX_SETUP_DIR=\"$REPO_DIR\""
    echo 'source "$CMUX_SETUP_DIR/shell/aliases.zsh"'
    echo "$MARK_END"
  } >> "$ZSHRC"
  ok "~/.zshrc 에 cmux-setup 블록 추가 (CMUX_SETUP_DIR=$REPO_DIR)"
fi

# 머신별 사적 alias 파일이 없으면 example 복사 권유 (자동 복사는 안 함)
LOCAL="$REPO_DIR/shell/aliases.local.zsh"
EXAMPLE="$REPO_DIR/shell/aliases.local.zsh.example"
if [[ ! -f "$LOCAL" && -f "$EXAMPLE" ]]; then
  log "선택: 자주 쓰는 프로젝트 단축 alias 를 두려면:"
  log "    cp \"$EXAMPLE\" \"$LOCAL\" 후 본인 환경에 맞게 수정"
fi

# ─── 6) smoke ────────────────────────────────────────────────────
step "6/6  smoke 점검"
"$REPO_DIR/bin/cmux-setup.sh" -h >/dev/null 2>&1 && ok "cmux-setup.sh 호출 정상" \
  || warn "cmux-setup.sh -h 실행 실패 — 권한/문법 점검 필요"

if [[ -x "$REPO_DIR/tests/smoke.sh" ]]; then
  "$REPO_DIR/tests/smoke.sh" >/dev/null 2>&1 && ok "tests/smoke.sh 통과" \
    || warn "tests/smoke.sh 실패 — tests/smoke.sh 직접 실행해 원인 확인"
fi

# ─── 마무리 ──────────────────────────────────────────────────────
echo
ok  "[✓] cmux setup completed"
echo
echo "${C_DIM}다음 단계:${C_RST}"
echo "  1) 새 zsh 셸 열기 (또는 'source ~/.zshrc')"
echo "  2) cmux GUI 실행 (Spotlight → 'cmux')"
echo "  3) 동작 확인:  cmx ~/work/myapp 80"
echo "  4) 단축키 충돌 해결:  docs/shortcuts.md 의 ⌃⌥1-9 재바인딩"
echo "  5) 코드 파일 Cursor 로:  ${REPO_DIR}/bin/set-cursor-default.sh"
echo "  6) 제거하려면:           ${REPO_DIR}/install.sh uninstall"
