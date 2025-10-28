#!/bin/sh

set -eu

ARCH_REPO=https://gitlab.archlinux.org/archlinux/packaging/packages
ALARM_REPO=https://github.com/archlinuxarm/PKGBUILDs.git

# ArchlinuxARM has all the PKGBUILDs in a single repository instead
ALARM_DIR="${TMPDIR:-/tmp}"/ALARM-PKGBUILDS

if [ "$ARCH" = 'x86_64' ]; then
	git clone --depth 1 "$ARCH_REPO"/"$PACKAGE" "$BUILD_DIR"
elif [ "$ARCH" = 'aarch64' ]; then
	git clone --depth 1 "$ALARM_REPO" "$ALARM_DIR"
	# if ALARM does not have the package, then use the archlinux package directly
	if [ -d "$ALARM_DIR"/*/"$PACKAGE" ]; then
		mv -v "$ALARM_DIR"/*/"$PACKAGE" "$BUILD_DIR"
	else
		>&2 echo "----------------------------------------"
		>&2 echo "ArchlinuxARM does not have '$PACKAGE'"
		>&2 echo "Using Archlinux PKGBUILD instead..."
		>&2 echo "----------------------------------------"
		git clone --depth 1 "$ARCH_REPO"/"$PACKAGE" "$BUILD_DIR"
	fi
	rm -rf "$ALARM_DIR"
fi

# change arch for aarch64 support, even ArchlinuxARM PKGBUILDs need this...
sed -i -e "s|x86_64|$ARCH|" "$PKGBUILD"

# always build without debug info
sed -i -e 's|-g1|-g0|' "$PKGBUILD"
