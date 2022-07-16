load("//bazel/rules/cxx:toolchain.bzl", "cxx_toolchain")

toolchain_type(
    name = "cxx_toolchain_type",
    visibility = ["//visibility:public"],
)

cxx_toolchain(
    name = "default_cxx_toolchain",
)

toolchain(
    name = "toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":default_cxx_toolchain",
    toolchain_type = ":cxx_toolchain_type",
)
