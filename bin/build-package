#!/bin/sh

set -ex

export ARCH="$(uname -m)"
export CC=gcc
export CXX=g++

SCRIPT="$1"
PACKAGE="${SCRIPT##*/}"
PACKAGE="${PACKAGE%-mini.sh}"
PACKAGE="${PACKAGE%-nano.sh}"
export PACKAGE
export BUILD_DIR="$PWD"/tmpbuild
export PKGBUILD="$BUILD_DIR"/PKGBUILD

_cleanup() { rm -rf "$BUILD_DIR"; }
trap _cleanup INT TERM EXIT

case "$ARCH" in
	'x86_64')  export EXT=zst;;
	'aarch64') export EXT=xz ;;
	*)
		>&2 echo "Unsupported Arch: '$ARCH'"
		exit 1
		;;
esac

if [ "$PACKAGE" != 'qt6-base' ]; then
	export CMAKE_C_COMPILER_LAUNCHER=ccache
	export CMAKE_CXX_COMPILER_LAUNCHER=ccache
else
	export CMAKE_C_COMPILER_LAUNCHER=sccache
	export CMAKE_CXX_COMPILER_LAUNCHER=sccache
fi

export PATH="$PWD:$PWD/bin:$PATH:/usr/bin/core_perl"
chmod +x "$PWD"/bin/* "$PWD"/*.sh

if [ "$FORCE_BUILD" = "1" ]; then
	echo "Forcing build!"
	echo "Packages will be built and released regardless of version mismatch"
fi

if [ -n "$ONE_PACKAGE" ] && [ "$ONE_PACKAGE" != "$PACKAGE" ]; then
	>&2 echo "ONE_PACKAGE is set to '$ONE_PACKAGE'"
	>&2 echo "Does not match '$PACKAGE', aborting..."
	:> ~/OPERATION_ABORTED
	exit 0
fi

COUNT=0
while :; do
	if "$SCRIPT"; then
		if [ -f ~/OPERATION_ABORTED ]; then
			exit 0
		fi
		echo "----------------------------------------"
		echo "Package built successfully!"
		echo "----------------------------------------"
		break
	else
		rm -rf "$BUILD_DIR"
		>&2 echo "----------------------------------------"
		>&2 echo "Failed to build package, trying again..."
		>&2 echo "----------------------------------------"
		COUNT=$(( COUNT + 1))
	fi
	if [ "$COUNT" -ge 3 ]; then
		>&2 echo "----------------------------------------"
		>&2 echo "Failed to build package 3 times"
		>&2 echo "----------------------------------------"
		exit 1
	fi
done

if [ "$PACKAGE" != 'qt6-base' ]; then
	ccache -s -v
else
	sccache --show-stats
fi

mkdir ./dist
sha256sum ./*.pkg.tar.*
mv ./*.pkg.tar.* ./dist
