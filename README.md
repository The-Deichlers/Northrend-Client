# Northrend

[![Push](https://github.com/The-Deichlers/Northrend-Client/actions/workflows/push.yml/badge.svg?branch=northrend)](https://github.com/The-Deichlers/Northrend-Client/actions/workflows/push.yml)

**Northrend** is the canonical open-source World of Warcraft 3.3.5a (build 12340) client project for The-Deichlers ecosystem.

This repository is derived from [SatyPardus/wotlk-rebuild](https://github.com/SatyPardus/wotlk-rebuild), whose Thunderbrew development branch significantly advanced the original [Whoa](https://github.com/whoahq/whoa) client reimplementation. We preserve that history and attribution while developing Northrend as our own long-term client.

> Northrend is an unofficial community project. It is not affiliated with, endorsed by, or distributed by Blizzard Entertainment.

## Project status

Northrend is under active development. The inherited codebase already includes realm authentication and character enumeration work, world loading, object management, player and unit systems, camera controls and collision, movement work, in-game UI loading, model rendering, and other substantial client functionality.

Our immediate target is not a cosmetic fork. It is a reproducible, testable client that can connect to our AzerothCore environment and progress toward normal 3.3.5a gameplay.

## Canonical branch

Development happens on `northrend`.

The imported `development` branch remains an upstream reference point. We will periodically evaluate and selectively integrate useful work from `SatyPardus/wotlk-rebuild:development` and `whoahq/whoa:master`.

See [docs/UPSTREAM.md](./docs/UPSTREAM.md) for the synchronization policy.

## Roadmap

The working roadmap is in [docs/ROADMAP.md](./docs/ROADMAP.md).

The first major goal is a verified end-to-end session against our AzerothCore test environment:

```
launch -> authenticate -> realm -> character select -> enter world
-> render player/world -> move -> interact -> play
```

## Build and validation status

CMake is the authoritative full-client build path. Apple Silicon is the primary
validation target; inherited Windows and Linux targets are also attempted by CI.
Zig is preserved but its source lists are stale and it is not a supported build
path for this milestone.

See [docs/BUILDING.md](./docs/BUILDING.md) for dependencies, recursive submodules,
Debug/Release builds and sanitizers, and [docs/RUNNING.md](./docs/RUNNING.md) for
legitimate 3.3.5a build 12340 data and startup diagnostics.

```sh
./scripts/build.sh debug clean test
./scripts/build.sh release clean test
build/debug/install/bin/Northrend -datadir '/path/to/WoW-3.3.5a'
```

The executable is named `Northrend`. The supplied-data launch passes archive
preflight but stops at the incomplete macOS GLL capability implementation.
Successful graphical startup is required before Milestone 0 can be declared complete. Actual results and unresolved
limitations are recorded in [the milestone report](./docs/milestones/MILESTONE-0-REPORT.md).

## Development principles

Northrend keeps the reverse-engineering fidelity requirements inherited from Whoa/Thunderbrew. Where behavior matters, implementations should target the original 3.3.5a build 12340 client rather than merely approximating behavior that happens to work against one server implementation.

At the same time, Northrend is developed against a real AzerothCore test environment. Changes that affect client/server behavior should be proven on the test server before they are considered stable.

Low-level inherited identifiers such as `WHOA_*` compile-time macros are intentionally retained for now. Renaming internal compatibility identifiers provides little value and creates unnecessary merge conflicts with upstream.

See [CONTRIBUTING.md](./CONTRIBUTING.md) before making implementation changes.

## Lineage and attribution

Northrend builds on work from:

- [SatyPardus/wotlk-rebuild](https://github.com/SatyPardus/wotlk-rebuild) / Thunderbrew
- [whoahq/whoa](https://github.com/whoahq/whoa)
- their contributors and supporting libraries

Git history is intentionally preserved.

## Legal

The source code in this repository retains its inherited public-domain licensing terms; see [LICENSE](./LICENSE).

World of Warcraft: Wrath of the Lich King ©2008 Blizzard Entertainment, Inc. All rights reserved. Wrath of the Lich King is a trademark, and World of Warcraft, Warcraft, and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. in the U.S. and/or other countries.
