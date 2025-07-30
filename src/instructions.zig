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
            .Register, .Immediate => {
                if (self.operationType == null) {
                    @panic("Register and immediate instructions must include an operationType");
                }

                switch (self.operationType.?) {
                    .Adc, .Add, .Cp, .Dec, .Inc, .Sbc, .Sub => self.Arithmetic(cpu),
                    .Load => self.Load(cpu),
                    //else => @panic("Unimplemented operation"),
                }
            },
        }

        cpu.IncrementSixteenBitRegister(.ProgramCounter, self.cycles);
    }

    fn Arithmetic(self: *const Instruction, cpu: *Cpu) void {
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
                    .immediate => |immediateValue| if (self.length == 2) cpu.PopStack() else immediateValue,
                };

                // In an ADC / SBC operation we include the value of the carry flag in the operation
                const modifiedValue = switch (self.operationType.?) {
                    .Adc, .Sbc => sourceValue + @intFromBool(cpu.GetFlag(Flag.Carry)),
                    else => sourceValue,
                };

                switch (self.operationType.?) {
                    .Adc, .Add, .Inc => cpu.IncrementEightBitRegister(destinationRegister, modifiedValue),
                    .Sbc, .Sub, .Dec => cpu.DecrementEightBitRegister(destinationRegister, modifiedValue),
                    // A compare function sets the flags as if it's doing a subtract operation, but doesn't actually modify the register
                    // To keep things simple we're going to run the increment function to set the flags, then force the register back to the original value
                    .Cp => {
                        const originalValue = cpu.GetEightBitRegister(destinationRegister);
                        cpu.DecrementEightBitRegister(destinationRegister, modifiedValue);
                        cpu.SetEightBitRegister(destinationRegister, originalValue);
                    },
                    else => @panic("Non-arithmatic operation routed to arithmetic function"),
                }
            },
            .sixteenBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.GetSixteenBitRegister(sourceRegister),
                    .immediate => |immediateValue| if (self.length == 2) cpu.PopStack() else immediateValue,
                };

                // In an ADC / SBC operation we include the value of the carry flag in the operation
                const modifiedValue = switch (self.operationType.?) {
                    .Adc, .Sbc => sourceValue + @intFromBool(cpu.GetFlag(Flag.Carry)),
                    else => sourceValue,
                };

                switch (self.operationType.?) {
                    .Adc, .Add, .Inc => cpu.IncrementSixteenBitRegister(destinationRegister, modifiedValue),
                    .Sbc, .Sub, .Dec => cpu.DecrementSixteenBitRegister(destinationRegister, modifiedValue),
                    // A compare function sets the flags as if it's doing a subtract operation, but doesn't actually modify the register
                    // To keep things simple we're going to run the increment function to set the flags, then force the register back to the original value
                    .Cp => {
                        const originalValue = cpu.GetSixteenBitRegister(destinationRegister);
                        cpu.DecrementSixteenBitRegister(destinationRegister, modifiedValue);
                        cpu.SetSixteenBitRegister(destinationRegister, originalValue);
                    },
                    else => @panic("Non-arithmatic operation routed to arithmetic function"),
                }
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
const OperationType = enum { Adc, Add, Cp, Dec, Inc, Sbc, Sub, Load };

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
    table[0o20] = Instruction{ .mnemonic = "STOP", .cycles = 1, .length = 2, .instructionType = .Nop };
    table[0o166] = Instruction{ .mnemonic = "HALT", .cycles = 1, .length = 1, .instructionType = .Nop };

    //// LOAD Instructions
    table[0o100] = Instruction{ .mnemonic = "LD B, B", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o101] = Instruction{ .mnemonic = "LD B, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .C } };
    table[0o102] = Instruction{ .mnemonic = "LD B, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .D } };
    table[0o103] = Instruction{ .mnemonic = "LD B, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .E } };
    table[0o104] = Instruction{ .mnemonic = "LD B, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .H } };
    table[0o105] = Instruction{ .mnemonic = "LD B, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .L } };
    table[0o106] = Instruction{ .mnemonic = "LD B, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o107] = Instruction{ .mnemonic = "LD B, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .A } };

    table[0o110] = Instruction{ .mnemonic = "LD C, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .B } };
    table[0o111] = Instruction{ .mnemonic = "LD C, C", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o112] = Instruction{ .mnemonic = "LD C, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .D } };
    table[0o113] = Instruction{ .mnemonic = "LD C, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .E } };
    table[0o114] = Instruction{ .mnemonic = "LD C, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .H } };
    table[0o115] = Instruction{ .mnemonic = "LD C, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .L } };
    table[0o116] = Instruction{ .mnemonic = "LD C, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .C }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o117] = Instruction{ .mnemonic = "LD C, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .A } };

    table[0o120] = Instruction{ .mnemonic = "LD D, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .B } };
    table[0o121] = Instruction{ .mnemonic = "LD D, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .C } };
    table[0o122] = Instruction{ .mnemonic = "LD D, D", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o123] = Instruction{ .mnemonic = "LD D, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .E } };
    table[0o124] = Instruction{ .mnemonic = "LD D, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .H } };
    table[0o125] = Instruction{ .mnemonic = "LD D, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .L } };
    table[0o126] = Instruction{ .mnemonic = "LD D, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .D }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o127] = Instruction{ .mnemonic = "LD D, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .A } };

    table[0o130] = Instruction{ .mnemonic = "LD E, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .B } };
    table[0o131] = Instruction{ .mnemonic = "LD E, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .C } };
    table[0o132] = Instruction{ .mnemonic = "LD E, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .D } };
    table[0o133] = Instruction{ .mnemonic = "LD E, E", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o134] = Instruction{ .mnemonic = "LD E, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .H } };
    table[0o135] = Instruction{ .mnemonic = "LD E, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .L } };
    table[0o136] = Instruction{ .mnemonic = "LD E, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .E }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o137] = Instruction{ .mnemonic = "LD E, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .A } };

    table[0o140] = Instruction{ .mnemonic = "LD H, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .B } };
    table[0o141] = Instruction{ .mnemonic = "LD H, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .C } };
    table[0o142] = Instruction{ .mnemonic = "LD H, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .D } };
    table[0o143] = Instruction{ .mnemonic = "LD H, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .E } };
    table[0o144] = Instruction{ .mnemonic = "LD H, H", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o145] = Instruction{ .mnemonic = "LD H, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .L } };
    table[0o146] = Instruction{ .mnemonic = "LD H, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .H }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o147] = Instruction{ .mnemonic = "LD H, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .A } };

    table[0o150] = Instruction{ .mnemonic = "LD L, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .B } };
    table[0o151] = Instruction{ .mnemonic = "LD L, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .C } };
    table[0o152] = Instruction{ .mnemonic = "LD L, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .D } };
    table[0o153] = Instruction{ .mnemonic = "LD L, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .E } };
    table[0o154] = Instruction{ .mnemonic = "LD L, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .H } };
    table[0o155] = Instruction{ .mnemonic = "LD L, L", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o156] = Instruction{ .mnemonic = "LD L, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .L }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o157] = Instruction{ .mnemonic = "LD L, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .A } };

    table[0o160] = Instruction{ .mnemonic = "LD [HL], B", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .sixteenBitRegister = .HL }, .source = .{ .eightBitRegister = .B } };
    table[0o161] = Instruction{ .mnemonic = "LD [HL], C", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .sixteenBitRegister = .HL }, .source = .{ .eightBitRegister = .C } };
    table[0o162] = Instruction{ .mnemonic = "LD [HL], D", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .sixteenBitRegister = .HL }, .source = .{ .eightBitRegister = .D } };
    table[0o163] = Instruction{ .mnemonic = "LD [HL], E", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .sixteenBitRegister = .HL }, .source = .{ .eightBitRegister = .E } };
    table[0o164] = Instruction{ .mnemonic = "LD [HL], H", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .sixteenBitRegister = .HL }, .source = .{ .eightBitRegister = .H } };
    table[0o165] = Instruction{ .mnemonic = "LD [HL], L", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .sixteenBitRegister = .HL }, .source = .{ .eightBitRegister = .L } };
    table[0o167] = Instruction{ .mnemonic = "LD [HL], A", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .sixteenBitRegister = .HL }, .source = .{ .eightBitRegister = .A } };

    table[0o170] = Instruction{ .mnemonic = "LD A, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o171] = Instruction{ .mnemonic = "LD A, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o172] = Instruction{ .mnemonic = "LD A, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o173] = Instruction{ .mnemonic = "LD A, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o174] = Instruction{ .mnemonic = "LD A, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o175] = Instruction{ .mnemonic = "LD A, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o176] = Instruction{ .mnemonic = "LD A, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o177] = Instruction{ .mnemonic = "LD A, A", .cycles = 1, .length = 1, .instructionType = .Nop };

    //// ADD Instructions
    table[0o200] = Instruction{ .mnemonic = "ADD A, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o201] = Instruction{ .mnemonic = "ADD A, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o202] = Instruction{ .mnemonic = "ADD A, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o203] = Instruction{ .mnemonic = "ADD A, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o204] = Instruction{ .mnemonic = "ADD A, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o205] = Instruction{ .mnemonic = "ADD A, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o206] = Instruction{ .mnemonic = "ADD A, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o207] = Instruction{ .mnemonic = "ADD A, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Add, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o210] = Instruction{ .mnemonic = "ADC A, B", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o211] = Instruction{ .mnemonic = "ADC A, C", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o212] = Instruction{ .mnemonic = "ADC A, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o213] = Instruction{ .mnemonic = "ADC A, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o214] = Instruction{ .mnemonic = "ADC A, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o215] = Instruction{ .mnemonic = "ADC A, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o216] = Instruction{ .mnemonic = "ADC A, HL", .cycles = 2, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o217] = Instruction{ .mnemonic = "ADC A, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Adc, .destinationRegister = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    break :blk table;
};

// Unit Tests
const testing = std.testing;

test "Execute NOP instruction (0o00)" {
    var cpu = Cpu{};
    const nop_instruction = instruction_table[0o00];

    // Set initial CPU state
    cpu.PC = 0x100;
    const initial_pc = cpu.PC;

    // Execute NOP instruction
    nop_instruction.Execute(&cpu);

    // NOP should only increment PC by the instruction length (1 byte) and cycles (1)
    try testing.expect(cpu.PC == initial_pc + nop_instruction.cycles);

    // All other registers should remain unchanged
    try testing.expect(cpu.AF == 0);
    try testing.expect(cpu.BC == 0);
    try testing.expect(cpu.DE == 0);
    try testing.expect(cpu.HL == 0);
    try testing.expect(cpu.SP == 0);
}

test "Execute LD B, A instruction (0o107)" {
    var cpu = Cpu{};
    const ld_instruction = instruction_table[0o107];

    // Set initial CPU state
    cpu.SetEightBitRegister(.A, 0x42);
    cpu.SetEightBitRegister(.B, 0x00);
    cpu.PC = 0x100;
    const initial_pc = cpu.PC;

    // Execute LD B, A instruction
    ld_instruction.Execute(&cpu);

    // B register should now contain the value from A register
    try testing.expect(cpu.GetEightBitRegister(.B) == 0x42);
    try testing.expect(cpu.GetEightBitRegister(.A) == 0x42); // A should be unchanged

    // PC should be incremented by cycles (1)
    try testing.expect(cpu.PC == initial_pc + ld_instruction.cycles);

    // Test with different values
    cpu.SetEightBitRegister(.A, 0xFF);
    cpu.SetEightBitRegister(.B, 0x00);
    cpu.PC = 0x200;
    const initial_pc2 = cpu.PC;

    ld_instruction.Execute(&cpu);

    try testing.expect(cpu.GetEightBitRegister(.B) == 0xFF);
    try testing.expect(cpu.GetEightBitRegister(.A) == 0xFF);
    try testing.expect(cpu.PC == initial_pc2 + ld_instruction.cycles);
}

test "Execute ADD A, C instruction (0o201)" {
    var cpu = Cpu{};
    const add_instruction = instruction_table[0o201];

    // Test case 1: Normal addition without overflow
    cpu.SetEightBitRegister(.A, 0x10);
    cpu.SetEightBitRegister(.C, 0x20);
    cpu.PC = 0x100;
    const initial_pc = cpu.PC;

    // Execute ADD A, C instruction
    add_instruction.Execute(&cpu);

    // A register should contain the sum
    try testing.expect(cpu.GetEightBitRegister(.A) == 0x30);
    try testing.expect(cpu.GetEightBitRegister(.C) == 0x20); // C should be unchanged

    // PC should be incremented by cycles (1)
    try testing.expect(cpu.PC == initial_pc + add_instruction.cycles);

    // Test case 2: Addition with overflow
    cpu.SetEightBitRegister(.A, 0xFF);
    cpu.SetEightBitRegister(.C, 0x01);
    cpu.PC = 0x200;
    const initial_pc2 = cpu.PC;

    add_instruction.Execute(&cpu);

    // A register should wrap around to 0
    try testing.expect(cpu.GetEightBitRegister(.A) == 0x00);
    try testing.expect(cpu.GetEightBitRegister(.C) == 0x01); // C should be unchanged
    try testing.expect(cpu.PC == initial_pc2 + add_instruction.cycles);

    // Zero flag should be set due to result being 0
    try testing.expect(cpu.GetFlag(.Zero) == true);
    try testing.expect(cpu.GetFlag(.Carry) == true); // Carry flag should be set due to overflow

    // Test case 3: Addition resulting in zero (but not overflow)
    cpu.SetEightBitRegister(.A, 0x00);
    cpu.SetEightBitRegister(.C, 0x00);
    cpu.PC = 0x300;
    const initial_pc3 = cpu.PC;

    add_instruction.Execute(&cpu);

    try testing.expect(cpu.GetEightBitRegister(.A) == 0x00);
    try testing.expect(cpu.PC == initial_pc3 + add_instruction.cycles);
    try testing.expect(cpu.GetFlag(.Zero) == true);
    try testing.expect(cpu.GetFlag(.Subrataction) == false); // Subtraction flag should be clear for ADD operations
}
