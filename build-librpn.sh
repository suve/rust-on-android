#!/bin/bash
set -eu -o pipefail

# -- Check the environment variables.
if [[ -z "${ANDROID_NDK_ROOT+isset}" ]]; then
	echo 'build-librpn.sh: The $ANDROID_NDK_ROOT environment variable is unset - unable to proceed' >&2
	exit 10
fi
if [[ -z "${ANDROID_API+isset}" ]]; then
	echo 'buld-librpn.sh: The $ANDROID_API environment variable is unset - unable to proceed' >&2
	exit 11
fi

# -- Parse arguments.
ARCH=""
BUILD_DIR=""
BUILD_MODE=""
CLEAN="0"
LIBS_DIR=""
RELEASE_FLAG=""
while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--arch" ]]; then
		ARCH="$2"
		shift 2

		if [[ "${ARCH}" != "aarch64" ]] && [[ "${ARCH}" != "armv7" ]] && [[ "${ARCH}" != "x86_64" ]]; then
			echo "build-librpn.sh: Unrecognized --arch '${ARCH}' (must be one of 'aarch64', 'armv7', 'x86_64')" >&2
			exit 1
		fi
	elif [[ "$1" == "--build-dir" ]]; then
		BUILD_DIR="$(pwd)/$2/librpn"
		shift 2
	elif [[ "$1" == "--build-mode" ]]; then
		BUILD_MODE="$2"
		shift 2

		if [[ "${BUILD_MODE}" != "debug" ]] && [[ "${BUILD_MODE}" != "release" ]]; then
			echo "build-librpn.sh: Unrecognized --build-mode '${BUILD_MODE}' (must be either 'debug' or 'release')" >&2
			exit 1
		fi
	elif [[ "$1" == "--build-mode" ]]; then
		BUILD_MODE="$2"
		shift 2
	elif [[ "$1" == "--clean" ]]; then
		CLEAN="1"
		shift 1
	elif [[ "$1" == "--libs-dir" ]]; then
		LIBS_DIR="$(pwd)/$2"
		shift 2
	else
		echo "build-librpn.sh: Unrecognized argument '$1'" >&2
		exit 1
	fi
done

if [[ -z "${ARCH}" ]]; then
	echo "build-librpn.sh: You must specify the --arch" >&2
	exit 1
fi

if [[ -z "${BUILD_DIR}" ]]; then
	echo "build-librpn.sh: You must specify the --build-dir" >&2
	exit 1
fi
mkdir -p "${BUILD_DIR}"

if [[ -z "${BUILD_MODE}" ]]; then
	echo "build-librpn.sh: You must specify the --build-mode" >&2
	exit 1
fi
if [[ "${BUILD_MODE}" == "release" ]]; then
	RELEASE_FLAG="--release"
fi

if [[ -z "${LIBS_DIR}" ]]; then
	echo "build-librpn.sh: You must specify the --libs-dir" >&2
	exit 1
fi
LIBS_DIR="${LIBS_DIR}/${BUILD_MODE}/${ARCH}"
mkdir -p "${LIBS_DIR}"

# -- Done with parsing arguments, time for the script proper.

# cd do this script's parent directory, and then to the rust/ subdir.
# That's where the Cargo workspace should be located.
cd "$(dirname "${BASH_SOURCE[0]}")/rust/"

TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
if [[ "${ARCH}" == "armv7" ]]; then
	HOST="armv7a-linux-androideabi"
	TOOL_PREFIX="${TOOLCHAIN}/bin/arm-linux-androideabi"

	RUST_TARGET="armv7-linux-androideabi"
else
	HOST="${ARCH}-linux-android"
	TOOL_PREFIX="${TOOLCHAIN}/bin/${HOST}"

	RUST_TARGET="${ARCH}-linux-android"
fi
COMPILER_PREFIX="${TOOLCHAIN}/bin/${HOST}${ANDROID_API}"
RUST_TARGET_CAPS="$(echo "${RUST_TARGET}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"

# If --clean was used, wipe the target directory for this platform.
TARGET_DIR="${BUILD_DIR}/${RUST_TARGET}/${BUILD_MODE}"
if [[ "${CLEAN}" -eq 1 ]]; then
	rm -rf "${TARGET_DIR}"
fi

# The toolchain variables are based on what cargo-apk uses for building.
# See: https://github.com/rust-windowing/android-ndk-rs/blob/master/ndk-build/src/cargo.rs
#
# The RUSTFLAGS variable sets up the linking path (tells rustc where to look for dependencies).
env \
	"AR_${RUST_TARGET}=${TOOL_PREFIX}-ar" \
	"CC_${RUST_TARGET}=${COMPILER_PREFIX}-clang" \
	"CARGO_TARGET_${RUST_TARGET_CAPS}_LINKER=${COMPILER_PREFIX}-clang" \
	"RUSTFLAGS=-L ${LIBS_DIR}" \
	cargo build ${RELEASE_FLAG} --lib \
		--target="${RUST_TARGET}" \
		--target-dir="${BUILD_DIR}"

cp -a "${TARGET_DIR}/librpn.so" "${LIBS_DIR}/librpn.so"
