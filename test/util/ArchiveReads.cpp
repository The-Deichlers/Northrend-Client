#include <catch.hpp>
#include "util/SFile.hpp"
#include <StormLib.h>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <string>
#include <thread>
#include <vector>

TEST_CASE("Synchronous and worker archive reads preserve file contents", "[startup][archive]") {
    const auto stamp = std::chrono::steady_clock::now().time_since_epoch().count();
    const std::string path = "northrend-read-test-" + std::to_string(stamp) + ".mpq";
    struct Archive {
        std::string path;
        HANDLE handle = nullptr;
        ~Archive() { if (handle) SFileCloseArchive(handle); std::remove(path.c_str()); }
    } archive;
    archive.path = path;
    REQUIRE(SFileCreateArchive(path.c_str(), 0, 8, &archive.handle));
    std::vector<unsigned char> payloads[2];
    const char* names[] = {"synthetic-ui.xml", "synthetic-texture.bin"};
    for (unsigned i = 0; i < 2; ++i) {
        payloads[i].resize(32768);
        uint32_t seed = i + 1;
        for (auto& byte : payloads[i]) {
            seed = seed * 1664525u + 1013904223u;
            byte = static_cast<unsigned char>(seed >> 24);
        }
        HANDLE file = nullptr;
        REQUIRE(SFileCreateFile(archive.handle, names[i], 0, payloads[i].size(), 0, MPQ_FILE_COMPRESS, &file));
        REQUIRE(SFileWriteFile(file, payloads[i].data(), payloads[i].size(), MPQ_COMPRESSION_ZLIB));
        REQUIRE(SFileFinishFile(file));
    }
    REQUIRE(SFileCloseArchive(archive.handle));
    archive.handle = nullptr;
    REQUIRE(SFileOpenArchive(path.c_str(), 0, MPQ_OPEN_READ_ONLY, &archive.handle));
    HANDLE handles[2] = {};
    for (unsigned i = 0; i < 2; ++i)
        REQUIRE(SFileOpenFileEx(archive.handle, names[i], SFILE_OPEN_FROM_MPQ, &handles[i]));
    std::atomic<unsigned> ready{0};
    std::atomic<unsigned> failures{0};
    auto read = [&](unsigned i) {
        SFile file;
        file.m_type = SFILE_PAQ;
        file.m_handle = handles[i];
        std::vector<unsigned char> buffer(payloads[i].size());
        ++ready;
        while (ready.load() < 2) std::this_thread::yield();
        for (unsigned round = 0; round < 500; ++round) {
            size_t bytes = 0;
            if (SFile::SetFilePointer(&file, 0, nullptr, 0) != 0 ||
                !SFile::Read(&file, buffer.data(), buffer.size(), &bytes, nullptr, nullptr) ||
                bytes != buffer.size() || buffer != payloads[i]) ++failures;
        }
    };
    std::thread first(read, 0), second(read, 1);
    first.join();
    second.join();
    for (auto handle : handles) SFileCloseFile(handle);
    REQUIRE(failures.load() == 0);
}
