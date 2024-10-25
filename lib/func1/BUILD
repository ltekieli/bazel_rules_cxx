load("//bazel/rules/cxx:rules.bzl", "cxx_static_library")

cxx_static_library(
    name = "func1",
    srcs = [
        "func1.cpp",
        "private_func1.cpp",
        "private_func1.h",
    ],
    hdrs = [
        "func1.h",
    ],
    visibility = [
        "//visibility:public",
    ],
)

cc_library(
    name = "cc_func1",
    srcs = [
        "func1.cpp",
        "private_func1.cpp",
        "private_func1.h",
    ],
    hdrs = [
        "func1.h",
    ],
    visibility = [
        "//visibility:public",
    ],
)
