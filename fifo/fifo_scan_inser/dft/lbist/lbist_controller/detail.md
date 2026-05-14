# LBIST Controller

## Overview

This folder contains the Verilog implementation of an **LBIST Controller**.

LBIST stands for **Logic Built-In Self-Test**.

LBIST is a DFT technique used to test digital logic internally. Instead of applying all test vectors from an external tester, LBIST generates pseudo-random test patterns on-chip using a PRPG/LFSR and compresses the DUT response using a MISR.

This module is the **control unit** of the LBIST architecture.

The controller does not generate test patterns by itself.  
The controller does not compress DUT outputs by itself.  
The controller does not compare signatures by itself.

Instead, it controls other LBIST blocks using enable signals.

The main blocks controlled by this module are:

```text
PRPG / LFSR
DUT
MISR
Signature Comparator
```

---

## File

```text
lbist_controller.v
```

---

## LBIST Architecture

```text
              +-------------------+
              | LBIST Controller  |
              +-------------------+
                 |       |       |
                 |       |       |
        prpg_enable  misr_enable  compare_enable
                 |       |       |
                 v       v       v

+-------------+      +-------+      +-------------+      +----------------------+
| PRPG / LFSR | ---> |  DUT  | ---> |    MISR     | ---> | Signature Comparator |
+-------------+      +-------+      +-------------+      +----------------------+
                                                             |
                                                             v
                                                        PASS / FAIL
```

The LBIST controller controls the complete test sequence:

```text
1. Wait for LBIST start
2. Initialize the test
3. Enable PRPG and MISR
4. Count how many patterns are applied
5. Stop pattern generation
6. Enable signature comparison
7. Assert LBIST done
```

---

## Verilog Code

```verilog
`timescale 1ns/1ps

