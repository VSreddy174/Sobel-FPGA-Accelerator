# FPGA Sobel Edge Detection Accelerator

## Project Overview
This project implements a hardware-optimized Sobel edge detection accelerator using Verilog HDL, deployed on a PYNQ-Z2 SoC platform (Zynq-7000). The primary objective is to offload computationally intensive 2D spatial filtering from the ARM Cortex-A9 processor to the FPGA programmable logic. 

By utilizing a custom AXI-Stream hardware architecture with specialized line-buffers and signed 11-bit arithmetic, the design achieves high-throughput, real-time image processing, demonstrating a **~10x speedup** over embedded software execution.

![System Block Design](docs/system_block_design.png)

## Key Specifications & Performance
The custom RTL was synthesized in Vivado 2024.1. By utilizing efficient bit-shifting techniques, the synthesizer inferred **zero DSP slices**, resulting in a highly lightweight IP block.
* **Target Frequency:** 100 MHz (Timing Met: WNS +1.182 ns)
* **LUT Utilization:** 2,758 (5.18%)
* **Register (FF) Utilization:** 3,571 (3.36%)
* **BRAM Utilization:** 2.50 Tiles (1.79%)
* **DSPs Used:** 0
* **Latency Speedup:** ~9.95x faster than ARM CPU software execution.

## Documentation Hub
For a detailed breakdown of the engineering process, architecture, and verification, please explore the documentation modules below:

1. [**Theory of Operation**](docs/1_Theory_of_Operation.md)
   * The mathematics behind the Sobel operator, convolution kernels ($G_x$ and $G_y$), and absolute magnitude approximation.
2. [**Hardware Architecture (RTL)**](docs/2_Hardware_Architecture.md)
   * Deep dive into the Read-Before-Write Line Buffers, 3x3 Sliding Window mechanics, and AXI-Stream handshaking.
3. [**Verification & Simulation**](docs/3_Verification_and_Simulation.md)
   * Testbench methodologies, solving pipeline latency, and waveform proofs for 10x10, 256x256, and mathematical stress tests.
4. [**System Integration & PYNQ Deployment**](docs/4_System_Integration_and_Deployment.md)
   * Vivado Block Design, AXI DMA configuration (solving TLAST and Buffer constraints), and Jupyter Notebook Python execution.

## Repository Structure
* `/rtl/` - Source Verilog code for the custom Sobel IP.
* `/sim/` - Testbenches (`tb_sobel_10x10.v`, `tb_sobel_file.v`, `tb_sobel_ramp.v`) and output data.
* `/scripts/` - Python pre-processing and post-processing scripts for file-based simulation.
* `/hardware_handoff/` - The compiled `.bit` and `.hwh` files for PYNQ deployment.
* `/notebooks/` - The Jupyter Notebook used for hardware execution and benchmarking.
* `/docs/` - System diagrams, waveform screenshots, and detailed markdown documentation.
