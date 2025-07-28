const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ziggyboy",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    // Run Step
    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the emulator");
    run_step.dependOn(&run_cmd.step);

    //// Tests
    // CPU-specific tests
    const cpu_tests = b.addTest(.{
        .root_source_file = b.path("src/cpu.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_cpu_tests = b.addRunArtifact(cpu_tests);
    const cpu_test_step = b.step("test-cpu", "Run CPU unit tests");
    cpu_test_step.dependOn(&run_cpu_tests.step);

    // Instructions-specific tests
    const instructions_tests = b.addTest(.{
        .root_source_file = b.path("src/instructions.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_instructions_tests = b.addRunArtifact(instructions_tests);
    const instructions_test_step = b.step("test-instructions", "Run instructions unit tests");
    instructions_test_step.dependOn(&run_instructions_tests.step);

    // All tests
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_cpu_tests.step);
    test_step.dependOn(&run_instructions_tests.step);
}
