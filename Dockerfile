FROM ghcr.io/pkgforge-dev/archlinux:latest

# bake the toolchain every build matrix leg used to reinstall with
# `pacman -Syu` in bin/prepare-build, which cost ~5 minutes per job.
# rebuild this image whenever the package list below changes.
RUN sed -i 's|^#\?ParallelDownloads.*|ParallelDownloads = 20|' /etc/pacman.conf && \
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
