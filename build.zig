const std = @import("std");

pub fn build(b: *std.Build) void {
    const use_hidraw_backend = b.option(bool, "hidraw-backend", "Use the hidraw backend on Linux") orelse true;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag == .linux) {
        if (use_hidraw_backend) {
            lib_mod.addCSourceFiles(.{ .files = &.{"linux/hid.c"}, .flags = &.{"-std=gnu11"} });
            lib_mod.linkSystemLibrary("udev", .{});
        } else { // libusb backend
            lib_mod.addCSourceFiles(.{ .files = &.{"libusb/hid.c"}, .flags = &.{"-std=gnu11"} });
            lib_mod.linkSystemLibrary("libusb", .{});
        }
        lib_mod.linkSystemLibrary("pthread", .{});
    } else if (target.result.os.tag == .freebsd) {
        lib_mod.addCSourceFiles(.{ .files = &.{"linux/hid.c"}, .flags = &.{"-std=gnu11"} });
        lib_mod.linkSystemLibrary("libusb", .{});
        lib_mod.linkSystemLibrary("libiconv", .{});
        lib_mod.linkSystemLibrary("pthread", .{});
    } else if (target.result.os.tag == .macos) {
        lib_mod.addCSourceFiles(.{ .files = &.{"mac/hid.c"}, .flags = &.{"-std=gnu11"} });
        lib_mod.linkSystemLibrary("IOKit", .{});
        lib_mod.linkSystemLibrary("CoreFoundation", .{});
        lib_mod.linkSystemLibrary("AppKit", .{});
        lib_mod.linkSystemLibrary("pthread", .{});
    } else if (target.result.os.tag == .windows) {
        lib_mod.addCSourceFiles(.{ .files = &.{"windows/hid.c"}, .flags = &.{"-std=gnu11"} });
        lib_mod.addCSourceFiles(.{ .files = &.{"windows/hidapi_descriptor_reconstruct.c"}, .flags = &.{"-std=gnu11"} });
        lib_mod.addIncludePath(b.path("windows"));
    }

    lib_mod.addIncludePath(b.path("hidapi"));

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "hidapi",
        .root_module = lib_mod,
    });

    lib.linkLibC();
    lib.installHeader(b.path("hidapi/hidapi.h"), "hidapi.h");

    b.installArtifact(lib);
}
