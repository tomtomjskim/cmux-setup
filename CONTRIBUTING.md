# Contributing

기여를 환영합니다. 작은 PR 도 좋습니다.

## 기본 원칙

- macOS 전용 도구입니다. 다른 OS 지원은 받지 않습니다 (cmux 자체가 macOS 앱).
- Bash 3.2 (macOS 기본) 호환을 유지합니다. 연관 배열 (`declare -A`), `mapfile`, `${var,,}` 등은 사용 금지.
- `set -euo pipefail` 을 모든 스크립트에 유지합니다.
- 사용자 환경 변경(특히 `~/.zshrc`)은 idempotent + uninstall 가능해야 합니다.

## 변경 절차

1. 이슈 먼저: 큰 변경(레이아웃 추가, 옵션 변경) 은 사전 논의 권장.
2. 브랜치 후 작업: `feat/...`, `fix/...`, `docs/...` 컨벤션.
3. 로컬 검증:
   ```bash
   bash -n bin/*.sh install.sh tests/smoke.sh shell/aliases.zsh
   ./tests/smoke.sh
   ```
4. PR 작성: 변경 이유 + 영향도(예: `~/.zshrc` 포맷 변경 여부, 환경변수 추가 등) 명시.

## 보안 원칙

- `.cmux.conf` 는 절대 `source` 하지 않습니다 (임의 코드 실행 방지). 화이트리스트 KEY=VALUE 파서만 사용.
- 새 기능에서 외부에서 들어오는 문자열을 셸로 평가하지 마세요. `eval`, 따옴표 없는 변수 확장 금지.
- 네트워크/파일 시스템 변경 동작은 첫 실행 시 사용자 동의 프롬프트를 둡니다 (`AUTO_INSTALL_*=1` 환경변수로 우회 허용).

## 새 레이아웃 추가

`bin/cmux-setup.sh` 안의 `layout_*` 함수 패턴을 따라 추가하고, 디스패치 `case` 에 줄 한 줄을 더하면 됩니다. `tests/smoke.sh` 의 통합 모드(섹션 6) 에 mock cmux 호출 검증 1세트 추가 필수.

## 코드 스타일

- 들여쓰기 2칸.
- 변수는 `local`. 글로벌은 화면 위쪽에 모아둡니다.
- 사용자 메시지는 `[i]` `[+]` `[!]` `[x]` 4단계 prefix 유지.
