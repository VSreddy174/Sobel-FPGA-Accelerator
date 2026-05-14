# System Integration and Deployment

This section details the integration of the custom Sobel IP into a complete System-on-Chip (SoC) and its deployment on the PYNQ-Z2 board.

## Vivado Block Design
The system was built by connecting the Zynq-7000 Processing System (PS) to the custom Sobel IP via an AXI Direct Memory Access (DMA) engine.

### Key Components:
* **ZYNQ7 Processing System:** Configured with the High-Performance (HP0) port enabled to provide a direct, high-speed 64-bit highway between the DMA and DDR RAM.
* **AXI DMA (axi_dma_0):** Configured in Direct Register Mode (Scatter-Gather disabled) to move image data efficiently between memory and the IP core.
* **Processor System Reset:** Synchronizes resets across the 100MHz clock domain to ensure the hardware and CPU reboot together perfectly.

## Critical Hardware Debugging & Solutions
Several system-level bottlenecks were identified and resolved during the integration phase:

### 1. DMA Buffer Length Register Crash
* **Problem:** The default 16-bit DMA buffer length register could only handle up to 65,535 bytes. A 256x256 image requires exactly 65,536 bytes, causing the DMA driver to crash.
* **Solution:** Increased the Width of Buffer Length Register to 23 bits in the Vivado DMA configuration, allowing transfers up to 8MB.

### 2. AXI-Stream Data Width Mismatch
* **Problem:** The DMA defaulted to 32-bit (4 pixels) while the Sobel IP was configured for 8-bit (1 pixel), causing data misalignment.
* **Solution:** Explicitly set the Stream Data Width for both Read (MM2S) and Write (S2MM) channels to 8 bits to ensure perfect byte alignment.

### 3. Infinite DMA Hangs (TLAST Synchronization)
* **Problem:** The DMA receive channel waited indefinitely for an "End of Frame" (TLAST) signal that was misaligned or dropped due to pipeline latency.
* **Solution:** Abandoned the input-to-output delay line. Implemented a robust 18-bit absolute pixel counter that forces m_axis_tlast high exactly on the 65,536th valid output pixel.

## PYNQ Deployment & Execution
The design was deployed to the PYNQ-Z2 board using the sobel.bit and sobel.hwh files within a Jupyter Notebook environment.

### Hardware Execution Flow:
1. **Overlay Loading:** The FPGA is flashed dynamically using the pynq.Overlay class.
2. **Contiguous Memory Allocation:** pynq.allocate is used to create physically contiguous buffers (np.uint8) that the DMA can directly access.
3. **Data Transfer:** Images are resized to 256x256 via OpenCV and pushed to the hardware using dma.sendchannel.transfer() and dma.recvchannel.transfer().

## Final Performance Benchmarking
The hardware accelerator was compared against a software baseline (OpenCV Sobel) running on the ARM Cortex-A9 CPU.

| Implementation | Execution Time (Avg) |
|----------------|----------------------|
| **ARM CPU (Software)** | ~16.295 ms |
| **FPGA Accelerator (Hardware)** | **~1.637 ms** |
| **Speedup Factor** | **~9.95x Faster** |

The final conclusion proved the FPGA was ~10x faster than the embedded CPU while maintaining minimal resource consumption.
