#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf
pacman -S --noconfirm wget unzip

get-pkgbuild

cp -v ./aux/filter.json "$BUILD_DIR"
cd "$BUILD_DIR"

# use filter
sed -i \
	-e 's|cd icu/source|export ICU_DATA_FILTER_FILE="$(readlink -f ../filter.json)"; cat "$ICU_DATA_FILTER_FILE"; cd icu/source|g' \
	"$PKGBUILD"

# download the data dir because meme library has to make this a nightmare
data='https://github.com/unicode-org/icu/releases/download/release-${pkgver}/icu4c-${pkgver}-data.zip'
sed -i \
	-e "s|prepare() {|prepare() { wget $data; unzip ./*-data.zip; rm -rf ./icu/source/data; cp -rv ./data ./icu/source|" \
	"$PKGBUILD"

# disable tests sicne they need full data
sed -i -e 's|make check|#make check|g' "$PKGBUILD"

cat "$PKGBUILD"

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
