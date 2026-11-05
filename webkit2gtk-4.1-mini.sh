#!/bin/sh

set -e

sed -i -e 's|-fexceptions|-fno-exceptions -fno-asynchronous-unwind-tables|' /etc/makepkg.conf

# this build is huge, cap the parallel jobs to keep peak memory down on the
# 4-core/16 GB GitHub runners (a cold build was killing the runner). The
# PKGBUILD builds with `cmake --build` + Ninja, so the job count comes from
# CMAKE_BUILD_PARALLEL_LEVEL; MAKEFLAGS is set too for any make-based steps.
export CMAKE_BUILD_PARALLEL_LEVEL=3
sed -i -e 's|^MAKEFLAGS=.*|MAKEFLAGS="-j3"|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove features unlikely to be used by most applications
sed -i '/-D USE_SOUP2=OFF/a\
	-D ENABLE_FTL_JIT=OFF\
	-D ENABLE_JAVASCRIPT_SHELL=OFF\
	-D ENABLE_SAMPLING_PROFILER=OFF\
	-D USE_SKIA=OFF\
	-D ENABLE_WEBDRIVER=OFF\
	-D USE_SYSPROF_CAPTURE=OFF\
	-D ENABLE_JOURNALD_LOG=OFF' "$PKGBUILD"

# rm -r fails when target dir doesn't exist
sed -i 's|rm -r|rm -rf|' "$PKGBUILD"

# make WEBKIT_EXEC_PATH env var always available (useful for appimage)
intercept-prepare <<'EOF'
	sed -i "s|#if ENABLE(DEVELOPER_MODE)|#if 1|" Source/WebKit/Shared/glib/ProcessExecutablePathGLib.cpp
	sed -i "s|#if ENABLE(DEVELOPER_MODE)|#if 1|" Source/WebKit/UIProcess/Launcher/glib/BubblewrapLauncher.cpp
	# ScriptExecutable.cpp uses CompilationResult under ENABLE(JIT) but only gets
	# its definition from a neighbour in the same unified source, and disabling
	# features here reshuffles those groups
	sed -i 's|#include "CodeBlock.h"|&\n#include "CompilationResult.h"|' Source/JavaScriptCore/runtime/ScriptExecutable.cpp

	# 2.54 includes the Skia backend unconditionally although USE_SKIA/USE_CAIRO
	# still exist and the cairo backend is still shipped
	sed -i 's|^SET_AND_EXPOSE_TO_BUILD(USE_CAIRO OFF)$|if (USE_SKIA)\n    SET_AND_EXPOSE_TO_BUILD(USE_CAIRO FALSE)\nelse ()\n    SET_AND_EXPOSE_TO_BUILD(USE_CAIRO TRUE)\nendif ()|' Source/cmake/OptionsGTK.cmake
	sed -i 's|^include(Platform/Skia.cmake)$|if (USE_SKIA)\n    include(Platform/Skia.cmake)\nendif ()|' Source/WebKit/PlatformGTK.cmake
	sed -i 's|^include(platform/Skia.cmake)$|if (USE_SKIA)\n    include(platform/Skia.cmake)\nelse ()\n    include(platform/Cairo.cmake)\nendif ()|' Source/WebCore/PlatformGTK.cmake

	# B3 is only enabled when FTL is on, but wasm uses its types behind ENABLE(JIT)
	sed -i 's|^#if !PLATFORM(PLAYSTATION) && ENABLE(JIT)$|#if !PLATFORM(PLAYSTATION) \&\& ENABLE(JIT) \&\& ENABLE(B3_JIT)|' \
		Source/JavaScriptCore/wasm/WasmAddressType.h Source/JavaScriptCore/wasm/WasmAddressType.cpp
EOF

cat "$PKGBUILD"

if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar.zst ../"$PACKAGE"-mini-"$ARCH".pkg.tar.zst

echo "All done!"
