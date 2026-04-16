## Scan-Inserted Asynchronous FIFO

This module is a manually scan-inserted version of the asynchronous FIFO. The original FIFO control and state registers are replaced with scan-capable flip-flops, while the memory array remains unchanged. The design preserves the asynchronous FIFO behavior and adds scan access separately for the write and read clock domains.

---

## Design Overview

The module is:

```verilog
module asy_fifo_scan #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4
)
```

It contains:

* Functional FIFO logic
* Scan-inserted write-domain registers
* Scan-inserted read-domain registers
* Two separate scan chains:
  * one for the write clock domain
  * one for the read clock domain

This is important because the DUT is an **asynchronous FIFO**, so the design uses **two clocks**, not one.

---

## Clocks Used in the Design

This design uses **two clocks**:

* `wr_clk` for the write domain
* `rd_clk` for the read domain

The scan architecture also follows this same dual-domain structure:

* the **write-domain scan chain** is clocked by `wr_clk`
* the **read-domain scan chain** is clocked by `rd_clk`

So this design does **not** use one common scan clock internally. It is partitioned into **two separate scan chains**, each associated with its own clock domain.

---

## Functional Ports

### Write-side ports

* `wr_clk`  
  Write clock

* `wr_rst_n`  
  Active-low reset for the write domain

* `wr_en`  
  Write enable

* `wr_data[DATA_WIDTH-1:0]`  
  Input data written into the FIFO memory

### Read-side ports

* `rd_clk`  
  Read clock

* `rd_rst_n`  
  Active-low reset for the read domain

* `rd_en`  
  Read enable

* `rd_data[DATA_WIDTH-1:0]`  
  Output data read from the FIFO

### Status outputs

* `full`  
  Indicates the FIFO is full

* `empty`  
  Indicates the FIFO is empty

---

## Scan Ports Added

The scan-inserted FIFO adds separate scan ports for the two domains.

### Write-domain scan ports

* `scan_en_wr`  
  Scan enable for the write-domain scan chain

* `scan_in_wr`  
  Serial scan input for the write-domain scan chain

* `scan_out_wr`  
  Serial scan output for the write-domain scan chain

### Read-domain scan ports

* `scan_en_rd`  
  Scan enable for the read-domain scan chain

* `scan_in_rd`  
  Serial scan input for the read-domain scan chain

* `scan_out_rd`  
  Serial scan output for the read-domain scan chain

These ports show that scan is implemented as **two separate chains**, not a single combined chain.

---

## Registers Converted into Scan Flip-Flops

The original FIFO storage elements for logic and control are implemented through scan flip-flop replacement.

### Write-domain scan-replaced registers

* `wr_bin`
* `wr_gray`
* `rd_gray_sync1`
* `rd_gray_sync2`

These are placed in the write-domain scan chain and clocked by `wr_clk`.

### Read-domain scan-replaced registers

* `rd_bin`
* `rd_gray`
* `wr_gray_sync1`
* `wr_gray_sync2`
* `rd_data_int`

These are placed in the read-domain scan chain and clocked by `rd_clk`.

---

## Registers Not Replaced

The memory array is not replaced by scan flip-flops:

```verilog
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
```

This is intentional.

* The FIFO memory remains a memory array
* It is not converted into scan cells
* In a complete DFT flow, memory is usually targeted using MBIST rather than full scan

---

## Functional Next-State Logic

The scan-inserted design keeps the original next-state logic and only changes how state is stored.

### Write-side next-state logic

* `wr_bin_next`
* `wr_gray_next`

Computed as:

* next write binary pointer
* next write Gray pointer

### Read-side next-state logic

* `rd_bin_next`
* `rd_gray_next`

Computed as:

* next read binary pointer
* next read Gray pointer

### Read data next-state logic

* `rd_data_next`

This computes the next value of the read data register.

So the design still uses normal combinational next-state logic, but the actual state elements are now implemented using scan flip-flops.

---

