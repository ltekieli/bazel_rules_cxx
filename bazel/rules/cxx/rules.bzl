CxxInfo = provider(
    fields = {
        "hdrs": "depset of header files",
        "archives": "depset of archives",
    },
)

GENERIC_ENV = {
    "PWD": "/proc/self/cwd",
}

def _cxx_create_dir(ctx, out):
    args = ctx.actions.args()
    args.add("-p", out.path)

    # TODO: direct mkdir usage
    ctx.actions.run(
        executable = "mkdir",
        outputs = [out],
        arguments = [args],
        mnemonic = "CxxCreateDir",
        env = GENERIC_ENV,
        use_default_shell_env = True,
    )

def _cxx_compile(ctx, src, hdrs, out, obj_dir):
    args = ctx.actions.args()
    args.add("-c")
    args.add("-o", out)
    args.add("-fPIC")
    args.add("-frandom-seed=%s" % out.path)
    args.add("-fno-canonical-system-headers")
    args.add("-Wno-builtin-macro-redefined")
    args.add("-D__DATE__=\"redacted\"")
    args.add("-D__TIMESTAMP__=\"redacted\"")
    args.add("-D__TIME__=\"redacted\"")
    args.add("-iquote", ".")
    args.add(src)

    toolchain = ctx.toolchains["//bazel/rules/cxx:cxx_toolchain_type"]

    ctx.actions.run(
        executable = toolchain.compiler,
        outputs = [out],
        inputs = [src, obj_dir] + hdrs,
        arguments = [args],
        mnemonic = "CxxCompile",
        env = GENERIC_ENV,
        use_default_shell_env = True,
    )

def _cxx_archive(ctx, objs, out):
    args = ctx.actions.args()
    args.add("rcsD", out)
    args.add_all(objs)

    toolchain = ctx.toolchains["//bazel/rules/cxx:cxx_toolchain_type"]

    ctx.actions.run(
        executable = toolchain.archiver,
        outputs = [out],
        inputs = objs,
        arguments = [args],
        mnemonic = "CxxArchive",
        env = GENERIC_ENV,
        use_default_shell_env = True,
    )

def _cxx_link(ctx, objs, out):
    args = ctx.actions.args()
    args.add("-static")
    args.add("-o", out)
    args.add_all(objs)

    toolchain = ctx.toolchains["//bazel/rules/cxx:cxx_toolchain_type"]

    ctx.actions.run(
        executable = toolchain.compiler,
        outputs = [out],
        inputs = objs,
        arguments = [args],
        mnemonic = "CxxLink",
        env = GENERIC_ENV,
        use_default_shell_env = True,
    )

def _collect_headers(ctx):
    # Collect all directly specified headers as well as public headers from dependencies.
    hdrs = depset(
        direct = ctx.files.hdrs if hasattr(ctx.files, "hdrs") else [],
        transitive = [dep[CxxInfo].hdrs for dep in ctx.attr.deps],
    ).to_list()

    for src in ctx.files.srcs:
        if src.basename.endswith(".h"):
            hdrs.append(src)

    return hdrs

def _compile_sources(ctx, hdrs):
    # Compile every source file, providing all collected headers.
    objs = []
    for src in ctx.files.srcs:
        if src.basename.endswith(".cpp"):
            obj_dir = ctx.actions.declare_directory("_cxx_objs/" + ctx.label.name)
            _cxx_create_dir(
                ctx,
                out = obj_dir,
            )

            obj = ctx.actions.declare_file(obj_dir.path + "/" + src.basename.removesuffix("." + src.extension) + ".pic.o")
            _cxx_compile(
                ctx,
                src = src,
                hdrs = hdrs,
                out = obj,
                obj_dir = obj_dir,
            )
            objs.append(obj)

    if not objs:
        fail("No cpp source files specified")

    return objs

def _cxx_static_library_impl(ctx):
    hdrs = _collect_headers(ctx)
    objs = _compile_sources(ctx, hdrs)

    static_library = ctx.actions.declare_file(ctx.label.name + ".a")
    _cxx_archive(
        ctx,
        objs = objs,
        out = static_library,
    )

    return [
        DefaultInfo(
            files = depset([static_library]),
        ),
        CxxInfo(
            hdrs = depset(ctx.files.hdrs, transitive = [dep[CxxInfo].hdrs for dep in ctx.attr.deps]),
            archives = depset([static_library], transitive = [dep[CxxInfo].archives for dep in ctx.attr.deps]),
        ),
    ]

cxx_static_library = rule(
    _cxx_static_library_impl,
    attrs = {
        "hdrs": attr.label_list(
            allow_files = [".h"],
            doc = "Public header files for this static library",
        ),
        "srcs": attr.label_list(
            allow_files = [".cpp", ".h"],
            doc = "Source files to compile for this binary",
        ),
        "deps": attr.label_list(
            providers = [CxxInfo],
        ),
    },
    doc = "Builds a static library from C++ source code",
    toolchains = ["//bazel/rules/cxx:cxx_toolchain_type"],
)

def _cxx_binary_impl(ctx):
    hdrs = _collect_headers(ctx)
    objs = _compile_sources(ctx, hdrs)
    objs += depset(transitive = [dep[CxxInfo].archives for dep in ctx.attr.deps]).to_list()

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
        "deps": attr.label_list(
            providers = [CxxInfo],
        ),
    },
    doc = "Builds an executable program from C++ source code",
    executable = True,
    toolchains = ["//bazel/rules/cxx:cxx_toolchain_type"],
)
