TOOLCHAIN_INFO = {
    "x86-64--glibc--bleeding-edge-2022.08-1": {
        "sha256": "9a09ac03001ef2a6cab391cc658fc2a32730b6a8f25614e97a91b9a79537fe33",
        "gcc_version": "12.2.0",
        "libc_version": "glibc_2.35",
    },
    "x86-64-v3--glibc--bleeding-edge-2023.08-1": {
        "sha256": "8c2a9de04b56a33ca55190e4479d5ebea17e853fd1ad38eb4750868f2bf459ee",
        "gcc_version": "13.2.0",
        "libc_version": "glibc_2.37",
    },
    "aarch64--glibc--bleeding-edge-2023.08-1": {
        "sha256": "62094460b853970dcba91cae4314bfd1210bb2963be540f7b69be882f5f795ba",
        "gcc_version": "13.2.0",
        "libc_version": "glibc_2.37",
    },
}

ALL_TOOLS = [
    "ar",
    "cpp",
    "gcc",
    "gcov",
    "ld",
    "nm",
    "objcopy",
    "objdump",
    "strip",
]
