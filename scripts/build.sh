#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configuration=Debug
clean=0
test_build=0
asan=OFF
for option in "$@"; do
    case "$option" in
        debug) configuration=Debug ;;
        release) configuration=Release ;;
        clean) clean=1 ;;
        test) test_build=1 ;;
        asan) asan=ON ;;
        *) echo "Usage: $0 [debug|release] [clean] [test] [asan]" >&2; exit 2 ;;
    esac
done
build_name="$(printf '%s' "$configuration" | tr '[:upper:]' '[:lower:]')"
build_dir="$root/build/$build_name"
if [[ "$asan" == ON ]]; then build_dir="$build_dir-asan"; fi
if [[ "$clean" == 1 ]]; then rm -rf "$build_dir"; fi
git -C "$root" submodule update --init --recursive
cmake_args=(-S "$root" -B "$build_dir" "-DCMAKE_BUILD_TYPE=$configuration" "-DWHOA_ASAN=$asan")
if [[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]]; then
    cmake_args+=(-DCMAKE_OSX_ARCHITECTURES=arm64)
fi
cmake "${cmake_args[@]}"
cmake --build "$build_dir" --config "$configuration" --parallel "${NORTHREND_BUILD_JOBS:-8}"
cmake --install "$build_dir" --config "$configuration" --prefix "$build_dir/install"
if [[ "$test_build" == 1 ]]; then
    ctest --test-dir "$build_dir" -C "$configuration" --output-on-failure
fi
printf 'Installed client: %s/install/bin/Northrend\n' "$build_dir"
