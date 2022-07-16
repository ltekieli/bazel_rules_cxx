def _cxx_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            compiler = "g++",
            archiver = "ar",
        ),
    ]

cxx_toolchain = rule(
    implementation = _cxx_toolchain_impl,
    attrs = {},
)
