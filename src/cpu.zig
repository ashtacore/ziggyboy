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

    pub fn IncrementSixteenBitRegister(self: *Cpu, register: SixteenBitRegister, value: u16) bool {
        const pointer = switch (register) {
            .AF => &self.AF,
            .BC => &self.BC,
            .DE => &self.DE,
            .HL => &self.HL,
            .StackPointer => &self.SP,
            .ProgramCounter => &self.PC,
        };

        const result = @addWithOverflow(pointer.*, value);

        pointer.* = result[0];
        return result[1] == 1;
    }
    
    pub fn IncrementEightBitRegister(self: *Cpu, register: EightBitRegister, value: u8) bool {
        const initiailValue = self.GetEightBitRegister(register);
        const result = @addWithOverflow(initiailValue, value);

        self.SetEightBitRegister(register, result[0]);
        return result[1] == 1;
    }

    pub fn PopStack(self: *Cpu) u8 {
        self.SP += 8;

        const rand = std.crypto.random;
        return rand.int(u8);
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
    cpu.AF = 0x1000;
    var overflow = cpu.IncrementSixteenBitRegister(.AF, 0x0234);
    try testing.expect(cpu.AF == 0x1234);
    try testing.expect(overflow == false);
    
    // Test increment with overflow
    cpu.BC = 0xFFFF;
    overflow = cpu.IncrementSixteenBitRegister(.BC, 0x0001);
    try testing.expect(cpu.BC == 0x0000);
    try testing.expect(overflow == true);
    
    // Test increment by zero
    cpu.DE = 0x5678;
    overflow = cpu.IncrementSixteenBitRegister(.DE, 0x0000);
    try testing.expect(cpu.DE == 0x5678);
    try testing.expect(overflow == false);
    
    // Test large increment
    cpu.HL = 0x1000;
    overflow = cpu.IncrementSixteenBitRegister(.HL, 0x8000);
    try testing.expect(cpu.HL == 0x9000);
    try testing.expect(overflow == false);
    
    // Test StackPointer increment
    cpu.SP = 0xFFF0;
    overflow = cpu.IncrementSixteenBitRegister(.StackPointer, 0x0010);
    try testing.expect(cpu.SP == 0x0000);
    try testing.expect(overflow == true);
    
    // Test ProgramCounter increment - This will fail due to bug in the code
    cpu.PC = 0x0100;
    cpu.SP = 0x0000; // Ensure SP is different to detect the bug
    overflow = cpu.IncrementSixteenBitRegister(.ProgramCounter, 0x0001);
    try testing.expect(cpu.PC == 0x0101); // This will fail because the code modifies SP instead of PC
}

test "IncrementEightBitRegister operations" {
    var cpu = Cpu{};
    
    // Test normal increment without overflow
    cpu.AF = 0x1000;
    var overflow = cpu.IncrementEightBitRegister(.A, 0x23);
    try testing.expect(cpu.GetEightBitRegister(.A) == 0x33);
    try testing.expect(overflow == false);
    
    // Test increment with overflow
    cpu.SetEightBitRegister(.B, 0xFF);
    overflow = cpu.IncrementEightBitRegister(.B, 0x01);
    try testing.expect(cpu.GetEightBitRegister(.B) == 0x00);
    try testing.expect(overflow == true);
    
    // Test increment by zero
    cpu.SetEightBitRegister(.C, 0x56);
    overflow = cpu.IncrementEightBitRegister(.C, 0x00);
    try testing.expect(cpu.GetEightBitRegister(.C) == 0x56);
    try testing.expect(overflow == false);
    
    // Test increment that doesn't overflow
    cpu.SetEightBitRegister(.D, 0x80);
    overflow = cpu.IncrementEightBitRegister(.D, 0x7F);
    try testing.expect(cpu.GetEightBitRegister(.D) == 0xFF);
    try testing.expect(overflow == false);
    
    // Test increment on different registers
    cpu.SetEightBitRegister(.E, 0x10);
    cpu.SetEightBitRegister(.H, 0x20);
    cpu.SetEightBitRegister(.L, 0x30);
    cpu.SetEightBitRegister(.F, 0x40);
    
    _ = cpu.IncrementEightBitRegister(.E, 0x05);
    _ = cpu.IncrementEightBitRegister(.H, 0x05);
    _ = cpu.IncrementEightBitRegister(.L, 0x05);
    _ = cpu.IncrementEightBitRegister(.F, 0x05);
    
    try testing.expect(cpu.GetEightBitRegister(.E) == 0x15);
    try testing.expect(cpu.GetEightBitRegister(.H) == 0x25);
    try testing.expect(cpu.GetEightBitRegister(.L) == 0x35);
    try testing.expect(cpu.GetEightBitRegister(.F) == 0x45);
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

test "Flag mask constants" {
    // Test that flag masks have correct bit positions
    try testing.expect(FLAG_MASK_ZERO == 0b1000_0000);
    try testing.expect(FLAG_MASK_SUBTRACTION == 0b0100_0000);
    try testing.expect(FLAG_MASK_HALFCARRY == 0b0010_0000);
    try testing.expect(FLAG_MASK_CARRY == 0b0001_0000);
    
    // Test that masks don't overlap
    try testing.expect((FLAG_MASK_ZERO & FLAG_MASK_SUBTRACTION) == 0);
    try testing.expect((FLAG_MASK_ZERO & FLAG_MASK_HALFCARRY) == 0);
    try testing.expect((FLAG_MASK_ZERO & FLAG_MASK_CARRY) == 0);
    try testing.expect((FLAG_MASK_SUBTRACTION & FLAG_MASK_HALFCARRY) == 0);
    try testing.expect((FLAG_MASK_SUBTRACTION & FLAG_MASK_CARRY) == 0);
    try testing.expect((FLAG_MASK_HALFCARRY & FLAG_MASK_CARRY) == 0);
}

