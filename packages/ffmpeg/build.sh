TERMUX_PKG_HOMEPAGE=https://ffmpeg.org
TERMUX_PKG_DESCRIPTION="Tools and libraries to manipulate a wide range of multimedia formats and protocols"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
# Please align version with `ffplay` package.
TERMUX_PKG_VERSION="8.1.2"
TERMUX_PKG_SRCURL="https://www.ffmpeg.org/releases/ffmpeg-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c
TERMUX_PKG_DEPENDS="fontconfig, freetype, fribidi, game-music-emu, glslang, harfbuzz, libaom, libandroid-glob, libandroid-stub, libass, libbluray, libbs2b, libbz2, libdav1d, libiconv, liblzma, libmysofa, libmp3lame, libopencore-amr, libopenmpt, libopus, libplacebo, librav1e, libsoxr, libsrt, libssh, libtheora, libv4l, libvidstab, libvmaf, libvo-amrwbenc, libvorbis, libvpx, libwebp, libx264, libx265, libxml2, libzimg, libzmq, littlecms, ocl-icd, openssl, rubberband, svt-av1, vulkan-icd, xvidcore, zlib"
TERMUX_PKG_BUILD_DEPENDS="opencl-headers, vulkan-headers"
TERMUX_PKG_CONFLICTS="libav"
TERMUX_PKG_BREAKS="ffmpeg-dev"
TERMUX_PKG_REPLACES="ffmpeg-dev"

termux_step_pre_configure() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed. (These variables are also used afterwards.)
	declare -gA _FFMPEG_SOVER=(
		[avutil]=60
		[avcodec]=62
		[avformat]=62
	)

	local lib so_version
	for lib in util codec format; do
		so_version=$(sh ffbuild/libversion.sh av${lib} \
				libav${lib}/version.h libav${lib}/version_major.h \
				| sed -En 's/^libav'"${lib}"'_VERSION_MAJOR=([0-9]+)$/\1/p')
		if [[ ! "${so_version}"  ||  "${_FFMPEG_SOVER[av${lib}]}" != "${so_version}" ]]; then
			termux_error_exit "SOVERSION guard check failed for libav${lib}.so. expected ${so_version}"
		fi
	done
}

termux_step_configure() {
	cd $TERMUX_PKG_BUILDDIR

	local _EXTRA_CONFIGURE_FLAGS=""
	case "$TERMUX_ARCH" in
		"aarch64")
			_ARCH="$TERMUX_ARCH"
			_EXTRA_CONFIGURE_FLAGS="--enable-neon"
		;;
		"arm")
			_ARCH="armeabi-v7a"
			_EXTRA_CONFIGURE_FLAGS="--enable-neon"
			CFLAGS+=" -Wno-error=incompatible-pointer-types"
		;;
		"i686")
			_ARCH="x86"
			_EXTRA_CONFIGURE_FLAGS="--disable-asm"
		;;
		"x86_64")
			_ARCH="x86_64"
		;;
		*) termux_error_exit "Unsupported arch: $TERMUX_ARCH";;
	esac

	$TERMUX_PKG_SRCDIR/configure \
		--arch="${_ARCH}" \
		--as="$AS" \
		--cc="$CC" \
		--cxx="$CXX" \
		--nm="$NM" \
		--ar="$AR" \
		--ranlib="llvm-ranlib" \
		--pkg-config="$PKG_CONFIG" \
		--strip="$STRIP" \
		--cross-prefix="${TERMUX_HOST_PLATFORM}-" \
		--enable-cross-compile \
		--enable-shared \
		--disable-static \
		--disable-doc \
		--disable-ffplay \
		--disable-ffprobe \
		--disable-postproc \
		--disable-avdevice \
		--disable-swresample \
		--disable-indevs \
		--disable-outdevs \
		--enable-indev=lavfi \
		--disable-encoders \
		--enable-encoder=libmp3lame,aac,libopus,libvorbis \
		--disable-decoders \
		--enable-decoder=mp3,mp3float,aac,aac_latm,h264,hevc,opus,vorbis,pcm_s16le,pcm_s24le \
		--disable-muxers \
		--enable-muxer=mp4,mpegts,matroska,webm,mp3,ogg,wav \
		--disable-demuxers \
		--enable-demuxer=mp3,aac,h264,hevc,mov,matroska,webm,ogg,wav \
		--disable-parsers \
		--enable-parser=h264,hevc,aac,mpegaudio,opus,vorbis \
		--disable-protocols \
		--enable-protocol=file,http,tcp,pipe \
		--disable-filters \
		--enable-filter=aresample,atrim,concat,volume,pan,amerge \
		--disable-bsfs \
		--enable-gpl \
		--enable-version3 \
		--enable-libmp3lame \
		--enable-libopus \
		--enable-libvorbis \
		--disable-libx264 \
		--disable-libx265 \
		--disable-libvpx \
		--disable-libaom \
		--disable-libdav1d \
		--disable-librav1e \
		--disable-libsvtav1 \
		--disable-libass \
		--disable-libfreetype \
		--disable-libfontconfig \
		--disable-libfribidi \
		--disable-libharfbuzz \
		--disable-libbluray \
		--disable-libbs2b \
		--disable-libgme \
		--disable-libmysofa \
		--disable-libopencore-amrnb \
		--disable-libopencore-amrwb \
		--disable-libopenmpt \
		--disable-libsoxr \
		--disable-libsrt \
		--disable-libssh \
		--disable-libtheora \
		--disable-libv4l2 \
		--disable-libvidstab \
		--disable-libvmaf \
		--disable-libvo-amrwbenc \
		--disable-libwebp \
		--disable-libxml2 \
		--disable-libxvid \
		--disable-libzimg \
		--disable-libzmq \
		--disable-lcms2 \
		--disable-libglslang \
		--disable-libplacebo \
		--disable-rubberband \
		--disable-openssl \
		--disable-opencl \
		--disable-vulkan \
		--disable-mediacodec \
		--disable-jni \
		--disable-symver \
		--target-os=android \
		--extra-libs="-landroid-glob" \
		--prefix="$TERMUX_PREFIX" \
		$_EXTRA_CONFIGURE_FLAGS
}

termux_step_post_massage() {
	cd "${TERMUX_PKG_MASSAGEDIR}/${TERMUX_PREFIX}/lib" || termux_error_exit "couldn't symlink shared libraries."
	local lib so_version
	for lib in util codec format; do
		so_version="${_FFMPEG_SOVER[av${lib}]}"
		if [[ ! "${so_version}" ]]; then
			termux_error_exit "Empty SOVERSION for libav${lib}."
		fi
		# SOVERSION suffix is expected by some programs, e.g. Firefox.
		if [[ ! -e "./libav${lib}.so.${so_version}" ]]; then
			ln -sf "libav${lib}.so" "libav${lib}.so.${so_version}"
		fi
	done
}

termux_step_create_debscripts() {
	# See: https://github.com/termux/termux-packages/issues/23189#issuecomment-2663464359
	# See also: https://github.com/termux/termux-packages/wiki/Termux-execution-environment#dynamic-library-linking-errors
	sed -e "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
		"$TERMUX_PKG_BUILDER_DIR/postinst.sh.in" > ./postinst
	chmod +x ./postinst
}
