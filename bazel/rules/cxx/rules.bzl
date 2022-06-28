load("@bazel_skylib//lib:shell.bzl", "shell")

def _cxx_compile(ctx, src, hdrs, out):
    args = ctx.actions.args()
    args.add("-c")
    args.add("-o", out)
    args.add(src)

    ctx.actions.run(
        executable = "g++",
        outputs = [out],
        inputs = [src] + hdrs,
        arguments = [args],
        mnemonic = "CxxCompile",
        use_default_shell_env = True,
    )

def _cxx_link(ctx, objs, out):
    args = ctx.actions.args()
    args.add("-o", out)
    args.add_all(objs)

    ctx.actions.run(
        executable = "g++",
        outputs = [out],
        inputs = objs,
        arguments = [args],
        mnemonic = "CxxLink",
        use_default_shell_env = True,
    )

def _cxx_binary_impl(ctx):
    hdrs = []
    for src in ctx.files.srcs:
        if src.basename.endswith(".h"):
            hdrs.append(src)

    objs = []
    for src in ctx.files.srcs:
        if src.basename.endswith(".cpp"):
            obj = ctx.actions.declare_file(src.basename + ".o")
            _cxx_compile(
                ctx,
                src = src,
                hdrs = hdrs,
                out = obj,
            )
            objs.append(obj)

    if not objs:
        fail("No cpp source files specified")

    executable = ctx.actions.declare_file(ctx.label.name)
    _cxx_link(
        ctx,
        objs = objs,
        out = executable,
    )

    return [DefaultInfo(
        files = depset([executable]),
        executable = executable,
    )]

cxx_binary = rule(
    _cxx_binary_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".cpp", ".h"],
            doc = "Source files to compile for this binary",
        ),
    },
    doc = "Builds an executable program from C++ source code",
    executable = True,
)
