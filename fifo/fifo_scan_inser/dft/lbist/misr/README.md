# MISR (Multiple Input Signature Register)

## What is MISR

MISR is a hardware block used in DFT to compress the output response of a DUT into a fixed-size value called a signature.

Instead of storing every output bit produced over many cycles, MISR keeps updating an internal register. At the end of the test, only the final register value is checked.

---

## Why MISR is Needed

During testing, the DUT produces output continuously.

Example:

Cycle 1 -> output  
Cycle 2 -> output  
Cycle 3 -> output  
...  
Cycle N -> output  

Storing and comparing all these outputs is difficult. MISR solves this by compressing the entire response into one smaller value.

---

## Basic Idea

MISR works like an LFSR, but instead of only shifting and feeding back internal bits, it also mixes in DUT output bits.

So on every clock cycle, the next signature depends on:

- the current signature
- the feedback bit
- the current DUT output

Because of this, the final signature represents the combined effect of all outputs seen during the test.

---

## What MISR Does

MISR does not generate test patterns.

It only captures and compresses DUT responses.

So in a BIST flow:

LFSR -> generates test patterns  
DUT -> responds to those patterns  
MISR -> compresses DUT outputs into a final signature  

---

## What Compression Means Here

Compression does not mean storing outputs in smaller form exactly.

It means many output bits over time are mixed into one fixed-size register.

For example, if the DUT gives output for 100 cycles, MISR may reduce all of that into a 16-bit signature.

So:

Large output sequence -> MISR -> final signature

---

## How It Works Internally

At every clock cycle, MISR does three things:

1. Takes a feedback bit from the current signature
2. Shifts the register
3. XORs the feedback and DUT input into selected positions

This repeated shifting and XOR mixing causes the register to depend on all previous outputs.

That is how compression is achieved.

---

## Role of the Polynomial

The polynomial decides where the feedback is applied inside the register.

This determines the tap positions.

Example polynomial:

x^16 + x^14 + x^13 + x^11 + 1

This means the feedback is XORed into specific register stages.

The polynomial is important because it gives good mixing and helps faults change the final signature.

---

## Why MISR is Useful

If even one DUT output bit changes because of a fault, the internal MISR state changes, and this usually changes the final signature.

So instead of checking the full output stream, we just compare one value.

If final signature matches expected signature -> PASS  
If final signature does not match -> FAIL

---

## In a FIFO Scan-Based Design

For a scan-inserted FIFO, the scan chain output can be connected to MISR.

Example flow:

LFSR -> scan input -> FIFO with scan FFs -> scan output -> MISR -> signature comparator

If the FIFO has separate write and read scan chains, separate MISRs can be used for each scan output.

---

## Difference Between LFSR and MISR

### LFSR
Used to generate pseudo-random test patterns

### MISR
Used to compress DUT response into a signature

So:

LFSR = pattern generator  
MISR = response compactor  

---

## Reference Signature

A correct design is first simulated with the same test setup.

The final MISR value from that run is stored as the reference or golden signature.

During testing, the new signature is compared with this reference.

---

## Interview Style Definition

MISR is a response compactor used in DFT and BIST. It compresses DUT output responses over multiple cycles into a fixed-length signature using shift and XOR feedback logic based on a polynomial. The final signature is compared with a known golden signature to detect faults.

---

## One-Line Summary

MISR is a hardware signature generator that compresses many DUT output bits over time into one fixed-size value for pass/fail testing.
