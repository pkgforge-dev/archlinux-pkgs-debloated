#!/bin/sh

set -ex

ARCH="$(uname -m)"
PATH="$PWD/bin:$PATH"
tmpbuild="$PWD"/tmpbuild
_cleanup() { rm -rf "$tmpbuild"; }
trap _cleanup INT TERM EXIT

PACKAGE="${0##*/}"
PACKAGE="${PACKAGE%-mini.sh}"
PACKAGE="${PACKAGE%-nano.sh}"
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

# debloat package, remove line that enables icu support
sed -i \
	-e '/--with-icu/d'               \
	-e 's/icu=enabled/icu=disabled/' \
	./PKGBUILD

cat ./PKGBUILD

# Do not build if version does not match with upstream
if ! check-upstream-version; then
	exit 0
else
	makepkg -fs --noconfirm --skippgpcheck
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./libxml2-*.pkg.tar."$EXT" ../libxml2-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
# keep older name to not break existing CIs
cp -v ./libxml2-mini-"$ARCH".pkg.tar."$EXT" ./libxml2-iculess-"$ARCH".pkg.tar."$EXT"
echo "All done!"
