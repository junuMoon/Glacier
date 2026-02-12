# Glacier

A lightweight macOS menu bar manager that hides menu bar items — no accessibility permission required.

Glacier uses the same expander trick as [Ice](https://github.com/jordanbaird/Ice) to push items off-screen, but in ~200 lines of Swift with zero dependencies.

[한국어](README.ko.md)

## How It Works

Glacier places invisible separator items in your menu bar. By expanding them, items to their left are pushed off-screen.

Three sections, separated by two markers:

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

## States

| State | What you see |
|-------|-------------|
| All hidden (default) | `●  [Visible items]` |
| Partial show | `◆  [Hidden items]  ●  [Visible items]` |
| Show all | `[Always hidden]  ◆  [Hidden items]  ●  [Visible items]` |

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
