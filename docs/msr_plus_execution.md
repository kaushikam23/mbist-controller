# mSR+ Style Execution Model

## Concept
The controller follows an mSR+ style execution model, where a memory test
is composed of multiple segments, each containing a sequence of memory
operations.

Each segment corresponds to a March phase, and each element corresponds
to a specific read or write operation.

## Implementation
- Segment transitions are driven by microcode
- Address sweep direction is controlled per segment
- Completion of a sweep advances the microcode index
- The final segment asserts test completion

## Benefits
- Compact representation of complex March algorithms
- Clear separation between algorithm and control logic
- Suitable for multi-segment memory test flows
