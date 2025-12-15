#!/bin/sh

set -e

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove x265 support and AV1 encoding support
# remove a lot of image formats support and other stuff like opencore
# a lot of these changes make ffmpeg more similar to what void and alpine do
# so they should not cause issues to most applications
sed -i \
	-e '/x265/d'                                \
	-e '/aom/d'                                 \
	-e '/amf/d'                                 \
	-e '/opencl/d'                              \
	-e '/placebo/d'                             \
	-e '/librav1e/d'                            \
	-e '/frei0r/d'                              \
	-e '/gsm/d'                                 \
	-e '/opencore/d'                            \
	-e '/libjxl/d'                              \
	-e '/librsvg/d'                             \
	-e '/libopenjpeg/d'                         \
	-e '/--enable-libsvtav1/d'                  \
	-e 's/--enable-vapoursynth/--enable-small/' \
	-e 's/--enable-libglslang/--disable-vdpau/' \
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

echo "All done!"
