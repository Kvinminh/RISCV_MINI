# RV32I Pipelined RISC-V CPU

> A modular five-stage RISC-V CPU written in SystemVerilog, with explicit
> pipeline control, data forwarding, early branch resolution, memory-mapped
> UART output, and reproducible Verilator testbenches.

![SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-1687A7)
![ISA](https://img.shields.io/badge/ISA-RV32I-6C4FBB)
![Simulator](https://img.shields.io/badge/Simulation-Verilator-4B8BBE)

## Overview

This project is an educational, RTL-level implementation of a 32-bit
RISC-V-style processor. The design follows a classic five-stage pipeline:

```text
Instruction Fetch → Instruction Decode → Execute → Memory → Write Back
        IF                   ID              EX        MEM        WB
```

The main goal is to build and verify the mechanisms that make a pipelined CPU
work correctly: pipeline registers, bypass paths, load-use stalls, control
hazard flushing, branch operand forwarding, and memory-mapped I/O.

The current implementation is intended as a bring-up and verification project,
not yet as a complete production RV32I compliance implementation.

## Highlights

- 32-bit SystemVerilog RTL with a five-stage IF/ID/EX/MEM/WB datapath.
- Separate pipeline registers: IF/ID, ID/EX, EX/MEM, and MEM/WB.
- Register file with x0 hard-wired to zero.
- Immediate generation for I, S, B, U, and J formats.
- ALU control and datapath support for integer arithmetic/logical operations.
- Decode paths for base integer instruction classes, loads/stores, branches,
  JAL, JALR, LUI, and AUIPC.
- EX-stage forwarding for dependent ALU operations.
- ID-stage forwarding for branch/JALR operand resolution.
- Load-use hazard detection that stalls PC and IF/ID, then inserts a bubble
  into ID/EX.
- Early branch decision in ID and wrong-path IF/ID flush.
- Internal instruction memory and SRAM model for simulation.
- Memory-mapped UART output at `0x4000_0000`.
- Verilator tests for Hello World, Fibonacci, and pipeline waveform inspection.
- Functional coverage model for IF-stage control, redirects, fetched opcode
  classes, PC properties, and relevant cross-coverage scenarios.

## Architecture

```text
                         +-------------------------------+
                         |            top_rtl            |
                         +-------------------------------+
                                         |
    +---------+    +---------+    +---------+    +---------+    +---------+
    |   IF    | -> |  IF/ID  | -> |   ID    | -> |  ID/EX  | -> |   EX    |
    | PC/IMEM |    |  reg    |    | Decode  |    |  reg    |    | ALU/FWD |
    +---------+    +---------+    | Regfile |    +---------+    +---------+
         ^                         | Hazard  |                       |
         |                         | Branch  |                       v
         |                         +---------+                +-------------+
         |                               |                    |   EX/MEM    |
         |                         early branch               |     reg     |
         |                         / PC redirect              +-------------+
         +------------------------------------------------------------+
                                                              |
                                                              v
                    +---------+    +---------+    +---------+    +---------+
                    |   MEM   | -> |  MEM/WB | -> |   WB    | -> | Regfile |
                    | SRAM/   |    |   reg   |    | WB MUX  |    | write   |
                    | UART    |    +---------+    +---------+    +---------+
                    +---------+
```

### Pipeline control

The hazard unit produces four control signals:

| Signal | Purpose |
| --- | --- |
| `stall_pc` | Holds the program counter during a data hazard. |
| `stall_if_id` | Holds the IF/ID register so the consumer instruction remains in ID. |
| `flush_id_ex` | Inserts a bubble into EX after a load-use stall. |
| `flush_if_id` | Removes the wrong-path instruction after a taken branch/jump. |

Forwarding avoids unnecessary stalls:

```text
MEM/WB result ─┐
               ├──> EX forwarding mux ──> ALU operands
EX/MEM result ─┘

EX/MEM result ─┐
               ├──> ID forwarding mux ──> branch/JALR comparator
MEM result    ─┘
```

## Repository layout

```text
.
├── rtl/
│   ├── core/
│   │   ├── if_stage/          # PC, PC mux, instruction memory
│   │   ├── id_stage/          # Decode, regfile, hazard and ID forwarding
│   │   ├── ex_stage/          # ALU, ALU control and EX forwarding
│   │   ├── mem_stage/         # SRAM, load/store units and UART
│   │   ├── wb_stage/          # Write-back mux
│   │   └── top_rtl.sv         # Processor integration top
│   ├── controlpath/           # Pipeline-register modules
│   └── pkg/                   # ISA, control, and shared type packages
├── tb/
│   ├── tb_hello_world_top.sv
│   ├── tb_fibonacci_top.sv
│   └── tb_pipeline_demo_top.sv
├── list_file/
│   ├── hello_world.f
│   ├── fibonacci.f
│   └── pipeline_demo.f
├── program_hello.mem
├── program_fibonacci.mem
├── program_pipeline_demo.mem
└── docs/images/               # Add captured GTKWave images here
```

## Prerequisites

The examples below assume Ubuntu/WSL.

```bash
sudo apt update
sudo apt install -y verilator gtkwave make g++
```

Check the installation:

```bash
verilator --version
gtkwave --version
```

## Running the simulations

Each test uses a dedicated build directory so simulator artifacts do not
overwrite one another.

### 1. Hello World

The program writes `Hello World!` through the memory-mapped UART.

```bash
verilator --binary --timing -Wall -Wno-fatal -sv \
  -f list_file/hello_world.f --top-module tb_top \
  --Mdir obj_dir_hello

./obj_dir_hello/Vtb_top
```

Expected output:

```text
Hello World!
[TB][PASS] UART printed: Hello World!
```

### 2. Fibonacci

The program calculates and prints the first seven Fibonacci values. It
exercises arithmetic, forwarding, a decrementing loop, `BNE`, and UART stores.

```bash
verilator --binary --timing -Wall -Wno-fatal -sv \
  -f list_file/fibonacci.f --top-module tb_fibonacci_top \
  --Mdir obj_dir_fibonacci

./obj_dir_fibonacci/Vtb_fibonacci_top
```

Expected output:

```text
0 1 1 2 3 5 8
[TB][PASS] Fibonacci UART output: 0 1 1 2 3 5 8
```

### 3. Pipeline hazard, forwarding, and early-branch waveform demo

This is the recommended demonstration for design reviews and the README. It
uses a directed instruction sequence that creates:

1. An ALU dependency resolved through EX forwarding.
2. A load-use dependency that causes a stall and an ID/EX bubble.
3. A branch whose operands are forwarded into ID; the taken branch flushes the
   wrong-path instruction.

```bash
verilator --binary --timing --trace --trace-structs -Wall -Wno-fatal -sv \
  -f list_file/pipeline_demo.f --top-module tb_top \
  --Mdir obj_dir_pipeline

./obj_dir_pipeline/Vtb_top
gtkwave pipeline_demo.vcd
```

The test passes only when the UART emits `P` (the wrong-path `X` store must be
flushed) and the checked register results are correct.

## Waveform evidence

Save the GTKWave screenshots under `docs/images/` and uncomment/update these
links before publishing.

```markdown
![Load-use hazard and EX forwarding](docs/images/hazard-forwarding.png)
![ID-stage forwarding and early branch](docs/images/early-branch.png)
```

For a concise, review-friendly hazard/forwarding image, include:

```text
clk rst_n pc_if instr_if instr_id
stall_pc stall_if_id flush_id_ex
forward_ex_a forward_ex_b
alu_ex alu_mem alu_wb
x6_t1 x7_t2 x28_t3 x29_t4 x30_t5
```

For early branch resolution, include:

```text
pc_if instr_id
forward_id_a forward_id_b
branch_enable branch_taken branch_target flush_if_id
```

At the `beq x31, x8` directed test point, the expected ID forwarding behavior
is:

```text
for_id_a = 2'b10  # operand x31 forwarded from MEM
for_id_b = 2'b01  # operand x8 forwarded from EX
compare_a = 32'd26
compare_b = 32'd26
branch_taken = 1'b1
```

## Verification strategy

| Test | What it checks | Result |
| --- | --- | --- |
| Hello World | Reset, instruction fetch, ALU/write-back path, UART store | Passed in Verilator |
| Fibonacci | Arithmetic loop, register dependencies, `BNE`, UART stores | Directed regression test |
| Pipeline demo | EX forwarding, load-use stall, ID forwarding, early branch flush | Directed VCD waveform test |

The testbench checks UART output and selected architectural register values.
The waveform demo also makes internal control signals visible for manual RTL
review.

### Functional coverage

The repository also includes a transaction-based functional coverage model for
the IF-stage verification environment (`if_stage_coverage`). It samples the
following behavior:

| Coverage area | Examples |
| --- | --- |
| Control | PC stall, branch enable/taken, JAL, JALR, redirect/no-redirect |
| Cross coverage | stall × redirect and branch-enable × branch-taken |
| Redirect | branch/JAL/JALR source and jump-target bins |
| Instruction fetch | RV32I opcode classes and NOP/non-NOP fetches |
| PC properties | alignment, `PC + 4` relation, and jump-target observation |

This is currently **block-level IF-stage coverage**, not a single aggregate
coverage metric for the whole CPU. Additional coverage scaffolding exists for
other blocks; extending it into a full-core coverage plan and reporting
regression percentages is a planned verification milestone.

## Design decisions

### Early branch resolution

Branches are resolved in ID to reduce the control penalty relative to resolving
them in EX. Because branch operands can be produced by preceding instructions,
the ID stage includes forwarding from EX/MEM sources and hazard logic for cases
that cannot be safely bypassed immediately.

### Memory-mapped UART

The address decoder routes accesses in the `0x4000_0000` region to the UART
model. In simulation, a valid UART write prints the low byte to the console.
This makes software bring-up observable without a separate peripheral model.

### Instruction memory image

Simulation program images are word-oriented hexadecimal files. The instruction
memory indexes words using `PC[11:2]`, matching the byte-addressed RISC-V PC
with 32-bit instructions.

## Current scope and next steps

This repository is deliberately transparent about its development status.

Implemented and demonstrated:

- Five-stage pipelined RTL integration.
- Core integer decode/datapath paths used by the directed tests.
- Hazard detection, forwarding, and early branch control.
- Simulation SRAM and UART models.

Planned improvements:

- Add a self-checking ISA regression suite and randomized instruction tests.
- Validate remaining RV32I corner cases, alignment behavior, and illegal
  instruction handling.
- Expand data-memory tests for byte/halfword/word accesses and sign extension.
- Add assertions and functional coverage for stalls, bypasses, and flushes.
- Add an ELF-to-memory-image flow driven by the RISC-V GCC toolchain.
- Add FPGA top-level integration, constraints, timing closure, and UART demo.
- Add exception/interrupt and CSR support if the project evolves beyond RV32I
  bring-up scope.

## Skills demonstrated

- SystemVerilog RTL design and modular hardware architecture.
- Pipelined CPU microarchitecture and control-path design.
- Hazard detection, bypass networks, and branch handling.
- Memory-mapped peripheral design.
- Verilator-based compilation, simulation, and debugging.
- VCD/GTKWave waveform analysis.
- Directed, self-checking testbench development.
- Transaction-based functional coverage and cross-coverage planning.
- Linux/WSL-based hardware development workflow.

## Author

**Minh**  
Computer Engineering / Digital Design Portfolio Project

If you are reviewing this project for an internship, start with the pipeline
demo and the two waveform screenshots: they show the control mechanisms that
are often hardest to validate in a basic CPU implementation.
