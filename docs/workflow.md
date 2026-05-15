# arcer workflow

This file is **the procedure**: how Kavan, Claude (chat), Claude Code (local), and Antigravity (local) actually collaborate to turn an idea into merged code. Read this once. Then refer back when you forget what step comes next.

## The three loops

There are three loops nested inside each other. Get them straight in your head.

```
┌─────────────────────────────────────────────────────────────────┐
│  SETUP LOOP   (once, then again every few months on Chromium    │
│                upgrade)                                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  VERSION LOOP   (per minor version, eg v0.1, v0.2...)    │   │
│  │  ┌──────────────────────────────────────────────────┐    │   │
│  │  │  FEATURE LOOP   (per feature within a version)   │    │   │
│  │  │  idea -> spec -> patch -> PR -> merge -> ship    │    │   │
│  │  └──────────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Setup loop (one-time, on a fresh Mac)

Goal: a working baseline build of unmodified ungoogled-chromium with arcer branding. After this, you never touch the Chromium fetch again unless you're upgrading milestones.

| Step | Command | Time |
|---|---|---|
| 1 | Clone arcer scaffold: `git clone git@github.com:kavan-vyas/arcer.git ~/arcer && cd ~/arcer` | 5 sec |
| 2 | `gh auth login` (HTTPS, paste fine-grained PAT scoped to arcer repo) | 1 min |
| 3 | `./scripts/bootstrap.sh` (installs depot_tools, Homebrew deps, sets PATH) | 5 min |
| 4 | Open a new shell so the new PATH takes effect | 1 sec |
| 5 | `./scripts/fetch-chromium.sh` (fetches Chromium source at pinned ref) | 1-4 hours, mostly network |
| 6 | `./scripts/apply-patches.sh` (applies ungoogled patches + the 0001 branding patch) | 1-3 min |
| 7 | `./scripts/build-mac.sh` (cold build) | 1-3 hours, CPU-bound |
| 8 | `./scripts/run-mac.sh` | 5 sec |
| 9 | Confirm a window labelled "arcer" opens and you can browse | 1 min |

**Realistic plan**: do step 1-4 on an evening. Kick off step 5 before bed (it runs overnight on home wifi). Apply patches and start build (steps 6-7) the next morning before school, build completes by evening. Test step 8-9 that evening. **One real day of elapsed time, mostly waiting.**

If anything in steps 5-7 fails, open an issue, paste the full error, tag it `area:build`, and stop. Don't keep retrying blindly.

## Version loop (per minor version)

Goal: complete a `vX.Y` section of `docs/roadmap.md`.

### Step 1. Open a tracking issue

```bash
gh issue create \
  --title "Track v0.1: foundation" \
  --label "scope:v0.1" \
  --body "$(cat docs/roadmap.md | sed -n '/^## v0.1/,/^## v0.2/p')"
```

This gives you one issue to pin to. All v0.1 PRs reference it.

### Step 2. Walk the feature list

For each feature in that version's row of the roadmap, run the **feature loop** below. Do them in order. Do not start F2 until F1 is merged.

### Step 3. Cut the release

When every feature in `vX.Y` is merged, you run:

```bash
# Update CHANGELOG.md: move [Unreleased] entries under [vX.Y.0]
# Bump chromium-version.txt comment line if applicable
git checkout -b chore/release-v0.1.0
# ...edits...
gh pr create --title "chore: release v0.1.0" --label "scope:v0.1,area:docs"
# After merge:
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --generate-notes
```

For v1.0 this also runs `scripts/release-mac.sh` for notarisation, but that doesn't exist yet.

## Feature loop (per feature within a version)

This is the loop you spend 95% of your time in. Five stages.

### Stage 1. Idea → spec (you + Claude chat)

Open a chat with Claude (this interface) and describe the feature in your own words. Claude turns it into a `docs/feature-specs/00X-name.md` design doc.

**The spec doc must include**:

1. **Summary**: one paragraph, what and why.
2. **User stories**: 1-3 sentences each.
3. **Keybinds touched**: every binding the feature adds, changes, or rebinds.
4. **Chromium files touched**: a list with one-line rationale per file.
5. **Patch plan**: the patch filenames that will be created, in order.
6. **State and persistence**: what gets stored, where (prefs? files? in-memory?).
7. **Test plan**: manual steps Kavan will run.
8. **Risks**: what could break, what upstream changes could invalidate the approach.
9. **Out of scope**: what this feature spec deliberately does NOT cover.

**The spec is its own PR.** Open it on a branch like `docs/spec-001-vertical-sidebar`, get review from Kavan, merge. Then code work begins, never before. This is not bureaucracy: the spec is what the coding agent reads as input. If the spec is sloppy, the code will be sloppy.

### Stage 2. Spec → branch (Claude Code or Antigravity, local)

On your Mac, in `~/arcer`:

```bash
# Claude Code:
claude

