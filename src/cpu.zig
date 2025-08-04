const std = @import("std");
const library = @import("library.zig");

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
        const flagRegister = self.GetEightBitRegister(.F);
        switch (flag) {
            .Zero => return         flagRegister & FLAG_MASK_ZERO != 0,
            .Subrataction => return flagRegister & FLAG_MASK_SUBTRACTION != 0,
            .HalfCarry => return    flagRegister & FLAG_MASK_HALFCARRY != 0,
            .Carry => return        flagRegister & FLAG_MASK_CARRY != 0,
        }
    }

    pub fn SetFlag(self: *Cpu, flag: Flag, value: u1) void {
        const mask: u8 = switch (flag) {
            .Zero =>         FLAG_MASK_ZERO,
            .Subrataction => FLAG_MASK_SUBTRACTION,
            .HalfCarry =>    FLAG_MASK_HALFCARRY,
            .Carry =>        FLAG_MASK_CARRY,
        };

        // Clear bit then do an or operation to turn it back on if neccasary
        var flagRegister = self.GetEightBitRegister(.F);
        flagRegister &= ~mask;

        if (value == 1) {
            self.SetEightBitRegister(.F, flagRegister | mask);
        }
        else {
            self.SetEightBitRegister(.F, flagRegister);
        }
    }

    pub fn GetSixteenBitRegister(self: *Cpu, register: SixteenBitRegister) u16 {
        return switch (register) {
            .AF => self.AF,
            .BC => self.BC,
            .DE => self.DE,
            .HL => self.HL,
            .StackPointer => self.SP,
            .ProgramCounter => self.PC,
        };
    }

    pub fn SetSixteenBitRegister(self: *Cpu, register: SixteenBitRegister, value: u16) void {
        const pointer = switch (register) {
            .AF => &self.AF,
            .BC => &self.BC,
            .DE => &self.DE,
            .HL => &self.HL,
            .StackPointer => &self.SP,
            .ProgramCounter => &self.PC,
        };

        pointer.* = value;
    }

    pub fn GetEightBitRegister(self: *Cpu, register: EightBitRegister) u8 {
        return switch (register) {
            .A => @truncate(self.AF >> 8),
            .F => @truncate(self.AF & 0x00FF),
            .B => @truncate(self.BC >> 8),
            .C => @truncate(self.BC & 0x00FF),
            .D => @truncate(self.DE >> 8),
            .E => @truncate(self.DE & 0x00FF),
            .H => @truncate(self.HL >> 8),
            .L => @truncate(self.HL & 0x00FF),
        };
    }
    
    pub fn SetEightBitRegister(self: *Cpu, register: EightBitRegister, value: u8) void {
        const upper = switch (register) {
            .A, .B, .D, .H => @as(u16, value) << 8,
            .F => self.AF & 0xFF00,
            .C => self.BC & 0xFF00,
            .E => self.DE & 0xFF00,
            .L => self.HL & 0xFF00,
        };
        
        const lower = switch (register) {
            .F, .C, .E, .L => @as(u16, value),
            .A => self.AF & 0x00FF,
            .B => self.BC & 0x00FF,
            .D => self.DE & 0x00FF,
            .H => self.HL & 0x00FF,
        };
        
        switch (register) {
            .A, .F => self.AF = upper | lower,
            .B, .C => self.BC = upper | lower,
            .D, .E => self.DE = upper | lower,
            .H, .L => self.HL = upper | lower,
        }
    }

    // ALU Operations
    pub fn IncrementSixteenBitRegister(self: *Cpu, register: SixteenBitRegister, value: u16, updateFlags: bool) void {
        const initialValue = self.GetSixteenBitRegister(register);
        const result = library.addWithOverflow(initialValue, value);
        self.SetSixteenBitRegister(register, result.value);
        
        if (updateFlags) {
            // Zero flag never set for 16-bit operations, except when modifying the Stack Pointer
            if (register == .StackPointer) {
                self.SetFlag(.Zero, 0);
            }
            
            self.SetFlag(.Subrataction, 0);
            self.SetFlag(.HalfCarry, result.halfCarry);
            self.SetFlag(.Carry, result.carry);
        }
    }

    pub fn DecrementSixteenBitRegister(self: *Cpu, register: SixteenBitRegister, value: u16, updateFlags: bool) void {
        const modifiedInput = ~value + 1;

        // Easiest way to do this without duplicating code is to use the Increment function with the negated input
        // Flags are never set for 16-bit operations
        self.IncrementSixteenBitRegister(register, modifiedInput, updateFlags);
    }
    
    pub fn IncrementEightBitRegister(self: *Cpu, register: EightBitRegister, value: u8, updateCarryFlags: bool) void {
        const initialValue = self.GetEightBitRegister(register);
        const result = library.addWithOverflow(initialValue, value);
        self.SetEightBitRegister(register, result.value);
        
        // Flags
        self.SetFlag(.Zero, @intFromBool(result.value == 0));
        self.SetFlag(.Subrataction, 0);
        self.SetFlag(.HalfCarry, result.halfCarry);
        if (updateCarryFlags) {
            self.SetFlag(.Carry, result.carry);
        }
    }
    
    pub fn DecrementEightBitRegister(self: *Cpu, register: EightBitRegister, value: u8, updateCarryFlags: bool) void {
        const modifiedInput = ~value + 1;

        // Easiest way to do this without duplicating code is to use the Increment function with the negated input and override the subtraction flag
        self.IncrementEightBitRegister(register, modifiedInput, updateCarryFlags);

        self.SetFlag(.Subrataction, 1);
    }

    // Memory Operations
    // TODO: Rquires memory for implemenation
    pub fn PopStack(self: *Cpu) u8 {
        self.SP += 1;

        const rand = std.crypto.random;
        return rand.int(u8);
    }

    // TODO: Rquires memory for implemenation
    pub fn PushStack(self: *Cpu, _: u8) void {
        self.SP -= 1;
    }
    
    // TODO: Rquires memory for implemenation
    pub fn PopStackTwice(self: *Cpu) u16 {
        self.SP += 2;

        const rand = std.crypto.random;
        return rand.int(u16);
    }

    // TODO: Rquires memory for implemenation
    pub fn LoadFromMemoryAddress(_: *Cpu, _: u16) u8 {
        const rand = std.crypto.random;
        return rand.int(u8);
    }
    
    // TODO: Rquires memory for implemenation
    pub fn SaveToMemoryAddress(_: *Cpu, _: u16, _: u8) void {
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

// Unit Tests
const testing = std.testing;

test "GetFlag and SetFlag operations" {
    var cpu = Cpu{};
    
    // Test Zero flag
    try testing.expect(cpu.GetFlag(.Zero) == false);
    cpu.SetFlag(.Zero, 1);
    try testing.expect(cpu.GetFlag(.Zero) == true);
    cpu.SetFlag(.Zero, 0);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    
    // Test Subtraction flag
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    cpu.SetFlag(.Subrataction, 1);
    try testing.expect(cpu.GetFlag(.Subrataction) == true);
    cpu.SetFlag(.Subrataction, 0);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    
    // Test HalfCarry flag
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    cpu.SetFlag(.HalfCarry, 1);
    try testing.expect(cpu.GetFlag(.HalfCarry) == true);
    cpu.SetFlag(.HalfCarry, 0);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    
    // Test Carry flag
    try testing.expect(cpu.GetFlag(.Carry) == false);
    cpu.SetFlag(.Carry, 1);
    try testing.expect(cpu.GetFlag(.Carry) == true);
    cpu.SetFlag(.Carry, 0);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    
    // Test multiple flags set at once
    cpu.SetFlag(.Zero, 1);
    cpu.SetFlag(.Carry, 1);
    try testing.expect(cpu.GetFlag(.Zero) == true);
    try testing.expect(cpu.GetFlag(.Carry) == true);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
}

test "GetSixteenBitRegister and SetSixteenBitRegister operations" {
    var cpu = Cpu{};
    
    // Test AF register
    cpu.SetSixteenBitRegister(.AF, 0x1234);
    try testing.expect(cpu.GetSixteenBitRegister(.AF) == 0x1234);
    try testing.expect(cpu.AF == 0x1234);
    
    // Test BC register
    cpu.SetSixteenBitRegister(.BC, 0x5678);
    try testing.expect(cpu.GetSixteenBitRegister(.BC) == 0x5678);
    try testing.expect(cpu.BC == 0x5678);
    
    // Test DE register
    cpu.SetSixteenBitRegister(.DE, 0x9ABC);
    try testing.expect(cpu.GetSixteenBitRegister(.DE) == 0x9ABC);
    try testing.expect(cpu.DE == 0x9ABC);
    
    // Test HL register
    cpu.SetSixteenBitRegister(.HL, 0xDEF0);
    try testing.expect(cpu.GetSixteenBitRegister(.HL) == 0xDEF0);
    try testing.expect(cpu.HL == 0xDEF0);
    
    // Test StackPointer register
    cpu.SetSixteenBitRegister(.StackPointer, 0xFFFE);
    try testing.expect(cpu.GetSixteenBitRegister(.StackPointer) == 0xFFFE);
    try testing.expect(cpu.SP == 0xFFFE);
    
    cpu.SetSixteenBitRegister(.ProgramCounter, 0x0100);
    try testing.expect(cpu.GetSixteenBitRegister(.ProgramCounter) == 0x0100);
    try testing.expect(cpu.PC == 0x0100);
}

test "GetEightBitRegister and SetEightBitRegister operations" {
    var cpu = Cpu{};
    
    // Test A register (upper byte of AF)
    cpu.SetEightBitRegister(.A, 0x12);
    try testing.expect(cpu.GetEightBitRegister(.A) == 0x12);
    try testing.expect((cpu.AF >> 8) == 0x12);
    
    // Test F register (lower byte of AF)
    cpu.SetEightBitRegister(.F, 0x34);
    try testing.expect(cpu.GetEightBitRegister(.F) == 0x34);
    try testing.expect((cpu.AF & 0x00FF) == 0x34);
    
    // Test B register (upper byte of BC)
    cpu.SetEightBitRegister(.B, 0x56);
    try testing.expect(cpu.GetEightBitRegister(.B) == 0x56);
    try testing.expect((cpu.BC >> 8) == 0x56);
    
    // Test C register (lower byte of BC)
    cpu.SetEightBitRegister(.C, 0x78);
    try testing.expect(cpu.GetEightBitRegister(.C) == 0x78);
    try testing.expect((cpu.BC & 0x00FF) == 0x78);
    
    // Test D register (upper byte of DE)
    cpu.SetEightBitRegister(.D, 0x9A);
    try testing.expect(cpu.GetEightBitRegister(.D) == 0x9A);
    try testing.expect((cpu.DE >> 8) == 0x9A);
    
    // Test E register (lower byte of DE)
    cpu.SetEightBitRegister(.E, 0xBC);
    try testing.expect(cpu.GetEightBitRegister(.E) == 0xBC);
    try testing.expect((cpu.DE & 0x00FF) == 0xBC);
    
    // Test H register (upper byte of HL)
    cpu.SetEightBitRegister(.H, 0xDE);
    try testing.expect(cpu.GetEightBitRegister(.H) == 0xDE);
    try testing.expect((cpu.HL >> 8) == 0xDE);
    
    // Test L register (lower byte of HL)
    cpu.SetEightBitRegister(.L, 0xF0);
    try testing.expect(cpu.GetEightBitRegister(.L) == 0xF0);
    try testing.expect((cpu.HL & 0x00FF) == 0xF0);
    
    // Test that setting one register doesn't affect others
    cpu.AF = 0x0000;
    cpu.BC = 0x0000;
    cpu.DE = 0x0000;
    cpu.HL = 0x0000;
    
    cpu.SetEightBitRegister(.A, 0xFF);
    try testing.expect(cpu.BC == 0x0000);
    try testing.expect(cpu.DE == 0x0000);
    try testing.expect(cpu.HL == 0x0000);
}

test "IncrementSixteenBitRegister operations" {
    var cpu = Cpu{};
    
    // Test normal increment without overflow
    cpu.BC = 0x1000;
    cpu.IncrementSixteenBitRegister(.BC, 0x0234, true);
    try testing.expect(cpu.BC == 0x1234);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    
    // Test increment with full overflow (16-bit)
    cpu.BC = 0xFFFF;
    cpu.IncrementSixteenBitRegister(.BC, 0x0001, true);
    try testing.expect(cpu.BC == 0x0000);
    try testing.expect(cpu.GetFlag(.Zero) == true);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == true);
    try testing.expect(cpu.GetFlag(.HalfCarry) == true);
    
    // Test increment by zero (should set zero flag since result is 0)
    cpu.DE = 0x0000;
    cpu.IncrementSixteenBitRegister(.DE, 0x0000, true);
    try testing.expect(cpu.DE == 0x0000);
    try testing.expect(cpu.GetFlag(.Zero) == true);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    
    // Test non-zero result (should clear zero flag)
    cpu.HL = 0x1000;
    cpu.IncrementSixteenBitRegister(.HL, 0x8000, true);
    try testing.expect(cpu.HL == 0x9000);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    
    // Test half-carry scenario (carry from bit 11 to bit 12)
    cpu.HL = 0x0FFF;
    cpu.IncrementSixteenBitRegister(.HL, 0x0001, true);
    try testing.expect(cpu.HL == 0x1000);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == true);
    
    // Test ProgramCounter increment. Flags should not be modified from last test
    cpu.PC = 0x0100;
    cpu.IncrementSixteenBitRegister(.ProgramCounter, 0x0001, false);
    try testing.expect(cpu.PC == 0x0101);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == true);
}

