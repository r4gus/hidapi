const std = @import("std");

pub fn build(b: *std.Build) void {
    const use_hidraw_backend = b.option(bool, "hidraw-backend", "Use the hidraw backend on Linux") orelse true;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "hidapi",
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag == .linux) {
        if (use_hidraw_backend) {
            lib.addCSourceFiles(.{ .files = &.{"linux/hid.c"}, .flags = &.{"-std=gnu11"} });
            lib.linkSystemLibrary("libudev");
        } else { // libusb backend
            lib.addCSourceFiles(.{ .files = &.{"libusb/hid.c"}, .flags = &.{"-std=gnu11"} });
            lib.linkSystemLibrary("libusb");
        }
        lib.linkSystemLibrary("pthread");
    } else if (target.result.os.tag == .freebsd) {
        lib.addCSourceFiles(.{ .files = &.{"linux/hid.c"}, .flags = &.{"-std=gnu11"} });
        lib.linkSystemLibrary("libusb");
        lib.linkSystemLibrary("libiconv");
        lib.linkSystemLibrary("pthread");
    } else if (target.result.os.tag == .macos) {
        lib.addCSourceFiles(.{ .files = &.{"mac/hid.c"}, .flags = &.{"-std=gnu11"} });
        lib.linkSystemLibrary("IOKit");
        lib.linkSystemLibrary("CoreFoundation");
        lib.linkSystemLibrary("AppKit");
        lib.linkSystemLibrary("pthread");
    } else if (target.result.os.tag == .windows) {
        lib.addCSourceFiles(.{ .files = &.{"windows/hid.c"}, .flags = &.{"-std=gnu11"} });
        lib.addCSourceFiles(.{ .files = &.{"windows/hidapi_descriptor_reconstruct.c"}, .flags = &.{"-std=gnu11"} });
        lib.addIncludePath(std.Build.LazyPath{ .path = "windows" });
    }

    lib.addIncludePath(std.Build.LazyPath{ .path = "hidapi" });
    lib.linkLibC();

    lib.installHeadersDirectory(
        std.Build.LazyPath{ .path = "hidapi" },
        "hidapi",
        .{
            .exclude_extensions = &.{},
            .include_extensions = &.{".h"},
        },
    );
    b.installArtifact(lib);
}
