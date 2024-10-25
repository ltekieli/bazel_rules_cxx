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

cxx_test(
    name = "test1",
    srcs = [
        "main2.cpp",
    ],
    deps = [
        "//lib/func1",
        "//lib/func2",
    ],
)

cxx_test(
    name = "test2",
    srcs = [
        "main3.cpp",
    ],
)
