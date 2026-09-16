FROM ghcr.io/pkgforge-dev/archlinux:latest

# Bake the toolchain that every build matrix leg would otherwise install with
# `pacman -Syu` in bin/prepare-build. Rebuild this image whenever the package
# list below changes.
#
# ArchPOWER (ppc64/ppc64le) publishes `archpower-keyring` (in `base/any`), which
# provides and replaces `archlinux-keyring`; asking for `archlinux-keyring` on
# those arches only reinstalls it, so skip that no-op there.
#
# BuildKit caches this layer on the instruction text alone, so without a value
# that changes on every build the `pacman -Syu` below would only ever run on the
# very first build, leaving the baked package database stale. The workflow
# passes the run id as CACHE_BUST to force it to re-run.
ARG CACHE_BUST=0
RUN echo "cache bust: $CACHE_BUST" && \
	sed -i 's|^#\?ParallelDownloads.*|ParallelDownloads = 20|' /etc/pacman.conf && \
	pacman-key --init && \
	([ "$(uname -m)" = ppc64 ] || [ "$(uname -m)" = ppc64le ] || pacman -Syy --noconfirm archlinux-keyring) && \
	pacman -Syu --needed --noconfirm \
		base-devel \
		ccache \
		clang \
		cmake \
		curl \
		git \
		mold \
		ninja \
		wget && \
	pacman -Scc --noconfirm
