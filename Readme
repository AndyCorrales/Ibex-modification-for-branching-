# Ibex RISC-V — Dynamic Branch Predictor Modification

> Modificación del procesador Ibex RISC-V para reemplazar el predictor de branch estático por un predictor dinámico bimodal de 2 bits, validado en OpenROAD-flow-scripts (ORFS).

---

## Nodos Funcionales

| Nodo | PDK | Estado | Predictor |
|------|-----|--------|-----------|
| 45nm | Nangate45 | ✅ Funcional | Dinámico bimodal habilitado |
| 130nm | SkyWater 130HD | ✅ Funcional | Dinámico bimodal habilitado |

---

## ¿Qué se modificó?

### Archivo nuevo
- `designs/src/ibex_sv/ibex_branch_predict_dynamic.sv` — Predictor bimodal de 2 bits con BHT de 64 entradas

### Archivos modificados
- `designs/src/ibex_sv/ibex_core.sv` — `BranchPredictor = 1'b1`, añade parámetro `DynamicBranchPredictor = 1'b1`
- `designs/src/ibex_sv/ibex_if_stage.sv` — Selección condicional entre predictor estático y dinámico, puertos de feedback desde ID/EX

### Overhead de área
| Config | Área (µm²) | Diferencia |
|--------|-----------|------------|
| Ibex original (sin predictor) | ~61,000 | baseline |
| Ibex con predictor dinámico | ~62,958 | +3.2% |

---

## Requisitos

- Ubuntu 20.04 o 22.04
- 16 GB RAM (mínimo 8 GB)
- 100 GB de disco libre
- 8 CPU cores (mínimo 4)

---

## Instalación desde cero

### 1. Instalar dependencias del sistema

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

### 2. Clonar y compilar OpenROAD-flow-scripts

```bash
mkdir -p ~/vlsi && cd ~/vlsi

# Clonar con submodulos
git clone --recursive \
  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts

cd OpenROAD-flow-scripts

# Usar el tag estable mas reciente
git tag --sort=-creatordate | head -3
git checkout -B 26Q1
git submodule update --init --recursive

# Instalar dependencias y compilar (~45 minutos)
sudo ./setup.sh
./build_openroad.sh --local

# Activar el entorno
source env.sh

# Verificar
openroad -version
yosys -V
```

### 3. Integrar este repositorio

```bash
cd ~/vlsi/OpenROAD-flow-scripts/flow

# Clonar este repo
git clone https://github.com/AndyCorrales/Ibex-modification-for-branching- \
    designs_ibex_branch

# Copiar RTL modificado
cp -r designs_ibex_branch/designs/src/ibex_sv \
      designs/src/

# Copiar configs de cada PDK
cp -r designs_ibex_branch/designs/sky130hd/ibex_branch \
      designs/sky130hd/

cp -r designs_ibex_branch/designs/nangate45/ibex_branch \
      designs/nangate45/

cp -r designs_ibex_branch/designs/asap7/ibex_branch \
      designs/asap7/
```

---

## Correr el flujo

```bash
cd ~/vlsi/OpenROAD-flow-scripts/flow

# Nangate45 (45nm) — ~30 minutos
make DESIGN_CONFIG=designs/nangate45/ibex_branch/config.mk

# SkyWater 130HD (130nm) — ~1.5-2 horas
make DESIGN_CONFIG=designs/sky130hd/ibex_branch/config.mk
```

### Ver resultados

```bash
# Area total de celdas
grep "design__instance__count__stdcell" \
  reports/nangate45/ibex_branch/base/6_final_metrics.json

grep "design__instance__count__stdcell" \
  reports/sky130hd/ibex_branch/base/6_final_metrics.json

# Timing (Worst Negative Slack)
grep "timing__setup__ws" \
  reports/nangate45/ibex_branch/base/6_final_metrics.json

# Abrir GUI con el layout final
make DESIGN_CONFIG=designs/nangate45/ibex_branch/config.mk gui_final
make DESIGN_CONFIG=designs/sky130hd/ibex_branch/config.mk gui_final
```

### Limpiar y volver a correr

```bash
# Limpiar un nodo especifico
make DESIGN_CONFIG=designs/nangate45/ibex_branch/config.mk clean_all

# Limpiar solo el routing
make DESIGN_CONFIG=designs/sky130hd/ibex_branch/config.mk clean_route
```

---

## Diferencias de configuración entre nodos

El nodo sky130hd requiere parámetros más conservadores debido a la congestión de routing generada por los 128 flip-flops del BHT en las capas de metal inferiores.

| Parámetro | Nangate45 | SkyWater 130HD |
|-----------|-----------|----------------|
| CORE_UTILIZATION | 45% | 20-30% |
| PLACE_DENSITY_LB_ADDON | 0.20 | 0.05-0.10 |
| fastroute.tcl | No requerido | Layer adj. 0.05/capa |
| DETAILED_ROUTE_END_ITERATION | 64 (default) | 100 |
| DETAILED_ROUTE_ALLOW_PARTIAL_DRC | 0 | 1 |

---

## Verificar que el predictor dinámico está activo

```bash
# Verificar que el modulo dinamico aparece en el netlist sintetizado
grep "ibex_branch_predict_dynamic" \
  results/nangate45/ibex_branch/base/1_synth.v
```

Si el comando retorna resultados, el predictor dinámico está correctamente instanciado.

---

## Estructura del repositorio

```
Ibex-modification-for-branching-/
├── README.md
└── designs/
    ├── src/
    │   └── ibex_sv/                         <- RTL completo de Ibex modificado
    │       ├── ibex_branch_predict_dynamic.sv  <- NUEVO: predictor bimodal
    │       ├── ibex_core.sv                    <- MODIFICADO: BranchPredictor=1
    │       ├── ibex_if_stage.sv                <- MODIFICADO: seleccion dinamica
    │       └── ... (resto del RTL sin cambios)
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

## Referencias

- [lowRISC Ibex RISC-V Core](https://github.com/lowRISC/ibex)
- [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
- [ORFS Flow Tutorial](https://openroad-flow-scripts.readthedocs.io/en/latest/tutorials/FlowTutorial.html)
- [SkyWater 130nm PDK](https://github.com/google/skywater-pdk)
