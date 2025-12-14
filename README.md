# archlinux-pkgs-debloated 

*Previously known as 'llvm-libs-debloated'*

---

This repo makes modified versiones of Archlinux packages, these are intended for AppImages to reduce final size, like:

* `mesa-mini` and `vulkan-{radeon,intel,etc}-mini` remove linking to `libLLVM.so`, making any hardware accelerated app tiny as result.

* `mesa-nano` and `vulkan-{radeon,intel,etc}-nano` similar to `mesa-mini`, built with -Os which makes it ~30% smaller. Note -Os can have a performance and even stability issue so do not use this package in apps like emulators where this is critical.

* `llvm-libs-mini` smaller version of `libLLVM.so` which is a 150+ MiB library, this version is reduced down to 99 MiB. 

* `llvm-libs-nano`, similar to `mini`, but with the llvm targets limited (`x86_64` or `aarch64`) + `AMDGPU`, this reduces the size of the library to less than 70 MiB. Note this will cause issues if application depends on more llvm targets like compilers.

* `qt6-base-mini` and `libxml2-mini`, remove 30 MiB libicudata lib dependency.

* `ffmpeg-mini` which removes 20 MiB libx265.so dependency, also removes AV1 enconding support (decoding still works).

* `opus-mini` I have no idea why Archlinux makes this lib 5 MiB when both ubuntu and alpine make it <500 KiB

* `gdk-pixbuf2-mini`, `librsvg-mini` These remove the glycin dependency, ~20 MiB of bloat. (glycin is also super buggy and depends on `bwrap` which is problematic for running appimages in very old kernels)

* `icu-mini` Much smaller version of `libicudata.so` that is less than 3 MIB in size (10x reduction in size). 

# Projects using these packages

* [Anylinux-AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages) - [ghostty](https://github.com/pkgforge-dev/ghostty-appimage), [citron](https://github.com/pkgforge-dev/Citron-appimage) and many more

* [goverlay](https://github.com/benjamimgois/goverlay)

* [Steam-appimage](https://github.com/ivan-hc/Steam-appimage)

* [interstellar](https://github.com/interstellar-app/interstellar)

* [QDiskInfo](https://github.com/edisionnano/QDiskInfo)

* [mangojuice](https://github.com/radiolamp/mangojuice)

* [CPU-X](https://github.com/TheTumultuousUnicornOfDarkness/CPU-X)

* [ppsspp](https://github.com/hrydgard/ppsspp)

* [Eden](https://github.com/eden-emulator/Releases)
