# Debugging and System Issues

The integration of a streaming hardware accelerator into a Zynq SoC environment presents several synchronization and protocol challenges. This document details the primary issues identified during simulation and hardware testing.

## 1. DMA System Hangs (Scatter-Gather Mismatch)
**Issue:** During initial testing, the Jupyter Notebook kernel would hang indefinitely after calling `dma.recvchannel.wait()`.
* **Root Cause:** The AXI DMA IP was initially configured with "Scatter-Gather" (SG) enabled, but the PYNQ driver was attempting a "Simple DMA" transfer. The mismatch caused the DMA to wait for a descriptor ring that did not exist in memory.
* **Resolution:** Re-configured the AXI DMA IP in the Vivado Block Design to disable Scatter-Gather and enabled "Simple DMA" mode.

## 2. Register Width Overflow (23-bit Fix)
**Issue:** Transfers for 256x256 images failed or resulted in incomplete data packets.
* **Root Cause:** By default, the DMA "Width of Buffer Length Register" is set to 14 bits, which allows a maximum transfer of 16,384 bytes. A 256x256 8-bit image requires 65,536 bytes.
* **Resolution:** Increased the "Width of Buffer Length Register" to **23 bits** in the DMA configuration settings to accommodate the full frame size.

## 3. TLAST Synchronization Errors
**Issue:** The DMA would successfully receive the first frame but would hang or report "DMA Channel Not Idle" on subsequent transfers.
* **Root Cause:** The `m_axis_tlast` signal was not firing at the exact moment the DMA expected. If `tlast` is missing or late, the DMA keeps the receive channel open, blocking future transactions.
* **Resolution:** Implemented a robust 18-bit absolute pixel counter (`out_pixel_count`) within the Verilog RTL. The `m_axis_tlast` signal is now tied strictly to this counter, asserting high only when the 65,536th valid pixel is emitted.

## 4. Arithmetic Underflow and Visual Artifacts
**Issue:** Simulation showed strange white-out effects on certain edges where black pixels were expected.
* **Root Cause:** Standard unsigned 8-bit arithmetic was being used for kernel convolution. When a kernel subtraction resulted in a negative number (e.g., $0 - 5$), the value wrapped around to 251 (a bright pixel) instead of staying near 0.
* **Resolution:** Upgraded the internal datapath to **signed 11-bit arithmetic** (`reg signed [10:0]`). A final absolute value and clipping stage was added to ensure all negative gradients are correctly handled before outputting to the 8-bit bus.

## 5. AXI-Stream Handshake Deadlocks
**Issue:** The pipeline would stall, and the `s_axis_tready` signal would never de-assert.
* **Root Cause:** Internal "Read-Before-Write" logic in the line buffers was not properly gated by the `s_axis_tvalid` signal, causing the internal registers to shift even when no valid data was being presented.
* **Resolution:** Synchronized the entire sliding window and line buffer shift logic to the AXI-Stream handshake condition: `(s_axis_tvalid && s_axis_tready)`. This ensures the pipeline only advances when a valid pixel is consumed.
