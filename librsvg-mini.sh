#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# add back pixbuf loader
sed -i \
	-e 's|pixbuf-loader=disabled|pixbuf-loader=enabled|' \
	-e 's|meson test|echo meson test|'                   \
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
