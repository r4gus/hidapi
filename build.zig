const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const use_hidraw_backend = b.option(bool, "hidraw-backend", "Use the hidraw backend on Linux") orelse true;

    const lib = b.addStaticLibrary(.{
        .name = "hidapi",
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    if (lib.target.isLinux()) {
        if (use_hidraw_backend) {
            lib.addCSourceFiles(&.{"linux/hid.c"}, &.{"-std=gnu11"});
            lib.linkSystemLibrary("libudev");
        } else { // libusb backend
            lib.addCSourceFiles(&.{"libusb/hid.c"}, &.{"-std=gnu11"});
            lib.linkSystemLibrary("libusb");
        }
        lib.linkSystemLibrary("pthread");
    } else if (lib.target.isFreeBSD()) {
        lib.addCSourceFiles(&.{"linux/hid.c"}, &.{"-std=gnu11"});
        lib.linkSystemLibrary("libusb");
        lib.linkSystemLibrary("libiconv");
        lib.linkSystemLibrary("pthread");
    } else if (lib.target.isDarwin()) {
        lib.addCSourceFiles(&.{"mac/hid.c"}, &.{"-std=gnu11"});
        lib.linkSystemLibrary("IOKit");
        lib.linkSystemLibrary("CoreFoundation");
        lib.linkSystemLibrary("AppKit");
        lib.linkSystemLibrary("pthread");
    } else if (lib.target.isWindows()) {
        lib.addCSourceFiles(&.{"windows/hid.c"}, &.{"-std=gnu11"});
        lib.addCSourceFiles(&.{"windows/hidapi_descriptor_reconstruct.c"}, &.{"-std=gnu11"});
        lib.addIncludePath(std.build.LazyPath{ .path = "windows" });
    }

    lib.addIncludePath(std.build.LazyPath{ .path = "hidapi" });
    lib.linkLibC();

    b.installArtifact(lib);
    lib.installHeadersDirectoryOptions(.{
        .source_dir = std.Build.LazyPath{ .path = "hidapi" },
        .install_dir = .header,
        .install_subdir = "hidapi",
        .exclude_extensions = &.{".c"},
    });
}
