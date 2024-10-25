load("//bazel/rules/cxx:rules.bzl", "cxx_binary", "cxx_test")

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

cxx_binary(
    name = "main-clone",
    srcs = [
        "main.cpp",
    ],
    deps = [
        "//lib/func1",
        "//lib/func2",
    ],
)

cxx_test(
    name = "main-test",
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
    defines = {
        "RULES_CC": 1,
    },
    deps = [
        "//lib/func1:cc_func1",
        "//lib/func2:cc_func2",
    ],
)

cc_test(
    name = "cc_main_test",
    srcs = [
        "main.cpp",
    ],
    defines = {
        "RULES_CC": 1,
    },
    deps = [
        "//lib/func1:cc_func1",
        "//lib/func2:cc_func2",
    ],
)
