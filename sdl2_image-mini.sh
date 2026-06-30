#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove AVIF and JPEG-XL support
# libavif pulls in the whole AV1 codec family (libaom, SvtAv1Enc, rav1e, dav1d)
# and libjxl, ~23 MiB most apps never use; PNG/JPG/TIFF/WEBP still work
sed -i \
	-e 's|--disable-avif-shared|--disable-avif|' \
	-e 's|--disable-jxl-shared|--disable-jxl|'   \
	-e "s| 'libavif'||" \
	-e "s| 'libjxl'||"  \
	"$PKGBUILD"

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
cd ..
echo "All done!"
