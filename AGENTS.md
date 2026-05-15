# arcer

> A lean, Chromium-based Arc-replacement for macOS. Built as a patch overlay on top of ungoogled-chromium. Currently developed by Kavan with assistance from autonomous coding agents.

This file is the canonical brief for any agent (Claude Code, Antigravity, or otherwise) working on this repository. Read it fully before touching code.

## TL;DR for agents

1. arcer is **not** a fresh browser. It is a stack of `.patch` files applied to ungoogled-chromium plus a thin set of build/branding scripts. Do not check in Chromium source.
2. Target platform for v0.1 is **macOS arm64 only**. Do not add cross-platform abstractions or Windows/Linux paths unless explicitly asked.
3. Work on a feature branch, open a PR against `main`, and wait for human review. Never push directly to `main`. Never force-push to a shared branch.
4. If a task feels larger than a single PR, stop and write a short design doc in `docs/feature-specs/` first. Get it reviewed before writing code.
5. If you are stuck or a decision is non-obvious, leave a `TODO(kavan):` and open the PR with `[draft]` in the title rather than guessing.

## Project identity

- **Name**: arcer
- **Maintainer**: Kavan (solo, with agent assistance)
- **Base**: ungoogled-chromium pinned to a specific Chromium milestone (see `chromium-version.txt` at repo root once set)
- **Licence**: BSD-3-Clause (matching Chromium)
- **Why it exists**: Arc was put into maintenance mode in May 2025 and acquired by Atlassian in September 2025. The macOS implementation is heavy partly because of Arc's Swift UI layer running alongside Chromium content processes, and partly because of the AI feature stack. Battery drain on M-series Macs is the single most consistent complaint from long-term Arc users. arcer rebuilds the Arc workflow that actually matters directly inside Chromium's Views UI (no second runtime, no Swift shell), skips the AI feature stack, and uses ungoogled-chromium so we inherit Google-telemetry stripping for free. The aim is "Arc workflow at Thorium-class power draw."

## Non-goals (do not work on these without explicit instruction)

- Windows or Linux support
- Mobile companion apps (iOS, iPadOS, Android). Do not add any code paths, build targets, or even stub files for mobile.
- AI features (no equivalent of Arc Max, Arc Search, Browse for Me)
- Easels, Notebooks, Boosts
- Little Arc (transient mini-windows)
- Sync server or account system
- Replacing the Chromium engine itself

## Architecture (locked decisions)

| Decision | Choice | Rationale |
|---|---|---|
| Base | ungoogled-chromium | Telemetry already stripped, mature patch tooling, active upstream |
| Patch model | quilt-style series of `.patch` files | Industry standard for Chromium downstream; what Brave/Thorium use |
| UI toolkit | Chromium Views (C++) with Cocoa shims where unavoidable | Native, fast, no second runtime |
| Spaces backing | Chromium Profiles | True account/cookie/bookmark separation, which is what Kavan wants |
| Build system | gn + autoninja | Chromium standard, no alternative |
| Branding | Override files in `branding/` copied over `chrome/app/theme/` at build time | Avoids editing upstream theme directly |

## Repo layout

```
arcer/
├── AGENTS.md                  This file. Source of truth for how to work here.
├── README.md                  Public-facing description.
├── chromium-version.txt       Pinned Chromium milestone, eg "M138.0.7204.169"
├── docs/
│   ├── architecture.md        Deeper architectural notes.
│   ├── building.md            Build prerequisites and commands for macOS.
│   ├── patch-conventions.md   How patches are named, ordered, refreshed.
│   └── feature-specs/         One markdown file per non-trivial feature.
├── patches/
│   ├── series                 Ordered list of patches to apply.
│   ├── 0001-*.patch           Branding, name strings, icons.
│   ├── 0010-*.patch           Vertical sidebar.
│   ├── 0020-*.patch           Spaces.
│   ├── 0030-*.patch           Favourites + cmd-N keybinds.
│   └── 0099-*.patch           Misc.
├── branding/                  Icon and string overrides.
├── scripts/
│   ├── bootstrap.sh           One-shot env setup on a fresh macOS machine.
│   ├── fetch-chromium.sh      Fetch and check out the pinned Chromium ref.
│   ├── apply-patches.sh       Apply ungoogled patches, then ours.
│   ├── build-mac.sh           gn gen + autoninja for the release target.
│   ├── run-mac.sh             Launch the built bundle.
│   └── refresh-patches.sh     Re-export patches after editing source in-tree.
└── .github/
    ├── workflows/ci.yml       Patch lint, series validation, shellcheck.
    ├── PULL_REQUEST_TEMPLATE.md
    └── ISSUE_TEMPLATE/
```

