load(":multiplatform_transition.bzl", "multiplatform_transition")

def _smart_binary_impl(ctx):
    ctx.actions.write(
        output = ctx.outputs.output,
        content = """#!/bin/sh
echo "We have runfiles for multiple platforms!"
cat ../linux
cat ../darwin
cat ../windows
""",
        is_executable = True,
    )

    default_infos = {
        platform_name: ctx.split_attr.data[platform_name][DefaultInfo]
        for platform_name in ["linux", "darwin", "windows"]
    }
    root_symlinks = {
        platform_name: default_infos[platform_name].files.to_list()[0]
        for platform_name in default_infos
    }

    runfiles = ctx.runfiles(
        root_symlinks = root_symlinks,
    )
    return [
        DefaultInfo(
            files = depset([ctx.outputs.output]),
            runfiles = runfiles,
            executable = ctx.outputs.output,
        )
    ]

smart_binary = rule(
    implementation = _smart_binary_impl,
    attrs = {
        "data": attr.label(allow_files = True, cfg = multiplatform_transition),
        "output": attr.output(),
    },
    executable = True,
)
