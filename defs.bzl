"""
Defines a bootlin_toolchain rule to allow toolchain customization.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "//toolchain:toolchain_info.bzl",
    "ALL_TOOLS",
    "TOOLCHAIN_INFO",
)

def _bootlin_toolchain_impl(rctx):
    architecture = rctx.attr.architecture
    libc_impl = rctx.attr.libc_impl
    buildroot_version = rctx.attr.buildroot_version

    platform_arch = architecture.replace("-", "_")

    files_workspace = "{}_files".format(rctx.attr.name)

    for tool in ALL_TOOLS:
        buildroot_tool = (
            "{}.br_real".format(tool) if tool in ["cpp", "gcc"] else tool
        )

        rctx.file(
            "tool_wrappers/{}".format(tool),
            content = """#!/bin/bash
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
    template = Label("//toolchain:BUILD.toolchain.tpl")

    rctx.template(
        "BUILD.bazel",
        template,
        {
            "{bazel_output_base}": bazel_output_base,
            "{bootlin_workspace}": template.workspace_name,
            "{identifier}": rctx.attr.identifier,
            "{toolchain_files_workspace}": files_workspace,
            "{target_arch}": architecture,
            "{libc_impl}": libc_impl,
            "{buildroot_version}": buildroot_version,
            "{extra_cxx_flags}": as_string(rctx.attr.extra_cxx_flags),
            "{extra_link_flags}": as_string(rctx.attr.extra_link_flags),
        },
    )

    rctx.file(
        "sysroot_path.bzl",
        content = """
SYSROOT_PATH="{bazel_output_base}/external/{files_workspace}/x86_64-buildroot-linux-gnu/sysroot"
""".format(
            bazel_output_base = bazel_output_base,
            files_workspace = files_workspace,
        ),
        executable = False,
    )

_bootlin_toolchain = repository_rule(
    attrs = {
        "identifier": attr.string(
            mandatory = True,
            doc = "bootlin identifier, key into TOOLCHAIN_INFO",
        ),
        "architecture": attr.string(
            mandatory = True,
        ),
        "libc_impl": attr.string(
            mandatory = True,
        ),
        "buildroot_version": attr.string(
            mandatory = True,
        ),
        "extra_cxx_flags": attr.string_list(
            default = [],
            doc = "Additional flags used for C++ compile actions.",
        ),
        "extra_link_flags": attr.string_list(
            default = [],
            doc = "Additional flags used for link actions.",
        ),
    },
    local = True,
    configure = True,
    implementation = _bootlin_toolchain_impl,
)

def bootlin_toolchain(**kwargs):
    # Handle microarchitecture suffixes.
    microarch = kwargs["architecture"]
    macroarch = "x86-64" if microarch.startswith("x86-64") else microarch

    identifier = "--".join([
        microarch,
        kwargs["libc_impl"],
        kwargs["buildroot_version"],
    ])
    kwargs["architecture"] = macroarch

    files_workspace = "{}_files".format(kwargs["name"])
    http_archive(
        name = files_workspace,
        build_file_content = """
filegroup(
    name = "{files_workspace}",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
""".format(files_workspace = files_workspace),
        url = ("https://toolchains.bootlin.com/downloads/releases/toolchains/" +
               "{arch}/tarballs/{iden}.tar.bz2").format(
            arch = microarch,
            iden = identifier,
        ),
        patch_cmds = [
            """
echo 'filegroup(' >> {arch}-buildroot-linux-gnu/sysroot/BUILD.bazel
echo '    name = "sysroot",' >> {arch}-buildroot-linux-gnu/sysroot/BUILD.bazel
echo '    srcs = glob(["**"]),' >> {arch}-buildroot-linux-gnu/sysroot/BUILD.bazel
echo '    visibility = ["//visibility:public"],' >> {arch}-buildroot-linux-gnu/sysroot/BUILD.bazel
echo ')' >> {arch}-buildroot-linux-gnu/sysroot/BUILD.bazel
""".format(arch = macroarch.replace("-", "_")),
        ],
        sha256 = TOOLCHAIN_INFO[identifier]["sha256"],
        strip_prefix = identifier,
    )

    _bootlin_toolchain(identifier = identifier, **kwargs)
