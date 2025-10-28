#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# debloat package, remove features that make the lib 5 MiB
sed -i \
	-e '/-D deep-plc=enabled/d' \
	-e '/-D dred=enabled/d' \
	-e '/-D osce=enabled/d' \
	"$PKGBUILD"

# skip tests since they take too long
sed -i -e 's|meson test -C build|echo "skipped" #meson test -C build|' ./PKGBUILD

cat "$PKGBUILD"

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* *-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"
cd ..
# keep older name to not break existing CIs
cp -v ./"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT" ./"$PACKAGE"-nano-"$ARCH".pkg.tar."$EXT"
echo "All done!"
