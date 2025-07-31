const std = @import("std");
const cpuLib = @import("../cpu.zig");
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
    destinationRegister: ?Destination = null,
    source: ?Source = null,

    pub fn Execute(self: *const Instruction, cpu: *Cpu) void {
        switch (self.instructionType) {
            .Nop => std.debug.print("No Op\n", .{}),
            .Invalid => @panic("Unimplemented instruction"),
            .Jump => {},
            .Data => {
                if (self.operationType == null) {
                    @panic("Register and immediate instructions must include an operationType");
                }

                switch (self.operationType.?) {
                    .Adc, .Add, .Cp, .Dec, .Inc, .Sbc, .Sub, .And, .Xor, .Or => self.Arithmetic(cpu),
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
                    .And => {
                        const result = sourceValue & modifiedValue;
                        cpu.SetEightBitRegister(destinationRegister, result);
                        cpu.SetFlag(.Zero, @intFromBool(result == 0));
                        cpu.SetFlag(.Subrataction, 0);
                        cpu.SetFlag(.Carry, 1);
                        cpu.SetFlag(.HalfCarry, 0);
                    },
                    .Xor => {
                        const result = sourceValue ^ modifiedValue;
                        cpu.SetEightBitRegister(destinationRegister, result);
                        cpu.SetFlag(.Zero, @intFromBool(result == 0));
                        cpu.SetFlag(.Subrataction, 0);
                        cpu.SetFlag(.Carry, 0);
                        cpu.SetFlag(.HalfCarry, 0);
                    },
                    .Or => {
                        const result = sourceValue | modifiedValue;
                        cpu.SetEightBitRegister(destinationRegister, result);
                        cpu.SetFlag(.Zero, @intFromBool(result == 0));
                        cpu.SetFlag(.Subrataction, 0);
                        cpu.SetFlag(.Carry, 0);
                        cpu.SetFlag(.HalfCarry, 0);
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
                    .And => {
                        const result = sourceValue & modifiedValue;
                        cpu.SetSixteenBitRegister(destinationRegister, result);
                        cpu.SetFlag(.Zero, @intFromBool(result == 0));
                        cpu.SetFlag(.Subrataction, 0);
                        cpu.SetFlag(.Carry, 1);
                        cpu.SetFlag(.HalfCarry, 0);
                    },
                    .Xor => {
                        const result = sourceValue ^ modifiedValue;
                        cpu.SetSixteenBitRegister(destinationRegister, result);
                        cpu.SetFlag(.Zero, @intFromBool(result == 0));
                        cpu.SetFlag(.Subrataction, 0);
                        cpu.SetFlag(.Carry, 0);
                        cpu.SetFlag(.HalfCarry, 0);
                    },
                    .Or => {
                        const result = sourceValue | modifiedValue;
                        cpu.SetSixteenBitRegister(destinationRegister, result);
                        cpu.SetFlag(.Zero, @intFromBool(result == 0));
                        cpu.SetFlag(.Subrataction, 0);
                        cpu.SetFlag(.Carry, 0);
                        cpu.SetFlag(.HalfCarry, 0);
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
                    .pointerRegister => |sourceRegister| cpu.LoadFromRegisterPointer(sourceRegister),
                    .immediateEight => |sourceImmediate| sourceImmediate,
                    else => @panic("Invalid eight-bit load operation"),
                };

                cpu.SetEightBitRegister(destinationRegister, sourceValue);
            },
            .sixteenBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.GetSixteenBitRegister(sourceRegister),
                    .immediateSixteen => |sourceImmediate| sourceImmediate,
                    else => @panic("Invalid sixteen-bit load operation"),
                };

                cpu.SetSixteenBitRegister(destinationRegister, sourceValue);
            },
            .pointerRegister => | destinationPointer| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.LoadFromRegisterPointer(sourceRegister),
                    .immediateEight => |sourceImmediate| sourceImmediate,
                    else => @panic("Invalid pointer load operation"),
                };

                cpu.SetToRegisterPointer(destinationPointer, sourceValue)
            }
        }
    }
};

const InstructionType = enum { Data, Jump, Nop, Invalid };
const OperationType = enum { Adc, Add, Cp, Dec, Inc, Sbc, Sub, And, Xor, Or, Load };

pub const Destination = union(enum) { eightBitRegister: EightBitRegister, sixteenBitRegister: SixteenBitRegister, pointerRegister: SixteenBitRegister };
pub const Source = union(enum) { eightBitRegister: EightBitRegister, sixteenBitRegister: SixteenBitRegister, pointerRegister: SixteenBitRegister, immediateEight: u8, immediateSixteen: u16 };
