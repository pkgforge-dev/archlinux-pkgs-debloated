#!/bin/sh

set -ex

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

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/"$PACKAGE" "$tmpbuild"
cd "$tmpbuild"

case "$ARCH" in
	x86_64)
		EXT=zst
		;;
	aarch64)
		EXT=xz
		# remove libxnvctrl since it is not possible in aarch64
		sed -i \
			-e "s|-Dmangohudctl=true|-Dmangohudctl=true -Dwith_xnvctrl=disabled|" \
			-e "s|'libxnvctrl'||" ./PKGBUILD
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

# Remove python deps
sed -i \
	-e "s|'python'||g"            \
	-e "s|'python-numpy'||g"      \
	-e "s|'python-matplotlib'||g" \
	./PKGBUILD

cat ./PKGBUILD

# Do not build if version does not match with upstream
# Only do it for x86_64 because aarch64 has no mangohud package
if [ "$ARCH" = 'aarch64' ] || check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
		exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
echo "All done!"
