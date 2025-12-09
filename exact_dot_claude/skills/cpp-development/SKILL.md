---
name: cpp-development
description: |
  Modern C/C++ development with CMake, Conan, Clang tools, C++20/23 standards, and
  cross-platform best practices. Covers high-performance systems programming, memory-safe
  design, RAII patterns, and modern C++ idioms.
  Use when user mentions C++, CMake, Conan, clang-format, clang-tidy, C++20, C++23,
  systems programming, or compiling C/C++ code.
allowed-tools: Glob, Grep, Read, Bash, Edit, Write, TodoWrite
---

# C++ Development

Expert knowledge for modern C++20/23 development with focus on high-performance, cross-platform systems programming.

## Core Expertise

**Modern C++ Standards (C++20/23)**
- **Core Language**: Modules, concepts, ranges, coroutines, and constexpr improvements
- **STL Enhancements**: std::format, std::span, std::jthread, and container improvements
- **Memory Safety**: Smart pointers, RAII patterns, and modern memory management
- **Type Safety**: Concepts, auto deduction, and template metaprogramming

## Key Capabilities

**Build Systems & Package Management**
- **CMake**: Modern CMake 3.20+ with targets, generators, and cross-platform builds
- **Conan**: C++ package management with conanfile.py and dependency resolution
- **vcpkg**: Microsoft's C++ package manager integration
- **Meson**: High-performance build system alternative

**Development Tools & Analysis**
- **Clang Tools**: clang-format, clang-tidy, clang-analyzer for code quality
- **AddressSanitizer/MemorySanitizer**: Runtime error detection
- **Valgrind**: Memory profiling and leak detection
- **GDB/LLDB**: Advanced debugging with pretty printers

**Performance Optimization**
- Profile with perf, Intel VTune, and custom profiling solutions
- Optimize with -O2/-O3 flags, LTO, and PGO optimization
- Memory layout optimization and cache-friendly data structures
- SIMD intrinsics and auto-vectorization

**Testing & Quality Assurance**
- **Catch2/GoogleTest**: Modern C++ testing frameworks
- **Google Benchmark**: Performance measurement
- **Fuzzing**: libFuzzer and AFL for security testing
- **CI Integration**: GitHub Actions, GitLab CI with multiple compilers

## Essential Commands

```bash
# CMake workflow
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --build build --target test

# Conan workflow
conan install . --output-folder=build --build=missing
cmake --preset conan-release
cmake --build --preset conan-release

# Code quality
clang-format -i src/**/*.cpp
clang-tidy src/**/*.cpp --
```

## Best Practices

**Modern C++ Coding Standards**
- Use RAII for all resource management
- Apply const-correctness and constexpr where possible
- Implement move semantics and perfect forwarding
- Use std::unique_ptr and std::shared_ptr instead of raw pointers
- Prefer algorithms and ranges over raw loops

**CMake Configuration**
```cmake
cmake_minimum_required(VERSION 3.20)
project(MyProject VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(fmt REQUIRED)

add_executable(myapp src/main.cpp)
target_link_libraries(myapp PRIVATE fmt::fmt)
target_compile_features(myapp PRIVATE cxx_std_20)
```

**RAII Pattern**
```cpp
class FileHandler {
private:
    std::unique_ptr<FILE, decltype(&fclose)> file_;
public:
    explicit FileHandler(const std::string& path)
        : file_(fopen(path.c_str(), "r"), &fclose) {
        if (!file_) throw std::runtime_error("Failed to open file");
    }
    // Automatic cleanup via RAII
};
```

For detailed concepts, ranges, coroutines, security patterns, and advanced optimization techniques, see REFERENCE.md.
