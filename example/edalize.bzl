def _edalize_impl(ctx):

    args = ctx.actions.args()

    outputs = []
    outputs.append(ctx.actions.declare_file("counter.bin"))
    
    args.add_all(ctx.files.srcs, format_each="--input=%s")

    args.add("--input=" + ctx.files._root[0].path)

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
       "_wrapper": attr.label(
            default="//example:el_docker",
            executable=True, cfg="exec"
       ),
       # Use repo rule to find repo path
       "_root" : attr.label(default="//:README.md", allow_single_file=True),

    },
)
