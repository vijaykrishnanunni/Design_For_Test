# LBIST Controller

## Overview

`lbist_controller.v` controls the LBIST operation using an FSM.

It enables the required LBIST blocks in the correct order:

```text
PRPG/LFSR ---> DUT ---> MISR ---> Signature Comparator
```

The controller does not generate patterns or compare signatures by itself.  
It only generates control signals.

---

## FSM States

```text
IDLE    : Wait for lbist_start
INIT    : Initialize LBIST and clear counter
RUN     : Enable PRPG and MISR
COMPARE : Enable signature comparator
DONE    : LBIST completed
```

FSM flow:

```text
IDLE -> INIT -> RUN -> COMPARE -> DONE -> IDLE
```

---

## Input Signals

```text
clk
Main clock for the controller.

rst_n
Active-low reset. Resets FSM to IDLE.

lbist_start
Starts LBIST. Usually comes from testbench, JTAG, or control register.

pattern_count
Number of PRPG patterns to apply before comparison.
```

---

## Output Signals

```text
lbist_active
High when LBIST is running.

prpg_enable
Goes to PRPG/LFSR. Enables pattern generation.

misr_enable
Goes to MISR. Enables response compression.

compare_enable
Goes to signature comparator. Enables final comparison.

lbist_done
Goes to status/JTAG/testbench. Indicates LBIST completed.
```

---

## Internal Signals

```text
state
Stores the current FSM state.

next_state
Stores the next FSM state.

count
Counts how many PRPG patterns have been applied.
```

---

## FSM Blocks

### 1. State Register Block

```text
Updates the current state on every clock edge.
On reset, state becomes IDLE.
```

---

### 2. Next-State Logic Block

```text
Decides the next state based on current state, lbist_start, count, and pattern_count.
```

Example:

```text
If state is RUN and count reaches pattern_count, go to COMPARE.
```

---

### 3. Pattern Counter Block

```text
Clears count in IDLE and INIT.
Increments count during RUN.
Holds count during COMPARE and DONE.
```

The counter tells the FSM when enough test patterns have been applied.

---

### 4. Output Control Block

```text
Generates control signals based on current state.
```

Output behavior:

```text
IDLE    : all outputs low
INIT    : lbist_active high
RUN     : lbist_active, prpg_enable, misr_enable high
COMPARE : lbist_active, compare_enable high
DONE    : lbist_done high
```

---

## Signal Origin and Destination

```text
Signal           Origin                         Destination

clk              System/test clock              Controller FSM and counter
rst_n            System/test reset              Controller FSM and counter
lbist_start      JTAG/register/testbench        Controller next-state logic
pattern_count    JTAG/register/testbench        Counter and next-state logic

prpg_enable      LBIST controller               PRPG/LFSR
misr_enable      LBIST controller               MISR
compare_enable   LBIST controller               Signature comparator
lbist_done       LBIST controller               Status register/JTAG/testbench
lbist_active     LBIST controller               Top wrapper/status logic
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

## Summary

The LBIST controller manages the complete LBIST sequence.

It starts the test, enables PRPG and MISR, counts the applied patterns, enables final comparison, and asserts `lbist_done` when testing is complete.
