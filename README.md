# RISC-V MINI CPU

A 32-bit RISC-V processor implemented in SystemVerilog, developed as an educational and FPGA-oriented CPU project.

> **Project status:** Under development

## Overview

**RISC-V MINI** is a custom 32-bit RISC-V processor based on the **RV32I instruction set architecture**.

The target architecture uses a **5-stage pipeline**:

```text
IF → ID → EX → MEM → WB
```

The processor is designed with a modular RTL structure, explicit pipeline registers, hazard detection, data forwarding, early branch resolution, and memory-mapped I/O.

### Main Features

- 32-bit RISC-V RV32I architecture
- 5-stage pipeline:
  - IF — Instruction Fetch
  - ID — Instruction Decode
  - EX — Execute
  - MEM — Memory Access
  - WB — Write Back
- Pipeline registers between stages
- Hazard detection
- Pipeline stall and flush control
- Data forwarding:
  - `forward_id`
  - `forward_ex`
- Early branch resolution in ID stage
- JAL / JALR control-flow support
- Register file
- Immediate generator
- ALU and ALU control
- Load/store unit
- SRAM-based data memory
- Memory-mapped UART
- SystemVerilog RTL
- Modular verification environment

---

## Architecture

The target CPU datapath is organized as:

```text
                         RISC-V RV32I
                     5-Stage Pipeline

        ┌────────┐
        │   IF   │
        │        │
        │   PC   │
        │  IMEM  │
        │  PC+4  │
        └───┬────┘
            │
          IF/ID
            │
        ┌───▼────┐
        │   ID   │
        │        │
        │ Decode │
        │ Regfile│
        │ ImmGen │
        │ Hazard │
        │Forward │
        │ Branch │
        └───┬────┘
            │
          ID/EX
            │
        ┌───▼────┐
        │   EX   │
        │        │
        │ Forward│
        │ ALU    │
        │ ALU Ctrl
        └───┬────┘
            │
         EX/MEM
            │
        ┌───▼────┐
        │  MEM   │
        │        │
        │  LSU   │
        │  SRAM  │
        │  UART  │
        └───┬────┘
            │
         MEM/WB
            │
        ┌───▼────┐
        │   WB   │
        │        │
        │  WB MUX│
        │ Regfile│
        └────────┘
```

### Pipeline Control

The pipeline control is designed around three main mechanisms:

#### Hazard Detection

The hazard unit detects data dependencies that cannot be resolved directly through forwarding.

Typical cases include:

- Load-use hazards
- Register dependencies between pipeline stages
- Control-flow dependencies

The hazard unit generates:

```text
stall_pc
stall_if_id
flush_id_ex
```

#### Forwarding

Two forwarding paths are used:

```text
Forward ID
    ↓
Branch / JALR operand resolution

Forward EX
    ↓
ALU operand resolution
```

This reduces unnecessary pipeline stalls caused by data dependencies.

#### Early Branch Resolution

Branches are resolved in the **ID stage** rather than waiting until EX.

The ID stage contains the logic required for:

- Branch comparison
- JAL target calculation
- JALR target calculation
- Next-PC selection

Conceptually:

```text
             Regfile
                │
                ▼
          Forward ID
                │
                ▼
        Branch Compare
                │
             br_taken
                │
                ▼
             PC MUX
```

This reduces the control-flow penalty for taken branches.

---

## RTL Structure

The repository is organized into functional RTL and verification components:

```text
RISCV_MINI/
├── rtl/
│   ├── controlpath/
│   ├── core/
│   └── pkg/
│
├── tb_regfile/
│   ├── regfile_driver.sv
│   ├── regfile_generator.sv
│   ├── regfile_if.sv
│   ├── regfile_monitor.sv
│   ├── regfile_top.sv
│   └── regfile_transaction.sv
│
├── map/
├── tb_if_stage.sv
├── .gitignore
└── README.md
```

The RTL is separated into:

- **Control path** — instruction decoding and control generation
- **Core/datapath** — processor datapath and pipeline logic
- **Package** — shared SystemVerilog definitions
- **Testbench** — verification components for individual modules and stages

---

## Memory and I/O

The target memory subsystem uses an address decoder to separate normal data memory from memory-mapped peripherals.

