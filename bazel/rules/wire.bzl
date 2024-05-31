def _wire_impl(ctx):
    # We don't know the output files at analyis time, so decalre a directory
    #output_dir = ctx.actions.declare_directory("generated_proto_kotlin_srcs")

    output_files = []
    for file in ctx.attr.outputs:
        output_files.append(
            ctx.actions.declare_file(file),
        )

    args = ctx.actions.args()
    args.add("--kotlin_out={}/{}".format(ctx.bin_dir.path, ctx.label.package))

    proto_root = "{}/{}/".format(ctx.label.package, ctx.attr.proto_root)
    args.add("--proto_path={}".format(proto_root))

    # Add all of the proto files to the arguments after the proto_path args
    for src in ctx.files.srcs:
        args.add(src.path.removeprefix(proto_root))

    ctx.actions.run(
        progress_message = "Generating Kotlin grpc files with the Wire compiler",
        executable = ctx.executable._wire,
        arguments = [args],
        inputs = ctx.files.srcs,
        outputs = output_files,
        mnemonic = "WireCompile",
        execution_requirements = {"no-sandbox": "1"},
    )

    return [
        DefaultInfo(files = depset(output_files)),
    ]

wire = rule(
    implementation = _wire_impl,
    attrs = {
        "outputs": attr.string_list(mandatory = True),
        "proto_root": attr.string(mandatory = True),
        "srcs": attr.label_list(mandatory = True, allow_files = True),
        "_wire": attr.label(
            default = "//third_party:wire",
            executable = True,
            cfg = "exec",
        ),
    },
)
