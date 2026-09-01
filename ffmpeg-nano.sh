#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# debloat package down to just decoders for mp3, opus, vorbis, png and jpeg.
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
    --disable-autodetect \\\
    --disable-network \\\
    --disable-programs \\\
    --disable-avdevice \\\
    --disable-avfilter \\\
    --enable-gpl \\\
    --disable-encoders \\\
    --disable-decoders \\\
    --enable-decoder=mp3,mp3float,opus,vorbis,png,mjpeg \\\
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
