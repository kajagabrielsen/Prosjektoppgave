# kg_mac_sram Synthesis Folder

This folder contains the RTL, synthesis scripts, generated netlists, and power analysis reports for the MAC-based CNN accelerator modules with weight memory and activation buffering.

## Implemented Modules

Three different module configurations are included in this folder:

- `top`  
  MAC architecture with integrated weight memory.

- `top_with_activation_buffer`  
  MAC architecture with integrated weight memory and activation buffer.

- `weight_sram`  
  Standalone weight memory module.

Each configuration has its own synthesis and power-analysis scripts.

---

## Folder Structure

- `rtl/`  
  Contains the VHDL source files for the MAC, weight memory, and activation-buffer architectures.

- `out/`  
  Contains synthesized netlists and generated output files from Cadence Genus.

- `synthesis_reports/`  
  Contains timing, area, and synthesis reports.

- `vcd_reports/`  
  Contains power analysis reports generated using VCD switching activity.

- `work/`  
  Contains temporary files generated during synthesis and formal verification.

---

## Main Scripts

### Top (MAC + weight memory)

- `run_genus_top`
- `run_power_top.sh`
- `config_syn_top.tcl`
- `synth_top.tcl`
- `power_vcd.tcl`

### Top with activation buffer

- `run_genus_top_with_activation_buffer`
- `run_power_top_with_activation_buffer.sh`
- `config_syn_top_with_activation_buffer.tcl`
- `synth_top_with_activation_buffer.tcl`
- `power_vcd_top_with_activation_buffer.tcl`

### Weight memory only

- `run_genus_weight_sram`
- `run_power_weight_sram.sh`
- `config_syn_weight_sram.tcl`
- `synth_weight_sram.tcl`
- `power_vcd_weight_sram.tcl`

---

## Typical Flow

Run the complete synthesis and power-analysis flow for the desired module.

### MAC + weight memory

```bash
./run_power_top.sh
```

### MAC + weight memory + activation buffer

```bash
./run_power_top_with_activation_buffer.sh
```

### Weight memory only

```bash
./run_power_weight_sram.sh
```

Each script:
1. Runs synthesis in Cadence Genus
2. Uses VCD switching activity for power estimation
3. Generates synthesis and power reports

Generated reports can be found in:
- `synthesis_reports/`
- `vcd_reports/`