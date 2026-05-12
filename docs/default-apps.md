# 코드 파일 기본 앱 → Cursor (Xcode 회피)

cmux 터미널의 파일 경로 링크를 ⌘+클릭 했을 때 **Xcode 가 열리는 건 cmux 가 아니라 macOS LaunchServices 의 default app 설정** 때문이다. 한 번만 일괄 변경해두면 끝.

## 사용

```bash
# 1) Cursor 가 macOS 에 등록돼 있어야 함 (Spotlight 에서 'Cursor' 한 번 실행)
~/dev/cmux-setup/bin/set-cursor-default.sh
# 또는 alias
cmx-cursor-default

# 다른 에디터 사용 시
EDITOR_APP="VS Code" cmx-cursor-default
EDITOR_APP="Zed"     cmx-cursor-default

# 일부 확장자만
cmx-cursor-default ts tsx php json md
```

내부적으로 `duti` 가 macOS LaunchServices 데이터베이스를 갱신한다. `brew install duti` 가 자동 시도된다.

기본으로 잡는 확장자: `ts tsx js jsx mjs cjs css scss sass less py rb go rs java kt swift c cpp cc h hpp php phtml json yaml yml toml ini md mdx rst txt log conf env sh bash zsh fish sql graphql gql prisma vue svelte astro` 등.

## 부작용 — 브라우저/뷰어 영역

기본 목록에서 `html`, `htm`, `xml`, `svg`, `pdf`, 이미지 류는 **의도적으로 제외**돼 있다. 인자로 명시했을 때만 적용된다.

### 진단

```bash
cmx-check-apps
# 또는
~/dev/cmux-setup/bin/check-default-apps.sh
```

"브라우저/뷰어 영역" 섹션의 `.html`, `.xml`, `.svg` 옆에 `⚠ Cursor 가 잡고 있음` 이 뜨면 부작용 발생 상태.

### 원복

```bash
# macOS 시스템 기본 브라우저(자동 감지) 로 되돌리기
cmx-check-apps --revert-web

# 명시적으로
BROWSER_APP="Google Chrome" cmx-check-apps --revert-web
BROWSER_APP="Safari"        cmx-check-apps --revert-web
```

## URL 핸들러 영향 없음

`http://` / `https://` URL 자체는 LaunchServices 의 URL 핸들러를 따로 쓰므로 위 작업의 영향을 받지 않는다. 영향이 있는 건 **확장자 기반의 파일 열기**(예: `.html` 더블클릭, 다른 앱에서 "Open in default app").

## 영향 범위 정리

| 동작 | 영향 |
|---|---|
| `http://`/`https://` URL 클릭 | 없음 — URL 핸들러는 별도 |
| 다른 앱의 "기본 브라우저" 설정 | 없음 |
| .html 파일 더블클릭 / Finder 의 "Open" | (인자로 명시 시) 변경됨 |
| .ts / .json / .md 등 코드 파일 열기 | Cursor 로 변경됨 |
| 이미지 (.png/.jpg) / PDF / SVG | 영향 없음 (기본 목록 미포함) |
