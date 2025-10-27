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
	-e 's/glycin$/libjpeg-turbo libpng libtiff librsvg/' \
	-e 's/glycin=enabled/glycin=disabled/'               \
	-e '/gif=.*/d'                                       \
	-e '/jpeg=.*/d'                                      \
	-e '/png=.*/d'                                       \
	-e '/tiff=.*/d'                                      \
	-e '/thumbnailer/d'                                  \
	-e 's/others=disabled/others=enabled/'               \
	./PKGBUILD

cat ./PKGBUILD

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
