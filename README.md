# Design-For-Test

## Design for Testability (DFT) Implementation

## Overview

This project implements a complete **Design for Testability (DFT) architecture** around digital designs, focusing on improving **controllability, observability, and fault coverage**.

The work demonstrates practical implementation of:

* Scan-based testing
* JTAG (TAP Controller)
* Built-In Self-Test (BIST)
* Memory BIST (MBIST)
* ATPG-ready design

Target DUTs include combinational and sequential designs, extended to **asynchronous FIFO systems**.

---


## Key Components

### 1. Scan Design

* Muxed scan flip-flops replacing standard FFs
* Serial shift capability via scan chain
* Modes:

  * Functional mode
  * Scan mode (shift + capture)

**Purpose:**

* Full internal state control and observation
* Enables high fault coverage via ATPG

---

### 2. TAP Controller (JTAG)

Implements IEEE 1149.1 standard FSM

* Inputs: TCK, TMS, TDI, TRST
* Output: TDO
* Controls:

  * Scan enable
  * Shift/Capture/Update operations

**Features:**

* 16-state TAP FSM
* Instruction & Data registers
* External test access

---

### 3. Built-In Self-Test (BIST)

#### Pattern Generator

* Linear Feedback Shift Register (LFSR)
* Generates pseudo-random test vectors

#### Response Analyzer

* Multiple Input Signature Register (MISR)
* Compresses DUT outputs into signature

**Flow:**

```
LFSR → DUT → MISR → Signature Compare
```

**Advantages:**

* At-speed testing
* Reduced dependency on external testers

---

### 4. Memory BIST (MBIST)

Used for embedded memories (e.g., FIFO RAM)

* Implements March algorithms
* Detects:

  * Stuck-at faults
  * Coupling faults
  * Address decoder faults

**Why needed:**
Scan is inefficient for memory → MBIST provides efficient coverage

---

### 5. ATPG Compatibility

* Scan chains designed for external ATPG tools
* Supports:

  * Stuck-at fault models
  * Transition faults
* Compatible with industry tools (e.g., Synopsys TetraMAX)

---

## DUT Integration Strategy

Two approaches implemented:

### 1. Wrapper-Based DFT

* DUT remains unchanged
* Scan logic wrapped around it

### 2. Internal Scan Replacement

* Flip-flops replaced with scan FFs
* Higher controllability

---

## Implementation Details

### Languages

* Verilog / SystemVerilog

### Structure

* Modular design:

  * `scan_ff.v`
  * `tap_controller.v`
  * `bist_controller.v`
  * `mbist_controller.v`
  * `dft_wrapper.v`
  * `dft_top.v`

---

## Verification Strategy

* Functional simulation using Synopsys VCS
* Test scenarios:

  * Scan shift and capture validation
  * TAP state transitions
  * BIST signature verification
  * MBIST memory test patterns

---

## Key Learnings

* Trade-offs between **area, test time, and coverage**
* Importance of scan chain balancing
* Handling clock domain crossings in DFT
* Integration challenges in real hardware systems
* Debugging scan and BIST failures

---

## Highlights

* Full DFT stack implemented from scratch
* Industry-aligned architecture (Scan + JTAG + BIST + MBIST)
* Extended to complex DUT (Asynchronous FIFO)
* Practical understanding of test flows used in VLSI industry

---

## Future Work

* LBIST (Logic BIST) integration
* Test compression techniques
* Power-aware DFT
* Integration with full ASIC flow

---

## Author

Vijay Krishnan Unni
Electronics Engineering (ECE)
Focus: VLSI Design,SoC Design, DFT, Verification, RTL-GDS2

---

