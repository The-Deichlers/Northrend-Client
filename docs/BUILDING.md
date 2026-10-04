# Building Northrend

CMake is the authoritative build path. Windows, macOS and Linux are inherited
platform targets; see the [validation report](milestones/MILESTONE-0-REPORT.md)
for actual validation, rather than treating a target as proof of support.

## Apple Silicon

Install Xcode with its command-line tools and CMake 3.13 or newer. Select the
Xcode developer directory with `xcode-select` if your compiler cannot find the
macOS SDK. The milestone was tested with CMake 4.4.3 and Apple Clang 21.
The default macOS deployment target is 11.0; an explicit override is respected.
No Rosetta, Homebrew graphics/audio library, or proprietary SDK is required by
the default build.

```sh
git clone --recurse-submodules https://github.com/The-Deichlers/Northrend-Client.git
cd Northrend-Client
git switch milestone-0-reproducible-build
./scripts/build.sh debug clean test
./scripts/build.sh release clean test
```

The helper builds, installs the executable and menu resources, and optionally
runs CTest. It uses separate directories per configuration. Set
`NORTHREND_BUILD_JOBS` to limit parallel compilation (default 8).
It does not download game data.

Equivalent direct commands:

```sh
git submodule update --init --recursive
cmake -S . -B build/debug -DCMAKE_BUILD_TYPE=Debug -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build/debug --parallel 8
ctest --test-dir build/debug --output-on-failure
cmake --install build/debug --prefix build/debug/install
file build/debug/install/bin/Northrend
```

Repeat in a fresh directory with `-DCMAKE_BUILD_TYPE=Release`. The raw executable
is `build/debug/bin/Northrend`; the installed client and menu resources are in
`build/debug/install/bin`. This is a command-line-installed native executable,
not an `.app` bundle. Run the installed copy for macOS menu resources.

## Dependencies

All default client libraries are checked in or pinned Git submodules. CMake
compilation does not fetch dependencies. Recursive submodule initialization
requires network access and obtains the exact Git object recorded in the tree.
Run `git submodule status --recursive` to inspect these pins.

| Component | Source and purpose |
| --- | --- |
| `lib/system` | Submodule; architecture/platform definitions |
| `lib/bc` | Submodule; filesystem, memory, strings and OS support |
| `lib/squall` | Submodule; Storm API implementation, logging, synchronization, crypto |
| `lib/typhoon` | Submodule; Tempest mathematics |
| `lib/common` | Submodule; shared handles, XML/data utilities; vendored Expat 2.0.1 |
| StormLib 9 | Vendored MPQ reader; includes its own zlib/bzip2/compression sources |
| zlib 1.2.2 | Vendored inherited compression library |
| Lua 5.1.3 | Vendored game scripting runtime |
| FreeType 2.0.9 | Vendored font rasterizer |
| Catch2 2.13.10 | Vendored tests (also present in dependencies) |
| SDL 3.2.10, GLEW 2.2.0 | Vendored Linux OpenGL/input backend; optional Windows backend |
| DirectXMath 3.19.0 | Vendored non-MSVC Windows math headers; MSVC uses SDK headers |
| FMOD Core 2.02.18 / Ex 4.24.16 | Optional proprietary audio libraries, disabled by default |
| xvidcore 1.3.7.1 | Vendored prebuilt Windows x86/x64 movie decoder archives |

macOS links system AppKit, Foundation (via dependencies), Carbon, IOKit and
OpenGL frameworks plus standard C/C++/pthread runtime support. OpenGL and Carbon
are inherited deprecated APIs. Linux needs OpenGL/GLX and window-system headers;
CI installs `libopengl-dev libglx-dev libxext-dev libglvnd-dev`. Windows uses the
Windows SDK, D3D9 and Winsock (`ws2_32`, `wsock32`). Networking has no external
TLS/networking package; protocol and SRP code are in the repository.

