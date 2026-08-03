#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

export PKGBUILD_REPO=https://github.com/QaidVoid/glycin-ng.git

get-pkgbuild
cd "$BUILD_DIR"

cat "$PKGBUILD"

makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.* ./*-demos-*.pkg.tar.*
mv -v ./glycin-ng-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
