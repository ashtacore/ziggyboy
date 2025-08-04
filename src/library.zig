pub fn addWithOverflow(a: anytype, b: anytype) struct { value: @TypeOf(a), carry: u1, halfCarry: u1 } {
    const T = @TypeOf(a);
    const U = @TypeOf(b);

    if (T != U) {
        @compileError("Input values must be of same type");
    }

    const halfType = switch (T) {
        u4 =>  u2,
        u8 =>  u4,
        u16 => u8,
        u32 => u16,
        u64 => u32,
        else => @compileError("Unsupported integer size"),
    };

    const fullResult = @addWithOverflow(a, b);
    const fullSum = fullResult[0];
    const carry = fullResult[1];

    const halfA: halfType = @truncate(a);
    const halfB: halfType = @truncate(b);
    const halfResult = @addWithOverflow(halfA, halfB);
    const halfCarry = halfResult[1];

    return .{ .value = fullSum, .carry = carry, .halfCarry = halfCarry};
}

pub fn combineEightBitValues(highBits: u8, lowBits: u8) u16 {
    const shiftedHighBits = @as(u16, highBits) << 8;
    const mask = 0xFF00;
    const maskedLowerBits = mask | @as(u16, lowBits);
    return shiftedHighBits & maskedLowerBits;
}