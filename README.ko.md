<div align="right">

**한국어** | [English](README.md)

</div>

# Glacier

macOS 메뉴바 아이템을 숨겨주는 앱 — Swift ~200줄.

[Ice](https://github.com/jordanbaird/Ice)는 훌륭하지만, 설정 창, 업데이트 프레임워크, 접근성 레이어까지 포함된 30,000줄 이상의 앱입니다. Glacier는 핵심 기능만 — 숨기고, 보여주고, 끝 — 의존성 없이, 접근성 권한 없이 동작합니다.

## Glacier vs Ice

| | Glacier | Ice |
|---|---------|-----|
| 코드 라인 수 | ~200 | 30,000+ |
| 의존성 | 0 | 다수 |
| 접근성 권한 | 불필요 | 필요 |
| 앱 크기 | < 1 MB | ~15 MB |
| 섹션 | 3 (보임 / 숨김 / 항상 숨김) | 3 |
| macOS 26 Tahoe | 정상 동작 | [알려진 이슈](https://github.com/jordanbaird/Ice/issues/867) |
| 설정 UI | 불필요 | 전체 설정 창 |

## 작동 원리

Glacier는 메뉴바에 보이지 않는 구분자를 배치합니다. 구분자를 확장하면 왼쪽 아이템들이 화면 밖으로 밀려납니다.

```
[항상 숨김] ◆ [숨김] ● [보이는 것]
```

| 마커 | 역할 |
|------|------|
| **●** | 클릭 대상 — 숨김 섹션 토글 |
| **◆** | 경계 표시 — "숨김"과 "항상 숨김" 구분 |

## 사용법

| 동작 | 결과 |
|------|------|
| **● 클릭** | 숨김 섹션 토글 |
| **Option + ● 클릭** | 항상 숨김 섹션 토글 |
| **● 우클릭** | 종료 메뉴 |
| **다른 곳 클릭** | 전부 숨김 |

**Cmd + 드래그**로 ●와 ◆ 마커를 이동하여 각 섹션에 속하는 아이템을 조정할 수 있습니다.

## 설치

### Homebrew

```bash
brew tap junuMoon/tap
brew install --cask --no-quarantine glacier
```

### 다운로드

[Releases](../../releases)에서 최신 `.zip`을 다운로드하고, 압축 해제 후 `Glacier.app`을 `/Applications`로 드래그하세요.

### 소스에서 빌드

Xcode 16+ 및 macOS 15+ 필요.

```bash
git clone https://github.com/junuMoon/Glacier.git
cd Glacier
xcodebuild -scheme Glacier -configuration Release build
```

## 요구사항

- macOS 15.0 (Sequoia) 이상
- 접근성 권한 불필요

## 라이선스

MIT
