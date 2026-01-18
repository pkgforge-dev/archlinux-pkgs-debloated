#!/bin/sh

set -e

sed -i -e 's|-O2|-Os -fno-strict-aliasing -fno-fast-math -fno-plt|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

gallium='d3d12,softpipe,virgl,zink'

# remove as much as possible and only leave gallium
sed -i \
	-e '/llvm-libs/d'                                   \
	-e '/sysprof/d'                                     \
	-e '/_pick vk/d'                                    \
	-e '/_pick opencl/d'                                \
	-e 's/opencl-mesa//'                                \
	-e 's/vulkan-intel//'                               \
	-e 's/vulkan-radeon//'                              \
	-e 's/vulkan-nouveau//'                             \
	-e 's/vulkan-swrast//'                              \
	-e 's/vulkan-virtio//'                              \
	-e 's/vulkan-gfxstream//'                           \
	-e 's/vulkan-dzn//'                                 \
	-e 's/vulkan-broadcom//'                            \
	-e 's/vulkan-freedreno//'                           \
	-e 's/vulkan-panfrost//'                            \
	-e 's/vulkan-powervr//'                             \
	-e 's/vulkan-asahi//'                               \
	-e 's/vulkan-mesa-layers//'                         \
	-e 's/vulkan-mesa-implicit-layers//'                \
	-e '/gallium-rusticl-enable-drivers/d'              \
	-e 's/intel-rt=enabled/intel-rt=disabled/'          \
	-e 's/gallium-rusticl=true/gallium-rusticl=false/'  \
	-e 's/valgrind=enabled/valgrind=disabled/'          \
	-e 's|vulkan-layers=.*|vulkan-layers=|'             \
	-e 's|vulkan-drivers=.*|vulkan-drivers=|'           \
	-e "s|gallium-drivers=.*|gallium-drivers=$gallium|" \
	-e 's/-D video-codecs=all/-D gallium-va=disabled -D draw-use-llvm=false/' \
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
mv -v ./mesa-*.pkg.tar."$EXT" ../mesa-zink-mini-"$ARCH".pkg.tar."$EXT"

echo "All done!"
