# Milestone 0 validation report

Status: **incomplete**. Native builds and asset-free startup validation pass.
A successful launch with legitimate 3.3.5a build 12340 assets has not been tested:
the developer is obtaining the Windows data set. CI validation remains in progress.
Do not merge or mark this milestone complete until these requirements pass.

## Machine and toolchain

Validated October 4, 2026 on Apple M2, native **arm64**, macOS **26.7**
(build **25G229**). Compiler target: `arm64-apple-darwin25.6.0`.
Xcode **27.0** (27A266a); Apple Clang **21.0.0** (clang-2100.3.34.2);
CMake **4.4.3**. Zig was not installed or executed.

Machine/tool commands:

```sh
uname -m
sw_vers
sysctl -n machdep.cpu.brand_string
clang --version
xcodebuild -version
cmake --version
command -v zig
```

## Build results

| Configuration | Native build | CTest | Architecture |
| --- | --- | --- | --- |
| Debug, default UBSan | configure/compile/link/install pass | 9/9 pass | arm64 |
| Release | configure/compile/link/install pass | 9/9 pass | arm64 |
| Debug with ASan + UBSan | configure/compile/link/install pass | 9/9 pass | arm64 |

Initial clean builds used `./scripts/build.sh debug clean test` and
`./scripts/build.sh release clean test`. ASan used
`./scripts/build.sh debug clean test asan`. Incremental repetitions after
corrections used the same commands without `clean`.

A separate fresh network clone initialized every recursive submodule and built
Debug from an empty build directory. Release also used an empty build directory;
the app interruption terminated that build at 72%, and it subsequently resumed
and passed. No previously generated objects from the primary checkout were used.
The fresh clone verified source revisions f22d9386 (initial Debug) and
99a88fad (Release), with Debug also repeated at d1c7a78e. Subsequent C3Spline's
`<cmath>` include was validated in the primary checkout.

```sh
git clone --branch milestone-0-reproducible-build --recurse-submodules \
  https://github.com/The-Deichlers/Northrend-Client.git \
  /tmp/northrend-m0-clean-checkout
/tmp/northrend-m0-clean-checkout/scripts/build.sh debug test
git -C /tmp/northrend-m0-clean-checkout pull --ff-only
/tmp/northrend-m0-clean-checkout/scripts/build.sh release clean test
# After interruption, resume:
/tmp/northrend-m0-clean-checkout/scripts/build.sh release test
file build/debug/install/bin/Northrend build/release/install/bin/Northrend
lipo -archs build/release/install/bin/Northrend
otool -L build/release/install/bin/Northrend
```

Primary artifacts:

- `/Users/deichler/Documents/ChatGPT/Northrend-Client/build/debug/install/bin/Northrend`
- `/Users/deichler/Documents/ChatGPT/Northrend-Client/build/release/install/bin/Northrend`
- `/Users/deichler/Documents/ChatGPT/Northrend-Client/build/debug-asan/install/bin/Northrend`

`file` and `lipo` report ARM64 only. `otool` lists system frameworks/runtime
libraries, with no FMOD or Homebrew dylib dependency in the default client.

## Test results

`WhoaTest` remains the inherited target name. CTest now executes dependency tests
rather than merely building their binaries.

| Executable | Debug cases/assertions | Release cases/assertions |
| --- | --- | --- |
| WhoaTest | 1 / 4 | 1 / 4 |
| BcTest | 20 / 49 | 19 / 48 |
| StormTest | 110 / 638 | 110 / 646 |
| TempestTest | 22 / 1272 | 22 / 1272 |
| CommonTest | 39 / 81 | 39 / 81 |

All listed tests pass. Assertions are exercised in Debug; the bc assertion case
is excluded in Release. Early runs failed bc's assertion test (unregistered
callback) and Common's bounded-string test (expected `foo` in a capacity-three
buffer including its terminator). Generated source corrections register/reset
the callback and check the actual safe `fo` result while retaining cursor checks.
The original submodule tests remain unmodified on disk.

```sh
ctest --test-dir build/debug --output-on-failure
ctest --test-dir build/release --output-on-failure
ctest --test-dir build/debug-asan --output-on-failure
# Individual totals were recorded by running each of these binaries:
./build/debug/bin/WhoaTest
./build/debug/bin/BcTest
./build/debug/bin/StormTest
./build/debug/bin/TempestTest
./build/debug/bin/CommonTest
```

## Launch and identity

The real native executable was launched without assets. Normal startup selects
the executable directory; explicit `-datadir` selects the specified root and
accepts native forward slashes. Four regression checks test missing option values,
unknown options, nonexistent roots and an existing empty data directory.
Every case exits **1** with an actionable diagnostic, without an unexplained crash.
The empty-data test verifies `Logs/Northrend.log` and its build/configuration,
architecture, path, renderer and specific fatal missing-file message.

Manual commands (the empty directory was a temporary directory outside the repo):

```sh
build/debug/install/bin/Northrend
build/debug/install/bin/Northrend -datadir
build/debug/install/bin/Northrend -datadir /nonexistent/northrend-data
build/debug/install/bin/Northrend -not-a-real-option
build/debug/install/bin/Northrend -datadir /path/to/existing-empty-directory
```

