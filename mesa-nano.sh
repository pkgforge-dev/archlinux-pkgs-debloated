#!/bin/sh

set -e

sed -i -e 's|-O2|-Os|' /etc/makepkg.conf

get-pkgbuild
cd "$BUILD_DIR"

common_gallium='nouveau,radeonsi,softpipe,svga,virgl,zink'
x64_gallium="crocus,iris,r600,$common_gallium"
arm_gallium="asahi,freedreno,etnaviv,lima,panfrost,rocket,v3d,vc4,$common_gallium"

common_vulkan='amd,nouveau,virtio,gfxstream'
x64_vulkan="intel,intel_hasvk,$common_vulkan"
arm_vulkan="asahi,broadcom,freedreno,panfrost,imagination,$common_vulkan"

# remove aarch64 drivers from x86_64
if [ "$ARCH" = 'x86_64' ]; then
	delete-func vulkan-freedreno vulkan-asahi vulkan-broadcom vulkan-panfrost vulkan-powervr
	sed -i \
		-e '/_pick vkfdreno/d'    \
		-e '/_pick vkasahi/d'     \
		-e '/_pick vkbrcom/d'     \
		-e '/_pick vkpfrost/d'    \
		-e '/_pick vkpowrvr/d'    \
		-e "s|gallium-drivers=.*|gallium-drivers=$x64_gallium|" \
		-e "s|vulkan-drivers=.*|vulkan-drivers=$x64_vulkan|"    \
		"$PKGBUILD"
elif [ "$ARCH" = 'aarch64' ]; then
	delete-func vulkan-intel
	sed -i \
		-e '/_pick vkintel/d' \
		-e "s|gallium-drivers=.*|gallium-drivers=$arm_gallium|" \
		-e "s|vulkan-drivers=.*|vulkan-drivers=$arm_vulkan|"    \
		"$PKGBUILD"
fi

# debloat package, remove software rast, remove ancient drivers, build without linking to llvm
delete-func vulkan-swrast vulkan-kosmickrisp opencl-mesa vulkan-dzn
sed -i \
	-e '/llvm-libs/d'           \
	-e '/sysprof/d'             \
	-e '/_pick vkswrast/d'      \
	-e '/_pick opencl/d'        \
	-e '/_pick vkkosmic/d'      \
	-e '/_pick vkd3d12/d'       \
	-e '/gallium-rusticl-enable-drivers/d' \
	-e 's/intel-rt=enabled/intel-rt=disabled/'         \
	-e 's/gallium-rusticl=true/gallium-rusticl=false/' \
	-e 's/valgrind=enabled/valgrind=disabled/'         \
	-e 's/-D video-codecs=all/-D video-codecs=all -D amd-use-llvm=false -D draw-use-llvm=false/' \
	"$PKGBUILD"

# Patch AMDGPU DRM version check for compatibility with older kernels
sed -i '/^  cd mesa-\$_pkgver$/a\
	echo "Patching amdgpu DRM version check..."\
	find . -name "ac_gpu_info.c" -print -exec sed -i "s/info->drm_minor < 54/info->drm_minor < 0/" {} \\;' "$PKGBUILD"

# Replace gen_perf.py with a stub to drop the Intel OA performance-counter
# metrics (~4.5MiB of const data for GL_INTEL_performance_query). The stub keeps
# the same generated API (no-op intel_oa_register_queries_*), so iris/crocus and
# intel_perf.c compile/link unchanged; the perf query extension just reports no
# counters at runtime. Saves ~5MiB in libgallium.
sed -i '/^  cd mesa-\$_pkgver$/a\
	echo "Patching gen_perf.py (drop Intel OA perf metrics)..."\
	cat > src/intel/perf/gen_perf.py <<PYEOF\
import os, sys\
args = sys.argv[1:]\
code = args[args.index("--code") + 1]\
header = args[args.index("--header") + 1]\
gens = [os.path.basename(x)[3:-4] for x in args if os.path.basename(x).startswith("oa-")]\
NL = chr(10)\
Q = chr(34)\
open(header, "w").write("#pragma once" + NL + "struct intel_perf_config;" + NL + "".join("void intel_oa_register_queries_" + g + "(struct intel_perf_config *perf);" + NL for g in gens))\
open(code, "w").write("#include " + Q + "perf/intel_perf_metrics.h" + Q + NL + "".join("void intel_oa_register_queries_" + g + "(struct intel_perf_config *perf) { (void)perf; }" + NL for g in gens))\
PYEOF' "$PKGBUILD"

cat "$PKGBUILD"

# fail loudly instead of silently shipping a package without the debloat.
if ! grep -q "Patching gen_perf.py" "$PKGBUILD"; then
	>&2 echo "Failed to patch gen_perf.py!"
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
mv -v ./mesa-*.pkg.tar."$EXT"           ../mesa-nano-"$ARCH".pkg.tar."$EXT"
mv -v ./vulkan-radeon-*.pkg.tar."$EXT"  ../vulkan-radeon-nano-"$ARCH".pkg.tar."$EXT"
mv -v ./vulkan-nouveau-*.pkg.tar."$EXT" ../vulkan-nouveau-nano-"$ARCH".pkg.tar."$EXT"
mv -v ./vulkan-virtio-*.pkg.tar."$EXT"  ../vulkan-virtio-nano-"$ARCH".pkg.tar."$EXT"

if [ "$ARCH" = 'x86_64' ]; then
	mv -v ./vulkan-intel-*.pkg.tar."$EXT" ../vulkan-intel-nano-"$ARCH".pkg.tar."$EXT"
elif [ "$ARCH" = 'aarch64' ]; then
	mv -v ./vulkan-broadcom-*.pkg.tar."$EXT"  ../vulkan-broadcom-nano-"$ARCH".pkg.tar."$EXT"
	mv -v ./vulkan-panfrost-*.pkg.tar."$EXT"  ../vulkan-panfrost-nano-"$ARCH".pkg.tar."$EXT"
	mv -v ./vulkan-freedreno-*.pkg.tar."$EXT" ../vulkan-freedreno-nano-"$ARCH".pkg.tar."$EXT"
	mv -v ./vulkan-asahi-*.pkg.tar."$EXT"     ../vulkan-asahi-nano-"$ARCH".pkg.tar."$EXT"
	mv -v ./vulkan-powervr-*.pkg.tar."$EXT"   ../vulkan-powervr-nano-"$ARCH".pkg.tar."$EXT"
fi

echo "All done!"

