#!/bin/sh

set -e

get-pkgbuild
cd "$BUILD_DIR"

# remove aarch64 drivers from x86_64
if [ "$ARCH" = 'x86_64' ]; then
		sed -i \
			-e '/_pick vkfdreno/d'    \
			-e '/_pick vkasahi/d'     \
			-e 's/vulkan-freedreno//' \
			-e 's/vulkan-asahi//'     \
			-e 's/,asahi//g'          \
			-e 's/,freedreno//g'      \
			"$PKGBUILD"
fi

# debloat package, remove software rast, remove ancient drivers, build iwhtout linking to llvm
sed -i \
	-e '/llvm-libs/d'      \
	-e 's/vulkan-swrast//' \
	-e 's/opencl-mesa//'   \
	-e 's/i915,//'         \
	-e 's/r300,//'         \
	-e 's/r600,//'         \
	-e 's/llvmpipe,//'     \
	-e 's/swrast,//'       \
	-e '/sysprof/d'        \
	-e '/_pick vkswrast/d' \
	-e '/_pick opencl/d'   \
	-e 's/intel-rt=enabled/intel-rt=disabled/'         \
	-e 's/gallium-rusticl=true/gallium-rusticl=false/' \
	-e 's/valgrind=enabled/valgrind=disabled/'         \
	-e 's/-D video-codecs=all/-D video-codecs=all -D amd-use-llvm=false -D draw-use-llvm=false/' \
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
mv -v ./mesa-*.pkg.tar."$EXT"           ../mesa-mini-"$ARCH".pkg.tar."$EXT"
mv -v ./vulkan-radeon-*.pkg.tar."$EXT"  ../vulkan-radeon-mini-"$ARCH".pkg.tar."$EXT"
mv -v ./vulkan-nouveau-*.pkg.tar."$EXT" ../vulkan-nouveau-mini-"$ARCH".pkg.tar."$EXT"

if [ "$ARCH" = 'x86_64' ]; then
	mv -v ./vulkan-intel-*.pkg.tar."$EXT" ../vulkan-intel-mini-"$ARCH".pkg.tar."$EXT"
elif [ "$ARCH" = 'aarch64' ]; then
	mv -v ./vulkan-broadcom-*.pkg.tar."$EXT"  ../vulkan-broadcom-mini-"$ARCH".pkg.tar."$EXT"
	mv -v ./vulkan-panfrost-*.pkg.tar."$EXT"  ../vulkan-panfrost-mini-"$ARCH".pkg.tar."$EXT"
	mv -v ./vulkan-freedreno-*.pkg.tar."$EXT" ../vulkan-freedreno-mini-"$ARCH".pkg.tar."$EXT"
	mv -v ./vulkan-asahi-*.pkg.tar."$EXT"     ../vulkan-asahi-mini-"$ARCH".pkg.tar."$EXT"
fi

echo "All done!"
