#!/bin/bash

set -eu -o pipefail

# -- Check env vars.
if [[ -z "${ANDROID_SDK_ROOT+isset}" ]]; then
	echo 'build-all.sh: The $ANDROID_SDK_ROOT environment variable is unset - unable to proceed' >&2
	exit 10
fi
if [[ -z "${ANDROID_NDK_ROOT+isset}" ]]; then
	echo 'build-all.sh: The $ANDROID_NDK_ROOT environment variable is unset - unable to proceed' >&2
	exit 11
fi
if [[ -z "${ANDROID_API+isset}" ]]; then
	echo 'build-all.sh: The $ANDROID_API environment variable is unset - unable to proceed' >&2
	exit 12
fi

# -- Parse arguments.
BUILD_MODE="debug"
CLEAN=""
while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--clean" ]]; then
		CLEAN="--clean"
		shift 1
	elif [[ "$1" == "--release" ]]; then
		BUILD_MODE="release"
		shift 1
	else
		echo "build-all.sh: Unrecognized argument '$1'" >&2
		exit 1
	fi
done

# -- Done with arguments. Time for the script proper.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

function build_arch() {
	local ARCH="$1"
	local FLAGS="--arch ${ARCH} --build-dir ./build --build-mode ${BUILD_MODE} ${CLEAN} --libs-dir ./build/libs"
	"${SCRIPT_DIR}/build-libgmp.sh" ${FLAGS}
	"${SCRIPT_DIR}/build-librpn.sh" ${FLAGS}
}

build_arch aarch64 "$@"
build_arch armv7 "$@"
build_arch x86_64 "$@"

"${SCRIPT_DIR}/build-apk.sh" ${CLEAN} \
	--build-dir ./build \
	--build-mode "${BUILD_MODE}" \
	--libs-dir ./build/libs
