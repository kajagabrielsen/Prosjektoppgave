# kg_mac Simulation Folder

This folder contains the simulation setup, testbenches, waveform dump files, and simulation scripts for the MAC-based CNN accelerator modules.

## Implemented Modules

Four different module configurations are simulated:

- `mac_csa`  
  MAC architecture with a CSA tree.

- `top_mac_with_weight_sram`  
  MAC architecture with integrated weight memory.

- `top_with_activation_buffer`  
  MAC architecture with integrated weight memory and activation buffer.

- `weight_sram`  
  Standalone weight memory module.

---

## Folder Structure

- `testbenches/`  
  Contains the SystemVerilog/VHDL testbenches used for simulation.

- `work_mac_csa/`  
  Contains compilation outputs, temporary simulation files, and generated waveform data for the MAC implementation.

- `work_top_mac_with_weight_sram/`  
  Contains simulation outputs and waveform data for the MAC with weight memory.

- `work_top_with_activation_buffer/`  
  Contains simulation outputs and waveform data for the MAC with activation buffering.

- `work_weight_sram/`  
  Contains simulation outputs and waveform data for the weight memory module.


---

## File Lists

- `files_mac_csa.f`  
  File list used for compiling the MAC implementation.

- `files_top_mac_with_weight_sram.f`  
  File list used for compiling the MAC with weight memory.

- `files_top_with_activation_buffer.f`  
  File list used for compiling the MAC with activation buffering.

- `files_weight_sram.f`  
  File list used for compiling the weight memory module.

---

## Main Scripts

### MAC with CSA tree

- `run_mac_sim.sh`
- `vcd_dump.sv`

### MAC with weight memory

- `run_top_sim.sh`
- `vcd_dump_top_sv`

### MAC with activation buffer

- `run_top_with_activation_buffer_sim.sh`
- `vcd_dump_top_with_activation_buffer.sv`

### Weight memory only

- `run_weight_sram_sim.sh`
- `vcd_dump_weight_sram.sv`

The `vcd_dump` files are used to generate VCD switching-activity files for power analysis.

---

## Typical Flow

Run the desired simulation script.

### MAC with CSA tree

```bash
./run_mac_sim.sh
```

### MAC with weight memory

```bash
./run_top_sim.sh
```

### MAC with activation buffer

```bash
./run_top_with_activation_buffer_sim.sh
```

### Weight memory only

```bash
./run_weight_sram_sim.sh
```

The generated VCD files can later be used for power estimation during synthesis and power analysis.