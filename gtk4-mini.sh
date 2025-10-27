#!/bin/sh

set -e

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/"$PACKAGE" "$BUILD_DIR"
cd "$BUILD_DIR"

# change arch for aarch64 support
sed -i -e "s|x86_64|$ARCH|" ./PKGBUILD
# build without debug info
sed -i -e 's|-g1|-g0|' ./PKGBUILD

# debloat package, remove vulkan renderer, remove linking to broadway and cloudproviders
sed -i \
	-e '/broadway/d'        \
	-e '/sysprof=/d'        \
	-e '/cloudproviders=/d' \
	-e '/libcups/d'         \
	-e '/libcolord/d'       \
	-e 's/-D colord=enabled/-D colord=disabled -D print-cups=disabled -D media-gstreamer=disabled -D vulkan=disabled -D build-testsuite=false/' \
	./PKGBUILD

cat ./PKGBUILD

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.* ./*-demos-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
