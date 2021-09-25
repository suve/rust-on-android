# rust-on-android

An example repository showing how to build Rust code for Android and embed it in an app.
Implements a very basic [Reverse Polish Notation](https://en.wikipedia.org/wiki/Reverse_Polish_Notation) calculator.

This README gives a quick rundown of the repo.
If you want some more information, check out [the post on my blog](https://blog.svgames.pl/article/running-rust-on-android).

**NOTE**: If you want a quick and easy solution,
there is a [Rust plugin for Gradle](https://github.com/mozilla/rust-android-gradle) which makes the whole
process rather trivial. For an example of how to use the plugin, you can check out
the [example repo by ssrlive](https://github.com/ssrlive/rust_on_android).

This repository contains a more low-level approach, where C and Rust compilers are directly called
and all the stuff related to setting up cross-compilation, compiler flags, linker flags etc.
is handled explicitly. Gradle is used pretty much only to glue everything together into an `.apk`.


## Requirements

To build this app, you'll need the following:
- Android Software Development Kit
- Android Native Development Kit r21
- bash
- curl
- gcc
- Java Runtime Environmennt
- m4
- make
- Rust with cross-compilers
- tar

### Android tools

You can download the Android tools from the Android developer portal.
- [SDK](https://developer.android.com/studio#command-tools) - you will only need the command-line tools, not the whole Android Studio package.
- [NDK](https://developer.android.com/ndk/downloads/) - make sure to grab the r21 LTS release, **not** the latest r22 release.

### Native build tools

The app has a dependency on the [GNU Multiple Precision Arithmetic Library](https://gmplib.org/),
or GMP, for short. To build GMP, you'll need some Linux build tools.

On Debian/Ubuntu, you can use the following:
```
apt install -y curl gcc m4 make tar
```
On Fedora/CentOS, you can use:
```
dnf install --assumeyes curl gcc m4 make tar
```

### Rust with cross-compilers

To install Rust, you can use [rustup-init](https://rust-lang.github.io/rustup/installation/other.html).

Once you have Rust installed, you can use `rustup` to install support for Android targets.
```
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
```

### Java runtime environment

For building the `.apk`, this repo uses Gradle, which requires a JRE to run.
While Android Studio offers you to download a JRE and Gradle can be configured
to run with that, this repo just tries to use the your system's default JRE.

On Debian/Ubuntu, you can use the following command to install one:
```
apt install -y openjdk-11-jre-headless
```
On Fedora/CentOS, you can use:
```
dnf install --assumeyes java-11-openjdk-headless
```


## Environment variables

Before you can trigger a build, you'll need to set up some environment variables.
- `ANDROID_SDK_ROOT` - should point to the directory where you installed the Android SDK.
- `ANDROID_NDK_ROOT` - should point to the directory where you installed the Android NDK r21.
- `ANDROID_API` - an integer specifying which [Android API level](https://en.wikipedia.org/wiki/Android_version_history#Overview) you want to target. Suggested value is 29.


## Building

The `build-all.sh` script can be used to perform all the steps and build the `.apk`.
```
build-all.sh [--clean] [--release]

Options:
  --clean  Remove all leftovers from previous builds before starting.
           Results in a clean build (i.e. "from scratch").
  --release  Build in release mode. When not specified, debug mode is used.
```
The resulting `.apk` files will be placed in the `build/` directory (which will be created, if it doesn't exist)
right next to this script. Building GMP and Rust code will happen inside said directory, too.

### build-libgmp.sh

This script can be used to build only the GMP library.
```
build-libgmp.sh --arch ARCH --build-dir BUILD_DIR --build-mode MODE
                --libs-dir LIBS_DIR [--clean]

Options:
  --arch ARCH  Specifies which architecture to build for.
               Valid values are 'aarch64', 'armv7' and 'x86_64'.
  --build-dir BUILD_DIR  Specifies the directory to use for building.
  --build-mode   Specifies the build mode.
                 Must be either 'debug' or 'release'.
  --clean  Perform a clean build (before starting,
           remove any files left over from previous builds).
  --libs-dir LIBS_DIR  Specified the directory where built libraries
                       should be copied over to.
```

### build-librpn.sh

This script can be used to build only the Rust code.
Note that you **must** build GMP first, and that GMP's `.so`
files must be present inside `LIBS_DIR`; otherwise, linking will fail.
```
build-librpn.sh --arch ARCH --build-dir BUILD_DIR --build-mode MODE
                --libs-dir LIBS_DIR [--clean]

Options:
  --arch ARCH  Specifies which architecture to build for.
               Valid values are 'aarch64', 'armv7' and 'x86_64'.
  --build-dir BUILD_DIR  Specifies the directory to use for building.
  --build-mode   Specifies the build mode.
                 Must be either 'debug' or 'release'.
  --clean  Perform a clean build (before starting,
           remove any files left over from previous builds).
  --libs-dir LIBS_DIR  Specified the directory where built libraries
                       should be copied over to. GMP libraries
                       should also be located here.
```

### build-apk.sh

This script can bse used to build only the `.apk`.
Note that you **should** build GMP and the Rust code first.
While the app will build without native libraries, it will crash at runtime.
```
build-apk.sh --build-dir BUILD_DIR --build-mode MODE
             --libs-dir LIBS_DIR [--clean]

Options:
  --build-dir BUILD_DIR  Specifies the directory where to put
                         the resulting .apk files.
  --build-mode   Specifies the build mode.
                 Must be either 'debug' or 'release'.
  --clean  Perform a clean build (before starting,
           remove any files left over from previous builds).
  --libs-dir LIBS_DIR  Specified the directory where native libraries
                       can be copied from.
```


## Directories

The main directory contains bash scripts used to perform the build and glue eveything together.

### android/

Contains the Android app files, such as the `AndroidManifest.xml` file,
an Activity with some basic UI, and "glue" classes for interfacing with
the Rust code.

### rust/

Contains the Rust code. It is split into three parts:
- `android.rs` - JNI glue code
- `lib.rs` - the actual RPN implementation
- `main.rs` - command-line program

It is possible to build the app as a standalone executable,
in which case it will take input from stdin, one line at a time,
evaluate it, and print the answer.

## Licensing

The contents of this repository are subject to the zlib licence.
For the full text of the licence, consult the `LICENCE` file.
