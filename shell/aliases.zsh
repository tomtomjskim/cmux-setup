# cmux-setup aliases — 공용 (git 에 커밋)
# install.sh 가 ~/.zshrc 에
#   export CMUX_SETUP_DIR="<repo-path>"
#   source "$CMUX_SETUP_DIR/shell/aliases.zsh"
# 두 줄을 자동으로 추가합니다. 수동으로 source 하는 경우 CMUX_SETUP_DIR 를 먼저 export 해야 합니다.

if [[ -z "${CMUX_SETUP_DIR:-}" ]]; then
  echo "[cmux-setup] CMUX_SETUP_DIR 가 설정되지 않음. install.sh 를 다시 실행하거나" >&2
  echo "             ~/.zshrc 에 export CMUX_SETUP_DIR=<repo-path> 를 추가하세요." >&2
  return 1 2>/dev/null || exit 1
fi
if [[ ! -d "$CMUX_SETUP_DIR" ]]; then
  echo "[cmux-setup] CMUX_SETUP_DIR 경로 없음: $CMUX_SETUP_DIR" >&2
  return 1 2>/dev/null || exit 1
fi

# ─── 글로벌 단축 — 어느 프로젝트든 이걸로 ───────────────────────────
# 사용법:
#   cmx                              # 현재 디렉토리, default layout
#   cmx ~/dev/myApp                  # port 80
#   cmx ~/dev/myApp 8081             # → localhost:8081
#   cmx ~/dev/myApp http://app.local # URL 인자
#   cmx ~/dev/myApp 80 --v-simple    # simple 레이아웃
#
# 레이아웃 옵션:
#   --v-default  (= 디폴트)   왼쪽:claude/codex | 중간:터미널 3등분 | 오른쪽:브라우저
#   --v-simple                터미널 | 브라우저
#   --v-4split   (= 이전 디폴트)  dev/test/claude/브라우저 4분할
alias cmx='"$CMUX_SETUP_DIR/bin/cmux-setup.sh"'

# ─── 보조 도구 ──────────────────────────────────────────────────────
alias cmx-cursor-default='"$CMUX_SETUP_DIR/bin/set-cursor-default.sh"'
alias cmx-check-apps='"$CMUX_SETUP_DIR/bin/check-default-apps.sh"'

# ─── 머신/회사별 사적 alias (있으면 자동 로드, 없으면 무시) ─────────
# 회사 프로젝트, 사적 경로 등은 $CMUX_SETUP_DIR/shell/aliases.local.zsh 에 둔다.
# 이 파일은 .gitignore 에 들어가 있어 외부에 노출되지 않는다.
if [[ -f "$CMUX_SETUP_DIR/shell/aliases.local.zsh" ]]; then
  source "$CMUX_SETUP_DIR/shell/aliases.local.zsh"
fi
