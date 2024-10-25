load("//bazel/rules/cxx:rules.bzl", "cxx_binary")

cxx_binary(
    name = "main",
    srcs = [
        "main.cpp",
    ],
    deps = [
        "//lib/func1",
        "//lib/func2",
    ],
)

cc_binary(
    name = "cc_main",
    srcs = [
        "main.cpp",
    ],
    deps = [
        "//lib/func1:cc_func1",
        "//lib/func2:cc_func2",
    ],
)
