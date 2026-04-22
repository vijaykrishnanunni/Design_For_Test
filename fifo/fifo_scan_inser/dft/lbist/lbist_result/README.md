## LBIST Result Evaluation

This folder contains the modules responsible for evaluating the final LBIST result after simulation or test completion.

### Files in this folder

* `golden_signature_mem.v`  
  Stores the expected fault-free MISR signature as the golden reference.

* `signature_comparator.v`  
  Compares the actual MISR output signature against the stored golden reference.

* `lbist_result_block.v`  
  Integrates the golden reference module and comparator into one result-evaluation block.

---

## Purpose of this folder

In LBIST, the MISR compresses the DUT responses into a final signature.

That signature alone does not say whether the design passed or failed.

To determine pass/fail, the final MISR output must be compared with a known correct signature obtained from a fault-free simulation. That expected signature is called the **golden reference** or **golden signature**.

This folder handles that comparison step.

---

## How the golden reference is obtained

The golden reference is taken from the **final MISR output of a fault-free simulation**.

### Steps

1. Simulate the complete fault-free LBIST path:
   * PRPG / LFSR
   * scan-inserted FIFO
   * MISR
   * LBIST controller
   * top module
   * testbench

2. Run the simulation until LBIST finishes.

3. Observe the final MISR output signature.

Example:

```text
Final MISR signature = 16'h3F92
