load(":multiplatform_transition.bzl", "multiplatform_transition")

def _conflict_free_symlinks_binary_impl(ctx):
    default_infos = {
        platform_name: ctx.split_attr.data[platform_name][DefaultInfo]
        for platform_name in ["linux", "darwin", "windows"]
    }
    files = [
        default_infos[platform_name].files.to_list()[0]
        for platform_name in default_infos
    ]

    # Blursed:
    # Each file gets its own unique symlink path, so there are no conflicts.
    # When "bazel run"'ing this binary, we start from the "foo.runfiles/_main" directory,
    # so just using "File.path" happens to match up with the runfiles symlink structure.
    symlinks = {
        file.path: file
        for file in files
    }
    ctx.actions.write(
        output = ctx.outputs.output,
        content = """#!/bin/sh
echo "We have conflict-free runfiles for multiple platforms!"
set -x
""" + "\n".join(
            [
                "cat {}".format(p)
                for p in symlinks.keys()
            ]
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        symlinks = symlinks,
    )
    return [
        DefaultInfo(
            files = depset([ctx.outputs.output]),
            runfiles = runfiles,
            executable = ctx.outputs.output,
        )
    ]

conflict_free_symlinks_binary = rule(
    implementation = _conflict_free_symlinks_binary_impl,
    attrs = {
        "data": attr.label(allow_files = True, cfg = multiplatform_transition),
        "output": attr.output(),
    },
    executable = True,
)
