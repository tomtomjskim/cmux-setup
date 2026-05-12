# 레이아웃 프리셋

3종이 있고, 명령행 옵션 `--v-default | --v-simple | --v-4split` 또는 `.cmux.conf` 의 `LAYOUT="..."` 으로 선택.

## `--v-default` (생략 시 디폴트, 3단)

```text
   35%             35%             30%
┌──────────────┬──────────────┬──────────────┐
│   claude     │     t1       │              │
│   (왼쪽 위)  │              │              │
├──────────────┤     t2       │   browser    │
│   codex      │              │              │
│   (왼쪽 아래)│     t3       │              │
└──────────────┴──────────────┴──────────────┘
```

- 왼쪽: `claude` / `codex` (상하 2분할)
- 중간: 빈 터미널 `t1` / `t2` / `t3` (3분할, 작업용 대기)
- 오른쪽: 내장 브라우저

### 비율 제한

cmux 는 CLI 로 비율 정밀 지정이 불가하다 (split 은 항상 50:50). 스크립트가 트리 구조를 `[좌 | [중간 | 브라우저]]` 로 만들어 **첫 실행 시 50:25:25** 가 된다.

권장 사용법:
1. 첫 실행 후 cmux GUI 에서 divider 두 개를 35:35:30 으로 드래그
2. 비율은 cmux 세션에 저장 → 다음 실행 시에도 유지

자동 `resize-pane` 호출이 포함되어 있지만 단위가 셀이라 정확하지 않다. 정밀 비율은 GUI 드래그가 정답.

## `--v-simple` (터미널 | 브라우저)

```text
┌────────────────────┬────────────────────┐
│      shell         │      browser       │
│  (DEV_CMD 실행)    │                    │
└────────────────────┴────────────────────┘
```

가벼운 작업용. `.cmux.conf` 의 `DEV_CMD` 가 있으면 왼쪽 쉘에 자동 실행.

## `--v-4split` (이전 디폴트, 4분할)

```text
┌──────────────┬──────────────┐
│              │    test      │
│     dev      ├──────────────┤
│              │   claude     │
├──────────────┴──────────────┤
│          browser            │
└─────────────────────────────┘
```

- 왼쪽: `DEV_CMD` 자동 실행
- 오른쪽 상: `test` 탭 (`TEST_CMD` 자동 실행 옵션)
- 오른쪽 하: `claude` 자동 실행
- 하단: 내장 브라우저

## 새 레이아웃 추가하기

`bin/cmux-setup.sh` 안의 `layout_*` 함수 패턴을 따라 추가하고, 디스패치 `case` 에 항목 한 줄을 더하면 된다.

```bash
layout_my_new() {
  local ws s1
  ws=$(new_ws "$WORKDIR")
  cmux rename-workspace --workspace "$ws" "$PROJECT_NAME" >/dev/null
  cmux select-workspace --workspace "$ws" >/dev/null 2>&1 || true
  # ... split 로직 ...
}

# 디스패치 case 에 추가
case "$LAYOUT" in
  ...
  mine) layout_my_new ;;
esac
```
