# Vivado Block Design and System Integration

The complete system is integrated using the Vivado IP Integrator, connecting the custom Sobel Hardware Accelerator to the Zynq-7000 Processing System (PS) via the AXI4-Stream and AXI4-Lite protocols.

## 1. System Architecture
The design utilizes a High-Performance (HP) port on the Zynq PS to allow the FPGA logic to access the DDR memory directly. This is facilitated by an AXI DMA engine that acts as the bridge between the memory-mapped domain of the CPU and the streaming domain of the Sobel IP.



![Vivado Block Design](../docs/system_block_design.png)

## 2. Key Component Configurations

### A. Custom Sobel IP
* **Interface:** AXI4-Stream (Slave for input, Master for output).
* **Clocking:** Driven by `FCLK_CLK0` at **100 MHz**.
* **Reset:** Synchronized via the `proc_sys_reset` IP to ensure clean startup.

### B. AXI Direct Memory Access (DMA)
The DMA is the most critical block for performance. To ensure compatibility with the 256x256 image size, the following settings were applied:
* **Enable Scatter Gather:** Disabled (Simple DMA mode used for lower latency).
* **Width of Buffer Length Register:** **23 bits** (To ensure the 65,536-byte transfer does not overflow the default 14-bit register).
* **Memory Map Data Width:** 32 bits.
* **Stream Data Width:** 8 bits (Matching our grayscale pixel width).

### C. Zynq Processing System (PS7)
* **High-Performance Port:** Enabled `S_AXI_HP0` to allow high-bandwidth DMA transfers.
* **Clocking:** Configured `FCLK_CLK0` to output a stable 100 MHz clock to the PL (Programmable Logic).

## 3. Connectivity Breakdown
1. **Instruction Path:** The CPU sends commands to the DMA via the **M_AXI_GP0** (General Purpose) port and an **AXI Interconnect**.
2. **Data Input Path:** The DMA reads raw pixels from DDR memory and streams them into the `s_axis` port of the Sobel IP.
3. **Data Output Path:** The Sobel IP processes the pixels and streams the results from the `m_axis` port back into the DMA.
4. **Write-Back Path:** The DMA writes the processed edge-detected data back to DDR memory via the **S_AXI_HP0** port.

## 4. Hardware Resource Utilization
Based on the Post-Implementation reports, the system utilizes the following resources on the PYNQ-Z2:

| Resource | Used | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **LUT** | 2,758 | 53,200 | 5.18% |
| **FF** | 3,571 | 106,400 | 3.36% |
| **BRAM** | 2.50 | 140 | 1.79% |
| **BUFG** | 1 | 32 | 3.13% |

*Note: The design achieves 0% DSP utilization because multiplications by 2 in the Sobel kernels were optimized using bit-shift operations in the Verilog RTL.*

## 5. Timing Closure
The design successfully met all timing constraints at 100 MHz:
* **Worst Negative Slack (WNS):** 1.182 ns.
* **Worst Hold Slack (WHS):** 0.020 ns.
* **Clock Period:** 10.000 ns.
