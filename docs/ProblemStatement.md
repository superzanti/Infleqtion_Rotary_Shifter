# Infleqtion 2025-09-17 Sr Embedded Systems Engineer Take Home Test

## Requirements

The goal of the exercise is to develop a barrel shifter RTL module targeting programmable logic.
The barrel shifter should employ a rotator operation to circulate bits and is only required to shift
bits in one direction.
For this application, assume that optimizing f_max is the most critical performance requirement
and, thus, no logic in the design should exceed logic level 1.
This exercise may be completed using any hardware descriptive language. The participant may
also choose device or programmable architecture that they are using but should document any
hardware assumptions in the deliverable.

## Module I/O

The module should have the following I/O:
- clock input
- active low synchronous reset input
- AXI4-Stream control input
    - TDATA: 64-bit payload input to be shifted by the module
    - TUSER: 8-bit argument (number of bits to shift TDATA)
- AXI4-Stream result output
    - TDATA: 64-bit result of barrel shift operation

## Deliverable

- A short write-up about your architecture. Include discussion of why you think your design is
correct, any assumptions that you made about the hardware or larger system, and any design
trade offs that you considered.
- All RTL files for the module
- Test benches and/or simulation outputs (optional, but encouraged)

## Example

The following table shows how the expected TDATA output depends on the TUSER input, for a
TDATA input of:

64'b0000_1000_0000_0000_0000_0000_0000_1010_0000_0000_0000_0000_0000_0000_0000
_0001.

| TUSER input | TDATA output |
| -------- | ------- |
| 8'd0 | 64’b0000_1000_0000_0000_0000_ 0000_0000_1010_0000_0000_0000 _0000_0000_0000_0000_0001 |
| 8'd3 | 64’b0100_0000_0000_0000_0000_ 0000_0101_0000_0000_0000_0000 _0000_0000_0000_0000_1000 |
| 8'd10 | 64’b0000_0000_0000_0000_0101_0 000_0000_0000_0000_0000_0000_ 0000_0000_0100_0010_0000 |
| 8'd63 | 63 64’b1000_0100_0000_0000_0000_0 000_0000_0101_0000_0000_0000_ 0000_0000_0000_0000_1000 |
