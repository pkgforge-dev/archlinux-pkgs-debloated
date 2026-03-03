#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove linking to massive libKF6BreezeIcons.so library
sed -i \
	-e 's|-DBUILD_TESTING=OFF|-DBUILD_TESTING=OFF -DUSE_BreezeIcons=OFF|g' \
	"$PKGBUILD"

cat "$PKGBUILD"

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* *-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
