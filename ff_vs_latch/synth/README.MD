# ff_vs_latch Synthesis Folder

This folder contains the RTL, synthesis scripts, generated netlists, and power analysis reports for the flip-flop-based and latch-based memory implementations used in the CNN accelerator project.

## Implemented Modules

Two different top-level implementations are included:

- `top_ff`  
  MAC architecture with flip-flop-based weight memory.

- `top_latch`  
  MAC architecture with latch-based weight memory.

These implementations are used to compare the power and area characteristics of flip-flop-based and latch-based storage structures.

---

## Folder Structure

- `rtl/`  
  Contains the VHDL source files for the MAC and memory architectures.

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

### Flip-flop-based implementation

- `run_genus_top_ff`
- `run_power_top_ff.sh`
- `config_syn_top_ff.tcl`
- `synth_top_ff.tcl`
- `power_vcd_top_ff.tcl`

### Latch-based implementation

- `run_genus_top_latch`
- `run_power_top_latch.sh`
- `config_syn_top_latch.tcl`
- `synth_top_latch.tcl`
- `power_vcd_top_latch.tcl`

---

## Typical Flow

Run the complete synthesis and power-analysis flow for the desired implementation.

### Flip-flop-based implementation

```bash
./run_power_top_ff.sh
```

### Latch-based implementation

```bash
./run_power_top_latch.sh
```

Each script:
1. Runs synthesis in Cadence Genus
2. Uses VCD switching activity for power estimation
3. Generates synthesis and power reports

Generated reports can be found in:
- `synthesis_reports/`
- `vcd_reports/`