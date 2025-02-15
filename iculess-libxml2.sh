#!/bin/sh

set -ex

ARCH="$(uname -m)"

git clone https://gitlab.archlinux.org/archlinux/packaging/packages/libxml2.git libxml2
cd ./libxml2

# remove the line that enables icu support
case "${ARCH}" in
	"x86_64")
		EXT="zst"
		sed -i '/--with-icu/d' ./PKGBUILD
		;;
	"aarch64")
		EXT="xz"
		sed -i "s/x86_64/${ARCH}/" ./PKGBUILD
		;;
	*)
		echo "Unsupported Arch: '${ARCH}'"
		exit 1
		;;
esac
cat ./PKGBUILD

makepkg -f --skippgpcheck
ls -la
rm -f ./libxml2-docs-*.pkg.tar.* ./libxml2-debug-*-x86_64.pkg.tar.* 
mv ./libxml2-*.pkg.tar.${EXT} ../libxml2-iculess-${ARCH}.pkg.tar.${EXT}
cd ..
rm -rf ./libxml2
echo "All done!"
