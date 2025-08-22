#!/bin/sh

set -ex

ARCH="$(uname -m)"

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

git clone https://gitlab.archlinux.org/archlinux/packaging/packages/gtk4.git gtk4
cd ./gtk4

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
	-e 's/-D colord=enabled/-D colord=enabled -D media-gstreamer=disabled -D vulkan=disabled -D build-testsuite=false/' \
	./PKGBUILD

cat ./PKGBUILD
makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.* ./*-demos-*.pkg.tar.*
mv ./gtk4-*.pkg.tar."$EXT" ../gtk4-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf ./gtk
echo "All done!"
