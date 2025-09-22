#!/bin/sh

set -ex

ARCH="$(uname -m)"
tmpbuild="$PWD"/tmpbuild
_cleanup() { rm -rf "$tmpbuild"; }
trap _cleanup INT TERM EXIT

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/intel-media-driver.git "$tmpbuild"
cd "$tmpbuild"

case "$ARCH" in
	x86_64)
		EXT=zst
		;;
	*)
		>&2 echo "Unsupported Arch: '$ARCH'"
		exit 1
		;;
esac
# build without debug info
sed -i -e 's|-g1|-g0|' ./PKGBUILD

# debloat package, remove proprietary blob that makes the lib huge
sed -i \
	-e 's|-DINSTALL_DRIVER_SYSCONF=OFF|-DINSTALL_DRIVER_SYSCONF=OFF -DBUILD_TYPE=MinSizeRel -DENABLE_NONFREE_KERNELS=OFF|' \
	./PKGBUILD

cat ./PKGBUILD

# Do not build if version does not match with upstream
CURRENT_VERSION=$(awk -F'=' '/pkgver=/{print $2; exit}' ./PKGBUILD)
UPSTREAM_VERSION=$(pacman -Ss '^intel-media-driver$' | awk '{print $2; exit}' | cut -d- -f1 | sed 's/^[0-9]\+://')
echo "----------------------------------------------------------------"
echo "PKGBUILD version: $CURRENT_VERSION"
echo "UPSTREAM version: $UPSTREAM_VERSION"
if [ "$FORCE_BUILD" != 1 ] && [ "$CURRENT_VERSION" != "$UPSTREAM_VERSION" ]; then
	>&2 echo "ABORTING BUILD BECAUSE OF VERSION MISMATCH WITH UPSTREAM!"
	>&2 echo "----------------------------------------------------------------"
	:> ~/OPERATION_ABORTED
	exit 0
fi
echo "Versions match, building package..."
echo "----------------------------------------------------------------"

makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv ./intel-*.pkg.tar."$EXT" ../intel-media-driver-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
# keep older name to not break existing CIs
cp -v ./intel-media-driver-mini-"$ARCH".pkg.tar."$EXT" ./intel-media-mini-"$ARCH".pkg.tar."$EXT"
echo "All done!"
