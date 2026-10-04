# Northrend Client Roadmap

## Mission

Build Northrend into a usable, maintainable, modern client for World of Warcraft 3.3.5a build 12340, with first-class compatibility testing against The-Deichlers AzerothCore environment.

This is a spare-time project, so work should favor small, testable milestones over broad rewrites.

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

Keep macOS/Apple Silicon healthy while preserving Windows and Linux wherever practical. Platform modernization should avoid altering game behavior unnecessarily.

### Documentation

Significant subsystems and compatibility fixes should be documented alongside the code. Reproducible test steps are part of the definition of done for world-entry and networking changes.

## Branch policy

- `northrend`: canonical project branch.
- `development`: imported upstream development reference.
- `master`: inherited upstream/default history; do not base new Northrend work on it.
- Feature work: short-lived branches from `northrend`, merged back after review/testing.

## Test policy

Client/server changes are tested against `northrend-test` first. Production server changes are outside this repository and must not be performed merely to make an unverified client change appear to work.
