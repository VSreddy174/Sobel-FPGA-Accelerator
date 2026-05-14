# Sobel Edge Detection FPGA Accelerator

This project implements a hardware accelerator for Sobel edge detection using Verilog HDL. The design is deployed on a PYNQ-Z2 board, where a custom IP core offloads the pixel-intensity calculations from the processor to the FPGA fabric to increase processing speed.

## Project Description
The system consists of a custom-designed Verilog module that processes 256x256 grayscale images. It uses an AXI-Stream interface to receive pixels, line buffers to store image rows for 3x3 convolution, and signed arithmetic to calculate edge gradients.

* **Hardware IP:** Written in Verilog; includes line buffers, a 3x3 sliding window, and a math core for Gx and Gy calculations.
* **DMA Integration:** An AXI DMA engine moves image data from memory to the IP and back.
* **Software Interface:** A Jupyter Notebook is used to program the FPGA, manage data transfers, and compare hardware results with a software baseline.

## Technical Specifications
The project was implemented using Vivado 2024.1 targeting the PYNQ-Z2 (Zynq-7000).

### Device Utilization
| Resource | Used | Available | Utilization (%) |
|:---|:---|:---|:---|
| LUT | 2,758 | 17,600 | 8.50% |
| FF | 3,571 | 35,200 | 5.79% |
| BRAM | 2.50 | 60 | 2.14% |
| DSP | 0 | 80 | 0.00% |

### Latency Results
* **Software (OpenCV):** 16.295 ms
* **Hardware (FPGA):** 1.637 ms
* **Measured Speedup:** ~10x

## Repository Structure
* **/rtl/**: Source Verilog files for the Sobel IP.
* **/sim/**: Testbenches and simulation data files.
* **/hardware_handoff/**: The compiled .bit and .hwh files.
* **/notebooks/**: Jupyter Notebook for board testing and benchmarking.
* **/docs/**: Detailed documentation files for each part of the project.

## Documentation Hub
The project details are divided into the following files:
1. [**Theory and Kernels**](docs/1_Theory_of_Operation.md)
2. [**Hardware RTL Design**](docs/2_Hardware_Architecture.md)
3. [**Vivado System Setup**](docs/3_System_Integration.md)
4. [**Verification and PYNQ Testing**](docs/4_Verification_Deployment.md)
