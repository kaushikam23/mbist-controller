# MBIST Controller Architecture

## Overview
The MBIST controller implements a microcode-based control architecture
capable of executing segmented March-style memory tests in the style of
mSR+.

Instead of encoding each March step as a fixed FSM state, the controller
fetches micro-instructions from a ROM and executes them sequentially.

## Control Hierarchy
The design uses two levels of sequencing:

- Segment Index:
  Selects a March phase (e.g., up-sweep, down-sweep).
- Element Index:
  Selects the operation within a phase (read, write, expect).

This structure allows complex March algorithms to be expressed compactly.

## Major Blocks
- MBIST Controller
- Microcode ROM
- Address Generator
- SRAM Wrapper
- Comparator and Status Logic

## Execution Flow
1. Test starts on assertion of `start`
2. Segment and element indices are initialized
3. Micro-instructions are fetched and decoded
4. Address sweeps are performed as specified
5. Read data is compared against expected values
6. Fail information is latched
7. Test completion is signaled