module lbist_controller #(
    parameter PATTERN_COUNT_WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rst_n,

    input  wire                         lbist_start,
    input  wire [PATTERN_COUNT_WIDTH-1:0] pattern_count,

    output reg                          lbist_active,
    output reg                          prpg_enable,
    output reg                          misr_enable,
    output reg                          compare_enable,
    output reg                          lbist_done
);

    localparam IDLE    = 3'd0;
    localparam INIT    = 3'd1;
    localparam RUN     = 3'd2;
    localparam COMPARE = 3'd3;
    localparam DONE    = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    reg [PATTERN_COUNT_WIDTH-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)

            IDLE: begin
                if (lbist_start)
                    next_state = INIT;
                else
                    next_state = IDLE;
            end

            INIT: begin
                next_state = RUN;
            end

            RUN: begin
                if (count == pattern_count)
                    next_state = COMPARE;
                else
                    next_state = RUN;
            end

            COMPARE: begin
                next_state = DONE;
            end

            DONE: begin
                if (!lbist_start)
                    next_state = IDLE;
                else
                    next_state = DONE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {PATTERN_COUNT_WIDTH{1'b0}};
        end
        else begin
            case (state)

                IDLE: begin
                    count <= {PATTERN_COUNT_WIDTH{1'b0}};
                end

                INIT: begin
                    count <= {PATTERN_COUNT_WIDTH{1'b0}};
                end

                RUN: begin
                    if (count < pattern_count)
                        count <= count + 1'b1;
                    else
                        count <= count;
                end

                default: begin
                    count <= count;
                end

            endcase
        end
    end

    always @(*) begin
        lbist_active   = 1'b0;
        prpg_enable    = 1'b0;
        misr_enable    = 1'b0;
        compare_enable = 1'b0;
        lbist_done     = 1'b0;

        case (state)

            IDLE: begin
                lbist_active   = 1'b0;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

            INIT: begin
                lbist_active   = 1'b1;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

            RUN: begin
                lbist_active   = 1'b1;
                prpg_enable    = 1'b1;
                misr_enable    = 1'b1;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

            COMPARE: begin
                lbist_active   = 1'b1;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b1;
                lbist_done     = 1'b0;
            end

            DONE: begin
                lbist_active   = 1'b0;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b1;
            end

            default: begin
                lbist_active   = 1'b0;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

        endcase
    end

endmodule
```

---

## Module Purpose

The purpose of `lbist_controller` is to control the LBIST sequence.

It decides:

```text
When LBIST should start
When PRPG should generate patterns
When MISR should capture responses
When final signature comparison should happen
When LBIST is completed
```

The controller is implemented using a finite state machine.

---

## Parameter

### PATTERN_COUNT_WIDTH

```verilog
parameter PATTERN_COUNT_WIDTH = 16
```

This parameter defines the width of:

```text
pattern_count input
count internal register
```

If:

```verilog
PATTERN_COUNT_WIDTH = 16
```

then the maximum count value is:

```text
2^16 - 1 = 65535
```

So the controller can support up to 65535 test patterns.

---

## Input Signals

### clk

```verilog
input wire clk
```

This is the main clock input.

All sequential operations happen on the positive edge of `clk`.

Used by:

```text
State register block
Pattern counter block
```

Origin:

```text
System clock
Test clock
LBIST clock
```

Terminates at:

```text
State register
Pattern counter register
```

---

### rst_n

```verilog
input wire rst_n
```

This is an active-low reset.

When:

```text
rst_n = 0
```

the controller is reset.

Reset effects:

```text
state = IDLE
count = 0
```

Origin:

```text
System reset
Test reset
External reset
```

Terminates at:

```text
State register
Pattern counter register
```

---

### lbist_start

```verilog
input wire lbist_start
```

This signal starts the LBIST operation.

When:

```text
lbist_start = 1
```

the controller moves from `IDLE` to `INIT`.

After LBIST completes, the controller stays in `DONE` until `lbist_start` becomes 0.

Origin can be:

```text
Testbench
JTAG register
Control/status register
SoC test controller
External tester
```

Terminates at:

```text
Next-state logic
```

Used in:

```text
IDLE state
DONE state
```

---

### pattern_count

```verilog
input wire [PATTERN_COUNT_WIDTH-1:0] pattern_count
```

This input tells the controller how many LBIST patterns should be applied.

Example:

```verilog
pattern_count = 16'd20;
```

Meaning:

```text
Apply 20 pseudo-random patterns
Capture 20 DUT responses in MISR
Then stop and compare the final signature
```

Origin can be:

```text
Testbench
JTAG data register
Configuration register
Control/status register
Hardcoded top-level value
```

Terminates at:

```text
Next-state logic
Pattern counter logic
```

---

## Output Signals

### lbist_active

```verilog
output reg lbist_active
```

This signal indicates that LBIST is currently active.

It is high during:

```text
INIT
RUN
COMPARE
```

It is low during:

```text
IDLE
DONE
```

Origin:

```text
LBIST controller output logic
```

Terminates at:

```text
Top-level wrapper
Status register
Debug logic
Optional test-mode logic
```

---

### prpg_enable

```verilog
output reg prpg_enable
```

This signal enables the PRPG/LFSR.

When:

```text
prpg_enable = 1
```

the PRPG generates pseudo-random patterns.

Origin:

```text
LBIST controller output logic
```

Terminates at:

```text
PRPG / LFSR enable input
```

Active during:

```text
RUN state
```

---

### misr_enable

```verilog
output reg misr_enable
```

This signal enables the MISR.

When:

```text
misr_enable = 1
```

the MISR captures and compresses the DUT response.

Origin:

```text
LBIST controller output logic
```

Terminates at:

```text
MISR enable input
```

Active during:

```text
RUN state
```

---

### compare_enable

```verilog
output reg compare_enable
```

This signal enables the signature comparator.

When:

```text
compare_enable = 1
```

the comparator compares:

```text
Final MISR signature
with
Golden reference signature
```

Origin:

```text
LBIST controller output logic
```

Terminates at:

```text
Signature comparator compare_en input
```

Active during:

```text
COMPARE state
```

---

### lbist_done

```verilog
output reg lbist_done
```

This signal indicates that LBIST operation is complete.

When:

```text
lbist_done = 1
```

the LBIST sequence has finished.

Origin:

```text
LBIST controller output logic
```

Terminates at:

```text
Top-level status output
Status register
JTAG readable register
Testbench monitor
External test controller
```

Active during:

```text
DONE state
```

---

## Internal Signals

### state

```verilog
reg [2:0] state;
```

This register stores the current FSM state.

Origin:

```text
Updated by state register block
```

Terminates at:

```text
Next-state logic
Pattern counter logic
Output control logic
```

---

### next_state

```verilog
reg [2:0] next_state;
```

This signal stores the next state that the FSM should move into.

Origin:

```text
Generated by next-state logic
```

Terminates at:

```text
State register block
```

---

### count

```verilog
reg [PATTERN_COUNT_WIDTH-1:0] count;
```

This internal register counts how many patterns have been applied.

Origin:

```text
Updated by pattern counter logic
```

Terminates at:

```text
Next-state logic
Pattern counter logic
```

Purpose:

```text
Used to stop LBIST after the required number of patterns are applied
```

---

## FSM States

The controller has five states:

```verilog
localparam IDLE    = 3'd0;
localparam INIT    = 3'd1;
localparam RUN     = 3'd2;
localparam COMPARE = 3'd3;
localparam DONE    = 3'd4;
```

---

## State Descriptions

### IDLE

The controller waits before LBIST starts.

In this state:

```text
LBIST is inactive
PRPG is disabled
MISR is disabled
Comparator is disabled
Done signal is low
Counter is cleared
```

Outputs:

```text
lbist_active   = 0
prpg_enable    = 0
misr_enable    = 0
compare_enable = 0
lbist_done     = 0
```

Transition:

```text
If lbist_start = 1, go to INIT
Else stay in IDLE
```

---

### INIT

This state initializes LBIST.

In this state:

```text
LBIST becomes active
Pattern counter is reset
PRPG is still disabled
MISR is still disabled
Comparator is disabled
```

Outputs:

```text
lbist_active   = 1
prpg_enable    = 0
misr_enable    = 0
compare_enable = 0
lbist_done     = 0
```

Transition:

```text
Go to RUN
```

---

### RUN

This is the main LBIST testing state.

In this state:

```text
PRPG generates pseudo-random patterns
Patterns are applied to DUT
DUT produces output responses
MISR compresses the responses
Pattern counter increments
```

Outputs:

```text
lbist_active   = 1
prpg_enable    = 1
misr_enable    = 1
compare_enable = 0
lbist_done     = 0
```

Transition:

```text
If count == pattern_count, go to COMPARE
Else stay in RUN
```

---

### COMPARE

This state enables final signature comparison.

In this state:

```text
PRPG is stopped
MISR is stopped
Final MISR signature is held
Comparator is enabled
```

Outputs:

```text
lbist_active   = 1
prpg_enable    = 0
misr_enable    = 0
compare_enable = 1
lbist_done     = 0
```

Transition:

```text
Go to DONE
```

---

### DONE

This state indicates LBIST completion.

In this state:

```text
LBIST is inactive
PRPG is disabled
MISR is disabled
Comparator is disabled
lbist_done is high
```

Outputs:

```text
lbist_active   = 0
prpg_enable    = 0
misr_enable    = 0
compare_enable = 0
lbist_done     = 1
```

Transition:

```text
If lbist_start = 0, go back to IDLE
Else remain in DONE
```

---

## FSM Flow

```text
IDLE
  |
  | lbist_start = 1
  v
INIT
  |
  v
RUN
  |
  | count reaches pattern_count
  v
COMPARE
  |
  v
DONE
  |
  | lbist_start = 0
  v
IDLE
```

---

## Output Activity Table

```text
State       lbist_active   prpg_enable   misr_enable   compare_enable   lbist_done

IDLE        0              0             0             0                0
INIT        1              0             0             0                0
RUN         1              1             1             0                0
COMPARE     1              0             0             1                0
DONE        0              0             0             0                1
```

---

## Signal Origin and Termination Summary

### Inputs

```text
Signal          Origin                              Used Inside Controller

clk             System/test/LBIST clock             State register, counter
rst_n           System/test reset                   State register, counter
lbist_start     Testbench/JTAG/control register     Next-state logic
pattern_count   Testbench/JTAG/control register     Next-state logic, counter logic
```

### Outputs

```text
Signal           Generated By Controller         Terminates At

lbist_active     Output control logic             Status/debug/top wrapper
prpg_enable      Output control logic             PRPG/LFSR enable
misr_enable      Output control logic             MISR enable
compare_enable   Output control logic             Signature comparator enable
lbist_done       Output control logic             Status register/testbench/JTAG
```

---

## Multi-Block FSM Structure

This controller uses a multi-block FSM.

The logic is separated into:

```text
1. State register logic
2. Next-state logic
3. Pattern counter logic
4. Output control logic
```

This style is preferred because each block has one clear job.

---

# Block 1: State Register Logic

```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end
```

## What this block does

This block stores the current FSM state.

It is sequential logic because it is triggered by:

```verilog
posedge clk
```

The state changes only on the positive edge of the clock.

## Reset operation

```verilog
if (!rst_n)
    state <= IDLE;
```

Since `rst_n` is active-low:

```text
rst_n = 0 means reset is active
```

So during reset, the FSM goes to `IDLE`.

## Normal operation

```verilog
else
    state <= next_state;
```

On every clock edge, the current state becomes `next_state`.

This block answers:

```text
What is the current state of the controller?
```

---

# Block 2: Next-State Logic

```verilog
always @(*) begin
    case (state)
        ...
    endcase
end
```

## What this block does

This block decides where the FSM should go next.

It is combinational logic.

It does not store anything.

It calculates:

```text
next_state
```

based on:

```text
state
lbist_start
count
pattern_count
```

## Important point

This block uses `count`, but it does not update `count`.

It only checks whether enough patterns have been applied.

Example:

```verilog
RUN: begin
    if (count == pattern_count)
        next_state = COMPARE;
    else
        next_state = RUN;
end
```

Meaning:

```text
If required number of patterns is completed, go to COMPARE.
Otherwise stay in RUN.
```

This block answers:

```text
Where should the controller go next?
```

---

# Block 3: Pattern Counter Logic

```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= {PATTERN_COUNT_WIDTH{1'b0}};
    end
    else begin
        case (state)
            ...
        endcase
    end
end
```

## What this block does

This block counts how many PRPG patterns have been applied.

It is sequential logic because `count` is a register.

The counter changes only on the clock edge.

## Why the counter is needed

LBIST should not run forever.

The controller must know:

```text
How many patterns have already been generated?
```

So the controller uses:

```text
count
```

and compares it with:

```text
pattern_count
```

---

## Meaning of this syntax

```verilog
{PATTERN_COUNT_WIDTH{1'b0}}
```

This is the Verilog replication operator.

General form:

```verilog
{N{value}}
```

Meaning:

```text
Repeat value N times
```

Examples:

```verilog
{4{1'b0}}  = 4'b0000
{8{1'b0}}  = 8'b00000000
{4{1'b1}}  = 4'b1111
{3{2'b10}} = 6'b101010
```

So if:

```verilog
PATTERN_COUNT_WIDTH = 16
```

then:

```verilog
{PATTERN_COUNT_WIDTH{1'b0}}
```

means:

```verilog
16'b0000_0000_0000_0000
```

It is equivalent to:

```verilog
count <= 0;
```

but it is more width-safe.

---

## Counter behavior

### IDLE

```verilog
IDLE: begin
    count <= {PATTERN_COUNT_WIDTH{1'b0}};
end
```

Meaning:

```text
LBIST is not running.
Clear count to 0.
```

---

### INIT

```verilog
INIT: begin
    count <= {PATTERN_COUNT_WIDTH{1'b0}};
end
```

Meaning:

```text
LBIST is starting.
Clear count to 0 before entering RUN.
```

This ensures every new LBIST run starts from count 0.

---

### RUN

```verilog
RUN: begin
    if (count < pattern_count)
        count <= count + 1'b1;
    else
        count <= count;
end
```

Meaning:

```text
LBIST is running.
PRPG is generating patterns.
MISR is capturing DUT responses.
So count increments every clock cycle.
```

If:

```text
count < pattern_count
```

then:

```text
count = count + 1
```

If count has reached pattern_count, it holds the same value.

---

### Default

```verilog
default: begin
    count <= count;
end
```

Meaning:

```text
In COMPARE and DONE states, keep the same count value.
```

---

## Counter Summary

```text
State       Counter Action

IDLE        count = 0
INIT        count = 0
RUN         count increments
COMPARE     count holds
DONE        count holds
```

---

## Why counter is in a separate block

The counter is separate because:

```text
Next-state logic is combinational.
Counter logic is sequential.
```

Next-state logic only decides:

```text
Where should the FSM go next?
```

Counter logic actually stores:

```text
How many patterns have been applied?
```

A counter must update with a clock, so it belongs in:

```verilog
always @(posedge clk or negedge rst_n)
```

---

# Block 4: Output Control Logic

```verilog
always @(*) begin
    lbist_active   = 1'b0;
    prpg_enable    = 1'b0;
    misr_enable    = 1'b0;
    compare_enable = 1'b0;
    lbist_done     = 1'b0;

    case (state)
        ...
    endcase
end
```

## What this block does

This block generates output control signals based on the current FSM state.

It is combinational logic.

The outputs depend on:

```text
state
```

## Default assignments

At the beginning:

```verilog
lbist_active   = 1'b0;
prpg_enable    = 1'b0;
misr_enable    = 1'b0;
compare_enable = 1'b0;
lbist_done     = 1'b0;
```

These default assignments prevent latch inference.

Then each state overrides the outputs as required.

---

## Output behavior in each state

### IDLE

```text
No LBIST operation is active.
All enable signals are low.
```

---

### INIT

```text
LBIST is active, but PRPG and MISR are not enabled yet.
This state prepares the controller before RUN starts.
```

---

### RUN

```text
PRPG and MISR are enabled.
PRPG generates patterns.
MISR captures compressed responses.
```

---

### COMPARE

```text
PRPG and MISR are disabled.
Signature comparison is enabled.
```

---

### DONE

```text
LBIST is completed.
lbist_done becomes high.
```

---

## Complete LBIST Operation

```text
1. rst_n is asserted low.
2. Controller resets to IDLE.
3. rst_n becomes high.
4. Controller waits in IDLE.
5. lbist_start becomes high.
6. Controller moves to INIT.
7. Counter is cleared.
8. Controller moves to RUN.
9. PRPG generates pseudo-random patterns.
10. DUT receives test patterns.
11. DUT produces responses.
12. MISR compresses responses.
13. Counter increments every cycle.
14. When count reaches pattern_count, controller moves to COMPARE.
15. Comparator compares MISR signature with golden signature.
16. Controller moves to DONE.
17. lbist_done becomes high.
18. When lbist_start becomes low, controller returns to IDLE.
```

---

## Example Operation

If:

```verilog
pattern_count = 16'd5;
```

then the controller applies 5 patterns.

During RUN:

```text
prpg_enable = 1
misr_enable = 1
```

The PRPG generates patterns and the MISR captures responses.

After the required count is reached:

```text
prpg_enable = 0
misr_enable = 0
compare_enable = 1
```

Then in DONE:

```text
lbist_done = 1
```

---

## Golden Signature Comparison

The LBIST controller does not compare the signature directly.

The comparison is performed by a separate module:

```text
signature_comparator.v
```

The comparator checks:

```text
MISR final signature == Golden reference signature
```

If both match:

```text
LBIST PASS
```

If they do not match:

```text
LBIST FAIL
```

Basic connection:

```text
final MISR signature ----\
                          ---> signature_comparator ---> pass/fail
golden signature --------/
```

---

## Where Golden Signature Comes From

The golden signature is obtained from fault-free simulation.

Flow:

```text
1. Simulate the fault-free DUT.
2. Run the same PRPG patterns.
3. Capture the final MISR output.
4. Store that value as the golden signature.
5. During LBIST, compare current MISR output with golden signature.
```

Example:

```text
Fault-free simulation gives final MISR signature = A93C
```

Then store:

```verilog
GOLDEN_SIG = 16'hA93C;
```

During LBIST:

```text
If final_signature == GOLDEN_SIG:
    pass

Else:
    fail
```

---

## Why Multi-Block FSM Is Used

This design uses multi-block FSM style because it is clean and scalable.

The FSM is divided like this:

```text
State register block   -> stores current state
Next-state block       -> decides next state
Counter block          -> counts LBIST patterns
Output block           -> generates control signals
```

This makes debugging easier.

If state transition is wrong:

```text
Check next-state logic
```

If count is wrong:

```text
Check pattern counter logic
```

If PRPG/MISR/comparator enable is wrong:

```text
Check output control logic
```

This style is preferred in RTL projects because it separates control decisions, counters, and output generation.

---

## Important Note About Pattern Count

The current code checks:

```verilog
if (count == pattern_count)
```

This works for demonstrating LBIST control flow.

However, depending on how exact pattern cycles are counted, this can apply one extra cycle.

For exact N-pattern operation, a better condition is:

```verilog
if (count == pattern_count - 1'b1)
```

Then if:

```verilog
pattern_count = 16'd5;
```

the counter runs:

```text
0, 1, 2, 3, 4
```

That gives exactly 5 RUN cycles.

Improved next-state RUN logic:

```verilog
RUN: begin
    if (count == pattern_count - 1'b1)
        next_state = COMPARE;
    else
        next_state = RUN;
end
```

Improved counter RUN logic:

```verilog
RUN: begin
    if (count < pattern_count - 1'b1)
        count <= count + 1'b1;
    else
        count <= count;
end
```

---

## Suggested Repository Placement

```text
dft/
└── lbist/
    ├── lfsr16_prpg.v
    ├── misr16.v
    ├── signature_comparator.v
    ├── golden_signature_mem.v
    ├── lbist_controller.v
    └── README.md
```

---

## Summary

The `lbist_controller` is the main control FSM of the LBIST system.

It controls:

```text
LBIST start
PRPG enable
MISR enable
Pattern counting
Signature comparison
LBIST done indication
```

It connects with:

```text
PRPG/LFSR for pattern generation
DUT for applying test patterns
MISR for response compression
Signature comparator for pass/fail checking
JTAG or control register for start and pattern_count input
Status register or testbench for lbist_done output
```

This module is suitable for a basic DFT/LBIST project and can be integrated with scan, JTAG, MISR, PRPG, and signature comparison blocks.
