#!/bin/sh

set -ex

ARCH="$(uname -m)"

case "$ARCH" in
	x86_64)
		EXT=zst
		git clone --depth 1 https://gitlab.archlinux.org/archlinux/packaging/packages/mesa.git ./mesa
		cd ./mesa
		# remove aarch64 drivers from x86_64
		sed -i \
			-e '/_pick vkfdreno/d' \
			-e '/_pick vkasahi/d'  \
			-e 's/vulkan-asahi//'  \
			-e 's/,asahi//g'       \
			-e 's/,freedreno//g'   \
			./PKGBUILD
		;;
	aarch64)
		EXT=xz
		git clone --depth 1 https://github.com/archlinuxarm/PKGBUILDs ./mesa
		cd ./mesa
		mv -v ./extra/mesa/* ./extra/mesa/.* ./
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

# debloat package, remove software rast, remove ancient drivers, build iwhtout linking to llvm
sed -i \
	-e '/llvm-libs/d'      \
	-e 's/vulkan-swrast//' \
	-e 's/opencl-mesa//'   \
	-e 's/r300,//'         \
	-e 's/r600,//'         \
	-e 's/softpipe,//'     \
	-e 's/llvmpipe,//'     \
	-e 's/swrast,//'       \
	-e '/sysprof/d'        \
	-e '/_pick vkswrast/d' \
	-e '/_pick opencl/d'   \
	-e 's/intel-rt=enabled/intel-rt=disabled/'         \
	-e 's/gallium-rusticl=true/gallium-rusticl=false/' \
	-e 's/valgrind=enabled/valgrind=disabled/'         \
	-e 's/-D video-codecs=all/-D video-codecs=all -D amd-use-llvm=false -D draw-use-llvm=false/' \
	./PKGBUILD

cat ./PKGBUILD
makepkg -fs --noconfirm --skippgpcheck

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

cd ..
rm -rf ./mesa
echo "All done!"
