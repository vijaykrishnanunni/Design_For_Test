## LBIST Controller

The `lbist_controller` module controls the overall LBIST execution flow for the scan-inserted asynchronous FIFO. It generates the control signals required to move the design through scan shifting, functional capture, and final result evaluation.

---

## Purpose

The LBIST controller acts as the main control FSM for self-test. It decides:

* when LBIST starts
* when scan shifting is enabled
* when pseudo-random patterns are generated
* when MISR compaction happens
* when the test is complete
* when result comparison is enabled

---

## Main Control Signals

The controller drives the following outputs:

* `scan_en_wr`  
  Enables scan shifting in the write-domain scan chain

* `scan_en_rd`  
  Enables scan shifting in the read-domain scan chain

* `prpg_enable`  
  Enables the LFSR / PRPG so that pseudo-random patterns are generated

* `misr_enable`  
  Enables the MISR during response capture

* `bist_done`  
  Indicates that the LBIST sequence has completed

* `result_en`  
  Enables final result evaluation using the golden signature and comparator

---

## Inputs

* `clk`  
  Controller clock used to sequence the LBIST FSM

* `rst_n`  
  Active-low reset

* `start`  
  Starts the LBIST process

---

## FSM States

The controller uses four states:

### 1. `IDLE`

* Waiting state
* LBIST does not run
* All enables remain low
* Transitions to `SHIFT` when `start` is asserted

### 2. `SHIFT`

* Scan shifting is enabled
* PRPG is enabled
* Pseudo-random patterns are shifted into the scan chains
* After the required number of shift cycles, transitions to `CAPTURE`

### 3. `CAPTURE`

* Scan is disabled
* Functional response is captured
* MISR is enabled so the DUT response is compacted into a signature
* If more patterns remain, transitions back to `SHIFT`
* Otherwise transitions to `DONE`

### 4. `DONE`

* LBIST is complete
* `bist_done` is asserted
* `result_en` is asserted
* Final signature comparison can now be performed

---

## Controller Operation Flow

```text
IDLE --> SHIFT --> CAPTURE --> SHIFT --> CAPTURE --> ... --> DONE
