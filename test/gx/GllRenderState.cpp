#include "catch.hpp"
#include "gx/GllRenderState.hpp"

TEST_CASE("GLL scalar states reject unsafe table indices and masks", "[gx]") {
    CHECK(GllValidateScalarState(GxRs_BlendingMode, GxBlend_Opaque) == nullptr);
    CHECK(GllValidateScalarState(GxRs_BlendingMode, GxBlends_Last - 1) == nullptr);
    CHECK(GllValidateScalarState(GxRs_BlendingMode, -1) != nullptr);
    CHECK(GllValidateScalarState(GxRs_BlendingMode, GxBlends_Last) != nullptr);
    CHECK(GllValidateScalarState(GxRs_Culling, 2) == nullptr);
    CHECK(GllValidateScalarState(GxRs_Culling, 3) != nullptr);
    CHECK(GllValidateScalarState(GxRs_DepthFunc, 3) == nullptr);
    CHECK(GllValidateScalarState(GxRs_DepthFunc, 4) != nullptr);
    CHECK(GllValidateScalarState(GxRs_AlphaRef, 255) == nullptr);
    CHECK(GllValidateScalarState(GxRs_AlphaRef, 256) != nullptr);
    CHECK(GllValidateScalarState(GxRs_ColorWrite, 15) == nullptr);
    CHECK(GllValidateScalarState(GxRs_ColorWrite, 16) != nullptr);
    CHECK(GllValidateScalarState(GxRs_ColorOp7, 5) == nullptr);
    CHECK(GllValidateScalarState(GxRs_AlphaOp7, 6) != nullptr);
    CHECK(GllValidateScalarState(GxRenderStates_Last, 0) != nullptr);
}

TEST_CASE("GLL texture operations preserve inherited combination semantics", "[gx]") {
    const GllTextureCombine expected[] = {
        {GllTextureCombine::Modulate, GllTextureCombine::Texture, GllTextureCombine::Previous, GllTextureCombine::Previous, 1},
        {GllTextureCombine::Modulate, GllTextureCombine::Texture, GllTextureCombine::Previous, GllTextureCombine::Previous, 2},
        {GllTextureCombine::Add, GllTextureCombine::Texture, GllTextureCombine::Previous, GllTextureCombine::Previous, 1},
        {GllTextureCombine::Replace, GllTextureCombine::Previous, GllTextureCombine::Previous, GllTextureCombine::Previous, 1},
        {GllTextureCombine::Interpolate, GllTextureCombine::Previous, GllTextureCombine::Texture, GllTextureCombine::Previous, 1},
        {GllTextureCombine::Interpolate, GllTextureCombine::Texture, GllTextureCombine::Previous, GllTextureCombine::PrimaryColor, 1}
    };
    for (int value = 0; value < 6; ++value) {
        const auto translated = GllTranslateTextureCombine(value);
        CHECK(translated.operation == expected[value].operation);
        CHECK(translated.first == expected[value].first);
        CHECK(translated.second == expected[value].second);
        CHECK(translated.weight == expected[value].weight);
        CHECK(translated.scale == expected[value].scale);
    }
}
