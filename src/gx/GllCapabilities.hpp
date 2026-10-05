#ifndef GX_GLL_CAPABILITIES_HPP
#define GX_GLL_CAPABILITIES_HPP

#include "gx/CGxCaps.hpp"
#include <algorithm>
#include <cstring>

// Hardware observations, independent of OpenGL calls so translation is testable.
struct GllHardwareCaps {
    bool valid = false;
    int textureUnits = 0;
    int vertexAttributes = 0;
    int textureSize = 0;
    int cubeSize = 0;
    int rectangleSize = 0;
    int anisotropy = 0;
    bool s3tc = false;
    bool vertexProgram = false;
    bool fragmentProgram = false;
    bool nonPowerOfTwo = false;
};

inline bool GllHasExtension(const char* extensions, const char* name) {
    if (!extensions || !name || !*name || std::strchr(name, ' ')) return false;
    const size_t length = std::strlen(name);
    const char* cursor = extensions;
    while ((cursor = std::strstr(cursor, name))) {
        if ((cursor == extensions || cursor[-1] == ' ') &&
            (cursor[length] == ' ' || cursor[length] == '\0')) return true;
        cursor += length;
    }
    return false;
}

inline const char* GllTranslateCaps(const GllHardwareCaps& hardware, CGxCaps& caps) {
    caps = CGxCaps{};
    if (!hardware.valid) return "OpenGL capability query failed or no context is current";
    if (hardware.textureUnits < 2) return "OpenGL requires at least two texture units";
    if (hardware.vertexAttributes < 14) return "OpenGL requires fourteen vertex attributes for Northrend vertex formats";
    if (hardware.textureSize <= 0 || hardware.cubeSize <= 0) return "OpenGL reports invalid texture-size limits";
    if (!hardware.vertexProgram || !hardware.fragmentProgram) return "OpenGL ARB vertex and fragment programs are required by GLL";
    if (!hardware.s3tc) return "OpenGL S3TC texture compression is required for game textures";
    caps.m_numTmus = std::min(hardware.textureUnits, 16);
    // CGxDeviceGLL submits one interleaved vertex stream, always at binding zero.
    caps.m_numStreams = 1;
    caps.m_maxIndex = 65535; // CGxBatch and GL_UNSIGNED_SHORT indices.
    caps.m_pixelCenterOnEdge = caps.m_texelCenterOnEdge = 1;
    caps.m_colorFormat = GxCF_rgba;
    caps.m_generateMipMaps = caps.int10 = caps.m_texFilterTrilinear = 1;
    caps.m_shaderTargets[GxSh_Vertex] = GxShVS_arbvp1;
    caps.m_shaderTargets[GxSh_Pixel] = GxShPS_arbfp1;
    for (auto format : {GxTex_Abgr8888, GxTex_Argb8888, GxTex_Argb4444,
                       GxTex_Argb1555, GxTex_Rgb565, GxTex_Dxt1, GxTex_Dxt3, GxTex_Dxt5})
        caps.m_texFmt[format] = 1;
    caps.m_texTarget[GxTex_2d] = caps.m_texTarget[GxTex_CubeMap] = 1;
    caps.m_texMaxSize[GxTex_2d] = hardware.textureSize;
    caps.m_texMaxSize[GxTex_CubeMap] = hardware.cubeSize;
    caps.m_texTarget[GxTex_Rectangle] = hardware.rectangleSize > 0;
    caps.m_texMaxSize[GxTex_Rectangle] = std::max(hardware.rectangleSize, 0);
    caps.m_texTarget[GxTex_NonPow2] = hardware.nonPowerOfTwo;
    caps.m_texMaxSize[GxTex_NonPow2] = hardware.nonPowerOfTwo ? hardware.textureSize : 0;
    caps.m_texFilterAnisotropic = hardware.anisotropy > 1;
    caps.m_maxTexAnisotropy = std::max(hardware.anisotropy, 1);
    caps.m_depthBias = 1;
    return nullptr;
}

#endif
