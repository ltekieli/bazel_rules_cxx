load("//bazel/rules/cxx:rules.bzl", "cxx_static_library")

cxx_static_library(
    name = "func2",
    srcs = [
        "func2.cpp",
    ],
    hdrs = [
        "func2.h",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//lib/func1",
    ],
)
