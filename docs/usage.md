# 사용법

## 명령 형태

```text
cmx <project_path> [port|url] [--v-default|--v-simple|--v-4split]
```

- `project_path`: 작업 디렉토리. 생략하면 `pwd`.
- 두 번째 인자: **숫자면 포트**(브라우저는 자동으로 `http://localhost:<포트>`), **URL이면 그대로** 브라우저 주소로 사용. `app.local:8080` 같이 스킴 없는 host:port 도 받는다.
- 레이아웃 옵션: 생략하면 `default` (3단).

## 두 번째 인자 동작

| 입력 | port | browser_url |
|---|---|---|
| `cmx ~/dev/myApp` | 80 | http://localhost:80 |
| `cmx ~/dev/myApp 81` | 81 | http://localhost:81 |
| `cmx ~/dev/myApp 8081` | 8081 | http://localhost:8081 |
| `cmx ~/dev/myApp http://app.local` | 80 | http://app.local |
| `cmx ~/dev/myApp http://app.local:9090` | 9090 | http://app.local:9090 |
| `cmx ~/dev/myApp app.local:7000` | 7000 | http://app.local:7000 |

호스트가 `localhost` 면 **숫자 하나만** 넣으면 끝. 호스트가 다를 때만 URL 전체를 주면 된다.

## 일상 사용 패턴

### A. 현재 디렉토리

```bash
cd ~/work/myapp
cmx
```

`pwd` 사용 + default 레이아웃 + port 80.

### B. 인자 명시

```bash
cmx ~/work/myapp 5173
cmx ~/work/myapp 80 --v-simple
cmx ~/work/myapp http://app.local
```

### C. `.cmux.conf` 영구 설정 — 자주 쓰는 프로젝트

프로젝트 폴더에 두면 자동 로드. 셸 수정 없이 영구화.

```bash
# <project>/.cmux.conf
PORT=8080
BROWSER_URL=http://app.local
DEV_CMD="npm run dev"
TEST_CMD="phpunit --watch"
CLAUDE_CMD="claude"
CODEX_CMD="codex"
LAYOUT="simple"
```

우선순위: **명령행 인자 > `.cmux.conf` > 스크립트 기본값**.

## 환경변수

| 변수 | 기본값 | 효과 |
|---|---|---|
| `CMX_DEBUG` | (off) | `1` 이면 cmux 응답을 stderr 로 출력 |
| `CMUX_SOCKET_PATH` | `/tmp/cmux.sock` | cmux 소켓 경로 (cmux 자체 환경변수) |
| `CMX_RESIZE_AMT` | `15` | default 레이아웃에서 컬럼 좁히기 시도값 (셀 단위) |
| `CMX_SKIP_SOCKET_CHECK` | (off) | 소켓/`cmux ping` 검사 우회 (테스트/CI 용) |
| `CMUX_SETUP_DIR` | (필수) | 리포 경로. install.sh 가 ~/.zshrc 에 export. |

예시:

```bash
CMX_DEBUG=1 cmx ~/work/myapp 2>&1 | tee /tmp/cmx.log
CMX_RESIZE_AMT=20 cmx ~/work/myapp 80
```

## 보조 명령

```bash
cmx-cursor-default          # 코드 파일을 Cursor 로 매핑
cmx-check-apps              # 기본 앱 매핑 진단
cmx-check-apps --revert-web # 브라우저 영역 원복
```
