#!/bin/sh

set -e

sed -i -e 's|-O2|-Os -fno-exceptions -fno-asynchronous-unwind-tables|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove features unlikely to be used by most applications
sed -i '/-D USE_SOUP2=OFF/a\
	-D ENABLE_FTL_JIT=OFF\
	-D ENABLE_JAVASCRIPT_SHELL=OFF\
	-D ENABLE_SAMPLING_PROFILER=OFF\
	-D ENABLE_PDFJS=OFF\
	-D USE_SKIA=OFF\
	-D ENABLE_WEBDRIVER=OFF\
	-D USE_SYSPROF_CAPTURE=OFF\
	-D ENABLE_JOURNALD_LOG=OFF' "$PKGBUILD"

# rm -r fails when target dir doesn't exist
sed -i 's|rm -r|rm -rf|' "$PKGBUILD"

# make WEBKIT_EXEC_PATH env var always available (useful for appimage)
sed -i '/^	cd webkitgtk-\$pkgver$/a\
	sed -i "s|#if ENABLE(DEVELOPER_MODE)|#if 1|" Source/WebKit/Shared/glib/ProcessExecutablePathGLib.cpp\
	sed -i "s|#if ENABLE(DEVELOPER_MODE)|#if 1|" Source/WebKit/UIProcess/Launcher/glib/BubblewrapLauncher.cpp' "$PKGBUILD"

# aarch64 runner hangs after a while (OOM?)
sed -i -e 's|cmake --build build|cmake --build build -j2|' "$PKGBUILD"

cat "$PKGBUILD"

if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
