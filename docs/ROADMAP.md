# Northrend Client Roadmap

## Mission

Build Northrend into a usable, maintainable, modern client for World of Warcraft 3.3.5a build 12340, with first-class compatibility testing against The-Deichlers AzerothCore environment.

This is a spare-time project, so work should favor small, testable milestones over broad rewrites.

## First-Class Client Standard

Northrend is not intended to be a proof of concept, compatibility demo, or "good enough" hobby client. The acceptance bar is a first-class desktop game client.

That means every subsystem we touch should be held to production-quality expectations:

- **Correctness:** behavior should match World of Warcraft 3.3.5a build 12340 where fidelity matters, while interoperating cleanly with modern AzerothCore.
- **Stability:** crashes, hangs, undefined behavior, corrupt state, silent failures, and unrecoverable networking states are release-blocking defects.
- **Performance:** rendering, loading, input, networking, animation, object updates, memory use, and startup should be profiled and optimized rather than merely made functional.
- **Responsiveness:** input, camera movement, UI interaction, loading transitions, and world updates should feel immediate and predictable.
- **Platform quality:** macOS, Windows, and Linux should behave like native first-class applications on their respective platforms, including windowing, input, filesystem behavior, logging, packaging, and process lifecycle.
- **Apple Silicon:** arm64 macOS is a primary development target, not an afterthought.
- **Networking:** authentication, realm selection, world entry, movement, reconnects, teleports, logout, and error handling should be robust under normal and abnormal server conditions.
- **Diagnostics:** important failures should be observable through useful logs and assertions; debugging should not require guessing.
- **Maintainability:** new work should be structured, documented, testable, and understandable enough that future upstream integration remains practical.
- **Testing:** important protocol, parsing, state-machine, movement, and object-system behavior should gain automated tests where feasible, plus real integration validation against `northrend-test`.
- **User experience:** no developer-only shortcuts, hard-coded selections, dead controls, placeholder flows, broken settings, or obviously unfinished behavior may be treated as complete.
- **Polish:** warnings, error messages, startup behavior, configuration, settings persistence, display handling, audio, input, and shutdown all count. A client is only first-class when the unglamorous paths are first-class too.

The project does **not** need a custom art-production effort. Northrend should use legitimate 3.3.5a game data and assets as intended. Our differentiation is engineering quality, compatibility, maintainability, and modern client behavior—not replacement artwork.

A milestone is not complete because a feature can be demonstrated once. It is complete when the feature is reliable, repeatable, testable, documented, and does not degrade the rest of the client.

## Milestone 0 — Reproducible build

Goal: any contributor can produce a known-good Northrend binary from the repository.

- Establish a clean Apple Silicon build.
- Preserve Windows and Linux builds.
- Keep CI green on supported platforms.
- Document required dependencies and game-data layout.
- Confirm the produced executable is branded `Northrend`.
- Record the source commit and build configuration used for test binaries.

Exit criteria: a fresh checkout can be built and launched reproducibly.

## Milestone 1 — AzerothCore compatibility baseline

Goal: complete a deterministic login-to-world path against `northrend-test`.

- Authenticate successfully.
- Retrieve/select realm.
- Enumerate characters.
- Select the requested character rather than relying on a hard-coded list entry.
- Send `CMSG_PLAYER_LOGIN`.
- Handle world-entry packets without disconnecting.
- Load the requested map and coordinates.
- Create the active player object.
- Transition from loading UI to the in-game UI.
- Add enough client/server logging to diagnose failures from both ends.

Exit criteria: a selected character consistently reaches the world on `northrend-test`.

## Milestone 2 — Stable world session

Goal: remain connected and operate normally in a loaded world.

- Render terrain, WMOs, doodads, units, and player models reliably.
- Stabilize camera movement and collision.
- Complete essential object update paths.
- Stabilize movement synchronization.
- Handle teleports and `SMSG_NEW_WORLD`.
- Handle disconnect/login failure conditions cleanly.
- Validate time synchronization and movement timestamps.
- Eliminate crash-level issues encountered during ordinary movement.

Exit criteria: the client can remain in-world, move around, and observe nearby entities without abnormal disconnects or crashes.

## Milestone 3 — Core gameplay loop

Goal: support the fundamental actions required to actually play.

- Targeting and selection.
- Chat.
- NPC interaction.
- Spells and combat.
- Inventory/equipment.
- Loot.
- Basic quest interaction.
- Player and unit frames.
- Common game UI flows.
- Logout/reconnect.

Exit criteria: a character can complete a representative normal gameplay loop.

## Milestone 4 — Northrend integration validation

Goal: make Northrend useful as both a playable client and a validation client for our server stack.

- Test against current AzerothCore.
- Exercise our installed modules.
- Exercise playerbots interactions.
- Complete a representative dungeon/gameplay scenario.
- Capture reproducible client/server regressions.
- Define a minimal automated smoke-test path that can eventually be orchestrated by infrastructure automation.

Exit criteria: Northrend is useful for validating changes on `northrend-test` before server-side promotion.

## Ongoing workstreams

### Upstream intake

Track `SatyPardus/wotlk-rebuild:development` and `whoahq/whoa:master`. Prefer selective, reviewed integration over blindly resetting our branch to upstream.

### Fidelity

When implementation details are uncertain, compare against the original 3.3.5a build 12340 client. Compatibility with AzerothCore is necessary but is not by itself proof of faithful behavior.

### Modern platforms

Official baselines are Windows 11 25H2+, macOS Tahoe 26+ on Apple Silicon / arm64,
and Ubuntu 26.04 LTS+. Support includes newer releases; use current operating
systems, compilers, and SDKs, and deliberately advance baselines as releases leave
normal support. Northrend targets contemporary, supported desktop operating
systems rather than preserving legacy OS compatibility. Harmless inherited code
may remain, but obsolete compatibility must not constrain new architecture.

The platform-baseline task follows integrated Milestone 0 and must be reviewed
and merged independently before Milestone 1. It changes policy/build/CI only;
OpenGL, windowing, input, networking, and game behavior retain their validated
implementations. See [the build policy](BUILDING.md#supported-platform-baseline).

### Documentation

Significant subsystems and compatibility fixes should be documented alongside the code. Reproducible test steps are part of the definition of done for world-entry and networking changes.

## Branch policy

- `northrend`: canonical project branch.
- `development`: imported upstream development reference.
- `master`: inherited upstream history; do not base new Northrend work on it.
- Feature work: short-lived branches from `northrend`, merged back after review/testing.

## Test policy

Client/server changes are tested against `northrend-test` first. Production server changes are outside this repository and must not be performed merely to make an unverified client change appear to work.