```text
                    CPU
                     │
                     ▼
              Address Decoder
                 /        \
                /          \
               ▼            ▼
          Data SRAM       UART
```

The memory subsystem is designed to support:

- Load operations
- Store operations
- Byte access
- Halfword access
- Word access
- Byte-lane write masking
- Sign extension
- Zero extension
- Memory-mapped UART transmission
- UART status reading

### Store Path

```text
rs2_data
    │
    ▼
Store Unit
    │
    ├──► SRAM write data
    ├──► SRAM byte mask
    └──► UART TX data
```

### Load Path

```text
SRAM / UART
     │
     ▼
Read Data MUX
     │
     ▼
Load Unit
     │
     ▼
Extended memory data
     │
     ▼
WB
```

---

## Verification

Verification is developed alongside the RTL implementation.

Current verification work includes:

- Register-file verification
- IF-stage verification
- SystemVerilog testbench components

The register-file verification environment contains:

```text
Transaction
     │
     ▼
Generator
     │
     ▼
Driver
     │
     ▼
DUT
     │
     ▼
Monitor
```

The verification environment will be expanded as additional CPU stages and control logic are implemented.

---

## Tools

The project is developed using:

- **SystemVerilog**
- **Visual Studio Code**
- **Icarus Verilog / Verilator** for simulation
- **GTKWave** for waveform analysis
- **Vivado** for FPGA synthesis and implementation
- **RISC-V GCC toolchain** for compiling RISC-V software

---

## Architecture Diagram

The CPU architecture diagram is maintained in Draw.io.

**[Open Architecture Diagram on Google Drive](https://drive.google.com/drive/folders/1R-oZVm88JJB9PE9jeTeoqIR7exhuMD6-?usp=drive_link)**

The diagram describes the target:

- RISC-V RV32I 32-bit architecture
- 5-stage pipeline
- Hazard detection
- Forwarding in ID and EX
- Early branch resolution in ID
- SRAM data memory
- Memory-mapped UART

---

## Project Roadmap

### Phase 1 — RTL Fundamentals

- [x] Register file
- [ ] ALU
- [ ] Immediate generator
- [ ] Instruction memory
- [ ] Data memory
- [ ] Control unit

### Phase 2 — 5-Stage Pipeline

- [ ] IF stage
- [ ] ID stage
- [ ] EX stage
- [ ] MEM stage
- [ ] WB stage
- [ ] IF/ID pipeline register
- [ ] ID/EX pipeline register
- [ ] EX/MEM pipeline register
- [ ] MEM/WB pipeline register

### Phase 3 — Hazard and Forwarding

- [ ] Load-use hazard detection
- [ ] Stall logic
- [ ] Flush logic
- [ ] Forward ID
- [ ] Forward EX
- [ ] Early branch resolution

### Phase 4 — Memory and I/O

- [ ] Load/store unit
- [ ] SRAM interface
- [ ] Address decoder
- [ ] Store unit
- [ ] Load unit
- [ ] UART TX
- [ ] Memory-mapped I/O

### Phase 5 — FPGA Demonstration

- [ ] FPGA top module
- [ ] FPGA constraints
- [ ] Synthesis
- [ ] Timing analysis
- [ ] UART demonstration
- [ ] RISC-V software test program

### Phase 6 — Software

- [ ] RISC-V GCC toolchain setup
- [ ] Linker script
- [ ] ELF generation
- [ ] ELF → memory image conversion
- [ ] Hello World
- [ ] Fibonacci program
- [ ] FPGA demonstration

---

## Repository

GitHub repository:

**[Kvinminh/RISCV_MINI](https://github.com/Kvinminh/RISCV_MINI)**

---

## Project Goal

The main goal of this project is to develop a functional **32-bit RISC-V processor from RTL**, understand the internal operation of a pipelined CPU, and eventually run the processor on an FPGA.

The project focuses on understanding:

- RISC-V ISA
- CPU datapath design
- Pipeline architecture
- Hazard handling
- Data forwarding
- Branch handling
- Memory systems
- Memory-mapped I/O
- RTL design
- Verification
- FPGA implementation

---

## License

This project is currently developed for educational and research purposes.