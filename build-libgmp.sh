#!/bin/bash
set -eu -o pipefail

# -- Check the environment variables.
if [[ -z "${ANDROID_NDK_ROOT+isset}" ]]; then
	echo 'build-libgmp.sh: The $ANDROID_NDK_ROOT environment variable is unset - unable to proceed' >&2
	exit 10
fi
if [[ -z "${ANDROID_API+isset}" ]]; then
	echo 'build-libgmp.sh: The $ANDROID_API environment variable is unset - unable to proceed' >&2
	exit 11
fi

# -- Parse arguments.
ARCH=""
BUILD_DIR=""
BUILD_MODE=""
CLEAN="0"
LIBS_DIR=""
while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--arch" ]]; then
		ARCH="$2"
		shift 2

		if [[ "${ARCH}" != "aarch64" ]] && [[ "${ARCH}" != "armv7" ]] && [[ "${ARCH}" != "x86_64" ]]; then
			echo "build-libgmp.sh: Unrecognized --arch '${ARCH}' (must be one of 'aarch64', 'armv7', 'x86_64')" >&2
			exit 1
		fi
	elif [[ "$1" == "--build-dir" ]]; then
		BUILD_DIR="$(pwd)/$2/libgmp"
		shift 2
	elif [[ "$1" == "--build-mode" ]]; then
		BUILD_MODE="$2"
		shift 2

		if [[ "${BUILD_MODE}" != "debug" ]] && [[ "${BUILD_MODE}" != "release" ]]; then
			echo "build-libgmp.sh: Unrecognized --build-mode '${BUILD_MODE}' (must be either 'debug' or 'release')" >&2
			exit 1
		fi
	elif [[ "$1" == "--clean" ]]; then
		CLEAN="1"
		shift 1
	elif [[ "$1" == "--libs-dir" ]]; then
		LIBS_DIR="$(pwd)/$2"
		shift 2
	else
		echo "build-libgmp.sh: Unrecognized argument '$1'" >&2
		exit 1
	fi
done

if [[ -z "${ARCH}" ]]; then
	echo "build-libgmp.sh: You must specify the --arch" >&2
	exit 1
fi

if [[ -z "${BUILD_DIR}" ]]; then
	echo "build-libgmp.sh: You must specify the --build-dir" >&2
	exit 1
fi
mkdir -p "${BUILD_DIR}"

if [[ -z "${BUILD_MODE}" ]]; then
	echo "build-libgmp.sh: You must specify the --build-mode" >&2
	exit 1
fi

if [[ -z "${LIBS_DIR}" ]]; then
	echo "build-libgmp.sh: You must specify the --libs-dir" >&2
	exit 1
fi
LIBS_DIR="${LIBS_DIR}/${BUILD_MODE}/${ARCH}"
mkdir -p "${LIBS_DIR}"

# -- Done with parsing arguments, time for the script proper.

# libgmp version to use.
VERSION="6.2.1"

# If --clean was specified, remove the libgmp build directory.
TARGET_DIR="${BUILD_DIR}/${ARCH}/${BUILD_MODE}/gmp-${VERSION}"
if [[ "${CLEAN}" -eq 1 ]]; then
	rm -rf "${TARGET_DIR}"
fi

# If the build directory does not exist, create it.
if [[ ! -d "${TARGET_DIR}" ]]; then
	# If we don't have a local copy of the libgmp archive, download it.
	if [[ ! -f "${BUILD_DIR}/gmp-${VERSION}.tar.lz" ]]; then
		cd "${BUILD_DIR}"
		curl --remote-name "https://gmplib.org/download/gmp/gmp-${VERSION}.tar.lz"
	fi

	# Extract the libgmp archive.
	mkdir -p "${BUILD_DIR}/${ARCH}/${BUILD_MODE}"
	cd "${BUILD_DIR}/${ARCH}/${BUILD_MODE}"
	tar lxf "${BUILD_DIR}/gmp-${VERSION}.tar.lz"
fi

# Set up the NDK tools for cross-compiling.
TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/"
if [[ "${ARCH}" == "armv7" ]]; then
	HOST="armv7a-linux-androideabi"
	TOOL_PREFIX="${TOOLCHAIN}/bin/arm-linux-androideabi"
else
	HOST="${ARCH}-linux-android"
	TOOL_PREFIX="${TOOLCHAIN}/bin/${HOST}"
fi
COMPILER_PREFIX="${TOOLCHAIN}/bin/${HOST}${ANDROID_API}"

export AR="${TOOL_PREFIX}-ar"
export AS="${TOOL_PREFIX}-as"
export CC="${COMPILER_PREFIX}-clang"
export LD="${TOOL_PREFIX}-ld"
export RANLIB="${TOOL_PREFIX}-ranlib"
export STRIP="${TOOL_PREFIX}-strip"

# Set up compiler flags.
if [[ "${BUILD_MODE}" == "release" ]]; then
	export CFLAGS="-O2 -s"
else
	export CFLAGS="-O0 -ggdb"
fi

# cd to the build directory and run make.
# If the Makefile does not exist, run configure.
cd "${TARGET_DIR}"
if [[ ! -f Makefile ]]; then
	./configure "--host=${HOST}" --with-pic --disable-static --enable-shared
fi
make -j $(nproc)

# Copy the built library.
cp .libs/libgmp.so "${LIBS_DIR}/libgmp.so"
