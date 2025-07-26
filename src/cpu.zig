const std = @import("std");
const testing = std.testing;

// zig fmt: off
const FLAG_MASK_ZERO        = 0b1000_0000;
const FLAG_MASK_SUBTRACTION = 0b0100_0000;
const FLAG_MASK_HALFCARRY   = 0b0010_0000;
const FLAG_MASK_CARRY       = 0b0001_0000;

pub const Cpu = struct {
    // Registers
    AF: u16 = 0,
    BC: u16 = 0,
    DE: u16 = 0,
    HL: u16 = 0,
    PC: u16 = 0, // Program Counter
    SP: u16 = 0, // Stack Pointer

    // Register Getters / Setters
    pub fn GetFlag(self: *Cpu, flag: Flag) bool {
        const flagRegister = self.AF & 0x00FF;
        switch (flag) {
            .Zero => return         flagRegister & FLAG_MASK_ZERO != 0,
            .Subrataction => return flagRegister & FLAG_MASK_SUBTRACTION != 0,
            .HalfCarry => return    flagRegister & FLAG_MASK_HALFCARRY != 0,
            .Carry => return        flagRegister & FLAG_MASK_CARRY != 0,
        }
    }

    pub fn SetFlag(self: *Cpu, flag: Flag, value: u1) void {
        const mask: u8 = switch (flag) {
            .Zero => FLAG_MASK_ZERO,
            .Subrataction => FLAG_MASK_SUBTRACTION,
            .HalfCarry => FLAG_MASK_HALFCARRY,
            .Carry => FLAG_MASK_CARRY,
        };

        // Clear bit then do an or operation to turn it back on if neccasary
        self.AF &= ~mask;

        if (value == 1) {
            self.AF |= (@as(u16, value) << @ctz(mask)); // Only set the bit if needed
        }
    }
};

pub const EightBitRegister = enum {
    A,
    F,
    B,
    C,
    D,
    E,
    H,
    L,
};

pub const SixteenBitRegister = enum { 
    AF, 
    BC, 
    DE, 
    HL, 
    StackPointer, 
    ProgramCounter
};

pub const Flag = enum { 
    Zero, 
    Subrataction, 
    HalfCarry, 
    Carry 
};

pub const Instruction = struct {
    mnemonic: []const u8,
    handler: fn (*Cpu) void,
};

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
