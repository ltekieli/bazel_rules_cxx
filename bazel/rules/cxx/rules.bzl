CxxInfo = provider(
    fields = {
        "hdrs": "depset of header files",
        "archives": "depset of archives",
    },
)

env = {
    "PWD": "/proc/self/cwd",
}

def _cxx_compile(ctx, src, hdrs, out, gcno = None):
    args = ctx.actions.args()
    args.add("-c")
    args.add("-o", out)
    args.add("-iquote", ".")

    outputs = [out]

    if gcno:
        args.add("-fprofile-arcs")
        args.add("-ftest-coverage")
        outputs += [gcno]

    args.add(src)

    toolchain = ctx.toolchains["//bazel/rules/cxx:cxx_toolchain_type"]

    ctx.actions.run(
        executable = toolchain.compiler,
        outputs = outputs,
        inputs = [src] + hdrs,
        arguments = [args],
        env = env,
        mnemonic = "CxxCompile",
        use_default_shell_env = True,
    )

def _cxx_archive(ctx, objs, out):
    args = ctx.actions.args()
    args.add("crs", out)
    args.add_all(objs)

    toolchain = ctx.toolchains["//bazel/rules/cxx:cxx_toolchain_type"]

    ctx.actions.run(
        executable = toolchain.archiver,
        outputs = [out],
        inputs = objs,
        arguments = [args],
        env = env,
        mnemonic = "CxxArchive",
        use_default_shell_env = True,
    )

def _cxx_link(ctx, objs, out):
    args = ctx.actions.args()
    args.add("-static")
    args.add("-o", out)

    if ctx.coverage_instrumented():
        args.add("-fprofile-arcs")
        args.add("-ftest-coverage")
        args.add("-lgcov")

    args.add_all(objs)

    toolchain = ctx.toolchains["//bazel/rules/cxx:cxx_toolchain_type"]

    ctx.actions.run(
        executable = toolchain.compiler,
        outputs = [out],
        inputs = objs,
        arguments = [args],
        env = env,
        mnemonic = "CxxLink",
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
    gcnos = []
    for src in ctx.files.srcs:
        if src.basename.endswith(".cpp"):
            obj = ctx.actions.declare_file(src.basename + ".o")

            gcno = None
            if ctx.coverage_instrumented():
                gcno = ctx.actions.declare_file(src.basename + ".gcno")
                gcnos.append(gcno)

            _cxx_compile(
                ctx,
                src = src,
                hdrs = hdrs,
                out = obj,
                gcno = gcno,
            )
            objs.append(obj)

    if not objs:
        fail("No cpp source files specified")

    return objs, gcnos

def _cxx_static_library_impl(ctx):
    hdrs = _collect_headers(ctx)
    objs, gcnos = _compile_sources(ctx, hdrs)

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
        coverage_common.instrumented_files_info(
            ctx,
            source_attributes = ["srcs"],
            dependency_attributes = ["deps"],
            metadata_files = gcnos,
        )
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
    objs, gcnos = _compile_sources(ctx, hdrs)
    objs += depset(transitive = [dep[CxxInfo].archives for dep in ctx.attr.deps]).to_list()

    executable = ctx.actions.declare_file(ctx.label.name)
    _cxx_link(
        ctx,
        objs = objs,
        out = executable,
    )

    return [
        DefaultInfo(
            files = depset([executable]),
            executable = executable,
        ),
        coverage_common.instrumented_files_info(
            ctx,
            source_attributes = ["srcs"],
            dependency_attributes = ["deps"],
            metadata_files = gcnos,
        )
    ]

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

def _cxx_test_impl(ctx):
    hdrs = _collect_headers(ctx)
    objs, gcnos = _compile_sources(ctx, hdrs)
    objs += depset(transitive = [dep[CxxInfo].archives for dep in ctx.attr.deps]).to_list()

    executable = ctx.actions.declare_file(ctx.label.name)
    _cxx_link(
        ctx,
        objs = objs,
        out = executable,
    )

    return [
        DefaultInfo(
            files = depset([executable]),
            executable = executable,
        ),
        coverage_common.instrumented_files_info(
            ctx,
            source_attributes = ["srcs"],
            dependency_attributes = ["deps"],
            metadata_files = gcnos,
            extensions = ["cpp"],
        )
    ]

cxx_test = rule(
    _cxx_test_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".cpp", ".h"],
            doc = "Source files to compile for this binary",
        ),
        "deps": attr.label_list(
            providers = [CxxInfo],
        ),
        "_collect_cc_coverage": attr.label(
            default = Label("//:collect_cc_coverage"),
            executable = True,
            cfg = "exec",
        ),
        "_lcov_merger": attr.label(
            default = configuration_field(fragment = "coverage", name = "output_generator"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Builds an executable program from C++ source code",
    test = True,
    toolchains = ["//bazel/rules/cxx:cxx_toolchain_type"],
)
