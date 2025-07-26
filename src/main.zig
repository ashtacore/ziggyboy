const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;
const Flag = @import("cpu.zig").Flag;

pub fn main() !void {
    var cpu = Cpu{};

    std.debug.print("AF: {b:16}\n", .{cpu.AF});
    cpu.SetFlag(Flag.HalfCarry, 1);
    std.debug.print("AF: {b:16}\n", .{cpu.AF});
    cpu.SetFlag(Flag.Subrataction, 1);
    std.debug.print("AF: {b:16}\n", .{cpu.AF});
    cpu.SetFlag(Flag.Carry, 1);
    std.debug.print("AF: {b:16}\n", .{cpu.AF});
    cpu.SetFlag(Flag.Zero, 1);
    std.debug.print("AF: {b:16}\n", .{cpu.AF});
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
