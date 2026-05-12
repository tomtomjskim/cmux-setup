# 단축키 — macOS 충돌 회피

cmux 의 디폴트 단축키 중 **`⌃ 1`–`⌃ 9` (surface 점프)** 가 macOS Mission Control 의 "Switch to Desktop N" 과 충돌한다.

## A. cmux 에서 재바인딩 (권장)

`⌘ ,` → Keyboard Shortcuts → "Jump to surface 1" ~ "Jump to surface 9" 9개 항목을 각각 클릭해 `⌃ ⌥ 1` ~ `⌃ ⌥ 9` 로 다시 입력. 5분 작업, 재시작 불필요.

| 기본 | 권장 변경 |
|---|---|
| `⌃ 1`–`⌃ 8` Jump to surface 1–8 | `⌃ ⌥ 1`–`⌃ ⌥ 8` |
| `⌃ 9` Jump to last surface | `⌃ ⌥ 9` |

**왜 `⌥ 1-9` 가 아니라 `⌃ ⌥ 1-9` 인가** — macOS 에서 `⌥` + 숫자는 특수문자 입력(`¡™£¢…`)으로 OS 가 가로채서 단축키로 잘 안 잡힌다. modifier 두 개 조합이 안전.

## B. macOS Mission Control 단축키 끄기

System Settings → Keyboard → Keyboard Shortcuts → Mission Control → "Switch to Desktop 1~9" 체크 해제. 이러면 cmux 기본 `⌃ 1–9` 가 그대로 동작.

Spaces 를 적극 쓰는 사람이면 A 권장.

## C. 자동화 (옵션)

cmux 종료 후 단축키 저장 위치 확인:

```bash
defaults read $(osascript -e 'id of app "cmux"') 2>/dev/null \
  | grep -iE 'shortcut|keybind|surface|jump'
```

키 이름이 식별되면 `defaults write` 로 9개 일괄 변경 가능. 출력 결과를 보고 스크립트화하면 머신 이주 시 편하다.

## 자주 쓰는 cmux 단축키 (디폴트)

| 단축키 | 동작 |
|---|---|
| `⌘ 1`–`⌘ 9` | 워크스페이스 점프 (충돌 없음) |
| `⌘ D` / `⌘ ⇧ D` | 우측 / 아래 split (터미널) |
| `⌥ ⌘ D` / `⌥ ⌘ ⇧ D` | 우측 / 아래 split (브라우저) |
| `⌥ ⌘ ←↑→↓` | 패널 포커스 이동 |
| `⌘ ⇧ ↩` | 패널 zoom 토글 (최대화/복원) |
| `⌘ T` | 새 surface (탭) |
| `⌘ W` | surface 닫기 |
| `⌘ ⇧ N` | 새 윈도우 |
| `⌘ ⇧ P` | 명령 팔레트 |
| `⌘ ,` | 설정 |
