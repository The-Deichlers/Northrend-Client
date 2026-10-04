# Milestone 0 validation report

Status: **incomplete**. Native builds, automated tests and cross-platform CI pass.
The supplied Windows HD data set opens and passes required-file preflight in both
launch layouts, but normal startup stops at the inherited macOS GLL graphics
capability check. No login UI or successful event-loop session is validated.
Do not merge or mark this milestone complete until graphical startup is fixed
and acceptance is satisfied.

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
99a88fad (Release), with Debug also repeated at d1c7a78e. A further clean Debug
build at bfcc4a5f and an incremental Debug run at 38bd42aa both passed 9/9.
Primary-checkout Debug, Release and ASan/UBSan also passed 9/9 at 38bd42aa.
After both dependency lifetime fixes, a fresh clean Debug build in the separate
network clone passed 9/9 at 5d559a72. Primary Debug, Release and ASan/UBSan
also passed 9/9 at that source revision. All three primary configurations
passed 9/9 again at 93e22301 after guarding the zero-byte big-integer copy.

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

**Actual data launch attempted October 4, 2026; graphical startup blocked.**
The user supplied `/Users/deichler/Downloads/World of Warcraft 3.3.5a HD`.
Its lowercase `data` directory contains base/enUS MPQs and additional HD patches.
The local filesystem resolves the loader's capitalization. This is a modified
asset set; its complete version/integrity and unmodified 12340 compatibility
have not been independently certified.

Debug, Release and Debug ASan/UBSan `-datadir` launches all open archives and
pass the AreaTable.dbc/GlueXML.toc preflight. A separate Debug install under
`/tmp/northrend-m0-adjacent/bin`, with `Data` symlinked to the external data
folder, gives the same result without `-datadir`, from the repository working
directory. No proprietary assets were copied into the repository or committed.
The application writes logs/configuration under its selected root.

All four attempts stop before database and GlueXML/login UI initialization.
`CGxDeviceGLL::ISetCaps` is explicitly unfinished and never assigns `m_numTmus`
or `m_numStreams`. The first remains zero and triggers ConsoleDeviceInitialize's
minimum-two-texture-units rejection. This is an incomplete backend capability
implementation, not evidence that the Apple M2 GPU lacks texture units. The
startup also reports many unhandled GLL render states. A proper backend audit
and implementation, with actual hardware capability queries and rendering
validation, are required; arbitrary capability values would hide the defect.

Originally this fatal path called `exit(0)` and bypassed startup-log closure.
The corrected graphics initializer returns its reason to CommonMain, which logs
it, flushes/closes the startup log and exits **1**. The reason appears in stderr,
`Logs/Northrend.log` and `Logs/gx.log`. Both launch layouts were repeated after
the correction. The ASan/UBSan data launch reports no sanitizer error before
this known failure; coverage does not extend beyond it. Local Debug, Release
and ASan/UBSan CTest each pass **9/9** after this source change.

Exact launch commands:

```sh
build/debug/install/bin/Northrend -datadir '/Users/deichler/Downloads/World of Warcraft 3.3.5a HD'
build/release/install/bin/Northrend -datadir '/Users/deichler/Downloads/World of Warcraft 3.3.5a HD'
build/debug-asan/install/bin/Northrend -datadir '/Users/deichler/Downloads/World of Warcraft 3.3.5a HD'
mkdir -p /tmp/northrend-m0-adjacent/bin
ln -s '/Users/deichler/Downloads/World of Warcraft 3.3.5a HD/data' /tmp/northrend-m0-adjacent/bin/Data
cmake --install build/debug --prefix /tmp/northrend-m0-adjacent
/tmp/northrend-m0-adjacent/bin/Northrend
```

The executable name is Northrend, macOS explicitly sets NSProcessInfo's process
name to Northrend, and the graphics title uses Northrend. The GLL window now
also receives Northrend at creation, before the later general title assignment. The generated macOS
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
layouts) and ASan + UBSan. The supplied-data startup was also attempted with ASan/UBSan and reached the
same graphics rejection; no full UI or server session was run under sanitizers.
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

