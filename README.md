# bazel_bootlin

Provides hermetic [Bazel](https://bazel.build/) C/C++ toolchains based on
[Buildroot](https://buildroot.org/) toolchains provided by
[Bootlin](https://toolchains.bootlin.com/).

## Usage

### WORKSPACE

To incorporate `bazel_bootlin` toolchains into your project, copy the following into your
`WORKSPACE` file.

```Starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_bootlin",
    # See release page for latest version url and sha.
)

load("@bazel_bootlin//:defs.bzl", "bootlin_toolchain")

bootlin_toolchain(
    name = "gcc_12_2",
    architecture = "x86-64",
    libc_impl = "glibc"
    buildroot_version = "bleeding-edge-2022.08-1",
)

register_toolchains(
    "@gcc_12_2//:toolchain",
)
```

* `architecture` - refers to the [architecture
  string](https://toolchains.bootlin.com/toolchains.html) used by Bootlin.
* `libc_impl` - refers to the libc implementation (e.g. `glibc`, `musl`, or `uclibc`).
* `buildroot_version` - refers to the [Buildroot version
  string](https://toolchains.bootlin.com/releases_x86-64.html) (e.g. `bleeding-edge-2022.08-1`).

### Available Toolchains

Currently `bazel_bootlin` only provides toolchains listed in
[toolchain/toolchain_info.bzl]. This list is easily expanded so feel free to add
more as necessary.

### Building With Bootlin Toolchains

In order to enable toolchain selection, Bazel requires flag
`--incompatible_enable_cc_toolchain_resolution`.

Additionally, you may also want to use
`--action_env="BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1"` to prevent
accidental use of any local toolchains.

To avoid needing always specify these flags on the command line, you can add
these to your [`.bazelrc`](https://bazel.build/docs/bazelrc) file:

```Shell
build --incompatible_enable_cc_toolchain_resolution
build --action_env="BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1"
```

### Toolchain configuration

Toolchains can configured during definition:

```Starlark
# //:WORKSPACE.bazel

bootlin_toolchain(
    name = "gcc_12_2",
    architecture = "x86-64",
    libc_impl = "glibc"
    buildroot_version = "bleeding-edge-2022.08-1",
    extra_cxx_flags = [
        "-std=c++23",
        "-fdiagnostics-color=always",
        "-Wduplicated-cond",
        "-Wduplicated-branches",
        "-Wlogical-op",
        "-Wuseless-cast",
        "-Wshadow=compatible-local",
        "-Werror",
        "-Wall",
        "-Wextra",
        "-Wpedantic",
        "-Wconversion",
        "-Wnon-virtual-dtor",
        "-Wold-style-cast",
        "-Wcast-align",
        "-Wunused",
        "-Woverloaded-virtual",
        "-Wmisleading-indentation",
        "-Wnull-dereference",
        "-Wdouble-promotion",
        "-Wformat=2",
        "-Wimplicit-fallthrough",
    ],
)
```

### Toolchain selection

If multiple toolchains are registered, toolchain resolution selects the first
available and compatible toolchain.
[`--extra_toolchains`](https://bazel.build/reference/command-line-reference#flag--extra_toolchains)
can then be used to select a specific toolchain when running Bazel:

```Starlark
# //:WORKSPACE.bazel

register_toolchains(
    "@gcc_12_2//:toolchain",
    "@gcc_11_5//:toolchain",
    "@clang_16_0//:...:"
)
```

```Shell
bazel build --extra_toolchains="@gcc_12_2//:toolchain" //...
```

### Toolchain features

`bootlin_toolchain` uses
[unix_cc_tooclahin_config](https://github.com/bazelbuild/bazel/blob/master/tools/cpp/unix_cc_toolchain_config.bzl) and has same features.

For example:

```Shell
bazel run <target> --features=asan
```
