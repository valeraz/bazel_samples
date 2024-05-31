load("@rules_android//android:rules.bzl", "android_library")
load("@rules_kotlin//kotlin:android.bzl", rules_kotlin_kt_android_library = "kt_android_library")
load("@rules_kotlin//kotlin:jvm.bzl", rules_kotlin_kt_jvm_library = "kt_jvm_library", rules_kotlin_kt_jvm_test = "kt_jvm_test")

# Allows for easier reading and undersanding of the rules_kotlin rules we're shimming in this macro
rules_kotlin = struct(
    kt_android_library = rules_kotlin_kt_android_library,
    kt_jvm_library = rules_kotlin_kt_jvm_library,
    kt_jvm_test = rules_kotlin_kt_jvm_test,
)

"""# Slack Android macros

Defines a set of thin wrappers around rules_kotlin and rules_android

These macros aid in both leveraging and enforcing consistent patterns used in the
slack-android-ng codebase and Slack for Android. These patterns can both speed
up development, as well as identify and eliminate inconsistencies.

- `srcs` always live at src/**/*.kt
- `visibility` is always ["//visibility:public"]
- `manifest` is set to a placeholder value for android libraries if one is not supplied
- when `srcs` is empty, use `android_library`
"""

def kt_android_library(**kwargs):
    if kwargs.pop("srcs", None):
        _override_warning("srcs", kwargs)

    if kwargs.pop("visibility", None):
        _override_warning("visibility", kwargs)

    kwargs["visibility"] = ["//visibility:public"]

    resources = native.glob(["src/main/res/**"])
    if resources:
        kwargs["resource_files"] = resources

        manifest = native.glob(["src/main/AndroidManifest.xml"])
        if manifest:
            kwargs["manifest"] = "src/main/AndroidManifest.xml"
        else:
            # rules_android requires a manifest when resource_files exist
            # Apply a placeholder.
            kwargs["manifest"] = "//bazel/macros:AndroidManifestPlaceholder.xml"

    srcs, kwargs = _get_srcs(**kwargs)

    if srcs:
        rules_kotlin.kt_android_library(
            srcs = srcs,
            **kwargs
        )
    else:
        android_library(
            srcs = srcs,
            **kwargs
        )

def kt_jvm_library(**kwargs):
    if kwargs.pop("srcs", None):
        _override_warning("srcs", kwargs)

    if kwargs.pop("visibility", None):
        _override_warning("visibility", kwargs)

    srcs, kwargs = _get_srcs(**kwargs)

    rules_kotlin.kt_jvm_library(
        visibility = ["//visibility:public"],
        srcs = srcs,
        **kwargs
    )

def kt_jvm_test(**kwargs):
    if kwargs.pop("srcs", None):
        _override_warning("srcs", kwargs)

    srcs, kwargs = _get_srcs(**kwargs)

    rules_kotlin.kt_jvm_test(
        srcs = srcs,
        **kwargs
    )

def _get_srcs(**kwargs):
    # Slack Android default src location
    srcs = native.glob(
        ["src/main/**/*.{}".format(e) for e in ["kt", "java"]],
    )

    # Grab any module-defined generated sources and source labels
    generated = kwargs.pop("generated_srcs", [])

    # Infer Gradle-derived generated sources
    sqldelight_package = kwargs.pop("sqldelight_hack", False)
    if sqldelight_package:
        sqldelight_db_name = sqldelight_package["db_name"]
        sqldelight_path = sqldelight_package["package"].replace(".", "/")

        generated += native.glob(["build/generated/sqldelight/code/{db}/{path}/**/*.kt".format(db = sqldelight_db_name, path = sqldelight_path)], allow_empty = False)

    return (srcs + generated, kwargs)

# NOTE: Unused after emergency refactor
def _override_warning(attr_name, kwargs):
    print("WARNING: Overriding `{attribute}` attribute for rule {package}:{name}".format(
        attribute = attr_name,
        package = native.package_name(),
        name = kwargs.get("name"),
    ))
