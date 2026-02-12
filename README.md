<div align="right">

[한국어](README.ko.md) | **English**

</div>

# Glacier

A macOS menu bar manager that hides menu bar items — in ~200 lines of Swift.

[Ice](https://github.com/jordanbaird/Ice) is great, but it's 30,000+ lines with its own settings window, update framework, and accessibility layer. Glacier does the core job — hide, show, done — with zero dependencies and no accessibility permission.

## Glacier vs Ice

| | Glacier | Ice |
|---|---------|-----|
| Lines of code | ~200 | 30,000+ |
| Dependencies | 0 | Multiple |
| Accessibility permission | No | Yes |
| App size | < 1 MB | ~15 MB |
| Sections | 3 (visible / hidden / always hidden) | 3 |
| macOS 26 Tahoe | Works | [Known issues](https://github.com/jordanbaird/Ice/issues/867) |
| Settings UI | None needed | Full settings window |

## How It Works

Glacier places invisible separator items in your menu bar. By expanding them, items to their left are pushed off-screen.

```
[Always Hidden] ◆ [Hidden] ● [Visible]
```

| Marker | Role |
|--------|------|
| **●** | Click target — toggles hidden section |
| **◆** | Boundary — separates "hidden" from "always hidden" |

## Usage

| Action | Effect |
|--------|--------|
| **Click ●** | Toggle hidden section |
| **Option + Click ●** | Toggle always-hidden section |
| **Right-click ●** | Quit menu |
| **Click anywhere else** | Hide everything |

**Cmd + Drag** the ● and ◆ markers to rearrange which items belong to each section.

## Install

### Download

Download the latest `.zip` from [Releases](../../releases), unzip, and drag `Glacier.app` to `/Applications`.

### Build from Source

Requires Xcode 16+ and macOS 15+.

```bash
git clone https://github.com/junuMoon/Glacier.git
cd Glacier
xcodebuild -scheme Glacier -configuration Release build
```

## Requirements

- macOS 15.0 (Sequoia) or later
- No accessibility permission needed

## License

MIT
