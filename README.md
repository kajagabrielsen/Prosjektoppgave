# Power-Reduction Techniques for Hardware Implementations of CNN Accelerator

This repository contains the source code and supporting material for the project thesis:

**"Power-Reduction Techniques for Hardware Implementations of CNN Accelerator"**

The project investigates architectural techniques for reducing power consumption in CNN accelerator hardware, with focus on:
- Multiply–Accumulate (MAC) architectures
- Memory-access optimization
- Operand isolation
- Truncation
- Clock gating
- Activation buffering
- Latch-based and flip-flop-based memory structures

The hardware architectures were implemented in VHDL and evaluated using synthesis and post-synthesis power analysis.

---

# Project Overview

The project evaluates several power-reduction techniques for CNN accelerator architectures implemented using:
- VHDL
- Cadence Xcelium
- Cadence Genus
- ASAP7 7 nm standard-cell library

The implemented architectures include:
- Baseline MAC architecture using a CSA tree
- Truncated MAC architecture
- Operand-isolated MAC architecture
- Clock-gated implementations
- Flip-flop-based weight memory
- Latch-based weight memory
- Sliding-window activation buffering
- Line-buffer-based activation reuse

Power consumption and area utilization were analyzed using synthesized netlists and VCD-based switching activity.

---

├── ff_vs_latch/
│   ├── sim/kg_mac      # Testbenches for MAC implementations with flip-flop-based and latch-based weight memory
│   └── synth/kg_mac    # RTL implementations of MAC architectures with flip-flop-based and latch-based weight memory
├── sim/kg_mac/
│   └── testbenches/    # Testbenches for MAC architectures with and without weight and activation memory
├── synth/
│   ├── kg_mac/         # RTL implementations of MAC architectures without weight or activation memory
│   └── kg_mac_sram/    # RTL implementations of MAC architectures with weight memory and optional activation buffering
└── README.md
