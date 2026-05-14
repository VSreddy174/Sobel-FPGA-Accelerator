# Sobel Edge Detection FPGA Accelerator

This project implements a hardware-optimized Sobel edge detection accelerator using Verilog HDL, deployed on the PYNQ-Z2 (Zynq-7000 SoC). The design utilizes a custom AXI-Stream hardware architecture to offload 2D spatial filtering from the ARM processor to the FPGA programmable logic.

## Project Overview
The core hardware architecture processes a continuous stream of pixels using four main functional blocks:
* **AXI-Stream Wrapper:** Handles the handshaking protocol (tvalid, tready, tdata) to safely ingest pixels and push output data without loss.
* **Line Buffers:** Two RAM arrays acting as FIFOs to store the previous two rows of the image (Row N-1 and Row N-2).
* **3x3 Sliding Window:** A shift-register grid consisting of 9 registers (p11 through p33) that forms the full neighborhood required for convolution.
* **Sobel Math Core:** An arithmetic unit using signed 11-bit arithmetic to calculate Gx and Gy gradients, clipped at 255 to fit 8-bit grayscale format.

## Technical Specifications
The design was synthesized and implemented using Vivado 2024.1 for a fixed 256x256 image resolution.

### Timing & Power Summary
* **Operating Frequency:** 100 MHz (Clocked via FCLK_CLK0).
* **Worst Negative Slack (WNS):** 1.182 ns (Timing Met).
* **Worst Hold Slack (WHS):** 0.020 ns.
* **Total On-Chip Power:** 1.411 W.
* **Junction Temperature:** 41.3°C.

### Post-Implementation Resource Utilization
| Resource | Used | Available | Utilization % |
|:---|:---|:---|:---|
| LUT | 2,758 | 53,200 | 5.18% |
| LUTRAM | 252 | 17,400 | 1.45% |
| FF | 3,571 | 106,400 | 3.36% |
| BRAM | 2.50 | 140 | 1.79% |
| BUFG | 1 | 32 | 3.13% |

## Performance Results
Performance was evaluated by comparing the custom FPGA IP against the ARM Cortex-A9 processor (OpenCV baseline).
* **Software (OpenCV on ARM):** ~16.295 ms.
* **Hardware (Custom FPGA IP):** ~1.637 ms.
* **Measured Speedup:** **~9.95x**.

## Repository Structure
* **/rtl/** : Core Verilog modules including `sobel_edge_detection.v`.
* **/sim/** : Simulation testbenches: `tb_sobel_10x10.v`, `tb_sobel_file.v`, and `tb_sobel_ramp.v`.
* **/hardware_handoff/** : Compiled `sobel.bit` and `sobel.hwh` files.
* **/notebooks/** : Jupyter Notebook for board deployment and benchmarking.
* **/docs/** : Detailed technical reports on theory, architecture, and integration.

## Documentation Sections

The project documentation is divided into the following technical modules:

### 1. [Theory](./docs/1_Theory.md)
* **Mathematical Definition:** Analysis of the horizontal (Gx) and vertical (Gy) convolution kernels.
* **Magnitude Approximation:** Hardware-optimized |Gx| + |Gy| calculation to avoid expensive square root operations.
* **Arithmetic Scaling:** Implementation of signed 11-bit logic to prevent integer overflow during subtractions.

### 2. [RTL Design](./docs/2_RTL_Design.md)
* **Line Buffer Architecture:** Detailed "Read-Before-Write" logic using dual RAM arrays to cache image rows.
* **3x3 Sliding Window:** Shift-register grid implementation for real-time spatial neighborhood generation.
* **Pipeline Management:** Use of `buff_valid` and `calc_valid` signals to synchronize data flow with internal hardware latency.

### 3. [Simulation and Waveform Analysis](./docs/3_Simulation.md)
* **Functional Verification:** Waveform results from the 10x10 edge test and 256x256 ramp stress simulation.
* **Handshake Timing:** Analysis of AXI-Stream `tvalid` and `tready` signals under streaming conditions.
* **TLAST Accuracy:** Verification of the 18-bit counter-driven End-of-Frame signal.

### 4. [Vivado Block Design](./docs/4_Block_Design.md)
* **SoC Integration:** Connectivity between the Zynq-7000 Processing System and the custom Sobel IP.
* **DMA Configuration:** Settings for Direct Register Mode, 8-bit stream width, and 23-bit buffer registers.
* **High-Performance Path:** Utilization of the HP0 port for direct memory access to DDR RAM.

### 5. [Pynq Jupyter](./docs/5_Pynq_Deployment.md)
* **Overlay Management:** Dynamic FPGA programming using the `pynq.Overlay` library.
* **Memory Allocation:** Creating physically contiguous buffers via `pynq.allocate`.
* **Benchmark Methodology:** Comparison of hardware execution time (1.637 ms) against software baseline (~16.295 ms).

### 6. [Debugging Issues](./docs/6_Debugging.md)
* **System Hangs:** Resolution of DMA lockups caused by Scatter-Gather protocol mismatches.
* **Handshake Synchronization:** Fixing TLAST misalignment using absolute pixel counting.
* **Register Overflow:** Resolving the 16-bit DMA buffer length limitation for 256x256 images.
