#!/bin/sh

set -ex

ARCH="$(uname -m)"

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf

git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/llvm llvm
cd ./llvm

case "$ARCH" in
	x86_64)
		EXT=zst
		TARGETS_TO_BUILD="X86;AMDGPU"
		;;
	aarch64)
		EXT=xz
		TARGETS_TO_BUILD="AArch64;AMDGPU"
		;;
	*)
		>&2 echo "Unsupported Arch: '$ARCH'"
		exit 1
		;;
esac
# change arch for aarch64 support
sed -i -e "s|x86_64|$ARCH|" ./PKGBUILD
# build without debug info
sed -i -e 's|-g1|-g0|' ./PKGBUILD

# debloat package, limit llvm targets, build with MinSizeRel
sed -i \
	-e 's|-DCMAKE_BUILD_TYPE=Release|-DCMAKE_BUILD_TYPE=MinSizeRel|' \
	-e 's|-DLLVM_BUILD_TESTS=ON|-DLLVM_BUILD_TESTS=OFF -DLLVM_ENABLE_ASSERTIONS=OFF|' \
	-e 's|-DLLVM_ENABLE_CURL=ON|-DLLVM_ENABLE_CURL=OFF -DLLVM_ENABLE_UNWIND_TABLES=OFF|' \
	-e "s|-DLLVM_BUILD_DOCS=ON|-DLLVM_TARGETS_TO_BUILD=\"$TARGETS_TO_BUILD\"|" \
	-e 's|-DLLVM_ENABLE_SPHINX=ON|-DLLVM_ENABLE_SPHINX=OFF|' \
	-e 's|rm -r|#rm -r|' \
	./PKGBUILD

# disable tests (they take too long)
sed -i -e 's|LD_LIBRARY_PATH|#LD_LIBRARY_PATH|' ./PKGBUILD

cat ./PKGBUILD
makepkg -fs --noconfirm --skippgpcheck

ls -la
mv ./llvm-libs-*.pkg.tar."$EXT" ../llvm-libs-nano-"$ARCH".pkg.tar."$EXT"
cd ..
rm -rf ./llvm
echo "All done!"
