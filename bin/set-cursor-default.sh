#!/usr/bin/env bash
# set-cursor-default.sh
# 자주 쓰는 코드 확장자의 기본 앱을 Cursor 로 일괄 설정한다.
# cmux 터미널에서 파일 경로 클릭 시 Xcode 가 아닌 Cursor 가 열리도록.
#
# 사용:
#   ./set-cursor-default.sh             # 기본 확장자 목록 적용
#   ./set-cursor-default.sh ts tsx php  # 인자로 받은 확장자만 적용
#   EXTRA_EXTS="rs zig" ./set-cursor-default.sh   # 기본 + 추가
#
# 다른 에디터를 쓰려면 EDITOR_APP 환경변수로 덮어쓰기:
#   EDITOR_APP="VS Code" ./set-cursor-default.sh
#   EDITOR_APP="Zed"     ./set-cursor-default.sh
#
# 자동 설치 동의 우회 (CI 등):
#   AUTO_INSTALL_DUTI=1 ./set-cursor-default.sh

set -euo pipefail

EDITOR_APP="${EDITOR_APP:-Cursor}"

# ─── 사전 점검 ───────────────────────────────────────────────────
need() { command -v "$1" >/dev/null || return 1; }

if ! need duti; then
  echo "[i] duti 미설치."
  if ! need brew; then
    echo "[x] Homebrew 가 없습니다. https://brew.sh 에서 brew 먼저 설치하세요." >&2
    exit 127
  fi
  if [[ "${AUTO_INSTALL_DUTI:-}" == "1" ]]; then
    answer="y"
  else
    printf "[?] duti 를 brew 로 지금 설치할까요? [y/N]: "
    read -r answer
  fi
  if [[ "$answer" =~ ^[yY]$ ]]; then
    brew install duti
  else
    echo "[x] duti 가 필요합니다. brew install duti 후 다시 실행하세요." >&2
    exit 1
  fi
fi

# 에디터 앱 존재 확인 + bundle ID 추출
if ! BUNDLE_ID=$(osascript -e "id of app \"$EDITOR_APP\"" 2>/dev/null); then
  echo "[x] '$EDITOR_APP' 앱을 찾을 수 없습니다. 설치되어 있는지 확인하세요." >&2
  echo "    Spotlight 에서 한 번 실행해본 뒤 다시 시도하면 등록됩니다." >&2
  exit 1
fi

echo "[i] 에디터  : $EDITOR_APP"
echo "[i] bundle : $BUNDLE_ID"

# ─── 확장자 목록 ─────────────────────────────────────────────────
# 주의: html/htm/xml/svg 등 "브라우저나 뷰어가 열어줘야 자연스러운" 포맷은
# 의도적으로 제외했다. 인자로 명시할 때만 적용된다.
#   예: ./set-cursor-default.sh html htm xml
DEFAULT_EXTS=(
  # JS/TS 계열
  ts tsx js jsx mjs cjs
  # 스타일 (브라우저 미리보기 거의 없음)
  css scss sass less
  # 백엔드 언어
  py rb go rs java kt swift
  c cpp cc h hpp
  php phtml
  # 데이터 포맷 (xml/svg 는 의도적 제외)
  json yaml yml toml ini
  # 문서/설정
  md mdx rst txt log
  conf env
  # 쉘
  sh bash zsh fish
  # 쿼리/스키마
  sql graphql gql prisma
  # 컴포넌트
  vue svelte astro
  # 빌드/CI
  dockerfile makefile
)

if [[ $# -gt 0 ]]; then
  EXTS=("$@")
else
  EXTS=("${DEFAULT_EXTS[@]}")
  if [[ -n "${EXTRA_EXTS:-}" ]]; then
    # shellcheck disable=SC2206
    EXTS=("${EXTS[@]}" ${EXTRA_EXTS})
  fi
fi

# ─── 적용 ─────────────────────────────────────────────────────────
echo "[i] ${#EXTS[@]} 개 확장자 일괄 등록"
OK=0; FAIL=0
for ext in "${EXTS[@]}"; do
  if duti -s "$BUNDLE_ID" ".$ext" all 2>/dev/null; then
    printf "  [+] .%-12s → %s\n" "$ext" "$EDITOR_APP"
    OK=$((OK+1))
  else
    printf "  [!] .%-12s 실패 (확장자 UTI 미등록일 수 있음)\n" "$ext"
    FAIL=$((FAIL+1))
  fi
done

echo
echo "[✓] 완료 — 성공 $OK · 실패 $FAIL"
echo "    이제 cmux 터미널에서 파일 경로를 ⌘+클릭 하거나"
echo "    Finder 에서 더블클릭하면 $EDITOR_APP 로 열립니다."
