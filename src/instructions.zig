const std = @import("std");
const cpuLib = @import("cpu.zig");
const Cpu = cpuLib.Cpu;
const Flag = cpuLib.Flag;
const EightBitRegister = cpuLib.EightBitRegister;
const SixteenBitRegister = cpuLib.SixteenBitRegister;
const Register = cpuLib.Register;

pub const Instruction = struct {
    mnemonic: []const u8,
    cycles: u3,
    conditionalCycles: u3 = 0, // Extra cycles for successful conditional operations
    length: u2, // Byte length of instruction
    instructionType: InstructionType,
    operationType: ?OperationType = null,
    destinationRegister: ?Register = null,
    sourceRegister: ?Register = null,

    pub fn Execute(self: *Instruction, cpu: *Cpu) void {
        switch (self.instructionType) {
            .Nop => std.debug.print("No Op\n"),
            .Invalid => @panic("Unimplemented instruction"),
            .Jump => {},
            else => {
                switch (self.operationType) {
                    .Add => self.Add(self, cpu),
                    else => @panic("Unimplemented instruction"),
                }
            },
        }

        cpu.IncrementProgramCounter(self.cycles);
    }

    fn Add(self: *Instruction, cpu: *Cpu) void {
        switch (self.destinationRegister) {
            .eightBitRegister => |destinationRegister| {
                const sourceValue = switch (self.sourceRegister) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.LoadFromRegisterPointer(sourceRegister),
                    else => if (self.length == 2) cpu.PopStack() else 1,
                };

                cpu.IncrementEightBitRegister(destinationRegister, sourceValue);
            },
            .sixteenBitRegister => |destinationRegister| {
                const sourceValue = switch (self.sourceRegister) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.GetSixteenBitRegister(sourceRegister),
                    else => if (self.length == 2) cpu.PopStack() else 1,
                };

                cpu.IncrementSixteenBitRegister(destinationRegister, sourceValue);
            },
        }
    }

    fn Load(self: *Instruction, cpu: *Cpu) void {
        switch (self.destinationRegister) {
            .eightBitRegister => |destinationRegister| {
                const sourceValue = switch (self.sourceRegister) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.LoadFromRegisterPointer(sourceRegister),
                    else => @panic("Unimplemented load operation"),
                };

                cpu.SetEightBitRegister(destinationRegister, sourceValue);
            },
            .sixteenBitRegister => |destinationRegister| {
                const sourceValue = switch (self.sourceRegister) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.GetSixteenBitRegister(sourceRegister),
                    else => @panic("Unimplemented load operation"),
                };

                cpu.SetSixteenBitRegister(destinationRegister, sourceValue);
            },
        }
    }
};

const InstructionType = enum { Register, Immediate, Jump, Nop, Invalid };
const OperationType = enum { Add, Load };

pub const instruction_table: [256]Instruction = blk: {
    var table: [256]Instruction = undefined;

    for (&table) |*instruc| {
        instruc.* = Instruction{
            .mnemonic = "UNIMPLEMENTED",
            .cycles = 0,
            .length = 1,
            .instructionType = .Invalid,
        };
    }

    table[0o00] = Instruction{ .mnemonic = "NOP", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o00] = Instruction{ .mnemonic = "STOP", .cycles = 1, .length = 2, .instructionType = .Nop };

    table[0o100] = Instruction{ .mnemonic = "LD B, B", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o101] = Instruction{ .mnemonic = "LD B, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .sourceRegister = .{ .eightBitRegister = .C } };
    table[0o101] = Instruction{ .mnemonic = "LD B, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .sourceRegister = .{ .eightBitRegister = .D } };
    table[0o101] = Instruction{ .mnemonic = "LD B, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .sourceRegister = .{ .eightBitRegister = .E } };
    table[0o101] = Instruction{ .mnemonic = "LD B, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .sourceRegister = .{ .eightBitRegister = .H } };
    table[0o101] = Instruction{ .mnemonic = "LD B, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .sourceRegister = .{ .eightBitRegister = .L } };
    table[0o101] = Instruction{ .mnemonic = "LD B, HL", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .sourceRegister = .{ .sixteenBitRegister = .HL } };
    table[0o101] = Instruction{ .mnemonic = "LD B, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .sourceRegister = .{ .eightBitRegister = .A } };

    table[0o200] = Instruction{ .mnemonic = "ADD A, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .eightBitRegister = .B } };
    table[0o201] = Instruction{ .mnemonic = "ADD A, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .eightBitRegister = .C } };
    table[0o202] = Instruction{ .mnemonic = "ADD A, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .eightBitRegister = .D } };
    table[0o203] = Instruction{ .mnemonic = "ADD A, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .eightBitRegister = .E } };
    table[0o204] = Instruction{ .mnemonic = "ADD A, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .eightBitRegister = .H } };
    table[0o205] = Instruction{ .mnemonic = "ADD A, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .eightBitRegister = .L } };
    table[0o206] = Instruction{ .mnemonic = "ADD A, HL", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .sixteenBitRegister = .HL } };
    table[0o207] = Instruction{ .mnemonic = "ADD A, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .sourceRegister = .{ .eightBitRegister = .A } };

    break :blk table;
};
