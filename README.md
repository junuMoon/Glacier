<div align="right">

[한국어](README.ko.md) | **English**

</div>

# Glacier

A compact macOS menu bar manager that hides menu bar items in a small Swift codebase.

[Ice](https://github.com/jordanbaird/Ice) is great, but it's 30,000+ lines with its own settings window, update framework, and accessibility layer. Glacier is a small menu bar app focused on the core job: hide, show, done.

> This README describes the repository's current shipping behavior.
> For an implementation review, see [the Korean code evaluation](docs/code-evaluation.ko.md). For the target product direction, see [the Korean product behavior PRD](docs/product-behavior-prd.ko.md). For document roles, see [the Korean document map](docs/document-map.ko.md).

## Glacier vs Ice

| | Glacier | Ice |
|---|---------|-----|
| Lines of code | Small (core Swift sources) | 30,000+ |
| Dependencies | 0 | Multiple |
| Accessibility layer | None | Included |
| App size | A few MB | ~15 MB |
| Sections | 3 (visible / hidden / always hidden) | 3 |
| macOS 26 Tahoe | Works | [Known issues](https://github.com/jordanbaird/Ice/issues/867) |
| Separate settings window | None | Full settings window |

## How It Works

Glacier places invisible separator items in your menu bar. By expanding them, items to their left are pushed off-screen.

```
[Always Hidden] ◆ [Hidden] ● [Visible]
```

| Marker | Role |
|--------|------|
| **●** | Click target — toggles hidden section |
| **◆** | Boundary control — reveals or hides the section to its left |

## Quick Start

After launching Glacier, you'll see a small **●** dot in your menu bar. That's your control point.

### 1. Organize your menu bar

Use **Cmd + Drag** to rearrange menu bar items into three sections:

```
[Always Hidden] ◆ [Hidden] ● [Visible]
                ↑            ↑
          drag this     and this
```

- Items **right of ●** → always visible
- Items **between ● and ◆** → hidden (toggle with click)
- Items **left of ◆** → always hidden (reveal with ◆ or Option+click)

### 2. Control visibility

| Action | Effect |
|--------|--------|
| **Click ●** | Show / hide the hidden section |
| **Click ◆** | When visible, show / hide items left of ◆ |
| **Option + Click ● or ◆** | Show / hide the always-hidden section |
| **Esc** | Hide open sections when Glacier has keyboard focus (menu bar utility; otherwise click **●** or use the 60 s timeout) |
| **60 s idle** | While **hidden** or **all-open** (not editing), sections collapse automatically; the timer resets when you switch between those two |
| **Right-click ● or ◆** | Usage / Edit Layout / Reset Layout / Quit |

## Current Notes

- `Edit Layout` keeps the layout open while you `Cmd + Drag` the markers.
- `Reset Layout` restores the marker positions to their defaults.

## Install

### Homebrew

```bash
brew tap junuMoon/tap
brew install --cask --no-quarantine glacier
```

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

## License

MIT
