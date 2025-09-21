#!/bin/sh

set -ex

ARCH="$(uname -m)"
tmpbuild="$PWD"/tmpbuild
_cleanup() { rm -rf "$tmpbuild"; }
trap _cleanup INT TERM EXIT

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/opus.git "$tmpbuild"
cd "$tmpbuild"

case "$ARCH" in
	x86_64)
		EXT=zst
		;;
	aarch64)
		echo "Skipping test for aarch64 due to timeout"
		sed -i -e 's|meson test -C build|echo "skipped" #meson test -C build|' ./PKGBUILD
		EXT=xz
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

# debloat package, remove features that make the lib 5 MiB
sed -i \
	-e '/-D deep-plc=enabled/d' \
	-e '/-D dred=enabled/d' \
	-e '/-D osce=enabled/d' \
	./PKGBUILD

cat ./PKGBUILD

# Do not build if version does not match with upstream
CURRENT_VERSION=$(awk -F'=' '/pkgver=/{print $2}' ./PKGBUILD)
UPSTREAM_VERSION=$(pacman -Ss '^opus$' | awk '{print $2; exit}' | cut -d- -f1)
echo "----------------------------------------------------------------"
echo "PKGBUILD version: $CURRENT_VERSION"
echo "UPSTREAM version: $UPSTREAM_VERSION"
if [ "$CURRENT_VERSION" != "$UPSTREAM_VERSION" ]; then
	>&2 echo "ABORTING BUILD BECAUSE OF VERSION MISMATCH WITH UPSTREAM!"
	>&2 echo "----------------------------------------------------------------"
	:> ~/OPERATION_ABORTED
	exit 0
fi
echo "Versions match, building package..."
echo "----------------------------------------------------------------"

makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv *-docs-*.pkg.tar.* *-debug-*.pkg.tar.*
mv ./opus-*.pkg.tar."$EXT" ../opus-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
# keep older name to not break existing CIs
cp -v ./opus-mini-"$ARCH".pkg.tar."$EXT" ./opus-nano-"$ARCH".pkg.tar."$EXT"
echo "All done!"
