#!/bin/sh

set -ex

ARCH="$(uname -m)"
tmpbuild="$PWD"/tmpbuild
_cleanup() { rm -rf "$tmpbuild"; }
trap _cleanup INT TERM EXIT

PACKAGE="${0##*/}"
PACKAGE="${PACKAGE%.sh}"
case "$ONE_PACKAGE" in
	''|"$PACKAGE") true;;
	*) :> ~/OPERATION_ABORTED; exit 0;;
esac

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/gtk4.git "$tmpbuild"
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
	-e '/broadway/d'        \
	-e '/sysprof=/d'        \
	-e '/cloudproviders=/d' \
	-e '/libcups/d'         \
	-e '/libcolord/d'       \
	-e 's/-D colord=enabled/-D colord=disabled -D print-cups=disabled -D media-gstreamer=disabled -D vulkan=disabled -D build-testsuite=false/' \
	./PKGBUILD

cat ./PKGBUILD

# Do not build if version does not match with upstream
CURRENT_VERSION=$(awk -F'=' '/pkgver=/{print $2; exit}' ./PKGBUILD)
UPSTREAM_VERSION=$(pacman -Ss '^gtk4$' | awk '{print $2; exit}' | cut -d- -f1 | sed 's/^[0-9]\+://')
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
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.* ./*-demos-*.pkg.tar.*
mv ./gtk4-*.pkg.tar."$EXT" ../gtk4-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
echo "All done!"
