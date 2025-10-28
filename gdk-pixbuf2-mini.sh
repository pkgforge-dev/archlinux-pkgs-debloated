#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove vulkan renderer, remove linking to broadway and cloudproviders
sed -i \
	-e 's/glycin$/libjpeg-turbo libpng libtiff librsvg/' \
	-e 's/glycin=enabled/glycin=disabled/'               \
	-e '/gif=.*/d'                                       \
	-e '/jpeg=.*/d'                                      \
	-e '/png=.*/d'                                       \
	-e '/tiff=.*/d'                                      \
	-e '/thumbnailer/d'                                  \
	-e 's/others=disabled/others=enabled/'               \
	"$PKGBUILD"

cat "$PKGBUILD"

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
