const instrLib = @import("instruction.zig");
const Instruction = instrLib.Instruction;
const InstructionType = instrLib.InstructionType;
const OperationType = instrLib.OperationType;
const Destination = instrLib.Destination;
const Source = instrLib.Source;

pub const InstructionTable: [256]Instruction = blk: {
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
    // Pops
    table[0o301] = Instruction{ .mnemonic = "POP BC", .cycles = 3, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .BC }, .source = .{ .sixteenBitRegister = .StackPointer} };
    table[0o321] = Instruction{ .mnemonic = "POP DE", .cycles = 3, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .DE }, .source = .{ .sixteenBitRegister = .StackPointer} };
    table[0o341] = Instruction{ .mnemonic = "POP HL", .cycles = 3, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .HL }, .source = .{ .sixteenBitRegister = .StackPointer} };
    table[0o361] = Instruction{ .mnemonic = "POP AF", .cycles = 3, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .AF }, .source = .{ .sixteenBitRegister = .StackPointer} };

    // Pushes
    table[0o301] = Instruction{ .mnemonic = "PUSH BC", .cycles = 4, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .StackPointer }, .source = .{ .sixteenBitRegister = .BC } };
    table[0o321] = Instruction{ .mnemonic = "PUSH DE", .cycles = 4, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .StackPointer }, .source = .{ .sixteenBitRegister = .DE } };
    table[0o341] = Instruction{ .mnemonic = "PUSH HL", .cycles = 4, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .StackPointer }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o361] = Instruction{ .mnemonic = "PUSH AF", .cycles = 4, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .StackPointer }, .source = .{ .sixteenBitRegister = .AF } };

    // Sixteen-Bit Load
    table[0o10] = Instruction{ .mnemonic = "LD [a16], SP", .cycles = 5, .length = 3, .instructionType = .Data, .operationType = .Load, .destination = .{ .immediatePointer = 0 }, .source = .{ .sixteenBitRegister = .StackPointer } };
    table[0o01] = Instruction{ .mnemonic = "LD BC, n16", .cycles = 3, .length = 3, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .BC }, .source = .{ .immediateSixteen = 0 } };
    table[0o21] = Instruction{ .mnemonic = "LD DE, n16", .cycles = 3, .length = 3, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .DE }, .source = .{ .immediateSixteen = 0 } };
    table[0o41] = Instruction{ .mnemonic = "LD HL, n16", .cycles = 3, .length = 3, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .HL }, .source = .{ .immediateSixteen = 0 } };
    table[0o61] = Instruction{ .mnemonic = "LD SP, n16", .cycles = 3, .length = 3, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .StackPointer }, .source = .{ .immediateSixteen = 0 } };

    table[0o370] = Instruction{ .mnemonic = "LD HL, SP + e8", .cycles = 3, .length = 2, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .HL }, .source = .{ .sixteenBitRegister = .StackPointer } };
    table[0o371] = Instruction{ .mnemonic = "LD SP, HL", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .sixteenBitRegister = .StackPointer }, .source = .{ .sixteenBitRegister = .HL } };

    // Eight-Bit Load
    table[0o100] = Instruction{ .mnemonic = "LD B, B", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o101] = Instruction{ .mnemonic = "LD B, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .C } };
    table[0o102] = Instruction{ .mnemonic = "LD B, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .D } };
    table[0o103] = Instruction{ .mnemonic = "LD B, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .E } };
    table[0o104] = Instruction{ .mnemonic = "LD B, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .H } };
    table[0o105] = Instruction{ .mnemonic = "LD B, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .L } };
    table[0o106] = Instruction{ .mnemonic = "LD B,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .B }, .source = .{ .pointerRegister = .HL } };
    table[0o107] = Instruction{ .mnemonic = "LD B, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .B }, .source = .{ .eightBitRegister = .A } };

    table[0o110] = Instruction{ .mnemonic = "LD C, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .B } };
    table[0o111] = Instruction{ .mnemonic = "LD C, C", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o112] = Instruction{ .mnemonic = "LD C, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .D } };
    table[0o113] = Instruction{ .mnemonic = "LD C, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .E } };
    table[0o114] = Instruction{ .mnemonic = "LD C, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .H } };
    table[0o115] = Instruction{ .mnemonic = "LD C, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .L } };
    table[0o116] = Instruction{ .mnemonic = "LD C,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .C }, .source = .{ .pointerRegister = .HL } };
    table[0o117] = Instruction{ .mnemonic = "LD C, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .C }, .source = .{ .eightBitRegister = .A } };

    table[0o120] = Instruction{ .mnemonic = "LD D, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .B } };
    table[0o121] = Instruction{ .mnemonic = "LD D, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .C } };
    table[0o122] = Instruction{ .mnemonic = "LD D, D", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o123] = Instruction{ .mnemonic = "LD D, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .E } };
    table[0o124] = Instruction{ .mnemonic = "LD D, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .H } };
    table[0o125] = Instruction{ .mnemonic = "LD D, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .L } };
    table[0o126] = Instruction{ .mnemonic = "LD D,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .D }, .source = .{ .pointerRegister = .HL } };
    table[0o127] = Instruction{ .mnemonic = "LD D, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .D }, .source = .{ .eightBitRegister = .A } };

    table[0o130] = Instruction{ .mnemonic = "LD E, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .B } };
    table[0o131] = Instruction{ .mnemonic = "LD E, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .C } };
    table[0o132] = Instruction{ .mnemonic = "LD E, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .D } };
    table[0o133] = Instruction{ .mnemonic = "LD E, E", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o134] = Instruction{ .mnemonic = "LD E, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .H } };
    table[0o135] = Instruction{ .mnemonic = "LD E, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .L } };
    table[0o136] = Instruction{ .mnemonic = "LD E,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .E }, .source = .{ .pointerRegister = .HL } };
    table[0o137] = Instruction{ .mnemonic = "LD E, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .E }, .source = .{ .eightBitRegister = .A } };

    table[0o140] = Instruction{ .mnemonic = "LD H, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .B } };
    table[0o141] = Instruction{ .mnemonic = "LD H, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .C } };
    table[0o142] = Instruction{ .mnemonic = "LD H, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .D } };
    table[0o143] = Instruction{ .mnemonic = "LD H, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .E } };
    table[0o144] = Instruction{ .mnemonic = "LD H, H", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o145] = Instruction{ .mnemonic = "LD H, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .L } };
    table[0o146] = Instruction{ .mnemonic = "LD H,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .H }, .source = .{ .pointerRegister = .HL } };
    table[0o147] = Instruction{ .mnemonic = "LD H, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .H }, .source = .{ .eightBitRegister = .A } };

    table[0o150] = Instruction{ .mnemonic = "LD L, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .B } };
    table[0o151] = Instruction{ .mnemonic = "LD L, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .C } };
    table[0o152] = Instruction{ .mnemonic = "LD L, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .D } };
    table[0o153] = Instruction{ .mnemonic = "LD L, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .E } };
    table[0o154] = Instruction{ .mnemonic = "LD L, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .H } };
    table[0o155] = Instruction{ .mnemonic = "LD L, L", .cycles = 1, .length = 1, .instructionType = .Nop };
    table[0o156] = Instruction{ .mnemonic = "LD L,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .L }, .source = .{ .pointerRegister = .HL } };
    table[0o157] = Instruction{ .mnemonic = "LD L, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .L }, .source = .{ .eightBitRegister = .A } };

    table[0o160] = Instruction{ .mnemonic = "LD [HL], B", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .pointerRegister = .HL }, .source = .{ .eightBitRegister = .B } };
    table[0o161] = Instruction{ .mnemonic = "LD [HL], C", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .pointerRegister = .HL }, .source = .{ .eightBitRegister = .C } };
    table[0o162] = Instruction{ .mnemonic = "LD [HL], D", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .pointerRegister = .HL }, .source = .{ .eightBitRegister = .D } };
    table[0o163] = Instruction{ .mnemonic = "LD [HL], E", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .pointerRegister = .HL }, .source = .{ .eightBitRegister = .E } };
    table[0o164] = Instruction{ .mnemonic = "LD [HL], H", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .pointerRegister = .HL }, .source = .{ .eightBitRegister = .H } };
    table[0o165] = Instruction{ .mnemonic = "LD [HL], L", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .pointerRegister = .HL }, .source = .{ .eightBitRegister = .L } };
    table[0o167] = Instruction{ .mnemonic = "LD [HL], A", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .pointerRegister = .HL }, .source = .{ .eightBitRegister = .A } };

    table[0o170] = Instruction{ .mnemonic = "LD A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o171] = Instruction{ .mnemonic = "LD A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o172] = Instruction{ .mnemonic = "LD A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o173] = Instruction{ .mnemonic = "LD A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o174] = Instruction{ .mnemonic = "LD A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o175] = Instruction{ .mnemonic = "LD A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o176] = Instruction{ .mnemonic = "LD A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Load, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o177] = Instruction{ .mnemonic = "LD A, A", .cycles = 1, .length = 1, .instructionType = .Nop };

    //// Arithmetic Instructions
    table[0o11] = Instruction{ .mnemonic = "ADD HL, BC", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .sixteenBitRegister = .HL }, .source = .{ .sixteenBitRegister = .BC } };
    table[0o31] = Instruction{ .mnemonic = "ADD HL, DE", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .sixteenBitRegister = .HL }, .source = .{ .sixteenBitRegister = .DE } };
    table[0o51] = Instruction{ .mnemonic = "ADD HL, HL", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .sixteenBitRegister = .HL }, .source = .{ .sixteenBitRegister = .HL } };
    table[0o71] = Instruction{ .mnemonic = "ADD HL, SP", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .sixteenBitRegister = .HL }, .source = .{ .sixteenBitRegister = .StackPointer } };

    table[0o03] = Instruction{ .mnemonic = "INC BC", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .sixteenBitRegister = .BC }, .source = .{ .immediateSixteen = 1 } };
    table[0o13] = Instruction{ .mnemonic = "DEC BC", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .sixteenBitRegister = .BC }, .source = .{ .immediateSixteen = 1 } };
    table[0o23] = Instruction{ .mnemonic = "INC DE", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .sixteenBitRegister = .DE}, .source = .{ .immediateSixteen = 1 } };
    table[0o33] = Instruction{ .mnemonic = "DEC DE", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .sixteenBitRegister = .DE}, .source = .{ .immediateSixteen = 1 } };
    table[0o43] = Instruction{ .mnemonic = "INC HL", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .sixteenBitRegister = .HL}, .source = .{ .immediateSixteen = 1 } };
    table[0o53] = Instruction{ .mnemonic = "DEC HL", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .sixteenBitRegister = .HL}, .source = .{ .immediateSixteen = 1 } };
    table[0o63] = Instruction{ .mnemonic = "INC SP", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .sixteenBitRegister = .StackPointer}, .source = .{ .immediateSixteen = 1 } };
    table[0o73] = Instruction{ .mnemonic = "DEC SP", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .sixteenBitRegister = .StackPointer }, .source = .{ .immediateSixteen = 1 } };

    table[0o04] = Instruction{ .mnemonic = "INC B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .eightBitRegister = .B }, .source = .{ .immediateEight = 1 } };
    table[0o14] = Instruction{ .mnemonic = "INC C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .eightBitRegister = .C }, .source = .{ .immediateEight = 1 } };
    table[0o24] = Instruction{ .mnemonic = "INC D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .eightBitRegister = .D }, .source = .{ .immediateEight = 1 } };
    table[0o34] = Instruction{ .mnemonic = "INC E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .eightBitRegister = .E }, .source = .{ .immediateEight = 1 } };
    table[0o44] = Instruction{ .mnemonic = "INC H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .eightBitRegister = .H }, .source = .{ .immediateEight = 1 } };
    table[0o54] = Instruction{ .mnemonic = "INC L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .eightBitRegister = .L }, .source = .{ .immediateEight = 1 } };
    table[0o64] = Instruction{ .mnemonic = "INC [HL]",.cycles = 3,.length = 1,.instructionType = .Data, .operationType = .Inc, .destination = .{ .pointerRegister = .HL }, .source = .{ .immediateEight = 1 }};
    table[0o74] = Instruction{ .mnemonic = "INC A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Inc, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 1 } };

    table[0o05] = Instruction{ .mnemonic = "DEC B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .eightBitRegister = .B }, .source = .{ .immediateEight = 1 } };
    table[0o15] = Instruction{ .mnemonic = "DEC C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .eightBitRegister = .C }, .source = .{ .immediateEight = 1 } };
    table[0o25] = Instruction{ .mnemonic = "DEC D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .eightBitRegister = .D }, .source = .{ .immediateEight = 1 } };
    table[0o35] = Instruction{ .mnemonic = "DEC E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .eightBitRegister = .E }, .source = .{ .immediateEight = 1 } };
    table[0o45] = Instruction{ .mnemonic = "DEC H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .eightBitRegister = .H }, .source = .{ .immediateEight = 1 } };
    table[0o55] = Instruction{ .mnemonic = "DEC L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .eightBitRegister = .L }, .source = .{ .immediateEight = 1 } };
    table[0o65] = Instruction{ .mnemonic = "DEC [HL]",.cycles = 3,.length = 1,.instructionType = .Data, .operationType = .Dec, .destination = .{ .pointerRegister = .HL }, .source = .{ .immediateEight = 1 }};
    table[0o75] = Instruction{ .mnemonic = "DEC A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Dec, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 1 } };

    table[0o200] = Instruction{ .mnemonic = "ADD A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o201] = Instruction{ .mnemonic = "ADD A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o202] = Instruction{ .mnemonic = "ADD A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o203] = Instruction{ .mnemonic = "ADD A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o204] = Instruction{ .mnemonic = "ADD A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o205] = Instruction{ .mnemonic = "ADD A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o206] = Instruction{ .mnemonic = "ADD A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o207] = Instruction{ .mnemonic = "ADD A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o210] = Instruction{ .mnemonic = "ADC A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o211] = Instruction{ .mnemonic = "ADC A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o212] = Instruction{ .mnemonic = "ADC A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o213] = Instruction{ .mnemonic = "ADC A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o214] = Instruction{ .mnemonic = "ADC A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o215] = Instruction{ .mnemonic = "ADC A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o216] = Instruction{ .mnemonic = "ADC A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o217] = Instruction{ .mnemonic = "ADC A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o220] = Instruction{ .mnemonic = "SUB A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o221] = Instruction{ .mnemonic = "SUB A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o222] = Instruction{ .mnemonic = "SUB A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o223] = Instruction{ .mnemonic = "SUB A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o224] = Instruction{ .mnemonic = "SUB A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o225] = Instruction{ .mnemonic = "SUB A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o226] = Instruction{ .mnemonic = "SUB A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o227] = Instruction{ .mnemonic = "SUB A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o230] = Instruction{ .mnemonic = "SBC A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o231] = Instruction{ .mnemonic = "SBC A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o232] = Instruction{ .mnemonic = "SBC A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o233] = Instruction{ .mnemonic = "SBC A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o234] = Instruction{ .mnemonic = "SBC A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o235] = Instruction{ .mnemonic = "SBC A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o236] = Instruction{ .mnemonic = "SBC A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o237] = Instruction{ .mnemonic = "SBC A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o240] = Instruction{ .mnemonic = "AND A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o241] = Instruction{ .mnemonic = "AND A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o242] = Instruction{ .mnemonic = "AND A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o243] = Instruction{ .mnemonic = "AND A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o244] = Instruction{ .mnemonic = "AND A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o245] = Instruction{ .mnemonic = "AND A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o246] = Instruction{ .mnemonic = "AND A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o247] = Instruction{ .mnemonic = "AND A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o250] = Instruction{ .mnemonic = "XOR A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o251] = Instruction{ .mnemonic = "XOR A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o252] = Instruction{ .mnemonic = "XOR A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o253] = Instruction{ .mnemonic = "XOR A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o254] = Instruction{ .mnemonic = "XOR A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o255] = Instruction{ .mnemonic = "XOR A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o256] = Instruction{ .mnemonic = "XOR A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o257] = Instruction{ .mnemonic = "XOR A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o260] = Instruction{ .mnemonic = "OR A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o261] = Instruction{ .mnemonic = "OR A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o262] = Instruction{ .mnemonic = "OR A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o263] = Instruction{ .mnemonic = "OR A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o264] = Instruction{ .mnemonic = "OR A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o265] = Instruction{ .mnemonic = "OR A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o266] = Instruction{ .mnemonic = "OR A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o267] = Instruction{ .mnemonic = "OR A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o270] = Instruction{ .mnemonic = "CP A, B", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .B } };
    table[0o271] = Instruction{ .mnemonic = "CP A, C", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .C } };
    table[0o272] = Instruction{ .mnemonic = "CP A, D", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .D } };
    table[0o273] = Instruction{ .mnemonic = "CP A, E", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .E } };
    table[0o274] = Instruction{ .mnemonic = "CP A, H", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .H } };
    table[0o275] = Instruction{ .mnemonic = "CP A, L", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .L } };
    table[0o276] = Instruction{ .mnemonic = "CP A,[HL]", .cycles = 2, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .pointerRegister = .HL } };
    table[0o277] = Instruction{ .mnemonic = "CP A, A", .cycles = 1, .length = 1, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .eightBitRegister = .A } };

    table[0o306] = Instruction{ .mnemonic = "ADD A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .Add, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    table[0o316] = Instruction{ .mnemonic = "ADC A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .Adc, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    table[0o326] = Instruction{ .mnemonic = "SUB A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .Sub, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    table[0o336] = Instruction{ .mnemonic = "SBC A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .Sbc, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    table[0o346] = Instruction{ .mnemonic = "AND A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .And, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    table[0o356] = Instruction{ .mnemonic = "XOR A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .Xor, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    table[0o366] = Instruction{ .mnemonic = "OR A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .Or, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    table[0o376] = Instruction{ .mnemonic = "CP A, n8", .cycles = 2, .length = 2, .instructionType = .Data, .operationType = .Cp, .destination = .{ .eightBitRegister = .A }, .source = .{ .immediateEight = 0 } };
    
    break :blk table;
};

// Unit Tests
const std = @import("std");
const testing = std.testing;
const cpuLib = @import("../cpu.zig");
const Cpu = cpuLib.Cpu;
const Flag = cpuLib.Flag;
const EightBitRegister = cpuLib.EightBitRegister;
const SixteenBitRegister = cpuLib.SixteenBitRegister;

test "Execute NOP instruction (0o00)" {
    var cpu = Cpu{};
    const nop_instruction = InstructionTable[0o00];

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
    const ld_instruction = InstructionTable[0o107];

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
    const add_instruction = InstructionTable[0o201];

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
