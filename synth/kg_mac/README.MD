# kg_mac Synthesis Folder

This folder contains the RTL, simulation, synthesis scripts, and generated reports for the MAC-based CNN accelerator modules.

## Folder Structure

- `rtl/`  
  Contains the VHDL source files for the MAC architecture and related modules.

- `out/`  
  Contains synthesized netlists and generated output files from synthesis.

- `synthesis_reports/`  
  Contains timing, area, and power reports generated after synthesis.

- `vcd_reports/`  
  Power analysis reports generated using switching activity from VCD files.

- `work/`  
  Temporary files generated during synthesis and formal verification.

---

## Main Scripts

- `run_power.sh`  
  Runs the complete synthesis and VCD-based power analysis flow.

- `run_genus`  
  Runs synthesis in Cadence Genus.

- `genus.cmd`  
  Main Cadence Genus command script.

- `config_syn.tcl`  
  Configuration settings for synthesis.

- `power_vcd.tcl`  
  TCL script for VCD-based power analysis.

- `synth.tcl`  
  Main synthesis TCL script.

---

## Typical Flow

Run the complete synthesis and power analysis flow:

```bash
./run_power.sh
```

This script:
1. Runs synthesis in Cadence Genus
2. Uses VCD switching activity for power estimation
3. Generates synthesis and power reports

Generated reports can be found in:
- `synthesis_reports/`
- `vcd_reports/`