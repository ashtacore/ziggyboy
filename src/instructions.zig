const std = @import("std");
const cpuLib = @import("cpu.zig");
const Cpu = cpuLib.Cpu;
const Flag = cpuLib.Flag;
const EightBitRegister = cpuLib.EightBitRegister;
const SixteenBitRegister = cpuLib.SixteenBitRegister;

pub const Instruction = struct {
    mnemonic: []const u8,
    cycles: u3,
    handler: fn (*Cpu) void,

    pub fn Execute(self: *Instruction, cpu: *Cpu) void {
        self.handler(cpu);
        cpu.IncrementProgramCounter(self.cycles);
    }
};

pub const instruction_table: [256]Instruction = blk: {
    var table: [256]Instruction = undefined;

    for (table) |*instruc| {
        instruc.* = Instruction{
            .mnemonic = "UNIMPLEMENTED",
            .cycles = 0,
            .handler = default_unimplemented,
        };
    }

    table[0x00] = Instruction{ .mnemonic = "NOP", .cycles = 1, .handler = nop };

    break :blk table;
};

fn default_unimplemented(_: *Cpu) void {
    @panic("Unimplemented instruction");
}

fn nop(_: *Cpu) void {
    std.debug.print("No Op\n");
}
