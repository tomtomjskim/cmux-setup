# 트러블슈팅

## 디버그 모드

```bash
CMX_DEBUG=1 cmx ~/dev/myApp 2>&1 | tee /tmp/cmx.log
cat /tmp/cmx.log
```

cmux 의 매 응답이 stderr 로 출력되어 어디서 막혔는지 보인다.

## 자주 보는 에러

### `cmux 소켓이 없음 (/tmp/cmux.sock)`

cmux GUI 가 안 켜져 있다. Spotlight 에서 `cmux` 실행.

### `'cmux' 미설치`

cmux.app 이 없거나, 한 번도 실행되지 않아 `/usr/local/bin/cmux` 가 등록 안 됨. 다음 중 하나로 해결:

- `brew install --cask manaflow/cmux/cmux` (가능한 경우)
- [https://cmux.com](https://cmux.com) 에서 DMG 다운로드 후 한 번 실행

### `ref 추출 실패`

cmux 응답 형식이 `OK <kind>:N` 이 아닐 때. `/tmp/cmx.log` 의 raw 응답을 보고 `bin/cmux-setup.sh` 의 `extract_ref()` 정규식 조정. 보통 cmux 가 비정상 종료 됐을 때 발생.

### `Workspace index not found`

full ref 가 아닌 숫자만 전달된 경우. 최신 스크립트는 자동으로 `workspace:N` 형태를 쓰므로 발생 안 해야 정상. 발생하면 `cmux version` 확인 후 이슈 등록.

### `codex` 명령이 없다고 뜸

`CODEX_CMD` 를 본인이 쓰는 도구로 바꾸거나 (`gh copilot suggest` 등), 빈 문자열로 두면 빈 쉘.

```bash
# <project>/.cmux.conf
CODEX_CMD=""
```

### 브라우저가 빈 페이지

nginx/dev 서버가 그 포트에 안 떠 있음. 별개 이슈로 해당 프로젝트 서버 기동 확인.

### `claude` 명령이 안 켜짐

Claude Code CLI 미설치/PATH 누락. `which claude` 확인.

## 레이아웃 관련

### 3단 컬럼 비율이 어색 (50:25:25)

cmux 의 split 은 무조건 50:50 이라 첫 실행 시 50:25:25 로 시작. GUI 에서 divider 를 한 번 35:35:30 으로 드래그하면 세션에 저장되어 다음부터는 그 비율이 유지된다.

### 3단이 아예 안 만들어짐

이전 빈 워크스페이스 잔재일 수 있다. cmux 사이드바에서 빈 워크스페이스를 우클릭 → close 로 정리 후 재시도. 그래도 안 되면 `CMX_DEBUG=1` 로 응답 로그 확인.

### 마우스로 조정한 비율을 다시 초기화 하고 싶음

cmux 사이드바에서 해당 워크스페이스 close 후 `cmx` 다시 실행. 새 워크스페이스는 기본 비율(50:25:25)로 시작.

## 단축키

### `⌃ 1-9` 가 데스크탑 전환으로 가버림

macOS Mission Control 과 충돌. [docs/shortcuts.md](shortcuts.md) 참조.

### `⌥ 1-9` 가 안 잡히고 특수문자가 입력됨

macOS 의 `⌥+숫자` 는 특수문자 입력으로 OS 가 먼저 가로챈다. modifier 두 개 조합 (`⌃ ⌥ 1-9` 등) 권장.

## 보조 도구

### Cursor 매핑 후 .html 이 Cursor 로 열림

`set-cursor-default.sh` 의 기본 목록에는 `html`/`htm` 이 없지만 인자로 명시했을 때 적용된다. 원복:

```bash
cmx-check-apps --revert-web
```

자세히는 [docs/default-apps.md](default-apps.md).