The Chromium checkout itself lives **outside** this repo (eg `~/chromium/src`), referenced by `CHROMIUM_SRC` env var. Never commit Chromium source into arcer.

## How agents work on this repo

### Branches

- Name: `feat/<kebab-name>`, `fix/<kebab-name>`, `chore/<kebab-name>`, `docs/<kebab-name>`
- Scope: one logical change per branch. If you need two unrelated changes, open two branches.
- Lifetime: deleted automatically on merge (repo setting). Never reuse a branch name after merge.

### Commits

- Conventional Commits format: `feat(sidebar): add right-aligned vertical tab strip`
- Subject under 72 chars. Body wrapped at 80. Imperative mood.
- Reference the patch file you touched, eg `Refreshes patches/0010-vertical-sidebar.patch`.
- Sign commits if you can.

### Pull requests

- Title in Conventional Commits form, same as the commit subject.
- Fill in the PR template fully. Empty sections are a review blocker.
- Mark `[draft]` in the title if you are unsure and want feedback before final review.
- One PR = one branch = one logical change.
- Add labels: `area:patches`, `area:build`, `area:ui`, `area:docs`, `area:ci`. Add `scope:v0.1` until v0.1 ships.
- Tag the agent that produced the PR: `agent:claude` or `agent:antigravity`.
- Do not self-approve. Kavan reviews and merges.

### When to stop and ask

Stop and ask (via a comment or by opening a draft PR with questions) when:

- A feature would require touching more than ~500 lines of Chromium source.
- A patch no longer applies cleanly to the pinned Chromium ref after upstream changes.
- You need to choose between two materially different designs.
- A task is described ambiguously enough that you would have to invent requirements.
- You hit a Chromium subsystem you have not touched before (sandbox, IPC, mojo, network stack).

Better one extra question than a wrong PR.

### Definition of done for any change

- Builds locally on macOS arm64 (`scripts/build-mac.sh` exits 0).
- Patches export cleanly via `scripts/refresh-patches.sh` with no unintended diff drift.
- New feature has a feature spec in `docs/feature-specs/`.
- CI is green.
- Manual test steps written in the PR description.

## Canonical Arc keybinds (target reference)

Source: Arc Help Center, "Keyboard Shortcuts" (macOS column). arcer uses these bindings unchanged for any feature it implements. If a binding conflicts with a Chromium default, rebind the Chromium default (Arc itself does this; eg `Cmd+S` is repurposed from Save Page As to Sidebar Toggle).

Bindings in scope for v0.1 are marked **(v0.1)**. The rest are the post-v0.1 backlog and are listed so agents do not invent conflicting bindings now.

