# ff_vs_latch Simulation Folder

This folder contains the simulation setup, testbenches, waveform dump files, and simulation scripts for the flip-flop-based and latch-based memory implementations.

## Implemented Modules

Two different top-level implementations are simulated:

- `top_mac_with_weight_sram`  
  MAC architecture with flip-flop-based weight memory.

- `top_mac_with_latch_mem`  
  MAC architecture with latch-based weight memory.

These implementations are used to compare the behavior, switching activity, and power consumption of flip-flop-based and latch-based memory structures.

---

## Folder Structure

- `testbenches/`  
  Contains the SystemVerilog/VHDL testbenches used for simulation.

- `work_top_mac_with_weight_sram/`  
  Contains compilation outputs, temporary simulation files, and generated waveform data for the flip-flop-based implementation.

- `work_top_mac_with_latch_mem/`  
  Contains compilation outputs, temporary simulation files, and generated waveform data for the latch-based implementation.

---

## File Lists

- `files_top_mac_with_weight_sram.f`  
  File list used when compiling the flip-flop-based implementation.

- `files_top_mac_with_latch_mem.f`  
  File list used when compiling the latch-based implementation.

---

## Main Scripts

### Flip-flop-based implementation

- `run_top_ff_sim.sh`
- `vcd_dump_top_ff.sv`

### Latch-based implementation

- `run_top_latch_sim.sh`
- `vcd_dump_top_latch.sv`

The `vcd_dump` files are used to generate VCD switching-activity files for power analysis.

---

## Typical Flow

Run the desired simulation:

### Flip-flop-based implementation

```bash
./run_top_ff_sim.sh
```

### Latch-based implementation

```bash
./run_top_latch_sim.sh
```

The generated VCD files can later be used for power estimation during synthesis and power analysis.