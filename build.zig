// © 2026 Antonio Caggiano
// SPDX-License-Identifier: MIT

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vma = b.dependency("vma", .{});
    const vulkan_headers = b.dependency("vulkan_headers", .{});

    const vma_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    vma_mod.addCSourceFile(.{ .file = b.path("src/vma-impl.cpp"), .flags = &.{"-std=c++17"} });
    vma_mod.addIncludePath(vma.path("include"));
    vma_mod.addIncludePath(vulkan_headers.path("include"));

    const lib = b.addLibrary(.{
        .name = "vma",
        .linkage = .static,
        .root_module = vma_mod,
    });
    b.installArtifact(lib);

    const mod = b.addModule("zvma", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });
    mod.linkLibrary(lib);
    mod.addIncludePath(vma.path("include"));
    mod.addIncludePath(vulkan_headers.path("include"));

    const tests = b.addTest(.{ .root_module = mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
