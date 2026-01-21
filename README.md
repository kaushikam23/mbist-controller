# Microcode-Based MBIST Controller 

## Overview
This repository contains a synthesizable Verilog implementation of a
**microcode-based Memory Built-In Self-Test (MBIST) controller** with
support for **mSR+ style segmented March execution**.

The design separates test behavior from control logic by encoding memory
test operations as microcode. This enables flexible sequencing of
multi-phase March algorithms without hardcoding large FSMs.

The controller has been implemented, simulated, and timing-verified
using Xilinx Vivado.

## Key Features
- Microcode-driven MBIST control
- Two-level sequencing:
  - Segment index (March phase)
  - Element index (operation within a phase)
- Address sweep support (increment / decrement)
- Read / write / compare operations
- Fail address capture and test completion signaling
- Timing-closed FPGA implementation

## Architecture Summary
- Microcode ROM defines memory test behavior
- Controller FSM sequences micro-instructions
- Address generator performs directional sweeps
- SRAM wrapper abstracts memory interface
- Behavioral SRAM model used for verification

## Tools Used
- Xilinx Vivado 

## Verification
- Functional simulation using Vivado simulator
- Testbench demonstrating correct microcode execution
- Timing summary meeting design constraints

