#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove 10 and 12bit modes which make the library super huge
sed -i \
  -e "/build-10/d"                             \
  -e "/build-12/d"                             \
  -e "/-D EXTRA_LIB=/d"                        \
  -e "/-D EXTRA_LINK_FLAGS=/d"                 \
  -e "s|LINKED_10BIT=.*|LINKED_10BIT=OFF|"     \
  -e "s|LINKED_12BIT=.*|LINKED_12BIT=OFF|"     \
  -e "s|HIGH_BIT_DEPTH=.*|HIGH_BIT_DEPTH=OFF|" \
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
