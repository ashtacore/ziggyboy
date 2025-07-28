const std = @import("std");
const cpuLib = @import("cpu.zig");
const Cpu = cpuLib.Cpu;
const Flag = cpuLib.Flag;
const EightBitRegister = cpuLib.EightBitRegister;
const SixteenBitRegister = cpuLib.SixteenBitRegister;

pub const Instruction = struct {
    mnemonic: []const u8,
    cycles: u3,
    conditionalCycles: u3 = 0, // Extra cycles for successful conditional operations
    length: u2, // Byte length of instruction
    instructionType: InstructionType,
    operationType: ?OperationType = null,
    destinationRegister: ?Register = null,
    source: ?Source = null,

    pub fn Execute(self: *const Instruction, cpu: *Cpu) void {
        switch (self.instructionType) {
            .Nop => std.debug.print("No Op\n", .{}),
            .Invalid => @panic("Unimplemented instruction"),
            .Jump => {},
            else => {
                if (self.operationType == null) {
                    @panic("Register and immediate instructions must include an operationType");
                }

                switch (self.operationType.?) {
                    .Add => self.Add(cpu),
                    .Load => self.Load(cpu),
                    //else => @panic("Unimplemented operation"),
                }
            },
        }

        cpu.IncrementSixteenBitRegister(.ProgramCounter, self.cycles);
    }

    fn Add(self: *const Instruction, cpu: *Cpu) void {
        if (self.destinationRegister == null) {
            @panic("Add operations require destination register");
        }
        if (self.source == null) {
            @panic("Add operations require source");
        }

        switch (self.destinationRegister.?) {
            .eightBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.LoadFromRegisterPointer(sourceRegister),
                    else => if (self.length == 2) cpu.PopStack() else 1,
                };

                cpu.IncrementEightBitRegister(destinationRegister, sourceValue);
            },
            .sixteenBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.GetSixteenBitRegister(sourceRegister),
                    else => if (self.length == 2) cpu.PopStack() else 1,
                };

                cpu.IncrementSixteenBitRegister(destinationRegister, sourceValue);
            },
        }
    }

    fn Load(self: *const Instruction, cpu: *Cpu) void {
        if (self.destinationRegister == null) {
            @panic("Load operations require destination register");
        }
        if (self.source == null) {
            @panic("Load operations require source");
        }

        switch (self.destinationRegister.?) {
            .eightBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.LoadFromRegisterPointer(sourceRegister),
                    else => @panic("Unimplemented load operation"),
                };

                cpu.SetEightBitRegister(destinationRegister, sourceValue);
            },
            .sixteenBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
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

pub const Register = union(enum) { eightBitRegister: EightBitRegister, sixteenBitRegister: SixteenBitRegister };
pub const Source = union(enum) { eightBitRegister: EightBitRegister, sixteenBitRegister: SixteenBitRegister, immediate: u8 };

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
    table[0o101] = Instruction{ .mnemonic = "LD B, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .C } };
    table[0o101] = Instruction{ .mnemonic = "LD B, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .D } };
    table[0o101] = Instruction{ .mnemonic = "LD B, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .E } };
    table[0o101] = Instruction{ .mnemonic = "LD B, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .H } };
    table[0o101] = Instruction{ .mnemonic = "LD B, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .L } };
    table[0o101] = Instruction{ .mnemonic = "LD B, HL", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o101] = Instruction{ .mnemonic = "LD B, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .A } };

    table[0o200] = Instruction{ .mnemonic = "ADD A, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o201] = Instruction{ .mnemonic = "ADD A, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o202] = Instruction{ .mnemonic = "ADD A, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o203] = Instruction{ .mnemonic = "ADD A, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o204] = Instruction{ .mnemonic = "ADD A, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o205] = Instruction{ .mnemonic = "ADD A, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o206] = Instruction{ .mnemonic = "ADD A, HL", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o207] = Instruction{ .mnemonic = "ADD A, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    break :blk table;
};