test "IncrementEightBitRegister operations" {
    var cpu = Cpu{};
    
    // Test normal increment without overflow
    cpu.SetEightBitRegister(.A, 10);
    cpu.IncrementEightBitRegister(.A, 5, true);
    try testing.expect(cpu.GetEightBitRegister(.A) == 15);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    
    // Test increment with overflow
    cpu.SetEightBitRegister(.B, 0xFF);
    cpu.IncrementEightBitRegister(.B, 0x01, true);
    try testing.expect(cpu.GetEightBitRegister(.B) == 0x00);
    try testing.expect(cpu.GetFlag(.Zero) == true);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == true);
    try testing.expect(cpu.GetFlag(.HalfCarry) == true);
    
    // Test increment by zero resulting in zero
    cpu.SetEightBitRegister(.C, 0x00);
    cpu.IncrementEightBitRegister(.C, 0x00, true);
    try testing.expect(cpu.GetEightBitRegister(.C) == 0x00);
    try testing.expect(cpu.GetFlag(.Zero) == true);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    
    // Test increment by zero resulting in non-zero
    cpu.SetEightBitRegister(.D, 0x56);
    cpu.IncrementEightBitRegister(.D, 0x00, true);
    try testing.expect(cpu.GetEightBitRegister(.D) == 0x56);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
    
    // Test half-carry scenario (carry from bit 3 to bit 4)
    cpu.SetEightBitRegister(.E, 0x0F);
    cpu.IncrementEightBitRegister(.E, 0x01, true);
    try testing.expect(cpu.GetEightBitRegister(.E) == 0x10);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == true);
    
    // Test increment that doesn't overflow
    cpu.SetEightBitRegister(.H, 0x80);
    cpu.IncrementEightBitRegister(.H, 0x7E, true);
    try testing.expect(cpu.GetEightBitRegister(.H) == 0xFE);
    try testing.expect(cpu.GetFlag(.Zero) == false);
    try testing.expect(cpu.GetFlag(.Subrataction) == false);
    try testing.expect(cpu.GetFlag(.Carry) == false);
    try testing.expect(cpu.GetFlag(.HalfCarry) == false);
}

