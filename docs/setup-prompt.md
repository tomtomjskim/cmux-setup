# 다른 PC 에 동일 셋업 적용 — AI 에이전트 프롬프트

새 macOS 머신에서 동일한 cmux 환경을 한 번에 재현하려면, Claude Code / Cursor 같은 AI 에이전트에 아래 프롬프트를 그대로 붙여 넣어 실행시키면 된다.

## 프롬프트 (그대로 복사해서 사용)

```text
이 macOS 머신에 cmux 셋업을 적용해줘.

repo: https://github.com/tomtomjskim/cmux-setup
대상 경로: 아래 <REPO_DIR> 자리에 본인이 원하는 경로 (예: ~/dev/cmux-setup, ~/work/tools/cmux-setup)

순서:
1) <REPO_DIR> 에 git clone (이미 있으면 git -C <REPO_DIR> pull)
2) <REPO_DIR>/install.sh 실행
   → 스크립트가 자동으로 ~/.zshrc 에
       export CMUX_SETUP_DIR="<REPO_DIR>"
       source "$CMUX_SETUP_DIR/shell/aliases.zsh"
     두 줄을 추가합니다 (idempotent — 두 번 실행해도 안전).
3) 출력 마지막에 "[✓] cmux setup completed" 가 보이는지 확인
4) cmux.app 이 미설치면 아래 중 하나 안내:
   • brew install --cask manaflow/cmux/cmux
   • https://cmux.com 에서 DMG 다운로드
   설치 후 한 번 실행해서 /usr/local/bin/cmux 가 등록되도록.
5) 새 zsh 셸을 열거나 `source ~/.zshrc` 후 `cmx --help` 가 동작하는지 sanity check
6) macOS 단축키 충돌 해결을 위해 docs/shortcuts.md 의 ⌃⌥1–9 재바인딩 절차를 사용자에게 보여줄 것
7) 코드 파일이 Xcode 로 안 열리도록 다음 명령을 한 번 실행할지 사용자에게 물어볼 것:
   <REPO_DIR>/bin/set-cursor-default.sh

원칙:
- 이미 있는 ~/.zshrc 는 수정 최소화. install.sh 가 한 블록만 중복 없이 추가.
- 실패하면 로그 보존하고 사용자에게 보고만 — 임의로 우회/추측 금지.
- 끝나면 마지막에 다음 4개 명령을 안내:
    cmx
    cmx ~/work/myapp
    cmx ~/work/myapp 8080
    cmx ~/work/myapp 8080 --v-simple

추가 사항 (선택):
- 머신/회사별 단축 alias 가 필요하면 아래 안내:
    cp <REPO_DIR>/shell/aliases.local.zsh.example \
       <REPO_DIR>/shell/aliases.local.zsh
  그 후 본인 환경에 맞게 수정. 이 파일은 .gitignore 되어 있어 외부에 노출되지 않음.
```

## 수동 명령으로 진행하고 싶으면

`<REPO_DIR>` 자리에 본인 경로를 넣어 실행:

```bash
REPO_DIR="$HOME/dev/cmux-setup"   # 또는 본인 선호 경로

# 1) clone + install
git clone https://github.com/tomtomjskim/cmux-setup.git "$REPO_DIR"
"$REPO_DIR/install.sh"

# 2) 새 셸 또는 source
source ~/.zshrc

# 3) cmux GUI 실행 (Spotlight)

# 4) 동작 확인
cmx ~/work/myapp 80

# 5) (선택) Cursor 매핑
"$REPO_DIR/bin/set-cursor-default.sh"

# 6) (선택) 머신별 alias
cp "$REPO_DIR/shell/aliases.local.zsh.example" \
   "$REPO_DIR/shell/aliases.local.zsh"
$EDITOR "$REPO_DIR/shell/aliases.local.zsh"
```
