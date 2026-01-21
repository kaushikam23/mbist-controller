# RTL – MBIST Controller

This directory contains the synthesizable Verilog RTL for a
**microcode-based MBIST controller** and its supporting modules.

The design uses a micro-instruction driven control scheme, where March
test operations are stored as microcode and executed by the controller
logic.

## Module Description

- mbist_controller.v  
  Top-level MBIST controller. Orchestrates microcode execution, address
  generation, read/write control, and test completion signaling.

- mbist_microcode.v  
  Contains the microcode ROM defining the sequence of March operations
  executed by the MBIST controller.

- mbist_addrgen.v  
  Address generator module supporting incrementing and decrementing
  address sequences required by March algorithms.

- sram_wrapper.v  
  Wrapper around the SRAM interface used by the MBIST controller,
  abstracting memory read/write signaling.

- sram_model.v  
  Behavioral SRAM model used for functional simulation and verification.
  This module is intended for simulation only.
