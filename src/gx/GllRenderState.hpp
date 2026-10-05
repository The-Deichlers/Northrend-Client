#ifndef GX_GLL_RENDER_STATE_HPP
#define GX_GLL_RENDER_STATE_HPP

#include "gx/Types.hpp"

struct GllTextureCombine {
    enum Operation { Modulate, Add, Replace, Interpolate } operation;
    enum Source { Texture, Previous, PrimaryColor } first, second, weight;
    int scale;
};

inline GllTextureCombine GllTranslateTextureCombine(int value) {
    // Caller validates 0..5. Match the inherited D3D texture-op/argument table.
    return {
        value == 2 ? GllTextureCombine::Add : value == 3 ? GllTextureCombine::Replace : value >= 4 ? GllTextureCombine::Interpolate : GllTextureCombine::Modulate,
        value == 3 || value == 4 ? GllTextureCombine::Previous : GllTextureCombine::Texture,
        value == 4 ? GllTextureCombine::Texture : GllTextureCombine::Previous,
        value == 5 ? GllTextureCombine::PrimaryColor : GllTextureCombine::Previous,
        value == 1 ? 2 : 1
    };
}

inline const char* GllValidateScalarState(EGxRenderState state, int value) {
    if (state < 0 || state >= GxRenderStates_Last) return "invalid render-state index";
    if (state == GxRs_BlendingMode && (value < 0 || value >= GxBlends_Last)) return "invalid blend mode";
    if (state == GxRs_Culling && (value < 0 || value > 2)) return "invalid cull mode";
    if (state == GxRs_DepthFunc && (value < 0 || value > 3)) return "unsupported depth comparison";
    if (state == GxRs_AlphaRef && (value < 0 || value > 255)) return "invalid alpha reference";
    if (state == GxRs_ColorWrite && (value < 0 || value > 15)) return "invalid color-write mask";
    if (state >= GxRs_ColorOp0 && state <= GxRs_AlphaOp7 && (value < 0 || value > 5)) return "invalid texture-combine operation";
    return nullptr;
}

#endif
