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
    table[0o102] = Instruction{ .mnemonic = "LD B, D", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .D } };
    table[0o103] = Instruction{ .mnemonic = "LD B, E", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .E } };
    table[0o104] = Instruction{ .mnemonic = "LD B, H", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .H } };
    table[0o105] = Instruction{ .mnemonic = "LD B, L", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .L } };
    table[0o106] = Instruction{ .mnemonic = "LD B, HL", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o107] = Instruction{ .mnemonic = "LD B, A", .cycles = 1, .length = 1, .instructionType = .Register, .operationType = .Load, .destinationRegister = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .A } };

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
