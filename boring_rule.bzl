def _boring_rule(ctx):
    ctx.actions.write(
        output = ctx.outputs.output,
        content = ctx.attr.content,
    )

boring_rule = rule(
    implementation = _boring_rule,
    attrs = {
        "content": attr.string(),
        "output": attr.output(),
    },
)
