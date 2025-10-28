#!/bin/sh

set -e

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove line that enables icu support
sed -i \
	-e '/--with-icu/d'               \
	-e 's/icu=enabled/icu=disabled/' \
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
cd ..
# keep older name to not break existing CIs
cp -v ./libxml2-mini-"$ARCH".pkg.tar."$EXT" ./libxml2-iculess-"$ARCH".pkg.tar."$EXT"
echo "All done!"