# Then in the agent prompt:
> Read AGENTS.md and docs/feature-specs/001-vertical-sidebar.md.
> Implement F1 per the spec. Create a branch feat/vertical-sidebar.
> Make patches under patches/ following docs/patch-conventions.md.
> Open a PR against main when ready, including the manual test plan.
> Stop and ask if you hit any unclear decision.
```

The agent does the work. You don't watch every keystroke; you check in every 15-30 min. The agent should:

- Branch: `feat/vertical-sidebar`.
- Fetch the pinned Chromium ref if not already present.
- Edit files inside `$CHROMIUM_SRC/chrome/...` directly.
- Run `./scripts/build-mac.sh` to verify it compiles.
- Run `./scripts/refresh-patches.sh` to export the edits as `.patch` files into `patches/`.
- Update `patches/series`.
- Commit using Conventional Commits.
- Push and run `gh pr create --fill --label "scope:v0.1,area:ui,agent:claude"`.

### Stage 3. PR review (you, locally)

When the PR is open:

1. Pull the branch locally: `gh pr checkout <number>`.
2. Run `./scripts/apply-patches.sh && ./scripts/build-mac.sh && ./scripts/run-mac.sh`.
3. Execute the manual test steps in the PR description.
4. If broken: comment on the PR with the issue, the agent (or you) fixes, push, re-review.
5. If good: leave comments on the diff itself if you want refinements.

**Do not merge code you have not built and tested locally**. CI doesn't build the full browser. You are the build-and-test gate.

### Stage 4. Merge (you, on GitHub)

Squash merge. Branch auto-deletes (repo setting). The Conventional Commit subject from the PR becomes the squash commit message.

Update `CHANGELOG.md` under `[Unreleased]` in a tiny follow-up PR or as part of the feature PR itself.

### Stage 5. Smoke (you, daily-ish)

After merge, the next morning, before any other dev work:

```bash
git pull
./scripts/apply-patches.sh
./scripts/build-mac.sh
./scripts/run-mac.sh
```

Use arcer for ~30 minutes of normal browsing. If anything regresses, file an issue immediately while it's fresh. This is how you catch interaction bugs between features.

## How to translate an idea into a working PR (worked example)

Suppose you wake up and decide: "I want the favourites to flash briefly when I switch into a space, so I can see what's pinned without scanning."

You do not jump to Claude Code and say "make favourites flash". You go through the loop.

### Step 1. Roadmap check

Open `docs/roadmap.md`. Is "favourite flash on space switch" already there?

- If yes, find which version it's slotted into. If the current focus is v0.2 and this is parked for v0.6, **stop**. Don't do it now.
- If no, this is a new idea. Decide: is it v0.1 scope (foundational) or post-v0.1 (decoration)? Probably the latter. Add it to v0.6 in the roadmap as part of the polish pass, in a small PR. Then close the loop.

The discipline matters. Otherwise you'll have eight half-finished features and zero shippable versions.

### Step 2. Spec it

When that version's turn comes, open Claude chat:

> "I want to add a brief flash animation to all favourites when the user switches spaces with Ctrl+1 or Ctrl+2. About 200ms, accent colour pulse. Generate the design doc."

Review the doc Claude produces. Push back if anything is hand-wavy. Merge the spec PR.

### Step 3. Implement it

Local Claude Code:

> "Implement docs/feature-specs/012-favourite-flash-on-space-switch.md. Branch feat/favourite-flash. Stop on uncertainty."

Wait. Review when the PR is open.

### Step 4. Merge it

Test locally, merge, update CHANGELOG.

That is the entire workflow.

## When to break the rules

- **Hotfix**: if arcer is broken on `main` and you can't browse, skip the spec stage and open a `fix/` PR directly. Note "no spec, fix-forward" in the PR body.
- **Trivial chores**: typo fixes, formatting, dependency bumps, doc edits skip the spec stage. Use `chore:` or `docs:`.
- **Refactor only**: same.

Anything that affects user-facing behaviour goes through the spec stage. Always.

## Common failure modes (avoid these)

- **Building before specing.** You end up implementing the wrong thing twice.
- **Letting the agent decide what's in scope.** Agents over-implement. The spec is your scope contract.
- **Merging unreviewed PRs.** "It builds in CI" is meaningless when CI does not build the browser.
- **Touching Chromium files without exporting patches.** You'll lose the work on the next checkout reset.
- **Skipping the smoke step.** Bugs compound. A 30-min daily smoke catches them when they're cheap to fix.
- **Working on more than one feature branch at a time.** Pick one. Finish it. Then start the next.

## Quick reference

```bash
# Daily incoming:
git pull && ./scripts/apply-patches.sh && ./scripts/build-mac.sh

# Start a new feature (after spec is merged):
git checkout main && git pull
git checkout -b feat/your-feature

# Hand off to Claude Code:
claude

# Export patches after editing Chromium source in-tree:
./scripts/refresh-patches.sh

# Open the PR:
gh pr create --fill --label "scope:v0.X,area:ui,agent:claude"

# Review a PR locally:
gh pr checkout <num> && ./scripts/apply-patches.sh && ./scripts/build-mac.sh && ./scripts/run-mac.sh
```
