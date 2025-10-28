#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# build without debug info
sed -i -e 's|-g1|-g0|' ./PKGBUILD

# debloat package, remove proprietary blob that makes the lib huge
sed -i \
	-e 's|-DINSTALL_DRIVER_SYSCONF=OFF|-DINSTALL_DRIVER_SYSCONF=OFF -DBUILD_TYPE=MinSizeRel -DENABLE_NONFREE_KERNELS=OFF|' \
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
cp -v ./"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT" ./intel-media-mini-"$ARCH".pkg.tar."$EXT"
echo "All done!"
