# FPGA Sobel Edge Detection Accelerator

## Project Overview
This project implements a hardware-optimized Sobel edge detection accelerator using Verilog HDL, deployed on a PYNQ-Z2 SoC platform (Zynq-7000). The primary objective is to offload computationally intensive 2D spatial filtering from the ARM Cortex-A9 processor to the FPGA programmable logic. By utilizing a custom AXI-Stream hardware architecture, the design achieves high-throughput, real-time image processing, demonstrating a **~10x speedup** over embedded software execution.

## Theory of Operation: The Sobel Operator
The Sobel operator is a discrete differentiation algorithm used to compute an approximation of the gradient of the image intensity function. It utilizes two $3 \times 3$ convolution kernels to detect changes in the horizontal ($G_x$) and vertical ($G_y$) directions.

The kernels are defined as:

**Horizontal Kernel ($G_x$)**
$$G_x = \begin{bmatrix} -1 & 0 & +1 \\ -2 & 0 & +2 \\ -1 & 0 & +1 \end{bmatrix}$$

**Vertical Kernel ($G_y$)**
$$G_y = \begin{bmatrix} +1 & +2 & +1 \\ 0 & 0 & 0 \\ -1 & -2 & -1 \end{bmatrix}$$

To calculate the final edge magnitude for a target pixel, the kernels are convolved with a $3 \times 3$ pixel neighborhood ($A$). The absolute values of the gradients are then summed to approximate the total magnitude:

$$Magnitude \approx |G_x * A| + |G_y * A|$$

In hardware, this requires simultaneous access to three rows of image data, specialized sliding window mechanics, and signed arithmetic to manage negative gradients safely.
