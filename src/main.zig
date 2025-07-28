const std = @import("std");
const cpuLib = @import("cpu.zig");
const instrLib = @import("instructions.zig");
const Cpu = cpuLib.Cpu;
const EightBitRegister = cpuLib.EightBitRegister;
const Flag = cpuLib.Flag;

pub fn main() !void {
    var cpu = Cpu{};

    cpu.SetEightBitRegister(EightBitRegister.A, 0xFB);
    cpu.SetEightBitRegister(EightBitRegister.C, 0xFB);
    std.debug.print("AF: {b:16}\n", .{cpu.AF});
    std.debug.print("BC: {b:16}\n", .{cpu.BC});
    std.debug.print("PC: {b:16}\n", .{cpu.PC});

    const instr = instrLib.instruction_table[0o201];
    instr.Execute(&cpu);
    std.debug.print("AF: {b:16}\n", .{cpu.AF});
    std.debug.print("BC: {b:16}\n", .{cpu.BC});
    std.debug.print("PC: {b:16}\n", .{cpu.PC});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
