#!/bin/sh

set -e

sed -i -e 's|-O2|-Os -fno-strict-aliasing -fno-fast-math -fno-plt|' /etc/makepkg.conf

export AUR_PACKAGE=gtk2-ng-git

get-pkgbuild
cd "$BUILD_DIR"

cat "$PKGBUILD"

makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.* ./*-demos-*.pkg.tar.*
mv -v ./"$AUR_PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
