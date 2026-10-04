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

## Supported platforms

The inherited codebase targets Windows 10+, macOS 10.14+ including Apple Silicon, and Ubuntu 22.04+.

Apple Silicon is our primary hands-on development target, but cross-platform compatibility should be preserved.

## Building with CMake

On Ubuntu:

```bash
sudo apt install -y libglx-dev libxext-dev libopengl-dev libglvnd-dev
```

Then:

```bash
mkdir build
cd build
cmake ..
cmake --build . --config Release
cmake --install .
```

The installed client executable is named `Northrend`.

## Running

Northrend requires legitimate World of Warcraft 3.3.5a (build 12340) game data.

The data directory can be either a fully extracted MPQ archive set or a directory containing the original `Data` directory and MPQ archives. The client can be launched from the game-data directory or pointed at another directory with:

```
-datadir \path\to\game_dir
```

The inherited path parser currently expects backslashes for this option, including on macOS and Linux.

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
