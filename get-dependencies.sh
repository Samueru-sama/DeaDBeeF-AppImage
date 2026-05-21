#!/bin/sh

set -ex

ARCH=$(uname -m)
BUILD_DIR=/tmp/deadbeef-build
SRC_DIR=$BUILD_DIR/deadbeef
INSTALL_DIR=$BUILD_DIR/install

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	alsa-lib       \
	autoconf       \
	automake       \
	clang          \
	faac           \
	faad2          \
	ffmpeg         \
	flac           \
	git            \
	gtk3           \
	intltool       \
	jansson        \
	lame           \
	libdispatch    \
	libtool        \
	libxss         \
	make           \
	mpg123         \
	musepack-tools \
	opus-tools     \
	pipewire       \
	pipewire-jack  \
	pulseaudio     \
	vorbis-tools   \
	wavpack        \
	wget           \
	yasm

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

pacman -Rsndd --noconfirm mesa # gtk3 app doesn't need mesa

echo "Building deadbeef..."
echo "---------------------------------------------------------------"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
git clone https://github.com/DeaDBeeF-Player/deadbeef.git "$SRC_DIR"

# Build ffmpeg 4.4 statically
FFMPEG_INSTALL_DIR=$BUILD_DIR/ffmpeg-static
if [ ! -d "$FFMPEG_INSTALL_DIR"/lib ]; then
	FFMPEG_BUILD_DIR="$BUILD_DIR/ffmpeg-4.4"
	wget -q https://ffmpeg.org/releases/ffmpeg-4.4.tar.xz -O "$BUILD_DIR"/ffmpeg-4.4.tar.xz
	tar xf "$BUILD_DIR"/ffmpeg-4.4.tar.xz -C "$BUILD_DIR" && (
		cd "$FFMPEG_BUILD_DIR"
		./configure \
			--prefix="$FFMPEG_INSTALL_DIR"   \
			--enable-pic                     \
			--enable-static                  \
			--disable-shared                 \
			--enable-gpl                     \
			--disable-doc                    \
			--disable-ffplay                 \
			--disable-ffprobe                \
			--disable-avdevice               \
			--disable-ffmpeg                 \
			--disable-postproc               \
			--disable-swresample             \
			--disable-avfilter               \
			--disable-swscale                \
			--disable-swscale-alpha          \
			--disable-vdpau                  \
			--disable-videotoolbox           \
			--disable-dxva2                  \
			--disable-vaapi                  \
			--disable-hwaccels               \
			--disable-encoders               \
			--disable-muxers                 \
			--disable-indevs                 \
			--disable-outdevs                \
			--disable-devices                \
			--disable-filters                \
			--disable-bsfs                   \
			--disable-bzlib                  \
			--disable-protocols              \
			--disable-libopus                \
			--disable-decoders               \
			--disable-demuxers               \
			--disable-parsers                \
			--enable-decoder=wmapro          \
			--enable-decoder=wmavoice        \
			--enable-parser=ac3              \
			--enable-demuxer=ac3             \
			--enable-decoder=ac3             \
			--enable-demuxer=eac3            \
			--enable-decoder=eac3            \
			--enable-decoder=amrnb           \
			--enable-demuxer=asf             \
			--enable-demuxer=oma             \
			--enable-demuxer=amr             \
			--enable-demuxer=tak             \
			--enable-decoder=tak             \
			--enable-decoder=dsd_lsbf        \
			--enable-decoder=dsd_lsbf_planar \
			--enable-decoder=dsd_msbf        \
			--enable-decoder=dsd_msbf_planar \
			--enable-demuxer=dsf             \
			--enable-demuxer=iff             \
			--enable-version3                \
			--disable-asm                    \
			--enable-protocol=file           \
			--enable-protocol=http
		make -j"$(nproc)"
		make install
	)
fi

# Build deadbeef
case $ARCH in
	x86_64)  STATIC_DEPS_ARCH="x86-64"  ;;
	aarch64) STATIC_DEPS_ARCH="aarch64" ;;
	*)       STATIC_DEPS_ARCH="$ARCH"   ;;
esac
STATIC_DEPS=$SRC_DIR/static-deps/lib-$STATIC_DEPS_ARCH
CONFIGURE_FLAGS=--build=$ARCH-unknown-linux-gnu

(
	cd "$SRC_DIR"
	if [ "$DEVEL_RELEASE" = true ]; then
		echo "Building nightly release..."
		DEADBEEF_VERSION=$(git rev-parse --short HEAD)
	else
		echo "Building stable release..."
		git fetch --tags
		TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|alpha' | grep -v '^v0\.' | head -1)
		git checkout "$TAG"
		DEADBEEF_VERSION="$TAG"
	fi
	git submodule update --init --recursive
	
	echo "$DEADBEEF_VERSION" > ~/version
	echo "m4_define([DEADBEEF_VERSION], [$DEADBEEF_VERSION])" > ./build_data/version.m4

	# Download static-deps for headers only
	STATICDEPS_URL="http://sourceforge.net/projects/deadbeef/files/staticdeps/ddb-static-deps-latest.tar.bz2/download"
	mkdir -p static-deps
	wget "$STATICDEPS_URL" -O "$BUILD_DIR/ddb-static-deps.tar.bz2"
	tar jxf "$BUILD_DIR/ddb-static-deps.tar.bz2" -C static-deps
	# Remove static libs from static-deps (incompatible glibc symbol versions)
	find static-deps -name "*.a" -delete

	export CFLAGS="\
		-I$FFMPEG_INSTALL_DIR/include \
		-I$STATIC_DEPS/include \
		-Wno-error=incompatible-pointer-types-discards-qualifiers \
		-Wno-error=implicit-int \
		-Wno-error=int-conversion"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="-L$STATIC_DEPS/lib"
	export PKG_CONFIG_PATH="$FFMPEG_INSTALL_DIR/lib/pkgconfig"

	./autogen.sh
	./configure CC=clang CXX=clang++ $CONFIGURE_FLAGS --disable-gtk2 --prefix=/usr
	make -j"$(nproc)"
	make install DESTDIR="$INSTALL_DIR"
)

# Move into AppDir structure
mkdir -p ./AppDir/bin/plugins
cp -v  "$INSTALL_DIR"/usr/bin/deadbeef    ./AppDir/bin
cp -vr "$INSTALL_DIR"/usr/lib/deadbeef/*  ./AppDir/bin/plugins
cp -vr "$INSTALL_DIR"/usr/share           ./AppDir/bin
# aarch64 has no libs here
cp -v  "$STATIC_DEPS"/lib/libBlocks*.so*  ./AppDir/bin || :
cp -v  "$STATIC_DEPS"/lib/libdispatch.so* ./AppDir/bin || :
cp -v  "$STATIC_DEPS"/lib/libcurl.so*     ./AppDir/bin || :
cp -v  "$STATIC_DEPS"/lib/libmbed*        ./AppDir/bin || :

# Portable mode marker (triggers /proc/self/exe plugin detection)
cp -v "$INSTALL_DIR"/usr/share/icons/hicolor/48x48/apps/deadbeef.png ./AppDir/bin

find ./AppDir/bin -type f -name '*.so*' -exec strip {} \;

chmod +x ./AppDir/bin/deadbeef
