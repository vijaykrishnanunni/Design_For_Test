# JTAG TAP Controller

## Overview

`tap_controller.v` implements a basic **JTAG TAP Controller**.

TAP stands for **Test Access Port**.

This module follows the standard JTAG FSM flow and controls instruction register and data register shifting using:

```text
TCK
TMS 
TDI
TDO
```

The controller can be used as the JTAG control block in a DFT architecture.

---

## Main JTAG Signals

```text
tck
JTAG test clock.

trst_n
Active-low TAP reset.

tms
Test Mode Select.
Controls movement between TAP FSM states.

tdi
Test Data Input.
Serial data input into instruction/data registers.

tdo
Test Data Output.
Serial data output from instruction/data registers.
```

---

## TAP FSM

The controller implements the 16 standard JTAG TAP states:

```text
TEST_LOGIC_RESET
RUN_TEST_IDLE

SELECT_DR_SCAN
CAPTURE_DR
SHIFT_DR
EXIT1_DR
PAUSE_DR
EXIT2_DR
UPDATE_DR

SELECT_IR_SCAN
CAPTURE_IR
SHIFT_IR
EXIT1_IR
PAUSE_IR
EXIT2_IR
UPDATE_IR
```

The FSM state changes on the positive edge of `tck`.

```verilog
always @(posedge tck or negedge trst_n)
```

When reset is active:

```text
current_state = TEST_LOGIC_RESET
```

---

## FSM Blocks

### 1. TAP State Register

```text
Stores the current TAP state.
Updates current_state to next_state on every TCK edge.
Resets to TEST_LOGIC_RESET when trst_n = 0.
```

---

### 2. TAP Next-State Logic

```text
Decides the next TAP state based on current_state and tms.
```

`tms` controls the movement through the JTAG state machine.

Example:

```text
If current_state = TEST_LOGIC_RESET:

tms = 1 -> stay in TEST_LOGIC_RESET
tms = 0 -> go to RUN_TEST_IDLE
```

---

### 3. Instruction Register Logic

The instruction register is used during IR scan.

Registers used:

```text
instruction_shift
Temporary shift register during SHIFT_IR

instruction_reg
Final instruction register after UPDATE_IR
```

Operation:

```text
CAPTURE_IR -> loads default instruction value
SHIFT_IR   -> shifts TDI into instruction_shift
UPDATE_IR  -> stores instruction_shift into instruction_reg
```

---

### 4. Data Register Logic

The data register is used during DR scan.

Registers used:

```text
data_shift
Temporary shift register during SHIFT_DR

data_reg
Final data register after UPDATE_DR
```

Operation:

```text
CAPTURE_DR -> loads data_reg into data_shift
SHIFT_DR   -> shifts TDI into data_shift
UPDATE_DR  -> stores data_shift into data_reg
```

---

### 5. TDO Output Logic

`tdo` gives serial output during shift states.

```text
SHIFT_IR -> tdo = instruction_shift[0]
SHIFT_DR -> tdo = data_shift[0]
Other states -> tdo = 0
```

---

## Output State Signals

The module provides decoded TAP state outputs:

```text
test_logic_reset
run_test_idle

shift_dr
pause_dr
update_dr

shift_ir
pause_ir
update_ir
```

These signals are useful for connecting the TAP controller to other DFT blocks.

---

## Signal Origin and Destination

```text
Signal              Origin                    Destination

tck                 JTAG tester               TAP state register, IR/DR registers
trst_n              JTAG reset/test reset      TAP controller reset
tms                 JTAG tester               TAP next-state logic
tdi                 JTAG tester               IR/DR shift registers
tdo                 TAP controller            JTAG tester

shift_ir            TAP controller            Instruction register control
update_ir           TAP controller            Instruction update logic

shift_dr            TAP controller            Data register / scan chain control
update_dr           TAP controller            Data register / scan update logic
```

---

## Basic JTAG Flow

```text
1. TAP starts in TEST_LOGIC_RESET.
2. TMS controls movement through FSM states.
3. For instruction scan:
   CAPTURE_IR -> SHIFT_IR -> UPDATE_IR
4. For data scan:
   CAPTURE_DR -> SHIFT_DR -> UPDATE_DR
5. Data enters through TDI.
6. Data exits through TDO.
```

---

## Use in DFT

This TAP controller can be used to control:

```text
Scan chain shifting
Instruction register selection
Data register shifting
Boundary scan logic
LBIST/MBIST control registers
```

Example connection:

```text
JTAG Tester
    |
    | TCK, TMS, TDI
    v
TAP Controller
    |
    | shift_dr / update_dr
    v
Scan Chain / Data Register
    |
    v
TDO
```

---

## Suggested Folder Structure

```text
dft/
└── jtag/
    ├── tap_controller.v
    └── README.md
```

---

## Summary

The `tap_controller` is the main JTAG control FSM.

It controls:

```text
TAP state transitions
Instruction register shifting
Data register shifting
TDO output selection
Decoded JTAG state outputs
```

This module can be integrated with scan, LBIST, MBIST, and other DFT control logic.
