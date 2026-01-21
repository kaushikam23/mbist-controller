# MBIST Controller (Verilog)

## Overview
This repository contains a synthesizable Verilog implementation of a
Memory Built-In Self-Test (MBIST) controller for SRAM testing.

The controller uses a **microcode-based FSM architecture**, where March
test algorithms are encoded as micro-operations rather than hardwired
state transitions. This approach improves flexibility, scalability, and
reuse across different memory configurations.

The design is technology-independent and suitable for both FPGA
prototyping and ASIC DFT flows.

## Motivation
Modern SoCs integrate large on-chip memories that require efficient,
configurable self-test mechanisms. Traditional hardcoded FSMs become
difficult to extend for multiple March algorithms.

A microcode-driven MBIST controller allows:
- Easy support for multiple March algorithms
- Compact and structured control logic
- Improved maintainability and extensibility

## Key Features
- **Microcode-driven MBIST controller**
- FSM for micro-instruction sequencing
- Configurable address generation (up / down)
- Read / Write / Compare operations
- Fail flag and test completion signaling
- Modular, reusable RTL structure

## Supported Algorithms
- mSR+ 
- March C− 
- Support for additional March algorithms via microcode ROM

## Architecture Overview
The MBIST controller consists of:
- Microcode ROM (stores March operations)
- Micro-instruction sequencer FSM
- Address generator
- Data generator
- Comparator and fail logic

## Repository Structure
rtl/ → Synthesizable Verilog modules
tb/ → Verification testbenches
docs/ → Architecture and microcode documentation
constraints/ → Constraints file for the Design
results/ → Simulation and verification outputs

## Tools & Environment
- Xilinx Vivado




