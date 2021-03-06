#
# This is generic boilerplate
#
if (NOT __cmake_setup_INCLUDED)
set(__cmake_setup_INCLUDED 1)

# Build in 64 bits mode by default... @fixme
set(CMAKE_CXX_FLAGS "-m64 ${CMAKE_CXX_FLAGS}")

# Enable C++14 and link libc++
set(CMAKE_CXX_FLAGS "-ferror-limit=3 ${CMAKE_CXX_FLAGS} -std=c++1y -stdlib=libc++")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++")

# Enable full error and warning reporting
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror -Wno-unused-parameter")

# Nasty boost.unit_test_framework
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unneeded-internal-declaration")

# Test effect of global constructors in our code, global constructors are usually bad idea.
# Cannot be enabled because boost uses them in boost.error_code
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wglobal-constructors")

# Clang invocation debug
#set(CMAKE_CXX_FLAGS "-v ${CMAKE_CXX_FLAGS}")

# On mac, use openssl from brew, not the default system one, because it is too old.
# Run 'brew install openssl' to install it.
if (APPLE)
    set(OPENSSL_ROOT_DIR /usr/local/opt/openssl)
    # Set pkg-config path in case pkg-config is installed on the machine.
    set(ENV{PKG_CONFIG_PATH} /usr/local/opt/openssl/lib/pkgconfig)
    # A bug in cmake prevents use of OPENSSL_ROOT_DIR for finding a custom openssl,
    # so we use an internal variable instead. This needs to be fixed in cmake.
    set(_OPENSSL_ROOT_HINTS_AND_PATHS PATHS /usr/local/opt/openssl)
endif (APPLE)

find_package(OpenSSL REQUIRED)
include_directories(${OPENSSL_INCLUDE_DIR})

set(BOOST_COMPONENTS)

if (BUILD_TESTING)
    list(APPEND BOOST_COMPONENTS unit_test_framework)
    enable_testing()
    include(Dart)
endif (BUILD_TESTING)

# boost/asio depends on libboost_system
list(APPEND BOOST_COMPONENTS system)
# For logging we need boost/posix_time
list(APPEND BOOST_COMPONENTS date_time)
# Program_options used to parse cmdline args in some tests
list(APPEND BOOST_COMPONENTS program_options)
# Thread library used in some nat libs and tests
list(APPEND BOOST_COMPONENTS thread)
# Filesystem library used on Linux for creating config directories
list(APPEND BOOST_COMPONENTS filesystem)

#set(Boost_USE_MULTITHREAD ON)
set(Boost_USE_STATIC_LIBS ON) # Easier to deploy elsewhere
set(BOOST_ROOT /usr/local/opt/boost)
set(BOOST_LIBRARYDIR /usr/local/opt/boost/lib64)
find_package(Boost REQUIRED COMPONENTS ${BOOST_COMPONENTS})

include_directories(${Boost_INCLUDE_DIR})

# Create and link a test application.
function(create_test NAME)
    cmake_parse_arguments(CT "NO_CTEST" "" "LIBS" ${ARGN})
    add_executable(test_${NAME} test_${NAME}.cpp)
    target_link_libraries(test_${NAME} ${CT_LIBS} ${Boost_LIBRARIES})
    if (UNIX AND NOT APPLE)
        target_link_libraries(test_${NAME} c++)
    endif()
    install(TARGETS test_${NAME}
        RUNTIME DESTINATION tests/unittests)
    if (NOT CT_NO_CTEST)
        add_test(${NAME} test_${NAME})
    endif (NOT CT_NO_CTEST)
endfunction(create_test)

endif (NOT __cmake_setup_INCLUDED)
