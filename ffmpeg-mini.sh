#!/bin/sh

set -e

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

case "$ARCH" in
	x86_64)
		git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/ffmpeg.git "$BUILD_DIR"
		cd "$BUILD_DIR"
		;;
	aarch64)
		git clone --depth 1 https://github.com/archlinuxarm/PKGBUILDs.git "$BUILD_DIR"
		cd "$BUILD_DIR"
		mv ./extra/ffmpeg/* ./extra/ffmpeg/.* ./
		;;
esac
# change arch for aarch64 support
sed -i -e "s|x86_64|$ARCH|" ./PKGBUILD
# build without debug info
sed -i -e 's|-g1|-g0|' ./PKGBUILD

# debloat package, remove x265 support and AV1 encoding support
sed -i \
	-e '/x265/d'                              \
	-e '/librav1e/d'                          \
	-e 's/--enable-libsvtav1/--enable-small/' \
	-e '/--enable-vapoursynth/d'              \
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
