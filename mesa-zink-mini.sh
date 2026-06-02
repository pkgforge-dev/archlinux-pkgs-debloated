#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

export PACKAGE=mesa
get-pkgbuild
cd "$BUILD_DIR"

gallium='d3d12,softpipe,virgl,zink'

# remove as much as possible and only leave gallium
delete-func vulkan-intel vulkan-radeon vulkan-nouveau vulkan-swrast \
	vulkan-virtio vulkan-gfxstream vulkan-dzn vulkan-broadcom vulkan-freedreno \
	vulkan-panfrost vulkan-powervr vulkan-asahi vulkan-kosmickrisp \
	vulkan-mesa-layers vulkan-mesa-implicit-layers opencl-mesa

sed -i \
	-e '/llvm-libs/d'                                   \
	-e '/sysprof/d'                                     \
	-e '/_pick vk/d'                                    \
	-e '/_pick opencl/d'                                \
	-e '/gallium-rusticl-enable-drivers/d'              \
	-e 's/intel-rt=enabled/intel-rt=disabled/'          \
	-e 's/gallium-rusticl=true/gallium-rusticl=false/'  \
	-e 's/valgrind=enabled/valgrind=disabled/'          \
	-e 's|vulkan-layers=.*|vulkan-layers=|'             \
	-e 's|vulkan-drivers=.*|vulkan-drivers=|'           \
	-e "s|gallium-drivers=.*|gallium-drivers=$gallium|" \
	-e 's/-D video-codecs=all/-D gallium-va=disabled -D draw-use-llvm=false/' \
	"$PKGBUILD"

# Patch AMDGPU DRM version check for compatibility with older kernels
sed -i '/^  cd mesa-\$_pkgver$/a\
	echo "Patching amdgpu DRM version check..."\
	find . -name "ac_gpu_info.c" -print -exec sed -i "s/info->drm_minor < 54/info->drm_minor < 0/" {} \\;' "$PKGBUILD"

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
