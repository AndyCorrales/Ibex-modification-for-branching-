# Ibex RISC-V — Dynamic Branch Predictor Modification

> Modification of the lowRISC Ibex RISC-V processor to replace the static branch predictor with a 2-bit bimodal dynamic predictor, validated using OpenROAD-flow-scripts (ORFS).

---

## Functional Nodes

| Node | PDK | Status | Predictor |
|------|-----|--------|-----------|
| 45nm | Nangate45 | Functional | Dynamic bimodal enabled |
| 130nm | SkyWater 130HD | Functional | Dynamic bimodal enabled |

---

## What Was Modified?

### New File
- `designs/src/ibex_sv/ibex_branch_predict_dynamic.sv` — 2-bit bimodal predictor with 64-entry BHT

### Modified Files
- `designs/src/ibex_sv/ibex_core.sv` — `BranchPredictor = 1'b1`, adds parameter `DynamicBranchPredictor = 1'b1`
- `designs/src/ibex_sv/ibex_if_stage.sv` — Conditional selection between static and dynamic predictor, feedback ports from ID/EX stage

### Area Overhead

| Configuration | Area (um2) | Difference |
|---------------|-----------|------------|
| Original Ibex (no predictor) | ~61,000 | baseline |
| Ibex with dynamic predictor | ~62,958 | +3.2% |

---

## Requirements

- Ubuntu 20.04 or 22.04
- 16 GB RAM (8 GB minimum)
- 100 GB free disk space
- 8 CPU cores (4 minimum)

---

## Setup from Scratch

### 1. Install System Dependencies

```bash
sudo apt update
sudo apt install -y git make python3 python3-pip \
    build-essential cmake gcc g++ \
    tcl-dev tk-dev swig bison flex \
    libboost-all-dev libeigen3-dev \
    libffi-dev libreadline-dev \
    liblemon-dev libspdlog-dev \
    qtbase5-dev qt5-image-formats-plugins \
    libqt5opengl5-dev klayout \
    zlib1g-dev libpcre3-dev
```

### 2. Clone and Build OpenROAD-flow-scripts

```bash
mkdir -p ~/vlsi && cd ~/vlsi

# Clone with submodules
git clone --recursive \
  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts

cd OpenROAD-flow-scripts

# Use the latest stable tag
git tag --sort=-creatordate | head -3
git checkout -B 26Q1
git submodule update --init --recursive

# Install dependencies and compile (~45 minutes)
sudo ./setup.sh
./build_openroad.sh --local

# Activate the environment
source env.sh

# Verify installation
openroad -version
yosys -V
```

### 3. Integrate This Repository

```bash
cd ~/vlsi/OpenROAD-flow-scripts/flow

# Clone this repo
git clone https://github.com/AndyCorrales/Ibex-modification-for-branching- \
    designs_ibex_branch

# Copy modified RTL
cp -r designs_ibex_branch/designs/src/ibex_sv \
      designs/src/

# Copy configs for each PDK
cp -r designs_ibex_branch/designs/sky130hd/ibex_branch \
      designs/sky130hd/

cp -r designs_ibex_branch/designs/nangate45/ibex_branch \
      designs/nangate45/

cp -r designs_ibex_branch/designs/asap7/ibex_branch \
      designs/asap7/
```

---

## Running the Flow

```bash
cd ~/vlsi/OpenROAD-flow-scripts/flow

# Nangate45 (45nm) — ~30 minutes
make DESIGN_CONFIG=designs/nangate45/ibex_branch/config.mk

# SkyWater 130HD (130nm) — ~1.5-2 hours
make DESIGN_CONFIG=designs/sky130hd/ibex_branch/config.mk
```

### View Results

```bash
# Total standard cell area
grep "design__instance__count__stdcell" \
  reports/nangate45/ibex_branch/base/6_final_metrics.json

grep "design__instance__count__stdcell" \
  reports/sky130hd/ibex_branch/base/6_final_metrics.json

# Timing (Worst Negative Slack)
grep "timing__setup__ws" \
  reports/nangate45/ibex_branch/base/6_final_metrics.json

# Open GUI with final layout
make DESIGN_CONFIG=designs/nangate45/ibex_branch/config.mk gui_final
make DESIGN_CONFIG=designs/sky130hd/ibex_branch/config.mk gui_final
```

### Clean and Re-run

```bash
# Clean a specific node entirely
make DESIGN_CONFIG=designs/nangate45/ibex_branch/config.mk clean_all

# Clean only routing stage
make DESIGN_CONFIG=designs/sky130hd/ibex_branch/config.mk clean_route
```

---

## Configuration Differences Between Nodes

The sky130hd node requires more conservative parameters due to routing congestion caused by the 128 BHT flip-flops in the lower metal layers.

| Parameter | Nangate45 | SkyWater 130HD |
|-----------|-----------|----------------|
| CORE_UTILIZATION | 45% | 20-30% |
| PLACE_DENSITY_LB_ADDON | 0.20 | 0.05-0.10 |
| fastroute.tcl | Not required | Layer adj. 0.05/layer |
| DETAILED_ROUTE_END_ITERATION | 64 (default) | 100 |
| DETAILED_ROUTE_ALLOW_PARTIAL_DRC | 0 | 1 |

### Why sky130hd Needs Special Configuration

The dynamic predictor adds 128 flip-flops (BHT) plus update logic, generating additional local connections in the lower metal layers (met1/met2). With the original parameters (50% utilization), the router produced up to 54,000 short violations in met1. Reducing core utilization to 20-30% and adjusting the per-layer routing adjustment to 0.05 gives the router enough space to resolve BHT connections without creating metal shorts.

---

## Verifying the Dynamic Predictor is Active

```bash
# Check that the dynamic module appears in the synthesized netlist
grep "ibex_branch_predict_dynamic" \
  results/nangate45/ibex_branch/base/1_synth.v
```

If the command returns results, the dynamic predictor is correctly instantiated.

---

## Repository Structure

```
Ibex-modification-for-branching-/
├── README.md
└── designs/
    ├── src/
    │   └── ibex_sv/                            <- Full modified Ibex RTL
    │       ├── ibex_branch_predict_dynamic.sv  <- NEW: bimodal predictor
    │       ├── ibex_core.sv                    <- MODIFIED: BranchPredictor=1
    │       ├── ibex_if_stage.sv                <- MODIFIED: dynamic selection
    │       └── ... (remaining RTL unchanged)
    ├── sky130hd/
    │   └── ibex_branch/
    │       ├── config.mk
    │       ├── constraint.sdc
    │       └── fastroute.tcl
    ├── nangate45/
    │   └── ibex_branch/
    │       ├── config.mk
    │       └── constraint.sdc
    └── asap7/
        └── ibex_branch/
            ├── config.mk
            └── constraint.sdc
```

---

## References

- [lowRISC Ibex RISC-V Core](https://github.com/lowRISC/ibex)
- [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
- [ORFS Flow Tutorial](https://openroad-flow-scripts.readthedocs.io/en/latest/tutorials/FlowTutorial.html)
- [SkyWater 130nm PDK](https://github.com/google/skywater-pdk)
