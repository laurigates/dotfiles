# C++ Development Reference

Comprehensive reference for modern C++ development with CMake, Conan, cross-platform patterns, C++20/23 features, and Clang tools.

## Table of Contents

- [CMake Advanced Configuration](#cmake-advanced-configuration)
- [Conan Package Management](#conan-package-management)
- [Cross-Platform Patterns](#cross-platform-patterns)
- [Modern C++20/23 Features](#modern-c2023-features)
- [Clang Tools Usage](#clang-tools-usage)
- [Build System Patterns](#build-system-patterns)
- [Memory Safety Tools](#memory-safety-tools)
- [Performance Tools](#performance-tools)

---

## CMake Advanced Configuration

### Modern CMake Project Structure

```cmake
cmake_minimum_required(VERSION 3.25)
project(MyProject
    VERSION 1.0.0
    DESCRIPTION "Modern C++ Project"
    LANGUAGES CXX
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands for tooling
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Enable testing
enable_testing()

# Add subdirectories
add_subdirectory(src)
add_subdirectory(tests)
add_subdirectory(extern)
```

### Target-Based Configuration

```cmake
# Create library target
add_library(mylib
    src/mylib.cpp
    src/utils.cpp
)

# Target properties (modern approach)
target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_compile_features(mylib PUBLIC cxx_std_20)

target_compile_options(mylib PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:Clang>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

target_link_libraries(mylib
    PUBLIC
        fmt::fmt
    PRIVATE
        spdlog::spdlog
)
```

### Generator Expressions

```cmake
# Compiler-specific options
target_compile_options(mylib PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:-fno-rtti>
    $<$<CXX_COMPILER_ID:Clang>:-fno-rtti>
    $<$<CXX_COMPILER_ID:MSVC>:/GR->
)

# Configuration-specific options
target_compile_definitions(mylib PRIVATE
    $<$<CONFIG:Debug>:DEBUG_BUILD>
    $<$<CONFIG:Release>:RELEASE_BUILD>
)

# Platform-specific options
target_compile_definitions(mylib PRIVATE
    $<$<PLATFORM_ID:Windows>:PLATFORM_WINDOWS>
    $<$<PLATFORM_ID:Linux>:PLATFORM_LINUX>
    $<$<PLATFORM_ID:Darwin>:PLATFORM_MACOS>
)

# Build type specific linking
target_link_libraries(mylib PRIVATE
    $<$<CONFIG:Debug>:debug_allocator>
    $<$<CONFIG:Release>:tcmalloc>
)
```

### Find Modules and Config Files

```cmake
# Find package with components
find_package(Boost 1.80 REQUIRED COMPONENTS
    system
    filesystem
    thread
)

# Find with custom paths
find_package(MyLib REQUIRED
    PATHS ${CMAKE_SOURCE_DIR}/extern/mylib
    NO_DEFAULT_PATH
)

# Use imported targets
target_link_libraries(myapp PRIVATE
    Boost::system
    Boost::filesystem
    Boost::thread
)

# Check if found
if(NOT Boost_FOUND)
    message(FATAL_ERROR "Boost not found")
endif()
```

### Custom Find Module

```cmake
# FindMyLib.cmake
find_path(MYLIB_INCLUDE_DIR
    NAMES mylib/mylib.h
    PATHS ${CMAKE_SOURCE_DIR}/extern/mylib/include
)

find_library(MYLIB_LIBRARY
    NAMES mylib
    PATHS ${CMAKE_SOURCE_DIR}/extern/mylib/lib
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MyLib
    REQUIRED_VARS MYLIB_LIBRARY MYLIB_INCLUDE_DIR
    VERSION_VAR MYLIB_VERSION
)

if(MyLib_FOUND AND NOT TARGET MyLib::MyLib)
    add_library(MyLib::MyLib UNKNOWN IMPORTED)
    set_target_properties(MyLib::MyLib PROPERTIES
        IMPORTED_LOCATION "${MYLIB_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${MYLIB_INCLUDE_DIR}"
    )
endif()
```

### Package Config File

```cmake
# MyLibConfig.cmake.in
@PACKAGE_INIT@

include("${CMAKE_CURRENT_LIST_DIR}/MyLibTargets.cmake")
check_required_components(MyLib)

# CMakeLists.txt
include(CMakePackageConfigHelpers)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)
```

---

## Conan Package Management

### conanfile.txt

```ini
[requires]
fmt/10.1.1
spdlog/1.12.0
boost/1.83.0
catch2/3.4.0

[generators]
CMakeDeps
CMakeToolchain

[options]
boost:shared=False
boost:without_test=True

[imports]
bin, *.dll -> ./bin
lib, *.dylib* -> ./lib
```

### conanfile.py

```python
from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout

class MyProjectConan(ConanFile):
    name = "myproject"
    version = "1.0.0"

    # Settings
    settings = "os", "compiler", "build_type", "arch"

    # Options
    options = {
        "shared": [True, False],
        "fPIC": [True, False]
    }
    default_options = {
        "shared": False,
        "fPIC": True
    }

    # Dependencies
    requires = [
        "fmt/10.1.1",
        "spdlog/1.12.0",
        "boost/1.83.0"
    ]

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def layout(self):
        cmake_layout(self)

    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["BUILD_TESTING"] = "ON"
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
```

### Conan Profiles

```ini
# profiles/gcc-debug
[settings]
os=Linux
arch=x86_64
compiler=gcc
compiler.version=12
compiler.libcxx=libstdc++11
build_type=Debug

[conf]
tools.cmake.cmaketoolchain:generator=Ninja

# profiles/clang-release
[settings]
os=Linux
arch=x86_64
compiler=clang
compiler.version=16
compiler.libcxx=libc++
build_type=Release

[conf]
tools.build:compiler_executables={"c": "clang-16", "cpp": "clang++-16"}
```

### Conan Workflow

```bash
# Install dependencies
conan install . --build=missing

# Install with profile
conan install . --profile=gcc-debug --build=missing

# Build
cmake --preset conan-default
cmake --build --preset conan-release

# Create package
conan create . --build=missing

# Export package
conan export . user/channel

# Search packages
conan search fmt -r=conancenter

# List installed packages
conan list "*"
```

---

## Cross-Platform Patterns

### Platform Detection

```cmake
# Detect platform
if(WIN32)
    message(STATUS "Configuring for Windows")
    add_compile_definitions(PLATFORM_WINDOWS)
elseif(APPLE)
    message(STATUS "Configuring for macOS")
    add_compile_definitions(PLATFORM_MACOS)
elseif(UNIX)
    message(STATUS "Configuring for Linux")
    add_compile_definitions(PLATFORM_LINUX)
endif()

# Detect compiler
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    message(STATUS "Using GCC")
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(STATUS "Using Clang")
elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    message(STATUS "Using MSVC")
endif()
```

### Platform-Specific Code

```cpp
// platform.h
#pragma once

#if defined(_WIN32) || defined(_WIN64)
    #define PLATFORM_WINDOWS
    #include <windows.h>
#elif defined(__APPLE__) && defined(__MACH__)
    #define PLATFORM_MACOS
    #include <unistd.h>
    #include <mach-o/dyld.h>
#elif defined(__linux__)
    #define PLATFORM_LINUX
    #include <unistd.h>
    #include <limits.h>
#endif

// Platform-specific path separator
#ifdef PLATFORM_WINDOWS
    constexpr char PATH_SEPARATOR = '\\';
#else
    constexpr char PATH_SEPARATOR = '/';
#endif

// Platform-specific dynamic library extension
#ifdef PLATFORM_WINDOWS
    constexpr const char* DLL_EXT = ".dll";
#elif defined(PLATFORM_MACOS)
    constexpr const char* DLL_EXT = ".dylib";
#else
    constexpr const char* DLL_EXT = ".so";
#endif

// Get executable path (cross-platform)
std::filesystem::path get_executable_path();
```

```cpp
// platform.cpp
#include "platform.h"
#include <filesystem>

std::filesystem::path get_executable_path() {
#ifdef PLATFORM_WINDOWS
    char buffer[MAX_PATH];
    GetModuleFileNameA(nullptr, buffer, MAX_PATH);
    return std::filesystem::path(buffer);

#elif defined(PLATFORM_MACOS)
    char buffer[PATH_MAX];
    uint32_t size = sizeof(buffer);
    _NSGetExecutablePath(buffer, &size);
    return std::filesystem::path(buffer);

#elif defined(PLATFORM_LINUX)
    char buffer[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
    if (len != -1) {
        buffer[len] = '\0';
        return std::filesystem::path(buffer);
    }
    return {};
#endif
}
```

### Compiler Portability

```cpp
// Compiler-specific attributes
#ifdef _MSC_VER
    #define FORCE_INLINE __forceinline
    #define NO_INLINE __declspec(noinline)
    #define LIKELY(x) (x)
    #define UNLIKELY(x) (x)
#else
    #define FORCE_INLINE inline __attribute__((always_inline))
    #define NO_INLINE __attribute__((noinline))
    #define LIKELY(x) __builtin_expect(!!(x), 1)
    #define UNLIKELY(x) __builtin_expect(!!(x), 0)
#endif

// Export symbols
#ifdef _MSC_VER
    #define DLL_EXPORT __declspec(dllexport)
    #define DLL_IMPORT __declspec(dllimport)
#else
    #define DLL_EXPORT __attribute__((visibility("default")))
    #define DLL_IMPORT
#endif

#ifdef BUILDING_MYLIB
    #define MYLIB_API DLL_EXPORT
#else
    #define MYLIB_API DLL_IMPORT
#endif
```

---

## Modern C++20/23 Features

### Concepts

```cpp
#include <concepts>

// Define concept
template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

// Use concept as constraint
template<Numeric T>
T add(T a, T b) {
    return a + b;
}

// Concept with requires clause
template<typename T>
concept Incrementable = requires(T t) {
    { ++t } -> std::same_as<T&>;
    { t++ } -> std::same_as<T>;
};

// Multiple constraints
template<typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::convertible_to<T>;
};

template<typename T>
requires Numeric<T> && Addable<T>
T calculate(T a, T b) {
    return a + b;
}
```

### Ranges

```cpp
#include <ranges>
#include <vector>
#include <algorithm>

// Range views
std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

// Filter, transform, take
auto result = numbers
    | std::views::filter([](int n) { return n % 2 == 0; })
    | std::views::transform([](int n) { return n * n; })
    | std::views::take(3);

for (int n : result) {
    std::cout << n << " ";  // 4 16 36
}

// Range algorithms
std::ranges::sort(numbers);
std::ranges::reverse(numbers);
auto [min, max] = std::ranges::minmax(numbers);

// Zip view (C++23)
std::vector<int> keys = {1, 2, 3};
std::vector<std::string> values = {"one", "two", "three"};

for (auto [k, v] : std::views::zip(keys, values)) {
    std::cout << k << ": " << v << "\n";
}
```

### Coroutines

```cpp
#include <coroutine>
#include <iostream>
#include <exception>

// Simple generator
template<typename T>
struct Generator {
    struct promise_type {
        T current_value;

        auto get_return_object() {
            return Generator{std::coroutine_handle<promise_type>::from_promise(*this)};
        }

        auto initial_suspend() { return std::suspend_always{}; }
        auto final_suspend() noexcept { return std::suspend_always{}; }

        auto yield_value(T value) {
            current_value = value;
            return std::suspend_always{};
        }

        void return_void() {}
        void unhandled_exception() { std::terminate(); }
    };

    std::coroutine_handle<promise_type> handle;

    Generator(std::coroutine_handle<promise_type> h) : handle(h) {}
    ~Generator() { if (handle) handle.destroy(); }

    bool next() {
        handle.resume();
        return !handle.done();
    }

    T value() { return handle.promise().current_value; }
};

// Use generator
Generator<int> fibonacci() {
    int a = 0, b = 1;
    while (true) {
        co_yield a;
        auto next = a + b;
        a = b;
        b = next;
    }
}

// Usage
auto fib = fibonacci();
for (int i = 0; i < 10 && fib.next(); ++i) {
    std::cout << fib.value() << " ";
}
```

### Modules (C++20)

```cpp
// math.cppm
export module math;

export namespace math {
    int add(int a, int b) {
        return a + b;
    }

    int multiply(int a, int b) {
        return a * b;
    }
}

// main.cpp
import math;
import <iostream>;

int main() {
    std::cout << math::add(2, 3) << "\n";
    std::cout << math::multiply(2, 3) << "\n";
}
```

### Three-Way Comparison (Spaceship Operator)

```cpp
#include <compare>

struct Point {
    int x, y;

    // Compiler generates all comparison operators
    auto operator<=>(const Point&) const = default;
};

struct Version {
    int major, minor, patch;

    // Custom three-way comparison
    std::strong_ordering operator<=>(const Version& other) const {
        if (auto cmp = major <=> other.major; cmp != 0) return cmp;
        if (auto cmp = minor <=> other.minor; cmp != 0) return cmp;
        return patch <=> other.patch;
    }
};

// Usage
Point p1{1, 2}, p2{3, 4};
if (p1 < p2) { /* ... */ }
if (p1 == p2) { /* ... */ }

Version v1{1, 0, 0}, v2{1, 2, 3};
auto result = v1 <=> v2;  // strong_ordering::less
```

### constexpr Improvements

```cpp
// constexpr std::string (C++20)
constexpr std::string get_message() {
    std::string msg = "Hello";
    msg += " World";
    return msg;
}

// constexpr std::vector (C++20)
constexpr auto compute_squares() {
    std::vector<int> squares;
    for (int i = 0; i < 10; ++i) {
        squares.push_back(i * i);
    }
    return squares;
}

// consteval (immediate functions)
consteval int square(int n) {
    return n * n;
}

constexpr int x = square(5);  // OK
// int y = square(runtime_value);  // Error: must be compile-time
```

---

## Clang Tools Usage

### clang-format

```yaml
# .clang-format
---
Language: Cpp
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 100
PointerAlignment: Left
AllowShortFunctionsOnASingleLine: Empty
AllowShortIfStatementsOnASingleLine: Never
BreakBeforeBraces: Attach
IncludeCategories:
  - Regex: '^".*"'
    Priority: 1
  - Regex: '^<.*\.h>'
    Priority: 2
  - Regex: '^<.*'
    Priority: 3
```

```bash
# Format single file
clang-format -i src/main.cpp

# Format all files
find src -name '*.cpp' -o -name '*.h' | xargs clang-format -i

# Check formatting (CI)
clang-format --dry-run --Werror src/*.cpp
```

### clang-tidy

```yaml
# .clang-tidy
---
Checks: >
  -*,
  bugprone-*,
  clang-analyzer-*,
  cppcoreguidelines-*,
  modernize-*,
  performance-*,
  readability-*,
  -modernize-use-trailing-return-type,
  -readability-magic-numbers

CheckOptions:
  - key: readability-identifier-naming.NamespaceCase
    value: lower_case
  - key: readability-identifier-naming.ClassCase
    value: CamelCase
  - key: readability-identifier-naming.FunctionCase
    value: lower_case
  - key: readability-identifier-naming.VariableCase
    value: lower_case
  - key: readability-identifier-naming.ConstantCase
    value: UPPER_CASE
```

```bash
# Run clang-tidy
clang-tidy src/main.cpp -- -Iinclude -std=c++20

# With compilation database
clang-tidy -p build src/main.cpp

# Fix issues automatically
clang-tidy -fix src/main.cpp -- -Iinclude

# Run on all files
find src -name '*.cpp' | xargs clang-tidy -p build
```

### Compilation Database

```bash
# Generate with CMake
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build

# Creates build/compile_commands.json
# Used by clang-tidy, clangd, and other tools
```

### clang-analyzer (Static Analysis)

```bash
# Scan with scan-build
scan-build cmake -B build
scan-build make -C build

# Generate HTML report
scan-build -o reports cmake -B build
scan-build -o reports make -C build
```

---

## Build System Patterns

### Out-of-Source Builds

```bash
# Create build directory
mkdir build && cd build

# Configure
cmake ..

# Build
cmake --build .

# Install
cmake --build . --target install

# Multiple build types
cmake -DCMAKE_BUILD_TYPE=Debug -B build-debug
cmake -DCMAKE_BUILD_TYPE=Release -B build-release
```

### Install Rules

```cmake
# Install targets
install(TARGETS mylib myapp
    EXPORT MyLibTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install headers
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install export
install(EXPORT MyLibTargets
    FILE MyLibTargets.cmake
    NAMESPACE MyLib::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)
```

### Testing Integration

```cmake
# Enable testing
enable_testing()

# Add test
add_executable(mylib_test tests/mylib_test.cpp)
target_link_libraries(mylib_test PRIVATE mylib Catch2::Catch2WithMain)

add_test(NAME mylib_test COMMAND mylib_test)

# CTest configuration
include(CTest)
add_test(NAME fast_test COMMAND mylib_test --quick)
set_tests_properties(fast_test PROPERTIES TIMEOUT 10)
```

```bash
# Run tests
ctest

# Verbose output
ctest -V

# Run specific test
ctest -R mylib_test

# Parallel execution
ctest -j4
```

### CPack Packaging

```cmake
# Package configuration
include(CPack)

set(CPACK_PACKAGE_NAME "MyLib")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "My Library")
set(CPACK_PACKAGE_VENDOR "My Company")

# Platform-specific
if(WIN32)
    set(CPACK_GENERATOR "NSIS" "ZIP")
elseif(APPLE)
    set(CPACK_GENERATOR "DragNDrop" "TGZ")
else()
    set(CPACK_GENERATOR "DEB" "RPM" "TGZ")
endif()

# Debian-specific
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "maintainer@example.com")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libfmt9, libspdlog1")

# Build package
# cmake --build build --target package
```

---

## Memory Safety Tools

### AddressSanitizer (ASan)

```cmake
# Enable AddressSanitizer
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fno-omit-frame-pointer")
set(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} -fsanitize=address")
```

```bash
# Run with ASan
ASAN_OPTIONS=detect_leaks=1:check_initialization_order=1 ./myapp

# Symbolize output
ASAN_SYMBOLIZER_PATH=/usr/bin/llvm-symbolizer ./myapp
```

### UndefinedBehaviorSanitizer (UBSan)

```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=undefined")
set(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} -fsanitize=undefined")
```

### ThreadSanitizer (TSan)

```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=thread")
set(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} -fsanitize=thread")
```

### Valgrind

```bash
# Memory leak detection
valgrind --leak-check=full --show-leak-kinds=all ./myapp

# Generate suppressions
valgrind --leak-check=full --gen-suppressions=all ./myapp

# With cache profiling
valgrind --tool=cachegrind ./myapp
```

---

## Performance Tools

### Profiling with perf

```bash
# Record profile
perf record -g ./myapp

# View report
perf report

# Annotate source
perf annotate function_name
```

### Google Benchmark

```cpp
#include <benchmark/benchmark.h>

static void BM_StringCopy(benchmark::State& state) {
    std::string src(state.range(0), 'x');
    for (auto _ : state) {
        std::string dst = src;
        benchmark::DoNotOptimize(dst);
    }
}

BENCHMARK(BM_StringCopy)->Range(8, 8<<10);

BENCHMARK_MAIN();
```

### Compiler Optimization Flags

```cmake
# Release build optimizations
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -march=native -mtune=native")

# Link-time optimization
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

# Profile-guided optimization
set(CMAKE_CXX_FLAGS_PGO "-fprofile-generate")
# ... run program to generate profile data ...
set(CMAKE_CXX_FLAGS_PGO "-fprofile-use")
```

---

## Additional Resources

- **CMake Documentation**: https://cmake.org/documentation/
- **Conan Documentation**: https://docs.conan.io/
- **C++ Reference**: https://en.cppreference.com/
- **C++ Core Guidelines**: https://isocpp.github.io/CppCoreGuidelines/
- **Clang Tools**: https://clang.llvm.org/docs/ClangTools.html
