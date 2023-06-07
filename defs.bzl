"""
Defines a bootlin_toolchain rule to allow toolchain customization.
"""
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@bazel_bootlin//toolchains:toolchain_info.bzl",
    "ALL_TOOLS",
    "AVAILABLE_TOOLCHAINS",
)

def _bootlin_toolchain_impl(rctx):
    architecture = rctx.attr.architecture
    buildroot_version = rctx.attr.buildroot_version
    platform_arch = AVAILABLE_TOOLCHAINS[architecture][buildroot_version]["platform_arch"]

    files_workspace = "{}_files".format(rctx.attr.name)

    for tool in ALL_TOOLS:
        buildroot_tool = (
            "{}.br_real".format(tool) if tool in ["cpp", "gcc"] else tool
        )

        rctx.file(
            "tool_wrappers/{0}/{1}/{0}-linux-gnu-{1}-{2}".format(
                architecture,
                buildroot_version,
                tool,
            ),
            content = """#!/usr/bin/env bash
exec external/{0}/bin/{1}-buildroot-linux-gnu-{2} $@
""".format(
                files_workspace,
                platform_arch,
                buildroot_tool,
            ),
        )

    as_string = lambda args: (
        "[{}]".format(", ".join(
            [
                "'{}'".format(arg)
                for arg in args
            ],
        ))
    )

    bazel_output_base = str(rctx.path(".")).removesuffix("/external/{}".format(rctx.attr.name))
    template = Label("//toolchains:BUILD.toolchain.tpl")

    rctx.template(
        "BUILD.bazel",
        template,
        {
            "{bazel_output_base}": bazel_output_base,
            "{bootlin_workspace}": template.workspace_name,
            "{toolchain_workspace_files}": files_workspace,
            "{architecture}": architecture,
            "{buildroot_version}": buildroot_version,
            "{platform_arch}": platform_arch,
            "{extra_cxxflags}": as_string(rctx.attr.extra_cxxflags),
            "{extra_ldflags}": as_string(rctx.attr.extra_ldflags),
        },
    )

_bootlin_toolchain = repository_rule(
    attrs = {
        "architecture": attr.string(
            mandatory = True,
        ),
        "buildroot_version": attr.string(
            mandatory = True,
        ),
        "extra_cxxflags": attr.string_list(
            default = [],
            doc = "Additional flags used for C++ compile actions.",
        ),
        "extra_ldflags": attr.string_list(
            default = [],
            doc = "Additional flags used for link actions.",
        ),
        "extra_toolchain_constraints": attr.string_list(
            default = [],  # TODO
            doc = "Additional platform constraints beyond `cpu` and `os`.",
        ),
    },
    local = True,
    configure = True,
    implementation = _bootlin_toolchain_impl,
)

def bootlin_toolchain(**kwargs):
    architecture = kwargs["architecture"]
    buildroot_version = kwargs["buildroot_version"]
    files_workspace = "{}_files".format(kwargs["name"])

    identifier = "{arch}--{libc}--{variant}-{release}".format(
        arch = architecture,
        libc = "glibc",
        variant = "bleeding-edge" if buildroot_version.endswith("_bleeding") else "stable",
        release = buildroot_version.rstrip("_bleeding"),
    )

    http_archive(
        name = files_workspace,
        build_file_content = """
filegroup(
    name = "{files_workspace}",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "sysroot_ld",
    srcs = glob(["**/ld-linux*.so.*"]),
    visibility = ["//visibility:public"],
)
""".format(files_workspace = files_workspace),
        url = ("https://toolchains.bootlin.com/downloads/releases/toolchains/" +
               "{}/tarballs/{}.tar.bz2").format(
                   architecture,
                   identifier,
        ),
        sha256 = AVAILABLE_TOOLCHAINS[architecture][buildroot_version]["sha256"],
        strip_prefix = identifier,
    )

    _bootlin_toolchain(**kwargs)
