#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

# remove libxnvctrl since it is not possible in aarch64
if [ "$ARCH" = 'aarch64' ]; then
	sed -i \
		-e "s|'libxnvctrl'||"                                                 \
		-e "s|-Dmangohudctl=true|-Dmangohudctl=true -Dwith_xnvctrl=disabled|" \
		"$PKGBUILD"
fi

# Remove python deps
sed -i \
	-e "s|'python'||g"            \
	-e "s|'python-numpy'||g"      \
	-e "s|'python-matplotlib'||g" \
	"$PKGBUILD"

cat "$PKGBUILD"

# Arch Linux ARM does not publish mangohud, but don't rebuild an existing version.
if [ "$ARCH" = 'aarch64' ]; then
	check-upstream-version --released-only || exit 0
else
	check-upstream-version || exit 0
fi
makepkg -fs --noconfirm --skippgpcheck

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar.zst ../"$PACKAGE"-mini-"$ARCH".pkg.tar.zst

echo "All done!"
