
cmake_minimum_required(VERSION 3.14.0)

# must set CMP0025 before calling project
cmake_policy(SET CMP0025 NEW)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Do not enable compiler specific extensions, for eg on GCC use -std=c++1z (=c++17) and not -std=gnu++17
set(CMAKE_CXX_EXTENSIONS OFF)

project(isomodel_project)

# Note: CMAKE_CXX_STANDARD set to 17 should already take care of adding -std=c++17 or equivalent
if(APPLE)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
elseif(MSVC)
  # warning level 3
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W3")

  # ignore needs to have dll-interface to be used by clients of class
  # we will not rely on exporting templates instead all libraries must
  # be linked against the same runtime
  add_compile_options(/wd4251)

  # ignore deprecation warnings
  add_compile_options(/wd4996)

endif()

option(BUILD_RUBY_BINDINGS "Build Ruby bindings" ON)
option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)

if(MSVC)
  option(BUILD_CSHARP_BINDINGS "Build C# bindings" ON)
else()
  option(BUILD_CSHARP_BINDINGS "Build C# bindings" OFF)
endif()

set(CPACK_BINARY_DEB OFF)
set(CPACK_BINARY_FREEBSD OFF)
set(CPACK_BINARY_IFW OFF)
set(CPACK_BINARY_NSIS OFF)
set(CPACK_BINARY_RPM OFF)
set(CPACK_BINARY_STGZ OFF)
set(CPACK_BINARY_TBZ2 OFF)
set(CPACK_BINARY_TGZ OFF)
set(CPACK_BINARY_TXZ OFF)
set(CPACK_BINARY_TZ OFF)
set(CPACK_BINARY_ZIP ON)
set(CPACK_SOURCE_RPM OFF)
set(CPACK_SOURCE_TBZ2 OFF)
set(CPACK_SOURCE_TGZ OFF)
set(CPACK_SOURCE_TXZ OFF)
set(CPACK_SOURCE_TZ OFF)
set(CPACK_SOURCE_ZIP OFF)
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Products")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Products")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Products")
set(CMAKE_POSITION_INDEPENDENT_CODE True)

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()

include("${PROJECT_SOURCE_DIR}/ConanInstall.cmake")
include("${PROJECT_SOURCE_DIR}/ProjectMacros.cmake")

enable_testing()
include(CTest)
#find_package(GTest REQUIRED)
include(GoogleTest)

include(CPack)

# So instead, we use a generator expression to find the right value. At least it makes sense, and should be robust.
FindValue(CONAN_SWIG_ROOT)

set(SWIG_EXECUTABLE "${CURRENT_CONAN_SWIG_ROOT}/bin/swig")

# The conan-provided binary has a built-in swiglib (`swig -swiglib`) that points to the build box on which it was built, which is problematic for us.
set(SWIG_LIB "${CURRENT_CONAN_SWIG_ROOT}/bin/swiglib")

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(CMAKE_SKIP_RPATH true)
endif()

set(standalone_src
  standalone_main.cpp
)

set(isomodel_lib_src
  Building.cpp
  Building.hpp
  Cooling.cpp
  Cooling.hpp
  EndUses.hpp
  EpwData.cpp
  EpwData.hpp
  Heating.cpp
  Heating.hpp
  HourlyModel.cpp
  HourlyModel.hpp
  ISOModelAPI.hpp
  ISOResults.cpp
  ISOResults.hpp
  Lighting.cpp
  Lighting.hpp
  Location.cpp
  Location.hpp
  Matrix.hpp
  MonthlyModel.cpp
  MonthlyModel.hpp
  PhysicalQuantities.cpp
  PhysicalQuantities.hpp
  Population.cpp
  Population.hpp
  Properties.cpp
  Properties.hpp
  Simulation.cpp
  Simulation.hpp
  SimulationSettings.cpp
  SimulationSettings.hpp
  SolarRadiation.cpp
  SolarRadiation.hpp
  Structure.cpp
  Structure.hpp
  TimeFrame.cpp
  TimeFrame.hpp
  UserModel.cpp
  UserModel.hpp
  Vector.hpp
  Ventilation.cpp
  Ventilation.hpp
  WeatherData.cpp
  WeatherData.hpp
)

add_library(isomodel_lib STATIC ${isomodel_lib_src})
target_include_directories(isomodel_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(isomodel_lib CONAN_PKG::boost)
target_compile_options(isomodel_lib PUBLIC "-DISOMODEL_STANDALONE")

if (MSVC)
  target_compile_options(isomodel_lib PRIVATE "-Dopenstudio_isomodel_EXPORTS")
endif()

set (exec_name isomodel_standalone)
add_executable(isomodel_standalone ${standalone_src})
target_link_libraries(isomodel_standalone isomodel_lib)

install(TARGETS isomodel_standalone
  DESTINATION bin
)

install(DIRECTORY ${PROJECT_SOURCE_DIR}/../test_data
  DESTINATION data
)

if (BUILD_RUBY_BINDINGS)
  include("${PROJECT_SOURCE_DIR}/FetchRubyMinGW.cmake")
  FetchRubyMinGW()
  get_target_property(RUBY_INCLUDE_DIRS CONAN_PKG::openstudio_ruby INTERFACE_INCLUDE_DIRECTORIES)
  message("RUBY_INCLUDE_DIRS = ${RUBY_INCLUDE_DIRS}")
  message("RUBY_MINGW_STUB_LIB = ${RUBY_MINGW_STUB_LIB}")
endif()

if (BUILD_PYTHON_BINDINGS)
  find_package(Python3 3.7 EXACT COMPONENTS Interpreter Development REQUIRED)
  message("Python3_INCLUDE_DIRS = ${Python3_INCLUDE_DIRS}")
  include_directories(SYSTEM ${Python3_INCLUDE_DIRS})
  message("Python3_LIBRARY_DIRS = ${Python3_LIBRARY_DIRS}")
  link_directories(${Python3_LIBRARY_DIRS})
  message("Python3_EXECUTABLE = ${Python3_EXECUTABLE}")
endif()

if (BUILD_CSHARP_BINDINGS)
  # Explicitly set the `PlatformTarget` for C# projects, since AnyCPU can result in
  # System.BadImageFormatException throws, when trying to load C++/CLI assemblies.
  IF(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
    SET(CMAKE_CSharp_FLAGS "/platform:x64")
  ELSEIF(CMAKE_GENERATOR_PLATFORM STREQUAL "x86")
      SET(CMAKE_CSharp_FLAGS "/platform:x86")
  ELSEIF(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
      SET(CMAKE_CSharp_FLAGS "/platform:x86")
  ELSE()
    MESSAGE(WARNING "Generator platform is set to '${CMAKE_GENERATOR_PLATFORM}', which is not supported by managed projects. Defaulting to 'x64'...")
    SET(CMAKE_CSharp_FLAGS "/platform:x64")
  ENDIF()
endif()

MAKE_SWIG_TARGET(isomodel isomodel "${PROJECT_SOURCE_DIR}/ISOModel.i" "${PROJECT_SOURCE_DIR}/ISOModel.i" isomodel_lib "")

add_subdirectory(Test)

if (BUILD_PYTHON_BINDINGS)
  add_subdirectory(Python)
endif()

if (BUILD_RUBY_BINDINGS)
  add_subdirectory(Ruby)
endif()

if (BUILD_CSHARP_BINDINGS)
  add_subdirectory(CSharp)
endif()
