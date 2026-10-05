#include "catch.hpp"
#include "gx/GllCapabilities.hpp"

TEST_CASE("GLL capabilities reflect hardware and implemented backend limits", "[gx]") {
    GllHardwareCaps hardware;
    hardware.valid = hardware.s3tc = hardware.vertexProgram = hardware.fragmentProgram = true;
    hardware.nonPowerOfTwo = true;
    hardware.textureUnits = 32;
    hardware.vertexAttributes = 16;
    hardware.textureSize = 16384;
    hardware.cubeSize = 8192;
    hardware.rectangleSize = 4096;
    hardware.anisotropy = 16;
    CGxCaps caps;
    SECTION("supported hardware is clamped to implemented bindings") {
        REQUIRE(GllTranslateCaps(hardware, caps) == nullptr);
        CHECK(caps.m_numTmus == 16);
        CHECK(caps.m_numStreams == 1);
        CHECK(caps.m_texMaxSize[GxTex_2d] == 16384);
        CHECK(caps.m_texMaxSize[GxTex_CubeMap] == 8192);
        CHECK(caps.m_maxIndex == 65535);
        CHECK(caps.m_texFilterAnisotropic == 1);
    }
    SECTION("optional absent extensions do not advertise support") {
        hardware.rectangleSize = hardware.anisotropy = 0;
        hardware.nonPowerOfTwo = false;
        REQUIRE(GllTranslateCaps(hardware, caps) == nullptr);
        CHECK(caps.m_texTarget[GxTex_Rectangle] == 0);
        CHECK(caps.m_texTarget[GxTex_NonPow2] == 0);
        CHECK(caps.m_texFilterAnisotropic == 0);
    }
    SECTION("failed queries clear previous capabilities") {
        caps.m_numTmus = 16;
        hardware.valid = false;
        REQUIRE(GllTranslateCaps(hardware, caps) != nullptr);
        CHECK(caps.m_numTmus == 0);
        CHECK(caps.m_texMaxSize[GxTex_2d] == 0);
    }
    SECTION("insufficient texture units are rejected") {
        hardware.textureUnits = 1;
        CHECK(GllTranslateCaps(hardware, caps) != nullptr);
    }
    SECTION("insufficient attributes are rejected") {
        hardware.vertexAttributes = 13;
        CHECK(GllTranslateCaps(hardware, caps) != nullptr);
    }
    SECTION("required extensions are rejected when absent") {
        hardware.fragmentProgram = false;
        CHECK(GllTranslateCaps(hardware, caps) != nullptr);
        hardware.fragmentProgram = true;
        hardware.s3tc = false;
        CHECK(GllTranslateCaps(hardware, caps) != nullptr);
    }
    SECTION("invalid texture limits are rejected") {
        hardware.textureSize = 0;
        CHECK(GllTranslateCaps(hardware, caps) != nullptr);
    }
}

TEST_CASE("GLL extension names must match complete tokens", "[gx]") {
    CHECK(GllHasExtension("GL_ARB_shadow GL_ARB_vertex_program", "GL_ARB_shadow"));
    CHECK_FALSE(GllHasExtension("GL_ARB_shadow_ambient", "GL_ARB_shadow"));
    CHECK_FALSE(GllHasExtension(nullptr, "GL_ARB_shadow"));
    CHECK_FALSE(GllHasExtension("GL_ARB_shadow", ""));
}
