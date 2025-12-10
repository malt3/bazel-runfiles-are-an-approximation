load(":multiplatform_transition.bzl", "multiplatform_transition")

def _naive_binary_impl(ctx):
    paths_of_runfiles = [f.short_path for f in ctx.files.data]
    ctx.actions.write(
        output = ctx.outputs.output,
        content = """#!/bin/sh
cat {}
""".format(" ".join(paths_of_runfiles)),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = ctx.files.data,
    )
    return [
        DefaultInfo(
            files = depset([ctx.outputs.output]),
            runfiles = runfiles,
            executable = ctx.outputs.output,
        )
    ]

naive_binary = rule(
    implementation = _naive_binary_impl,
    attrs = {
        "data": attr.label(allow_files = True, cfg = multiplatform_transition),
        "output": attr.output(),
    },
    executable = True,
)
