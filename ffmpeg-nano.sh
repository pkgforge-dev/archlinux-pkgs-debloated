#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# debloat package down to a small set of decoders for the most common
# audio, image and video formats: mp3, opus, vorbis, flac, aac, png,
# jpeg, h264, vp8, vp9, theora and wav (pcm). every decoder added is
# native, so no external libraries are linked, dependencies stay at
# glibc and zlib.
# --disable-autodetect turns off every external library and all hardware
# acceleration. --disable-encoders drops every encoder, and all decoders are
# disabled except the ones for the formats above.
sed -i \
	-e '/^depends=($/,/^)$/c\
depends=(\
  glibc\
  zlib\
)' \
	-e '/^makedepends=($/,/^)$/c\
makedepends=(\
  git\
  nasm\
)' \
	-e '/^optdepends=($/,/^)$/c\
# no optional dependencies' \
	-e '/^  \.\/configure \\$/,/^    --disable-decoder=magicyuv/c\
  ./configure \\\
    --prefix=/usr \\\
    --disable-debug \\\
    --disable-static \\\
    --disable-stripping \\\
    --enable-shared \\\
    --enable-small \\\
    --enable-lto \\\
    --disable-autodetect \\\
    --disable-network \\\
    --disable-programs \\\
    --disable-avdevice \\\
    --disable-avfilter \\\
    --enable-gpl \\\
    --disable-encoders \\\
    --disable-decoders \\\
    --enable-decoder=mp3,mp3float,opus,vorbis,flac,aac,aac_latm,png,mjpeg,h264,vp8,vp9,theora,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le,pcm_u8,pcm_alaw,pcm_mulaw \\\
    --enable-zlib' \
	-e '/qt-faststart/d' \
	-e '/doc\/ff{mpeg,play}/d' \
	-e 's/ install install-man/ install/' \
	-e '/libavdevice\.so/d' \
	-e '/libavfilter\.so/d' \
	-e '/^  depends+=(/,/^  )$/d' \
	"$PKGBUILD"

cat "$PKGBUILD"

# fail loudly instead of silently shipping a package without the debloat.
if ! grep -q -- '--disable-encoders' "$PKGBUILD"; then
	>&2 echo "Failed to debloat ffmpeg PKGBUILD!"
	exit 1
fi

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-nano-"$ARCH".pkg.tar."$EXT"

echo "All done!"