The consolidated workflow covers northrend pushes and PRs to northrend and
attempts Debug and Release on macOS, Linux and Windows. The inherited duplicate
PR workflow lacked Linux dependencies; its checks are replaced by this broader
shared workflow. Concurrency cancels superseded runs without hiding failures. All five test binaries and four startup
checks run through CTest; failures are not hidden or allowed to fail silently.

Linux builds exposed Common's missing `<cstring>`, C3Spline's missing `<cmath>`,
a case-sensitive `Zlib.hpp`/`ZLib.hpp` include mismatch, and further direct
math/C-string/stdio calls lacking their own standard headers; all were corrected.
GCC also required `std::isnan` qualification. At 38bd42aa, Linux Debug and
Release compiled/linked but CommonTest aborted: CSimpleSortedArray explicitly
destroyed its array member, which C++ then destroyed again. Revision e1fa76b4
removes the explicit destruction in a generated header shared by the client and
tests. The existing array suite passes locally (3 cases, 19 assertions); final
Linux Release passed 9/9 at e1fa76b4, while Linux
Debug UBSan found TSFixedArray::Clear calling Constructor after its explicit
destructor. Revision 5d559a72 releases elements/storage without destroying the
array object. The existing Storm array suite passes locally (8 cases, 27
assertions). Full Debug, Release and ASan/UBSan CTest pass 9/9 with this
correction. A clean local Release build at e1fa76b4 also passed 9/9. The next
Linux Debug run exposed a zero-byte memcpy from a null big-integer output buffer;
93e22301 skips that empty copy. The following Linux Debug run found an
out-of-bounds flattened access across rows of a 20-by-10 decimal digit table
in SStrToFloat. Revision c522b7b5 uses the actual row and digit indices,
preserving its numeric values. All three local configurations passed 9/9 again
at c522b7b5; the hosted run also passed all six configurations.
Validated code revision: `c522b7b50db8f386b9d088a04ed09b416b459bcb`.
[Run 37238585712](https://github.com/The-Deichlers/Northrend-Client/actions/runs/37238585712)
completed successfully; all six jobs ran and passed all nine CTest checks.

| Hosted platform | Debug | Release |
| --- | --- | --- |
| macOS, Clang | pass, 9/9 | pass, 9/9 |
| Ubuntu, GCC | pass, 9/9 | pass, 9/9 |
| Windows, MSVC | pass, 9/9 | pass, 9/9 |

An earlier hosted macOS Debug log (99a88fad, run 37236015195) explicitly reports
image `macos-26-arm64`, `RUNNER_ARCH=ARM64` and `uname -m=arm64`.
Hosted macOS is therefore observed on native ARM64; local Apple M2 acceptance
is independently recorded above. Windows Debug logs report X64. No hosted
full-game-data launch is attempted. Documentation-only commits after the tested
code revision may trigger new runs; the linked run records the code validation.

## Remaining blockers and next steps

1. Complete and validate the inherited macOS GLL capability/rendering backend.
   Supplied-data launches reach its rejection in both layouts; successful
   graphical startup, full asset loading and visible menu/process identity remain
   blocked. Repeat with an unmodified legitimate 12340 data set as well.
2. Keep the PR in draft until full-data acceptance is satisfied. CI now passes
   all six configurations; do not merge if subsequent required checks fail.
3. Upstream the small generated dependency corrections into maintained dependency
   commits; strengthen bounds/asset-parser tests before expanding integration.
4. Keep Milestone 1 limited to northrend-test after this baseline is accepted.
   Default audio/movie limitations and conservative hardware tiers should be
   tracked separately. Test suite breadth is insufficient to establish reliable
   login/world entry, and no production AzerothCore server was accessed.

No proprietary data, fake gameplay, custom assets or server changes are included.
This report deliberately does not declare Milestone 0 complete.
