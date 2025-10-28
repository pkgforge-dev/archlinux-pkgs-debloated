#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove vulkan renderer, remove linking to broadway and cloudproviders
sed -i \
	-e '/broadway/d'        \
	-e '/sysprof=/d'        \
	-e '/cloudproviders=/d' \
	-e '/libcups/d'         \
	-e '/libcolord/d'       \
	-e 's/-D colord=enabled/-D colord=disabled -D print-cups=disabled -D media-gstreamer=disabled -D vulkan=disabled -D build-testsuite=false/' \
	"$PKGBUILD"

cat "$PKGBUILD"

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
