#ifndef UTIL_CLOCK_CONVERSION_HPP
#define UTIL_CLOCK_CONVERSION_HPP

#include <cstdint>

// mach_timebase_info supplies a positive denominator. Preserve its fractional
// ratio before converting nanoseconds to milliseconds, including on Apple Silicon.
inline uint64_t ClockTicksToMilliseconds(uint64_t ticks, uint32_t numerator, uint32_t denominator) {
    return static_cast<uint64_t>(static_cast<long double>(ticks) * numerator / denominator / 1000000.0L);
}

#endif
