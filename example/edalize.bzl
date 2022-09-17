def _edalize_impl(ctx):

    args = ctx.actions.args()

    outputs = [ctx.actions.declare_file(name) for name in ctx.attr.outs]
    
    args.add_all(ctx.files.srcs, format_each="--input=%s")

    args.add("--root=" + ctx.files._root[0].path)

    args.add_all(outputs, format_each="--output=%s")
    

    ctx.actions.run(
        mnemonic = "fileGeneration",
        executable = ctx.executable.spec,
	tools = [ctx.executable._wrapper],
        arguments = [args],
        inputs = ctx.files.srcs + ctx.files.spec + ctx.files._wrapper + ctx.files._root,
	env = {"EDALIZE_LAUNCHER":ctx.files._wrapper[0].path},
        outputs = outputs,
    )

    return [
        DefaultInfo(files = depset(outputs)),
    ]

edalize = rule(
    implementation = _edalize_impl,
    attrs = {
        "srcs": attr.label_list(mandatory = True, allow_files=True),
        "spec" : attr.label(default="//example:example", executable=True, cfg="exec"),
        "outs": attr.string_list(mandatory = True),
       "_wrapper": attr.label(
            default="//example:el_docker",
            executable=True, cfg="exec"
       ),
       # Use repo rule to find repo path
       "_root" : attr.label(default="//:README.md", allow_single_file=True),

    },
)
