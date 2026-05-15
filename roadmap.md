# arcer roadmap

The single source of truth for what ships in each version. Agents consult this before opening any PR labelled `scope:vX.Y`. The detailed list of Arc keybindings each version targets lives in `AGENTS.md` under "Canonical Arc keybinds".

Numbering: `v0.X` while the browser is pre-stable. `v1.0` is the first version Kavan signs, notarises, and runs as his daily driver. After `v1.0`, semver applies.

## v0.1 - Foundation
*Target: first usable build with the irreducible Arc workflow.*

| ID | Feature | Keybind | Notes |
|---|---|---|---|
| F1 | Right-aligned vertical sidebar with toggle | `Cmd+S` | Replaces horizontal tab strip. Save Page As moves to `Cmd+Shift+S`. |
| F2 | Two Spaces backed by separate Chromium Profiles | `Ctrl+1`, `Ctrl+2` | Full cookie/bookmark/account isolation. |
| F3 | Up to 9 pinned favourites per space | `Cmd+1` to `Cmd+9` | Favicon-only display. Indicator dot when the favourite's tab is currently open. |

**Exit criteria for v0.1**: arcer builds clean on macOS arm64, launches with `arcer.app` branding, the three features above work, no Chromium upstream regressions detected by smoke test.

## v0.2 - Tab lifecycle (auto-archive)
*Target: replicate the single Arc behaviour Kavan called out as transformative, "deleting tabs unless you save them".*

- Auto-archive unpinned tabs after N hours of inactivity (default 12, configurable in prefs).
- Archive recovery view accessible from the sidebar footer. Lists archived tabs grouped by archive date with one-click restore.
- `Cmd+Shift+K` clears today's tabs manually (canonical Arc binding).
- Pinned tabs and favourites are never auto-archived.

**Where in Chromium**: `chrome/browser/sessions/`, `chrome/browser/ui/views/tabs/tab_strip_model.{h,cc}`. Persist archive list in profile prefs.

**Exit criteria**: leaving arcer open overnight does not produce a wall of tabs; archived tabs are recoverable within ~7 days.

## v0.3 - Quality-of-life keybinds
*Target: parity with Arc's keyboard-first workflow.*

| Keybind | Action |
|---|---|
| `Cmd+T` | New tab / command bar focus |
| `Cmd+W` | Close current tab |
| `Cmd+Shift+T` | Reopen last closed tab |
| `Cmd+D` | Pin/unpin current tab |
| `Cmd+L` | Edit current tab URL |
| `Cmd+Shift+C` | Copy current URL |
| `Cmd+Shift+Option+C` | Copy current URL as Markdown |
| `Cmd+Option+Up` / `Down` | Switch between tabs (vertical) |
| `Cmd+Option+Left` / `Right` | Cycle between spaces |
| `Ctrl+Tab` | Toggle between recent tabs |

**Exit criteria**: every binding above works in every space. `chrome/browser/ui/views/accelerator_table.cc` is the single point of registration.

## v0.4 - Bookmarks and cascading folders
*Target: the bookmarks workflow Kavan called "key" in the original brief.*

- Cascading folders in the sidebar (folder containing folders containing tabs).
- Per-space bookmark roots, so each Space has its own bookmark tree (consistent with the per-Profile favourites decision).
- Bookmark a tab from the sidebar context menu or `Cmd+D` long-press (TBD in spec).
- Bookmark search via the command bar (depends on v0.3 command bar work).

**Where in Chromium**: `components/bookmarks/`, `chrome/browser/ui/views/bookmarks/`. Profile prefs already partition the bookmark store, so isolation is mostly free.

**Exit criteria**: a 3-level folder tree per space, with drag-and-drop reordering, persists across restart.

## v0.5 - Split view
*Target: Arc's split workflow, with the specific behaviour Kavan called out: browser shortcuts take priority over website shortcuts.*

| Keybind | Action |
|---|---|
| `Ctrl+Shift+Plus` | Add split view pane (up to 4) |
| `Ctrl+Shift+Minus` | Close active split view pane |
| `Ctrl+Shift+1` to `Ctrl+Shift+4` | Focus split view pane N |

**Browser-shortcut priority**: intercept `Cmd+W`, `Cmd+S`, `Cmd+N` etc. at the browser-window level *before* they reach the `RenderWidgetHost`, so a webpage's `keydown` handler cannot swallow them. Look at `chrome/browser/ui/views/frame/browser_view.cc` and `content/browser/renderer_host/render_widget_host_impl.cc`.

**Exit criteria**: open a website that hijacks `Cmd+S` (e.g. Google Docs) inside split view, press `Cmd+S`, arcer's sidebar toggles. The website never sees the event.

## v0.6 - Theming, animation, performance pass
*Target: feel as polished as Arc, run lighter than Arc.*

- Per-space accent colour applied to the sidebar background and active-tab highlight.
- Sidebar slide-in/out animation on `Cmd+S` toggle (subtle, ~150ms).
- Space-switch transition (cross-fade or slide, TBD).
- Memory and CPU profiling pass against unmodified ungoogled-chromium baseline. Goal: arcer's overhead on top of ungoogled-chromium is under 50 MB resident and under 1% idle CPU.
- Battery profiling on M-series under realistic load. Goal: arcer drains less than Arc by a measurable margin in like-for-like browsing.

**Exit criteria**: profiling numbers documented in `docs/performance.md`. No animation jank on the M4 14-inch.

## v1.0 - Stable release
*Target: daily-driver quality, distributable.*

- All v0.x features merged and stable for two weeks of daily use without major regressions.
- Apple Developer ID signing.
- macOS notarisation pipeline (`scripts/release-mac.sh`).
- GitHub Releases auto-publish from a `release/*` tag.
- Auto-update channel (Sparkle or Chromium's own update mechanism, decision in v0.6 design doc).
- `README.md`, `docs/install.md`, `docs/uninstall.md` finalised.
- Open-source licence headers audited.

**Exit criteria**: a friend can download `arcer.dmg` from GitHub Releases, install it, and use it for a week without hitting a P0 bug.

## Post-v1.0 (parked)

Tracked in `docs/parking-lot.md`. Highlights:

- Tab previews on hover.
- Notification-dot rendering on favourites.
- Mouse gesture support.
- "Air Traffic Control" link routing (open external links in a specified Space).
- Boosts equivalent (CSS/JS site customisation).
- Linux support (Windows: unlikely).

No work begins on these until v1.0 ships.
