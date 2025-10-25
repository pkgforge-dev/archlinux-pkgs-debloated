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
export PACKAGE

case "$ONE_PACKAGE" in
	''|"$PACKAGE") true;;
	*) :> ~/OPERATION_ABORTED; exit 0;;
esac

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/"$PACKAGE" "$tmpbuild"
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
if ! check-upstream-version; then
	exit 0
else
	makepkg -fs --noconfirm --skippgpcheck
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* *-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf "$tmpbuild"
# keep older name to not break existing CIs
cp -v ./"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT" ./"$PACKAGE"-nano-"$ARCH".pkg.tar."$EXT"
echo "All done!"
