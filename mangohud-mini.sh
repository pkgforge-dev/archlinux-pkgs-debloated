#!/bin/sh

set -e

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/"$PACKAGE" "$BUILD_DIR"
cd "$BUILD_DIR"

case "$ARCH" in
	aarch64)
		# remove libxnvctrl since it is not possible in aarch64
		sed -i \
			-e "s|-Dmangohudctl=true|-Dmangohudctl=true -Dwith_xnvctrl=disabled|" \
			-e "s|'libxnvctrl'||" ./PKGBUILD
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

echo "All done!"
