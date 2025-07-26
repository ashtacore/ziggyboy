# ziggyboy

A Game Boy emulator written in Zig.

## Overview

ziggyboy is a Game Boy emulator project built using the Zig programming language. The project aims to provide accurate emulation of the original Game Boy hardware.

## Features

- CPU implementation with register management
- Flag register support (Zero, Subtraction, Half Carry, Carry)
- Instruction structure for Game Boy opcodes

## Building

Make sure you have Zig installed on your system. You can download it from [ziglang.org](https://ziglang.org/).

```bash
zig build
```

## Running

After building, you can run the emulator:

```bash
./zig-out/bin/ziggyboy.exe
```

Alternatively, you can build and run in one step:

```bash
zig build run
```

## Testing

Run the test suite:

```bash
zig test src/cpu.zig
```

## Project Structure

```
├── src/
│   ├── main.zig          # Main entry point
│   └── cpu.zig           # CPU implementation
├── build.zig             # Build configuration
├── build.zig.zon         # Package configuration
└── LICENSE               # MIT License
```

## Development Status

This project is currently in early development. Core CPU functionality is being implemented.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
