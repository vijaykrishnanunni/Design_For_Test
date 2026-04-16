# Scan Inserted Asynchronous FIFO

## Overview

This project implements a **scan-inserted asynchronous FIFO** designed for DFT (Design for Testability). The FIFO operates across two clock domains and includes scan chains for controllability and observability during testing.

---

## Features

* Dual clock domains (write and read)
* Gray-coded pointer synchronization (CDC safe)
* Full and empty flag generation
* Scan chain integration for DFT
* Compatible with ATPG testing

---

## FIFO Architecture

### Core Blocks

* Memory array (dual-port)
* Write pointer (binary + Gray)
* Read pointer (binary + Gray)
* Synchronizers (2-stage flip-flops)
* Full/Empty logic

---

## Scan Insertion

### What is Added

* All flip-flops replaced with **Scan Flip-Flops (SFFs)**
* Scan chain connectivity
* Test control signals

### Additional Ports

```
input scan_in;
output scan_out;
input scan_en;
input test_clk;   // optional (depends on design)
```

---

## Scan Flip-Flop Behavior

Each scan FF acts as:

* **Normal Mode (scan_en = 0):** behaves like a regular DFF
* **Scan Mode (scan_en = 1):** shifts data serially through scan chain

---

## Scan Chain Structure

All FFs are connected in a serial chain:

```
scan_in -> FF1 -> FF2 -> ... -> FFn -> scan_out
```

This allows:

* Shifting test patterns in
* Observing internal states

---

## Changes from Original FIFO

### 1. Flip-Flops

* Original: DFFs
* Modified: Scan FFs

### 2. Additional Logic

* Multiplexer inside each FF (functional vs scan input)

### 3. Control Signals

* Added scan_en to switch modes

### 4. No Functional Change

* Functional FIFO behavior remains identical when scan_en = 0

---

## Clocking Considerations

* Functional mode uses:

  * wr_clk
  * rd_clk

* Scan mode uses:

  * Single test clock (preferred) OR stitched clocks

---

## Testing Flow

1. Enable scan mode (scan_en = 1)
2. Shift in test vector via scan_in
3. Apply test clock pulses
4. Capture response
5. Shift out via scan_out

---

## CDC and Scan Interaction

* Synchronizers are also scan inserted
* Care must be taken to avoid metastability during test
* Typically controlled using test constraints (ATPG)

---

## Advantages

* High fault coverage
* Easy internal visibility
* Supports automated test generation

---

## Limitations

* Increased area (due to scan FFs)
* Slight timing overhead
* Requires careful clock handling in test mode

---

## Summary

This design enhances a standard asynchronous FIFO with **scan-based DFT**, enabling robust post-silicon testing without affecting functional operation.

---

## Keywords

DFT, Scan Chain, Asynchronous FIFO, CDC, Gray Code, ATPG