## Status Logic

The FIFO status logic remains functionally the same.

### Empty logic

```verilog
assign empty = (rd_gray == wr_gray_sync2);
```

The FIFO is empty when the read pointer matches the synchronized write pointer in the read domain.

### Full logic

```verilog
assign full =
    (wr_gray_next ==
     {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
       rd_gray_sync2[ADDR_WIDTH-2:0]});
```

The FIFO is full when the next write Gray pointer matches the inverted-MSB full condition based on the synchronized read pointer.

---

## Write-Domain Scan Chain

The RTL explicitly defines the write-domain scan chain as:

* `wr_bin`
* `wr_gray`
* `rd_gray_sync1`
* `rd_gray_sync2`

This leads to the chain length:

```verilog
localparam WR_CHAIN_LEN = 4 * (ADDR_WIDTH + 1);
```

Why `4 * (ADDR_WIDTH + 1)`?

Because the chain contains 4 register groups:

* `wr_bin`
* `wr_gray`
* `rd_gray_sync1`
* `rd_gray_sync2`

Each of these is `ADDR_WIDTH+1` bits wide.

So total write-chain length is:

* `4 × (ADDR_WIDTH+1)`

The write chain starts from:

* `scan_in_wr`

and ends at:

* `scan_out_wr`

---

## Read-Domain Scan Chain

The RTL explicitly defines the read-domain scan chain as:

* `rd_bin`
* `rd_gray`
* `wr_gray_sync1`
* `wr_gray_sync2`
* `rd_data_int`

This leads to the chain length:

```verilog
localparam RD_CHAIN_LEN = 4 * (ADDR_WIDTH + 1) + DATA_WIDTH;
```

Why?

Because the chain contains:

* 4 register groups of width `ADDR_WIDTH+1`
* 1 data register group of width `DATA_WIDTH`

So total read-chain length is:

* `4 × (ADDR_WIDTH+1) + DATA_WIDTH`

The read chain starts from:

* `scan_in_rd`

and ends at:

* `scan_out_rd`

---

## How Scan Operation Works

Each internal state bit is implemented using a `scan_ff`.

A scan flip-flop has:

* functional input `d`
* scan input `si`
* scan enable `scan_en`
* output `q`
* scan output `so`

### In functional mode

* `scan_en = 0`
* the flip-flop captures functional data `d`

### In scan mode

* `scan_en = 1`
* the flip-flop captures serial scan input `si`

This allows internal FIFO state to be shifted in and shifted out through the scan chains.

---

## Why Two Scan Chains Are Used

This design uses two scan chains because the FIFO itself has two asynchronous clock domains.

Using a single internal chain across both domains would be unsafe and structurally incorrect for this architecture.

So the design separates scan access into:

* one chain for write-domain registers
* one chain for read-domain registers

This matches the dual-clock nature of the asynchronous FIFO.

---

## What Changed from the Original FIFO

Compared to the original FIFO:

* normal state registers are replaced with scan flip-flops
* new scan ports are added
* internal states become serially controllable and observable
* write and read domains now each have their own scan chain
* the memory array remains unchanged
* functional FIFO operation is preserved when scan is disabled

---

## DFT Significance

This scan-inserted FIFO improves testability by making important internal states directly accessible during test.

Benefits include:

* improved controllability of internal registers
* improved observability of internal registers
* compatibility with scan-based test methodologies
* support for ATPG-oriented scan testing
* a structure that can later work with LBIST support

---

## Summary

This design is a **dual-clock scan-inserted asynchronous FIFO**.

Key features:

* asynchronous FIFO structure retained
* two functional clocks:
  * `wr_clk`
  * `rd_clk`
* two independent scan chains:
  * write-domain scan chain
  * read-domain scan chain
* internal control/state registers replaced by scan flip-flops
* memory array kept outside scan

So this is not a single-clock scan design. It is a **two-clock, two-scan-chain scan-inserted FIFO**, matching the actual RTL design.
