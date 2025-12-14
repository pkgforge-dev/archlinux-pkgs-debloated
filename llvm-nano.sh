#!/bin/sh

set -e

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

case "$ARCH" in
	'x86_64')  TARGETS_TO_BUILD="X86"    ;;
	'aarch64') TARGETS_TO_BUILD="AArch64";;
esac

# debloat package, limit llvm targets, build with MinSizeRel
sed -i \
	-e 's|-DCMAKE_BUILD_TYPE=Release|-DCMAKE_BUILD_TYPE=MinSizeRel|' \
	-e 's|-DLLVM_BUILD_TESTS=ON|-DLLVM_BUILD_TESTS=OFF -DLLVM_ENABLE_ASSERTIONS=OFF|' \
	-e 's|-DLLVM_ENABLE_CURL=ON|-DLLVM_ENABLE_CURL=OFF -DLLVM_ENABLE_UNWIND_TABLES=OFF|' \
	-e "s|-DLLVM_BUILD_DOCS=ON|-DLLVM_TARGETS_TO_BUILD=\"$TARGETS_TO_BUILD\"|" \
	-e 's|-DLLVM_ENABLE_SPHINX=ON|-DLLVM_ENABLE_SPHINX=OFF|' \
	-e 's|rm -r|#rm -r|' \
	"$PKGBUILD"

# disable tests (they take too long)
sed -i -e 's|LD_LIBRARY_PATH|#LD_LIBRARY_PATH|' "$PKGBUILD"

cat "$PKGBUILD"

# Do not build if version does not match with upstream
if check-upstream-version; then
	makepkg -fs --noconfirm --skippgpcheck
else
	exit 0
fi

ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-libs-*.pkg.tar."$EXT" ../"$PACKAGE"-libs-nano-"$ARCH".pkg.tar."$EXT"

echo "All done!"
