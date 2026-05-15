# arcer parking lot

Ideas that have been considered and explicitly deferred. Anything here is **not** to be worked on by agents until promoted into `docs/roadmap.md` by Kavan. The point of this file is to prevent agents from "helpfully" implementing things that were left out for a reason.

## Deferred past v1.0

### Tab previews on hover
Hovering a sidebar entry shows a small preview of the page. Useful but expensive; renders need a snapshot pipeline. Revisit after v1.0.

### Notification dots on favourites
A red dot on a favourite when its underlying tab has new activity (matches Arc's pinned-tab notification UX). Depends on per-site signals from the renderer; non-trivial. Revisit after the v0.3 command-bar work proves out the IPC patterns.

### Mouse gestures
Vivaldi-style mouse gestures (right-drag to navigate back, etc.). Niche; defer.

### Air Traffic Control
Arc's feature for routing external link opens into a specific Space based on URL rules. Needs a rules engine in the prefs UI. Defer.

### Boosts equivalent
Per-site CSS/JS injection. Useful but a big surface area for security review. The standard answer (Stylus + a UserScripts manager) covers 90% of Boosts. Defer indefinitely unless Kavan changes priority.

### Picture-in-picture
Already exists in Chromium upstream. We do not need to add anything for v0.x. If we want Arc's specific UX (PIP attached to sidebar bottom), that is a v1.x design exercise.

### Cross-device sync
Account-based bookmark/history/favourites sync. Requires a backend. Not happening.

### Linux build
Maybe one day. Not before v1.0. macOS arm64 only for now.

## Explicitly rejected (do not implement)

### Mobile companion app (iOS, iPadOS, Android)
Out of scope forever in this repo. Hard non-goal.

### Little Arc (transient mini-windows)
Arc's mini-window-for-one-link feature. Not implementing.

### Easels and Notes
Out of scope. arcer is a browser, not a note-taking app.

### AI features
No Arc Max equivalent. No Browse-for-Me. No AI summarisation in the URL bar. Kavan can call any LLM from a normal tab; the browser does not embed one.

### Account system
arcer does not have accounts. Profiles are local. There is no login.

### Telemetry
No analytics, no crash reporting that phones home, no usage metrics. Period.

### A WebKit or Gecko build target
arcer is Chromium-based. There is no plan to support other engines.
