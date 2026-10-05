#include <catch.hpp>
#include "util/ClockConversion.hpp"
#include <common/time/Time.hpp>
#include <chrono>
#include <thread>

TEST_CASE("Mach timebase conversion returns milliseconds", "[startup][time]") {
    CHECK(ClockTicksToMilliseconds(1000000, 1, 1) == 1);
    CHECK(ClockTicksToMilliseconds(24000000, 125, 3) == 1000);
    CHECK(ClockTicksToMilliseconds(23999, 125, 3) == 0);
    CHECK(ClockTicksToMilliseconds(24000, 125, 3) == 1);
    CHECK(ClockTicksToMilliseconds(1000000000000000ULL, 125, 3) == 41666666666ULL);
}

#if defined(WHOA_SYSTEM_MAC)
TEST_CASE("macOS clock and sleep use wall-clock milliseconds", "[startup][time]") {
    const auto wallStart = std::chrono::steady_clock::now();
    const auto start = OsGetAsyncTimeMsPrecise();
    OsSleep(100);
    const auto elapsed = OsGetAsyncTimeMsPrecise() - start;
    const auto wallElapsed = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - wallStart).count();
    CHECK(wallElapsed >= 80);
    CHECK(elapsed >= 80);
    CHECK(static_cast<int64_t>(elapsed) >= wallElapsed - 20);
    CHECK(static_cast<int64_t>(elapsed) <= wallElapsed + 20);
}
#endif