**Complete data loading and visible graphical startup: not validated.** No
legitimate game assets were available. The preflight checks AreaTable.dbc and
GlueXML.toc; it does not certify every asset's version/integrity. Launch beside
complete data and launch with `-datadir` must both still be exercised.

The executable name is Northrend, macOS explicitly sets NSProcessInfo's process
name to Northrend, and the graphics title uses Northrend. The generated macOS
menu's keyed archive contains Northrend, verified with:

```sh
plutil -convert xml1 -o - build/debug/install/bin/MainMenu.nib/keyedobjects.nib
```

CMake now compiles MainMenu.xib with ibtool instead of installing an inherited
compiled nib that still contained World of Warcraft. Visible menu/process
inspection during a full game-data session remains pending. Windows resource
source specifies Northrend.exe, FileDescription and ProductName; Windows artifact
metadata inspection awaits successful Windows CI/build verification.

## Build/dependency discoveries

CMake has complete current subsystem source globs; it is authoritative. Zig lists
nonexistent `src/app/macos/*` and `src/world/CWorld.cpp`, lacks current map/object
subsystems, expects SDL2 rather than SDL3 and fetches mutable master archives with
hashes. It is retained, explicitly unverified and stale for this client.

The original Squall commit e3a5b2db was unavailable from thunderbrewhq, SatyPardus
and whoahq remotes. The branch uses reachable SatyPardus Squall ea79d8d6 and bc
c57a029f, which provide the required heap/hash and aligned-allocation APIs.
Canonical dependency targets resolve before transitive copies. Submodules have
no local edits. Small corrections compile from checked generated source copies;
see `cmake/DependencyFixes.cmake` and `docs/BUILDING.md`.

CMake previously overwrote Release with Debug. It now preserves configuration,
respects a selected macOS deployment target, defaults to macOS 11.0, supports
CMake 4's vendored policy floor, registers tests and enables Clang/GCC ASan.
Compiler fixes preserve existing behavior: missing includes, modern public
accessors, unsigned sentinel/pointer widths, lifetime of call temporaries,
platform-specific guards and declarations. No gameplay or server features added.

FMOD is optional/off. Core's macOS dylib has arm64 and x86_64 slices, but audio
operation was not tested. Vendored xvidcore is Windows COFF x86/x64; automatic
movie-module enablement is therefore Intel-Windows-only. No native macOS movie
module was validated. Detailed dependency inventory: `docs/BUILDING.md`.

## Sanitizers and warnings

Debug tests/startup failures pass UBSan (alignment excluded for inherited data
layouts) and ASan + UBSan. No full-data or server session was run under sanitizers.
Prebuilt proprietary components are uninstrumented; macOS leak-sanitizer coverage
was not established. Do not infer broad runtime safety from the small suite.

Inherited warnings remain: deprecated macOS APIs, mismatched exception
specifications for global delete, abstract/nonvirtual destructors, unhandled enum
cases and duplicate static-library linkage due to dependency cycles. They were
not suppressed wholesale. Old vendored FreeType/Lua/zlib/Expat/StormLib and
legacy OpenGL/Carbon are technical debt; security/modernization is not validated.
macOS hardware detection retains conservative legacy tiers when unavailable
Intel-era sysctl keys cannot be read; an Apple Silicon performance policy is not
established by a successful compile.

## CI

The workflow covers northrend pushes and PRs to northrend and attempts Debug and
Release on macOS, Linux and Windows. All five test binaries and four startup
checks run through CTest; failures are not hidden or allowed to fail silently.

Initial Linux builds found Common's missing `<cstring>` and C3Spline's missing
`<cmath>`; both were corrected. The current platform checks are still running.
Latest code run: https://github.com/The-Deichlers/Northrend-Client/actions

Hosted macOS Debug passed 9/9 tests on revision 99a88fad in run 37236015195.
Its log explicitly reports image `macos-26-arm64`, `RUNNER_ARCH=ARM64` and
`uname -m=arm64`. Thus this observed hosted build is also native ARM64;
local Apple M2 acceptance remains separately recorded. Other final job results
are pending.

## Remaining blockers and next steps

1. Supply complete legitimate 3.3.5a build 12340 data outside the repository.
   Validate both supported launch layouts, actual asset loading, graphical
   renderer/menu/process identity and fatal initialization diagnostics.
2. Finish CI, fix reasonably scoped platform failures, and record final statuses.
   Do not merge failing required checks.
3. Upstream the small generated dependency corrections into maintained dependency
   commits; strengthen bounds/asset-parser tests before expanding integration.
4. Keep Milestone 1 limited to northrend-test after this baseline is accepted.
   Default audio/movie limitations and conservative hardware tiers should be
   tracked separately. Test suite breadth is insufficient to establish reliable
   login/world entry, and no production AzerothCore server was accessed.

No proprietary data, fake gameplay, custom assets or server changes are included.
This report deliberately does not declare Milestone 0 complete.
