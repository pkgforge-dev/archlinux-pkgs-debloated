#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/"$PACKAGE" "$BUILD_DIR"
cd "$BUILD_DIR"

case "$ARCH" in
	aarch64)
		sed -i -e 's/-DFEATURE_no_direct_extern_access=ON/-DQT_FEATURE_sql_ibase=OFF/' ./PKGBUILD
		;;
esac
# change arch for aarch64 support
sed -i -e "s|x86_64|$ARCH|" ./PKGBUILD
# build without debug info
sed -i -e 's|-g1|-g0|' ./PKGBUILD

# debloat package, remove the line that enables icu support
sed -i \
	-e 's/-DCMAKE_BUILD_TYPE=RelWithDebInfo/-DCMAKE_BUILD_TYPE=MinSizeRel/' \
	-e 's/-DFEATURE_journald=ON/-DFEATURE_journald=OFF/'                    \
	-e '/-DFEATURE_libproxy=ON \\/a\    -DFEATURE_icu=OFF \\'               \
	./PKGBUILD

cat ./PKGBUILD

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"
cd ..
# keep older name to not break existing CIs
cp -v ./"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT" ./"$PACKAGE"-iculess-"$ARCH".pkg.tar."$EXT"
echo "All done!"
