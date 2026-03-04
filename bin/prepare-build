#!/bin/sh

echo "Installing basic packages..."
pacman-key --init
pacman -Syy --noconfirm archlinux-keyring
pacman -Syu --noconfirm \
	base-devel \
	ccache     \
	clang      \
	cmake      \
	curl       \
	git        \
	ninja      \
	sccache    \
	wget
echo "------------------------------------------------------------"

echo "Settings up build options..."
sed -i \
	-e 's|DEBUG_CFLAGS="-g"|DEBUG_CFLAGS="-g0"|' \
	-e 's|-fno-omit-frame-pointer|-fomit-frame-pointer|' \
	-e 's|-mno-omit-leaf-frame-pointer||' \
	-e 's|-Wp,-D_FORTIFY_SOURCE=3||' \
	-e 's|-fstack-clash-protection||' \
	-e 's|MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|' \
	-e 's|!ccache|ccache|' \
	-e 's|#MAKEFLAGS|MAKEFLAGS|' /etc/makepkg.conf
cat /etc/makepkg.conf
echo "------------------------------------------------------------"

echo "Hacking makepkg to allow building as root in the container..."
sed -i 's|EUID == 0|EUID == 69|g' /usr/bin/makepkg
mkdir -p /usr/local/bin
cp /usr/bin/makepkg /usr/local/bin
echo "------------------------------------------------------------"
