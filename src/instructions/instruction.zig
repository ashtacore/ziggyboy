const std = @import("std");
const library = @import("../library.zig");
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
    destination: ?Destination = null,
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
                    .Pop => self.Pop(cpu),
                    .Push => self.Push(cpu),
                    //else => @panic("Unimplemented operation"),
                }
            },
        }

        cpu.IncrementSixteenBitRegister(.ProgramCounter, self.cycles, false);
    }

    fn Arithmetic(self: *const Instruction, cpu: *Cpu) void {
        if (self.destination == null) {
            @panic("Add operations require destination register");
        }
        if (self.source == null) {
            @panic("Add operations require source");
        }

        switch (self.destination.?) {
            .eightBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .pointerRegister => |sourceRegister| cpu.LoadFromMemoryAddress(cpu.GetSixteenBitRegister(sourceRegister)),
                    .immediateEight => |immediateValue| if (self.length == 2) cpu.PopStack() else immediateValue,
                    else => @panic("Invalid eight-bit arithmetic operation"),
                };

                // In an ADC / SBC operation we include the value of the carry flag in the operation
                const modifiedValue = switch (self.operationType.?) {
                    .Adc, .Sbc => sourceValue + @intFromBool(cpu.GetFlag(Flag.Carry)),
                    else => sourceValue,
                };

                switch (self.operationType.?) {
                    .Adc, .Add => cpu.IncrementEightBitRegister(destinationRegister, modifiedValue, true),
                    .Sbc, .Sub => cpu.DecrementEightBitRegister(destinationRegister, modifiedValue, true),
                    .Inc => cpu.IncrementEightBitRegister(destinationRegister, modifiedValue, false),
                    .Dec => cpu.DecrementEightBitRegister(destinationRegister, modifiedValue, false),
                    // A compare function sets the flags as if it's doing a subtract operation, but doesn't actually modify the register
                    // To keep things simple we're going to run the increment function to set the flags, then force the register back to the original value
                    .Cp => {
                        const originalValue = cpu.GetEightBitRegister(destinationRegister);
                        cpu.DecrementEightBitRegister(destinationRegister, modifiedValue, true);
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
                    .sixteenBitRegister => |sourceRegister| cpu.GetSixteenBitRegister(sourceRegister),
                    .immediateSixteen => |immediateValue| immediateValue,
                    else => @panic("Invalid sixteen-bit arithmetic operation"),
                };

                switch (self.operationType.?) {
                    .Add => cpu.IncrementSixteenBitRegister(destinationRegister, sourceValue, true),
                    .Inc => cpu.IncrementSixteenBitRegister(destinationRegister, sourceValue, false),
                    .Dec => cpu.DecrementSixteenBitRegister(destinationRegister, sourceValue, false),
                    else => @panic("Arithmetic operation not supported for sixteen-bit registers"),
                }
            },
            .pointerRegister => |destinationRegister| {
                const destinationAddress = cpu.GetSixteenBitRegister(destinationRegister);
                const originalValue = cpu.LoadFromMemoryAddress(cpu.GetSixteenBitRegister(destinationRegister));

                switch (self.operationType.?) {
                    .Inc => cpu.SaveToMemoryAddress(destinationAddress, originalValue + 1),
                    .Dec => cpu.SaveToMemoryAddress(destinationAddress, originalValue - 1),
                    else => @panic("Invalid pointer arithmetic operation"),
                }
            },
            .immediatePointer => @panic("Invalid destination for arithmetic function"),
        }
    }

    fn Load(self: *const Instruction, cpu: *Cpu) void {
        if (self.destination == null) {
            @panic("Load operations require destination register");
        }
        if (self.source == null) {
            @panic("Load operations require source");
        }

        switch (self.destination.?) {
            .eightBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .pointerRegister => |sourceRegister| cpu.LoadFromMemoryAddress(cpu.GetSixteenBitRegister(sourceRegister)),
                    .immediateEight => if (self.length == 2) cpu.PopStack() else @panic("Invalid eight-bit immediate load operation"),
                    else => @panic("Invalid eight-bit load operation"),
                };

                cpu.SetEightBitRegister(destinationRegister, sourceValue);
            },
            .sixteenBitRegister => |destinationRegister| {
                const sourceValue = switch (self.source.?) {
                    .sixteenBitRegister => |sourceRegister| cpu.GetSixteenBitRegister(sourceRegister),
                    .immediateSixteen => if (self.length == 3) cpu.PopStackTwice() else @panic("Invalid sixteen-bit immediate load operation"),
                    else => @panic("Invalid sixteen-bit load operation"),
                };

                cpu.SetSixteenBitRegister(destinationRegister, sourceValue);
                
                // Special handling for command 0o370
                if (destinationRegister == .StackPointer) {
                    const signedImmediate = cpu.PopStack();
                    const sign: u1 = @truncate(signedImmediate >> 7);
                    const unsignedImmediate = signedImmediate & 0b0111_1111;
                    
                    if (sign == 1) { //negative
                        cpu.DecrementSixteenBitRegister(destinationRegister, unsignedImmediate, true);
                    }
                    else { //positive
                        cpu.IncrementSixteenBitRegister(destinationRegister, unsignedImmediate, true)  ; 
                    }
                    cpu.SetFlag(.Zero, 0);
                    cpu.SetFlag(.Subrataction, 0);
                }
            },
            .pointerRegister => |destinationPointer| {
                const destinationAddress = cpu.GetSixteenBitRegister(destinationPointer);
                const sourceValue = switch (self.source.?) {
                    .eightBitRegister => |sourceRegister| cpu.GetEightBitRegister(sourceRegister),
                    .sixteenBitRegister => |sourceRegister| cpu.LoadFromMemoryAddress(cpu.GetSixteenBitRegister(sourceRegister)),
                    .immediateEight => if (self.length == 2) cpu.PopStack() else @panic("Invalid pointer load operation"),
                    else => @panic("Invalid pointer load operation"),
                };

                cpu.SaveToMemoryAddress(destinationAddress, sourceValue);
            },
            .immediatePointer => {
                const destinationPointer = if (self.length == 3) cpu.PopStackTwice() else @panic("Invalid immediate pointer load operation");
                switch (self.source.?) {
                    // Weird command: https://rgbds.gbdev.io/docs/v0.9.3/gbz80.7#LD__n16_,SP
                    .sixteenBitRegister => |sourceRegister| {
                        const stackPointerValue = cpu.GetSixteenBitRegister(sourceRegister);
                        const upperBits: u8 = @truncate(stackPointerValue & 0x00FF);
                        const lowerBits: u8 = @truncate(stackPointerValue >> 8);
                        cpu.SaveToMemoryAddress(destinationPointer, upperBits);
                        cpu.SaveToMemoryAddress(destinationPointer, lowerBits);
                    },
                    else => @panic("Invalid immediate pointer load operation"),
                }
            }
        }
    }
    
    fn Pop(self: *const Instruction, cpu: *Cpu) void {
        switch (self.destination.?) {
            .sixteenBitRegister => |destinationRegister| {
                const lowBits = cpu.PopStack();
                const highBits = cpu.PopStack();
                const combinedBits = library.combineEightBitValues(highBits, lowBits);
                
                cpu.SetSixteenBitRegister(destinationRegister, combinedBits);
            },
            else => @panic("Pop operation requires sixteen-bit destination")
        }
    }
    
    fn Push(self: *const Instruction, cpu: *Cpu) void {
        switch (self.source.?) {
            .sixteenBitRegister => |sourceRegister| {
                const storedValue = cpu.GetSixteenBitRegister(sourceRegister);
                const lowBits: u8 = @truncate(storedValue & 0x00FF);
                const highBits: u8 = @truncate(storedValue >> 8);
                
                cpu.PushStack(highBits);
                cpu.PushStack(lowBits);
            },
            else => @panic("Pop operation requires sixteen-bit destination")
        }
    }
};

const InstructionType = enum { Data, Jump, Nop, Invalid };
const OperationType = enum { Adc, Add, Cp, Dec, Inc, Sbc, Sub, And, Xor, Or, Load, Pop, Push };

pub const Destination = union(enum) { eightBitRegister: EightBitRegister, sixteenBitRegister: SixteenBitRegister, pointerRegister: SixteenBitRegister, immediatePointer: u16 };
pub const Source = union(enum) { eightBitRegister: EightBitRegister, sixteenBitRegister: SixteenBitRegister, pointerRegister: SixteenBitRegister, immediateEight: u8, immediateSixteen: u16 };
