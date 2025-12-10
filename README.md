# Bazel runfiles are an approximation

This reproducer shows shortcomings of Bazel runfiles as a lossy representation of data dependencies for binaries.

## First Problem: Split Transitions

Let's say I want to build target `//:my_boring_file` for Linux, macOS, and Windows and add all of them to the runfiles of a binary. I'm using a [split transition](/multiplatform_transition.bzl) for this.

But what the heck?

```
❯ bazel run //:bin_with_data
This is some boring content for Linux!
This is some boring content for Linux!
This is some boring content for Linux!
```

I wanted to print the output I got from my split transition, but this happened.
Since I'm fearless, I look at the runfiles tree and the output base:

```
❯ ls bazel-out/*/bin/boring_output.txt
bazel-out/k8-fastbuild-ST-3d154b188fd7/bin/boring_output.txt  bazel-out/k8-fastbuild-ST-800bba173962/bin/boring_output.txt
bazel-out/k8-fastbuild-ST-576ef9824eaa/bin/boring_output.txt  bazel-out/k8-fastbuild/bin/boring_output.txt

❯ cat bazel-out/k8-fastbuild-ST-3d154b188fd7/bin/boring_output.txt
This is some boring content for Windows!

❯ cat bazel-out/k8-fastbuild/bin/boring_output.txt
This is some boring content for Linux!

❯ ls -l bazel-bin/bin_with_data.sh.runfiles/_main/
total 8
lrwxrwxrwx 1 malte users 129 Dez 10 21:52 bin_with_data.sh -> /home/malte/.cache/bazel/_bazel_malte/5e329a62e2595f8a50c849d35c322c30/execroot/_main/bazel-out/k8-fastbuild/bin/bin_with_data.sh
lrwxrwxrwx 1 malte users 146 Dez 10 21:52 boring_output.txt -> /home/malte/.cache/bazel/_bazel_malte/5e329a62e2595f8a50c849d35c322c30/execroot/_main/bazel-out/k8-fastbuild-ST-800bba173962/bin/boring_output.txt
```

As you can see, this is a limitation of runfiles and `File.short_path`: The runfiles path strips the `BINDIR` part of the output path (like `k8-fastbuild` or `k8-fastbuild-ST-800bba173962`), leading to multiple files using the same runfiles path. One of them wins, the others are silently ignored.

## Runfiles Symlinks to the rescue?

Now you wouldn't give up yet, would you? There's an alternative way to allows us to reference files from different configurations safely (or slightly safer.. more on that later).
If we use [runfiles symlinks](https://bazel.build/extending/rules#runfiles_symlinks) with unique names, we can access the files from the different configurations without problem:

```
❯ bazel run :bin_with_runfiles_symlinks
We have runfiles for multiple platforms!
This is some boring content for Linux!
This is some boring content for macOS!
This is some boring content for Windows!
```

This works because the runfiles symlink are a dict of symlink names to `File`, so we can choose names that do not collide:

```
❯ ls -l bazel-bin/bin_with_runfiles_symlinks.sh.runfiles
total 20
-r-xr-xr-x 1 malte users 811 Dez 10 21:57 MANIFEST
drwxr-xr-x 1 malte users  58 Dez 10 21:57 _main
lrwxrwxrwx 1 malte users 155 Dez 10 21:57 _repo_mapping -> /home/malte/.cache/bazel/_bazel_malte/5e329a62e2595f8a50c849d35c322c30/execroot/_main/bazel-out/k8-fastbuild/bin/bin_with_runfiles_symlinks.sh.repo_mapping
lrwxrwxrwx 1 malte users 146 Dez 10 21:57 darwin -> /home/malte/.cache/bazel/_bazel_malte/5e329a62e2595f8a50c849d35c322c30/execroot/_main/bazel-out/k8-fastbuild-ST-800bba173962/bin/boring_output.txt
lrwxrwxrwx 1 malte users 146 Dez 10 21:57 linux -> /home/malte/.cache/bazel/_bazel_malte/5e329a62e2595f8a50c849d35c322c30/execroot/_main/bazel-out/k8-fastbuild-ST-576ef9824eaa/bin/boring_output.txt
lrwxrwxrwx 1 malte users 146 Dez 10 21:57 windows -> /home/malte/.cache/bazel/_bazel_malte/5e329a62e2595f8a50c849d35c322c30/execroot/_main/bazel-out/k8-fastbuild-ST-3d154b188fd7/bin/boring_output.txt
```

## The limits of runfiles symlinks: runfiles merging

Let's say a user combines the runfiles of two different binaries that use the same runfiles symlinks.
Internally, Bazel has to merge the two symlink dicts and we have a new problem.
When merging runfiles symlinks, Bazel happily corrupts our runfiles tree by giving us one set of symlinks while silently dropping the other (if both use the same names). Merging runfiles with symlinks is an inherently lossy operation.

This is easily demonstrated using multirun:

```
❯ bazel run //:run_all
Running @@//:content_command
We have runfiles for multiple platforms!
I'm a penguin!
I'm a mac!
I'm a PC!
Running @@//:greeting_command
We have runfiles for multiple platforms!
I'm a penguin!
I'm a mac!
I'm a PC!
```
