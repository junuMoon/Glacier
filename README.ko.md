<div align="right">

**한국어** | [English](README.md)

</div>

# Glacier

macOS 메뉴바 아이템을 숨겨주는 앱 — 작은 Swift 코드베이스로 구현.

[Ice](https://github.com/jordanbaird/Ice)는 훌륭하지만, 설정 창, 업데이트 프레임워크, 접근성 레이어까지 포함된 30,000줄 이상의 앱입니다. Glacier는 핵심 기능만 — 숨기고, 보여주고, 끝 — 에 집중한 작은 메뉴바 앱입니다.

> 이 README는 현재 레포의 배포 기준 동작을 설명합니다.
> 구현 진단은 [코드 평가 문서](docs/code-evaluation.ko.md), 목표 제품 방향은 [행동 동선 PRD](docs/product-behavior-prd.ko.md), 전체 문서 역할은 [문서 맵](docs/document-map.ko.md)을 참고하세요.

## Glacier vs Ice

| | Glacier | Ice |
|---|---------|-----|
| 코드 라인 수 | 작음(핵심 Swift 소스) | 30,000+ |
| 의존성 | 0 | 다수 |
| 접근성 레이어 | 없음 | 포함 |
| 앱 크기 | 수 MB대 | ~15 MB |
| 섹션 | 3 (보임 / 숨김 / 항상 숨김) | 3 |
| macOS 26 Tahoe | 정상 동작 | [알려진 이슈](https://github.com/jordanbaird/Ice/issues/867) |
| 별도 설정 창 | 없음 | 전체 설정 창 |

## 작동 원리

Glacier는 메뉴바에 보이지 않는 구분자를 배치합니다. 구분자를 확장하면 왼쪽 아이템들이 화면 밖으로 밀려납니다.

```
[항상 숨김] ◆ [숨김] ● [보이는 것]
```

| 마커 | 역할 |
|------|------|
| **●** | 클릭 대상 — 숨김 섹션 토글 |
| **◆** | 경계 컨트롤 — 왼쪽 섹션을 보이거나 숨김 |

## 빠른 시작

Glacier를 실행하면 메뉴바에 작은 **●** 점이 나타납니다. 이것이 조작 포인트입니다.

### 1. 메뉴바 정리하기

**Cmd + 드래그**로 메뉴바 아이템을 세 구역으로 배치하세요:

```
[항상 숨김] ◆ [숨김] ● [보이는 것]
            ↑          ↑
       이것을 드래그  이것도 드래그
```

- **● 오른쪽** 아이템 → 항상 보임
- **● 과 ◆ 사이** 아이템 → 숨김 (클릭으로 토글)
- **◆ 왼쪽** 아이템 → 항상 숨김 (◆ 또는 Option+클릭으로 표시)

### 2. 표시/숨기기

| 동작 | 결과 |
|------|------|
| **● 클릭** | 숨김 섹션 보이기 / 숨기기 |
| **◆ 클릭** | 보이는 상태에서 ◆ 왼쪽 아이템 보이기 / 숨기기 |
| **Option + ● 또는 ◆ 클릭** | 항상 숨김 섹션 보이기 / 숨기기 |
| **Esc** | Glacier(또는 열린 메뉴)에 키보드 포커스가 있을 때 숨기기(그 외에는 **●** 클릭 또는 60초 타임아웃) |
| **60초** | **숨김 열림** 또는 **전체 열림**(편집 모드 제외)이면 자동으로 접힘; 두 상태 사이를 바꿀 때마다 타이머 리셋 |
| **● 또는 ◆ 우클릭** | 사용법 / Edit Layout / Reset Layout / 종료 |

## 현재 참고사항

- `Edit Layout`은 열린 상태를 유지한 채 `Cmd + Drag`로 marker를 다시 배치할 때 사용합니다.
- `Reset Layout`은 marker 위치를 기본값으로 되돌립니다.

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

## 라이선스

MIT
