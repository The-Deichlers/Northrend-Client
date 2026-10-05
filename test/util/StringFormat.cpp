#include <catch.hpp>
#include <bc/string/QuickFormat.hpp>
#include <cstring>

TEST_CASE("File diagnostics format into an uninitialized destination", "[startup][format]") {
    Blizzard::String::QuickFormat<128> message("Posix Read - %s - %u", "asset.xml", 7u);
    REQUIRE(std::strcmp(message.ToString(), "Posix Read - asset.xml - 7") == 0);

    Blizzard::String::QuickFormat<8> truncated("%s", "long diagnostic");
    REQUIRE(std::strcmp(truncated.ToString(), "long di") == 0);
}