Legacy FreeType, Lua, zlib, Expat and StormLib versions are technical debt;
this milestone does not establish their security or replace fidelity-sensitive
implementations. Internal `WHOA_*` and test names intentionally remain.

FMOD is enabled with `-DWHOA_BUILD_FMOD=ON`; the Core macOS dylib contains both
ARM64 and x86_64 slices, but audio-enabled operation is not validated by the
default build. FMOD Ex and Linux ARM audio require separate investigation.
The default audio-disabled build must not be described as verified audio.

The XvidDecoder module defaults on only for Intel Windows when the vendor package
is present. These COFF libraries cannot link on macOS/Linux. To enable movies on
another platform, provide an architecture-compatible static xvidcore with
`-DWHOA_BUILD_XVID_DECODER=ON -DXVIDCORE_ROOT=...`; see
`tools/xviddecoder/README.md`. Decoder operation on Apple Silicon is unverified.

## Debugging and sanitizers

Debug preserves assertions and defaults to UBSan on Clang/GCC. Alignment checks
are excluded for inherited binary-data layouts, and other UB is fatal. Release
uses optimized compilation and disables the default UBSan option. Explicit
`-DWHOA_UB_SAN=OFF` disables UBSan. Use fresh configuration directories when
changing these options: cached options persist.

```sh
./scripts/build.sh debug clean test asan
```

`WHOA_ASAN` enables AddressSanitizer with frame pointers on Clang/GCC and uses the
inherited MSVC ASan setup. Instrumented client code links into an instrumented
process; proprietary prebuilt FMOD/Xvid components are not instrumented.
Tests do not cover a complete game-data launch or client/server interaction.
Consult the report for observed sanitizer results and inherited warnings.

`cmake/DependencyFixes.cmake` applies small verified corrections to generated
source copies under the build directory: Storm log-directory creation, fatal
function termination, a Common GCC header, sorted-array member double destruction,
fixed-array Clear lifetime preservation, zero-byte big-integer buffer copying,
bounded decimal digit-table indexing, and two inherited test defects.
It checks the original text before applying each correction and leaves pinned
submodule working trees untouched. These corrections should eventually move
into maintained dependency commits. CTest registers all five inherited test
executables and four asset-free startup regression checks.

## Windows and Linux

Use the same CMake commands, omitting `CMAKE_OSX_ARCHITECTURES`. With Visual
Studio, configure `CMAKE_BUILD_TYPE` to match `--config` (the inherited assertion
and UBSan selection is configure-time), and pass `-C Debug`/`-C Release` to CTest.
Windows binaries are under `build/bin/<configuration>/Northrend.exe` before
installation. The CI workflow attempts both configurations on all three OSes.

## Zig status

Preserved for upstream reference, not an alternative supported milestone path.
`build.zig` names a Northrend executable but lists nonexistent `src/app/macos`
files and the old `src/world/CWorld.cpp`, and omits current clientobject,
componentcore and map sources. It expects SDL2 while CMake uses vendored SDL3.
`build.zig.zon` fetches mutable `master.zip` URLs with hashes, which can reject
changed remote archives. No Zig executable is installed on the validation Mac;
no Zig configure/build or compatibility version was verified. Do not use Zig to
infer that the current full client builds.

## Common failures

- Initialize **recursive** submodules; empty directories are not dependencies.
- The original Squall pin was unavailable from its configured remote. This
  branch pins reachable SatyPardus Squall and bc commits with required APIs.
- Do not use an in-source build. Delete only your selected build directory for a
  clean rebuild; do not remove data directories.
- CMake 4 needs a compatibility floor for old vendored projects; the root now
  sets `CMAKE_POLICY_VERSION_MINIMUM=3.5`.
- Do not turn on the Windows-only vendored movie decoder on ARM64 macOS.
- A missing SDK or x86_64-only external library is a configuration error; do not
  silently switch architectures. Verify the final file with `file`/`lipo -archs`.
