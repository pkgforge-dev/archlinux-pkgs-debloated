#!/bin/sh

#!/bin/sh

set -ex

ARCH="$(uname -m)"
tmpbuild="$PWD"/tmpbuild
_cleanup() { rm -rf "$tmpbuild"; }
trap _cleanup INT TERM EXIT

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/gdk-pixbuf2.git "$tmpbuild"
cd "$tmpbuild"

case "$ARCH" in
	x86_64)
		EXT=zst
		;;
	aarch64)
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

# debloat package, remove vulkan renderer, remove linking to broadway and cloudproviders
sed -i \
	-e 's/glycin$/libjpeg-turbo libpng libtiff librsvg/' \
	-e 's/glycin=enabled/glycin=disabled/'               \
	-e 's/jpeg=disabled/jpeg=enabled/'                   \
	-e 's/others=disabled/others=enabled/'               \
	-e 's/tiff=disabled/tiff=enabled/'                   \
	./PKGBUILD

cat ./PKGBUILD


# Do not build if version does not match with upstream
pkgver=$(awk -F'=' '/pkgver=/{print $2; exit}' ./PKGBUILD)
pkgrel=$(awk -F'=' '/pkgrel=/{print $2; exit}' ./PKGBUILD)
CURRENT_VERSION="$pkgver"-"$pkgrel"
UPSTREAM_VERSION=$(pacman -Ss '^gdk-pixbuf2$' | awk '{print $2; exit}' | sed 's/^[0-9]\+://')
echo "----------------------------------------------------------------"
echo "PKGBUILD version: $CURRENT_VERSION"
echo "UPSTREAM version: $UPSTREAM_VERSION"
if [ "$FORCE_BUILD" != 1 ] && [ "$CURRENT_VERSION" != "$UPSTREAM_VERSION" ]; then
	>&2 echo "ABORTING BUILD BECAUSE OF VERSION MISMATCH WITH UPSTREAM!"
	>&2 echo "----------------------------------------------------------------"
	#:> ~/OPERATION_ABORTED
	#exit 0
fi
echo "Versions match, building package..."
echo "----------------------------------------------------------------"

makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.* ./*-demos-*.pkg.tar.*
mv ./gdk-pixbuf2-*.pkg.tar."$EXT" ../gdk-pixbuf2-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
echo "All done!"
