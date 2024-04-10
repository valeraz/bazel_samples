def _wire_impl(ctx):
    # We don't know the output files at analyis time, so decalre a directory
    output_dir = ctx.actions.declare_directory("generated_proto_kotlin_srcs")

    args = ctx.actions.args()
    args.add("--kotlin_out={}".format(output_dir.path))

    # This first . proto path help wire "see" the files relative to the CWD
    # when run. i.e. the relative paths look like:
    #     libraries/telemetry-definitions/src/main/proto/foo.proto
    # where the CWD is the directory 'libraries' exists.
    args.add("--proto_path=.")
    for proto_path in depset([src.dirname for src in ctx.files.srcs]).to_list():
        # To help with the relative-to-proto-files import statements,
        # we also need to pass every directory name of every proto file that
        # is passed into this rule
        args.add("--proto_path=./{}".format(proto_path))

    # Add all of the proto files to the arguments after the proto_path args
    for src in ctx.files.srcs:
        args.add(src.path)

    ctx.actions.run(
        progress_message = "Generating Kotlin grpc files with the Wire compiler",
        executable = ctx.executable._wire,
        arguments = [args],
        inputs = ctx.files.srcs,
        outputs = [output_dir],
        mnemonic = "WireCompile",
        execution_requirements = {"no-sandbox": "1"},
    )

    return [
        DefaultInfo(files = depset([output_dir])),
    ]

wire = rule(
    implementation = _wire_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "_wire": attr.label(
            default = "//third_party:wire",
            executable = True,
            cfg = "exec",
        ),
    },
)
