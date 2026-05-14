# PYNQ Jupyter Implementation and Benchmarking

This section details how the custom Sobel hardware accelerator is initialized, deployed, and benchmarked on the PYNQ-Z2 development board.

## 1. Notebook Reference
The complete executable testing framework, driver logic, and visualization plots are maintained in the repository notebook file:
* [Sobel Benchmarking Notebook](../notebooks/pynq_jupyter_notebook.ipynb)

## 2. PYNQ Runtime Environment
The deployment environment utilizes the PYNQ subsystem to bridge Python wrappers with the physical FPGA programmable logic framework.
* **Bitstream Loading:** The compiled configuration file (`sobel.bit`) and its hardware handoff companion (`sobel.hwh`) are loaded dynamically using the `pynq.Overlay` API.
* **DMA Access:** The master and slave pixel streams are managed directly through the simple AXI DMA memory-mapped registers (`overlay.axi_dma_0`).

## 3. Memory Management Requirements
Because the AXI DMA engine utilizes Direct Register transfers without Scatter-Gather support, memory buffers must be physically contiguous in DDR RAM.
* **Buffer Allocation:** The runtime allocates hardware-safe tracking zones using the `pynq.allocate` method.
* **Data Types:** Buffers are explicitly configured as 8-bit unsigned integers (`np.uint8`) to map directly to the 8-bit streaming input width of the Sobel RTL logic.

## 4. Benchmarking Methodology
Performance is measured by comparing the processing duration of a 256x256 grayscale image across two separate execution paths:

### A. Software Path (ARM CPU)
The image is processed on the ARM Cortex-A9 host processor using native OpenCV bindings (`cv2.Sobel`). This creates a baseline execution profile that represents standard software computing overhead.

### B. Hardware Path (FPGA PL)
The pixel array is transferred directly to the programmable logic fabric via the DMA channel interface. The Python execution thread blocks (`dma.recvchannel.wait()`) until the hardware asserts the `m_axis_tlast` signal, signifying that all 65,536 processed pixels have safely written back to the DDR destination buffer.

## 5. Performance Profile Summary

* **Software Execution Time (OpenCV Baseline):** ~16.295 ms
* **Hardware Execution Time (Custom Sobel IP):** ~1.637 ms
* **Measured Acceleration Speedup:** **~9.95x**

The performance gain is achieved because the FPGA completely bypasses the traditional CPU instruction-fetch pipeline, calculating the vertical and horizontal gradients in parallel directly from the streaming line buffers.