| Action | macOS shortcut | Status |
|---|---|---|
| Show/hide sidebar | `Cmd+S` | **(v0.1)** |
| Focus space 1, 2, 3... | `Ctrl+1`, `Ctrl+2`, `Ctrl+3`... | **(v0.1)** |
| Go directly to favourite 1, 2, 3... | `Cmd+1`, `Cmd+2`, `Cmd+3`... | **(v0.1)** |
| New tab / command bar | `Cmd+T` | post-v0.1 |
| New window | `Cmd+N` | post-v0.1 |
| New incognito window | `Cmd+Shift+N` | post-v0.1 |
| Open Little Arc | `Cmd+Option+N` | non-goal (see below) |
| Close current tab | `Cmd+W` | post-v0.1 |
| Reopen last closed tab | `Cmd+Shift+T` | post-v0.1 |
| Pin/unpin current tab | `Cmd+D` | post-v0.1 |
| Copy current tab URL | `Cmd+Shift+C` | post-v0.1 |
| Copy current tab URL as Markdown | `Cmd+Shift+Option+C` | post-v0.1 |
| Edit current tab URL | `Cmd+L` | post-v0.1 |
| Clear unpinned tabs (archive today's tabs) | `Cmd+Shift+K` | post-v0.1 |
| Toggle recent tabs | `Ctrl+Tab` | post-v0.1 |
| Switch between tabs (vertical) | `Cmd+Option+Up` / `Cmd+Option+Down` | post-v0.1 |
| Switch between spaces (cycle) | `Cmd+Option+Left` / `Cmd+Option+Right` | post-v0.1 |
| Go back on tab history | `Cmd+Left` or `Cmd+[` | post-v0.1 |
| Go forward on tab history | `Cmd+Right` or `Cmd+]` | post-v0.1 |
| Add split view pane | `Ctrl+Shift+Plus` | post-v0.1 |
| Close split view pane | `Ctrl+Shift+Minus` | post-v0.1 |
| Switch split view focus | `Ctrl+Shift+1`, `Ctrl+Shift+2`... | post-v0.1 |
| New easel | (Arc default, not applicable) | non-goal |
| New note | (Arc default, not applicable) | non-goal |

Non-goals reminder: Little Arc, Easels, Notes, Boosts, mobile (iOS/Android) builds are explicitly out of scope. Do not add code paths for them.

## v0.1 scope

Three features. Nothing else. Anything outside this list is parked in `docs/parking-lot.md`.

### F1: Right-aligned vertical sidebar with toggle

**User-facing**: A vertical tab strip on the right edge of the window. Tabs stack vertically with favicon plus title. The conventional horizontal tab strip is removed. The sidebar can be toggled on/off with `Cmd+S` (canonical Arc binding). When the sidebar is off, the window enters max-content mode with no chrome eating horizontal space.

`Cmd+S` collides with Chromium's default Save Page As. Rebind Save Page As to `Cmd+Shift+S` in the menu and accelerator table, matching what Arc itself does.

**Where in Chromium**:
- Tab strip view: `chrome/browser/ui/views/tabs/tab_strip.{h,cc}` and `tab_strip_layout_helper.{h,cc}`.
- Browser frame composition: `chrome/browser/ui/views/frame/browser_view.{h,cc}` and `browser_root_view.{h,cc}`.
- macOS-specific window chrome: `chrome/browser/ui/cocoa/` (most layout is now Views, but title bar plumbing still touches Cocoa).
- Keybind registration: `chrome/browser/ui/views/accelerator_table.cc` and the macOS main menu in `chrome/browser/app_controller_mac.mm`.

**Approach**:
1. Add a `VerticalTabStrip` view class as a sibling of the existing `TabStrip` rather than replacing it. Gate it behind a build flag `enable_arcer_vertical_tabs`.
2. In `BrowserView::Layout`, when the flag is on, dock `VerticalTabStrip` to the right edge and skip rendering the horizontal strip.
3. Implement a `BrowserCommand::IDC_TOGGLE_ARCER_SIDEBAR` and wire it to `Cmd+S` in the accelerator table.
4. Rebind Save Page As to `Cmd+Shift+S` in `chrome/app/chrome_command_ids.h` and the macOS main menu.

**Spec doc**: `docs/feature-specs/001-vertical-sidebar.md` (write before coding).

### F2: Spaces with Ctrl+1 / Ctrl+2 switching

**User-facing**: At least two "spaces" per window. Each space is backed by a separate Chromium Profile, so cookies, bookmarks, favourites, history, and signed-in accounts are fully isolated. `Ctrl+1` switches the active window to Space 1. `Ctrl+2` to Space 2. The vertical sidebar shows only the tabs of the active space.

**Where in Chromium**:
- Profile system: `chrome/browser/profiles/profile_manager.{h,cc}`. Profiles are first-class.
- Browser/Profile coupling: `chrome/browser/ui/browser.{h,cc}`. A `Browser` is bound to a single `Profile` at construction.
- Window/Browser binding: `chrome/browser/ui/views/frame/browser_view.cc`.

**Approach (this one is genuinely hard, design before coding)**:
The naive path is to spawn a second `Browser` for Space 2 and stack them inside one window frame, swapping which is visible on `Ctrl+1/2`. Concretely: keep two `Browser*` instances per `BrowserView`, route input to the active one, and reuse the same `views::Widget` so the OS-level window remains one. Tab strip pulls from `active_browser_->tab_strip_model()`.

The clean path is a `BrowserSession` abstraction that owns N `Browser` instances and presents whichever is active. That is a bigger change but is the right shape long-term.

**Decide which path to take in the design doc**. Default to the naive path for v0.1 unless the doc surfaces a blocker.

**Spec doc**: `docs/feature-specs/002-spaces.md` (write before coding, get review).

### F3: Pinned favourites with Cmd+1 to Cmd+9

**User-facing**: Up to 9 favourite sites pinned at the top of the sidebar in the active space. Favicon-only display (no title). `Cmd+1` jumps to favourite 1, etc. `Cmd+9` jumps to the last favourite. Pinning a tab as favourite is a context-menu action for now. Persistence is per-Profile, so each space has its own favourites.

**Deliberate divergence from Arc**: in Arc, pinned tabs are global across spaces. arcer makes favourites per-space (ie per-Profile). This is intentional. Kavan's mental model treats spaces as fully separate identities, so favourites should not cross the boundary. Do not "fix" this back to Arc's behaviour without an explicit instruction.

**Visual state**: a favourite whose underlying tab is currently open in the active space gets a subtle ring or dot indicator. A favourite that is not currently open renders as favicon only. This addresses a known Arc UX complaint about not being able to tell at a glance whether a pinned tab is open.

**Where in Chromium**:
- Pinned tabs already exist: `TabStripModel::SetTabPinned`.
- Favicon rendering in tabs: `chrome/browser/ui/views/tabs/tab.cc`.
- Accelerators: `chrome/browser/ui/views/accelerator_table.cc` plus the macOS menu.

**Approach**:
1. Extend `TabStripModel` with an arcer-flavoured pin level (`PINNED_FAVOURITE`) that locks position in the vertical strip and renders favicon-only.
2. Register `IDC_ARCER_GO_TO_FAVOURITE_1..9` and wire to `Cmd+1..9`.
3. Store the favourite list in profile prefs (one list per Profile, ie per space).
4. Render the "currently open" indicator by querying the active `TabStripModel` for a matching URL.

**Spec doc**: `docs/feature-specs/003-favourites.md`.

## Build workflow (macOS arm64)

Prerequisites are detailed in `docs/building.md`. Quick reference:

```bash
# First time only, takes a few hours and ~150 GB of disk.
./scripts/bootstrap.sh
./scripts/fetch-chromium.sh

# For every change:
./scripts/apply-patches.sh
./scripts/build-mac.sh        # autoninja, ~30-90 min cold, ~1-15 min incremental
./scripts/run-mac.sh          # launches the bundle

# After editing files inside $CHROMIUM_SRC/chrome/...:
./scripts/refresh-patches.sh  # re-exports your in-tree edits as patches under patches/
```

Recommended `gn` args for development (set in `scripts/build-mac.sh`):

```
is_debug=false
is_official_build=false
symbol_level=1
enable_nacl=false
blink_symbol_level=0
v8_symbol_level=0
use_remoteexec=false
chrome_pgo_phase=0
is_component_build=true        # faster incremental linking
enable_arcer_vertical_tabs=true
```

## Patch conventions

- One patch per logical change. Do not bundle the sidebar and spaces work into one giant patch.
- Filename: `NNNN-short-kebab-name.patch`. NNNN is a 4-digit zero-padded series number. Group by feature: 0001-0009 branding, 0010-0019 sidebar, 0020-0029 spaces, 0030-0039 favourites, 0099 misc.
- Header on every patch:
  ```
  Subject: [arcer] <imperative one-liner>
  Author: <name or agent>
  Description:
    <paragraph explaining the why and what>
  ```
- The `series` file at `patches/series` defines apply order. Edit it whenever you add/rename a patch.
- Refresh by editing in-tree, then running `scripts/refresh-patches.sh`. Do not hand-edit `.patch` files unless you have to.

## CI

CI is intentionally lightweight because full Chromium builds blow past GitHub Actions free-tier time limits. CI runs on every PR and validates:

- Patch headers parse correctly
- `series` file lists exactly the patches present
- shellcheck passes on `scripts/*.sh`
- yamllint passes on workflows
- Markdown links are not broken in `docs/`

Full build verification happens on Kavan's M4 locally before merge.

## Things to never do

- Commit Chromium source into this repo.
- Add network calls to telemetry, analytics, or "phone home" endpoints.
- Disable Chromium's sandbox or weaken site isolation.
- Touch the network stack or sandbox subsystems without writing a spec first.
- Add a runtime dependency on Electron, CEF, Tauri, or any other Chromium wrapper. arcer is a fork, not a wrapper.
- Squash PRs that touch more than one logical area.

## Glossary

- **Space**: an isolated browsing context backed by its own Chromium Profile. Two spaces share no cookies, history, bookmarks, signed-in accounts.
- **Favourite**: a pinned tab that lives at the top of the sidebar with a favicon-only display and a `Cmd+N` keybind.
- **Sidebar**: the right-aligned vertical tab strip.
- **arcer flag**: a `gn` build-time flag prefixed `enable_arcer_`. All custom features gate behind one of these.
