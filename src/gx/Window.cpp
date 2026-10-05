#include "gx/Window.hpp"
#include "gx/Device.hpp"
#include "os/Gui.hpp"

bool s_forceOnscreen;
Rect s_savedWindowRect;
Rect s_savedWindowZoomedRect;

RECT s_defaultWindowRect;
int32_t s_savedResize;

// OFFSET: 0x86A1A0
int32_t OsGetDefaultWindowRect(RECT* rect) {
    if (!rect) {
        SErrSetLastError(87);
        return 0;
    }

    if (!s_defaultWindowRect.right || !s_defaultWindowRect.bottom) {
#if defined(WHOA_SYSTEM_WIN)
        auto v2 = (HWND)OsGuiGetWindow(0);
        if (!GetClientRect(v2, &s_defaultWindowRect))
            return 0;
#else
        if (!GxDevExists()) {
            return 0;
        }
        CRect bounds;
        GxCapsWindowSize(bounds);
        s_defaultWindowRect = {
            static_cast<int32_t>(bounds.minX), static_cast<int32_t>(bounds.minY),
            static_cast<int32_t>(bounds.maxX), static_cast<int32_t>(bounds.maxY)
        };
#endif
    }
    *rect = s_defaultWindowRect;

    return 1;
}

Rect* GetSavedWindowBounds() {
    return &s_savedWindowRect;
}

Rect* GetSavedZoomedWindowBounds() {
    return &s_savedWindowZoomedRect;
}

void SetSavedWindowBounds(Rect rect) {
    s_forceOnscreen = true;
    s_savedWindowRect = rect;
}

void SetSavedZoomedWindowBounds(Rect rect) {
    s_forceOnscreen = true;
    s_savedWindowZoomedRect = rect;
}