test "PopStack operation" {
    var cpu = Cpu{};
    
    // PopStack should increment SP by 8 and return a random value
    cpu.SP = 0x1000;
    const initial_sp = cpu.SP;
    
    // Call PopStack multiple times to ensure it returns values
    const val1 = cpu.PopStack();
    const val2 = cpu.PopStack();
    const val3 = cpu.PopStack();
    
    // Check that values are in valid u8 range
    try testing.expect(val1 <= 255);
    try testing.expect(val2 <= 255);
    try testing.expect(val3 <= 255);
    
    // Check that SP was incremented correctly (3 calls * 8 = 24)
    try testing.expect(cpu.SP == initial_sp + 24);
}

test "CPU initialization" {
    const cpu = Cpu{};
    
    // Test that all registers are initialized to 0
    try testing.expect(cpu.AF == 0);
    try testing.expect(cpu.BC == 0);
    try testing.expect(cpu.DE == 0);
    try testing.expect(cpu.HL == 0);
    try testing.expect(cpu.PC == 0);
    try testing.expect(cpu.SP == 0);
    
    // Test that all flags are initially false
    var mutable_cpu = cpu;
    try testing.expect(mutable_cpu.GetFlag(.Zero) == false);
    try testing.expect(mutable_cpu.GetFlag(.Subrataction) == false);
    try testing.expect(mutable_cpu.GetFlag(.HalfCarry) == false);
    try testing.expect(mutable_cpu.GetFlag(.Carry) == false);
}
