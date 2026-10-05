# Modern platform baseline validation

This policy/build/CI task starts from integrated Milestone 0,
`f416e6e56373708e0a869be60c48fd4102945efc`, on `platform-modern-baseline`.
It must be reviewed and merged separately before Milestone 1; no client/server
or renderer work is included. The [M0 report](MILESTONE-0-REPORT.md) retains its
original validation evidence and adds a clearly separated post-M0 policy note.

## Supported policy

- Windows 11 25H2 and newer.
- macOS Tahoe 26 and newer, Apple Silicon / arm64 only.
- Ubuntu 26.04 LTS and newer as the Linux reference.

See [Supported Platform Baseline](../BUILDING.md#supported-platform-baseline)
for the philosophy, inherited-code policy, and runner differences.

## Native validation before PR creation

Validated October 4, 2026 on the existing Apple M2, macOS 26.7 (25G229),
Xcode 27.0 (27A266a), Apple Clang 21.0.0, CMake 4.4.3. Build configuration
revision: `7a627216` (macOS defaults/helper; subsequent changes are CI/docs only).

```sh
./scripts/build.sh debug clean test
./scripts/build.sh release clean test
file build/debug/install/bin/Northrend build/release/install/bin/Northrend
xcrun vtool -show-build build/debug/install/bin/Northrend
xcrun vtool -show-build build/release/install/bin/Northrend
```

| Native configuration | Clean build/install | CTest | Architecture | Mach-O minimum OS / SDK |
| --- | --- | --- | --- | --- |
| Debug, default UBSan | passed | 9/9 passed | arm64, single slice | 26.0 / 27.0 |
| Release | passed | 9/9 passed | arm64, single slice | 26.0 / 27.0 |

Both installed executables reached the genuine animated 3.3.5 (12340) login
screen using the user's existing clean data at
`/Users/deichler/Desktop/ChromieCraft_3.3.5a`. Mouse Options opened and closed
normally. Debug Command-Q and Release window close both exited **0**. No Login
action, credentials, or server connection were used. There were no runtime-UB
diagnostics in these smoke tests. No new game assets were required or committed.
The temporary native-inspection wrapper and logs are outside the repository.

This is a deployment-target regression smoke test, not a repeat of M0's full
60-second clean/HD/adjacent-data acceptance matrix or a new gameplay acceptance.
Inherited deprecation/linkage warnings and incomplete particle/model diagnostics
remain; the working OpenGL GLL path is unchanged.

## Hosted validation

The workflow retains six required jobs: Debug and Release on macOS, Linux, and
Windows, each running the existing nine CTest checks. PR validation targets
`northrend`; feature branches are not added to permanent push triggers.

- Linux: stable `ubuntu-26.04`, x64, GCC 15; matches the reference OS.
- macOS: stable `macos-26`, arm64, image-default current stable Xcode/Clang;
  explicit deployment 26.0 and arm64 with artifact inspection.
- Windows: `windows-2025-vs2026`, x64, MSVC/Windows SDK. This is a **Server 2025**
  toolchain/test environment, not Windows 11 25H2 desktop-runtime evidence.
  GitHub's Windows 11 arm64 images do not replace inherited x64 coverage here.

Runner choices were checked against [GitHub's image inventory](https://github.com/actions/runner-images)
and [hosted-runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).
Final PR CI results are recorded in the PR checks and description; this pre-PR
local report does not manufacture hosted or Windows/Linux graphical results.

## Remaining legacy code

Harmless inherited Intel detection, `WHOA_SYSTEM_*` identifiers, older SDK header
compatibility, Carbon/OpenGL usage, and pinned parser/library versions remain.
They do not imply support for legacy operating systems. The separate renderer,
windowing, input, audio, movies, and networking subsystems are unchanged.
Dependency corrections remain a bounded bridge for upstream contributions or
maintained Northrend dependency forks, as documented during M0 cleanup.
