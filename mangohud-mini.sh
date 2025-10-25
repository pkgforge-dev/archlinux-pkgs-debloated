#!/bin/sh

set -ex

:> ~/OPERATION_ABORTED
exit 0

ARCH="$(uname -m)"
tmpbuild="$PWD"/tmpbuild
_cleanup() { rm -rf "$tmpbuild"; }
trap _cleanup INT TERM EXIT

PACKAGE="${0##*/}"
PACKAGE="${PACKAGE%-mini.sh}"
PACKAGE="${PACKAGE%-nano.sh}"
export PACKAGE

case "$ONE_PACKAGE" in
	''|"$PACKAGE") true;;
	*) :> ~/OPERATION_ABORTED; exit 0;;
esac

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

git clone --depth 1 https://github.com/VHSgunzo/mangohud-PKGBUILD.git "$tmpbuild"
cd "$tmpbuild"
rm -rf ./lib32-mangohud
mv -v ./mangohud/PKGBUILD ./

case "$ARCH" in
	x86_64)
		EXT=zst
		;;
	aarch64)
		EXT=xz
		# remove libxnvctrl since it is not possible in aarch64
		sed -i \
			-e 's|-Dmangohudctl=true|-Dmangohudctl=true -Dwith_xnvctrl=disabled|' \
			-e '/libxnvctrl/d' ./PKGBUILD
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

cat ./PKGBUILD
makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
echo "All done!"
