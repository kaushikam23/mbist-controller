# Microcode Engine

## Purpose
The microcode engine defines memory test behavior independently of the
controller FSM.

Each micro-instruction specifies:
- Operation type
- Write data bit
- Expected read data bit
- End-of-sequence marker

## Microcode Interface
Inputs:
- index   : Selects the test segment
- element : Selects the operation within the segment

Outputs:
- op      : Memory operation encoding
- wr_bit  : Data value for write
- exp_bit : Expected data for read
- last    : Indicates final instruction

## Advantages
- Eliminates large hardcoded FSMs
- Enables scalable March-style algorithms
- Allows future extension without controller redesign
