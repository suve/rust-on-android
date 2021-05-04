#!/bin/bash

set -eu -o pipefail

# -- Check env vars.
if [[ -z "${ANDROID_SDK_ROOT+isset}" ]]; then
	echo 'build-apk.sh: The $ANDROID_SDK_ROOT environment variable is unset - unable to proceed' >&2
	exit 10
fi

# -- Parse arguments.
BUILD_DIR=""
BUILD_MODE=""
CLEAN=""
LIBS_DIR=""
while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--build-dir" ]]; then
		BUILD_DIR="$(pwd)/$2"
		shift 2
	elif [[ "$1" == "--build-mode" ]]; then
		BUILD_MODE="$2"
		shift 2

		if [[ "${BUILD_MODE}" != "debug" ]] && [[ "${BUILD_MODE}" != "release" ]]; then
			echo "build-apk.sh: Unrecognized --build-mode '${BUILD_MODE}' (must be either 'debug' or 'release')" >&2
			exit 1
		fi
	elif [[ "$1" == "--clean" ]]; then
		CLEAN="1"
		shift 1
	elif [[ "$1" == "--libs-dir" ]]; then
		LIBS_DIR="$(pwd)/$2"
		shift 2
	else
		echo "build-apk.sh: Unrecognized argument '$1'" >&2
		exit 1
	fi
done

if [[ -z "${BUILD_DIR}" ]]; then
	echo "build-apk.sh: You must specify the --build-dir" >&2
	exit 1
fi
mkdir -p "${BUILD_DIR}"

if [[ -z "${BUILD_MODE}" ]]; then
	echo "build-apk.sh: You must specify the --build-mode" >&2
	exit 1
fi

if [[ -z "${LIBS_DIR}" ]]; then
	echo "build-apk.sh: You must specify the --libs-dir" >&2
	exit 1
fi

# -- Done with arguments. Time for the script proper.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="${SCRIPT_DIR}/android"
JNI_LIBS_DIR="${ANDROID_DIR}/app/src/main/jniLibs"

# If --clean was passed, remove the jniLibs dir and other build-related dirs.
if [[ "${CLEAN}" -eq 1 ]]; then
	rm -rf "${JNI_LIBS_DIR}"
	rm -rf "${ANDROID_DIR}/build"
	rm -rf "${ANDROID_DIR}/app/build"
fi

# Copy the compiled libraries.
for ARCH in 'aarch64:arm64-v8a' 'armv7:armeabi-v7a' 'x86_64:x86_64'; do
	ARCH_LIB="$(echo "${ARCH}" | cut -d: -f1)"
	ARCH_JNI="$(echo "${ARCH}" | cut -d: -f2)"

	ARCH_LIB_DIR="${LIBS_DIR}/${BUILD_MODE}/${ARCH_LIB}"
	ARCH_JNI_DIR="${JNI_LIBS_DIR}/${ARCH_JNI}"

	if [[ ! -d "${ARCH_LIB_DIR}" ]]; then
		echo "Libraries for ${ARCH_LIB} not found, skipping..." >&2
		continue
	fi

	mkdir -p "${ARCH_JNI_DIR}"
	cp -a "${ARCH_LIB_DIR}"/*.so --target-directory "${ARCH_JNI_DIR}"
done

# Call gradle and peform the build.
cd "${ANDROID_DIR}"
./gradlew
./gradlew build

# Copy the built apk.
APK_DIR="${ANDROID_DIR}/app/build/outputs/apk/"
if [[ "${BUILD_MODE}" == "debug" ]]; then
	cp -a "${APK_DIR}/debug/app-debug.apk" "${BUILD_DIR}/rpn.apk"
else
	cp -a "${APK_DIR}/release/app-release-unsigned.apk" "${BUILD_DIR}/rpn.apk"
fi
