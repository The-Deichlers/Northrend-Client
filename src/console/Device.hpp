#ifndef CONSOLE_DEVICE_HPP
#define CONSOLE_DEVICE_HPP

#include "gx/CGxFormat.hpp"

#include "console/Detect.hpp"

extern DefaultSettings s_defaults;
extern Hardware s_hardware;
extern bool s_hwChanged;
extern bool s_hwDetect;
extern CGxFormat s_requestedFormat;
extern CGxFormat s_lastGoodFormat;
extern CGxFormat s_desktopFormat;
extern CGxFormat s_fallbackFormat;
extern char s_windowTitle[256];

void ValidateFormatMonitor(CGxFormat& format);

const char* ConsoleDeviceInitialize(const char* title);

bool ConsoleDeviceExists();

void ConsoleDeviceDestroy();

#endif
