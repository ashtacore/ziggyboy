const std = @import("std");
const cpuLib = @import("cpu.zig");
const InstructionTable = @import("instructions/instruction_table.zig").InstructionTable;
const Cpu = cpuLib.Cpu;
const EightBitRegister = cpuLib.EightBitRegister;
const Flag = cpuLib.Flag;

pub fn main() !void {
    var cpu = Cpu{};

    cpu.SetEightBitRegister(EightBitRegister.A, 0xFB);
    cpu.SetEightBitRegister(EightBitRegister.C, 0xFB);
    std.debug.print("A: {b:8}\n", .{cpu.GetEightBitRegister(.A)});
    std.debug.print("C: {b:8}\n", .{cpu.GetEightBitRegister(.C)});
    std.debug.print("F: {b:8}\n", .{cpu.GetEightBitRegister(.F)});
    std.debug.print("PC: {b:16}\n", .{cpu.PC});

    const instr = InstructionTable[0o201];
    instr.Execute(&cpu);
    std.debug.print("A: {b:8}\n", .{cpu.GetEightBitRegister(.A)});
    std.debug.print("C: {b:8}\n", .{cpu.GetEightBitRegister(.C)});
    std.debug.print("F: {b:8}\n", .{cpu.GetEightBitRegister(.F)});
    std.debug.print("PC: {b:16}\n", .{cpu.PC});

    const little: u4 = 0b1000;
    var big: u8 = 0;
    big = little;
    std.debug.print("test: {b:8}\n", .{big});
    big = @as(u8, little) << 4;
    std.debug.print("test: {b:8}\n", .{big});
}
