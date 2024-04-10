Points to a local build of android_tools from Ben's fork https://github.com/Bencodes/bazel/commits/blee/fork/8.0.0-pre.20240303.2
Built at commit: da7dd5a2e3031112d59246b908a5120a05ddee00
Build bazel build //tools/android/runtime_deps:android_tools --experimental_cc_shared_library
Extract the jar from bazel-bin/tools/android/runtime_deps/android_tools.tar