#!/bin/sh

set -ex

ARCH="$(uname -m)"
tmpbuild="$PWD"/tmpbuild
_cleanup() { rm -rf "$tmpbuild"; }
trap _cleanup INT TERM EXIT

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

case "$ARCH" in
	x86_64)
		EXT=zst
		git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/ffmpeg.git "$tmpbuild"
		cd "$tmpbuild"
		;;
	aarch64)
		EXT=xz
		git clone --depth 1 https://github.com/archlinuxarm/PKGBUILDs.git "$tmpbuild"
		cd "$tmpbuild"
		mv ./extra/ffmpeg/* ./
		;;
	*)
		>&2 echo "Unsupported Arch: '$ARCH'"
		exit 1
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
makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -f ./ffmpeg-docs-*.pkg.tar.* ./ffmpeg-debug-*.pkg.tar.*
mv ./ffmpeg-*.pkg.tar."$EXT" ../ffmpeg-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
echo "All done!"
