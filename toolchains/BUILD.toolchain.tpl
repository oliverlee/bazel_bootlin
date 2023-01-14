# //:BUILD.bazel
load("@{bootlin_workspace}//toolchains:toolchains.bzl", "cc_bootlin_toolchain_config")

filegroup(name = "empty")

filegroup(
    name = "all_files",
    srcs = [
        "@{toolchain_workspace_files}",
    ] + glob(["tool_wrappers/**"]),
)

cc_bootlin_toolchain_config(
    name = "toolchain_config",
    architecture = "{architecture}",
    bazel_output_base = "{bazel_output_base}",
    buildroot_base = "{toolchain_workspace_files}",
    buildroot_version = "{buildroot_version}",
    extra_cxxflags = {extra_cxxflags},
    extra_ldflags = {extra_ldflags},
    sysroot_ld = "@{toolchain_workspace_files}//:sysroot_ld",
)

cc_toolchain(
    name = "cc_toolchain",
    all_files = ":all_files",
    ar_files = ":all_files",
    compiler_files = ":all_files",
    dwp_files = ":empty",
    linker_files = ":all_files",
    objcopy_files = ":empty",
    strip_files = ":empty",
    toolchain_config = ":toolchain_config",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:{platform_arch}",
        "@platforms//os:linux",
    ],
    toolchain = "cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    visibility = ["//visibility:public"],
)
