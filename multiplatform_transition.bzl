def _multiplatform_transition(_settings, _attr):
    return {
        "linux": {"//command_line_option:platforms": "//platform:linux_amd64"},
        "darwin": {"//command_line_option:platforms": "//platform:darwin_arm64"},
        "windows": {"//command_line_option:platforms": "//platform:windows_amd64"},
    }

multiplatform_transition = transition(
    implementation = _multiplatform_transition,
    inputs = [],
    outputs = ["//command_line_option:platforms"],
)
