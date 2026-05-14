# Hardware Architecture (RTL Design)

The Sobel Edge Detection accelerator is a custom hardware IP designed to process high-throughput image streams with minimal resource overhead. It utilizes an AXI-Stream interface to communicate with the Zynq Processing System via an AXI DMA engine.

## Top-Level System Architecture
The architecture transforms a 1D sequential pixel stream into a 2D spatial neighborhood for edge calculation using a pipelined approach.

### 1. AXI-Stream Interface
The hardware utilizes the AXI-Stream protocol for high-speed data movement. 
* **Slave Interface:** Receives raw 8-bit grayscale pixels from DDR memory via DMA.
* **Handshaking:** Flow control is managed by tvalid and tready signals.
* **Backpressure:** The IP deasserts s_axis_tready if internal buffers are full to safely pause the stream.
* **TLAST Handling:** The slave s_axis_tlast is ignored to prevent synchronization bugs, replaced by a robust internal counter.

### 2. Line Buffer Subsystem
To perform 3x3 convolution, the hardware caches two preceding image rows using internal RAM arrays.
* **Read-Before-Write:** As a new pixel arrives, the hardware simultaneously reads from Buffer 0 (Row N-1) and Buffer 1 (Row N-2).
* **Shift Logic:** The new pixel is written into Buffer 0, while the old pixel from Buffer 0 is shifted into Buffer 1.

### 3. 3x3 Sliding Window
The spatial neighborhood is formed by a grid of 9 registers (p11 through p33).
* **Shift-Register Grid:** On every clock cycle, pixels shift one position to the left.
* **Vertical Insertion:** The vertical slice from the line buffers enters the rightmost column of the window (p13, p23, p33).



### 4. Sobel Math Core & Arithmetic
The arithmetic unit applies the kernels to the window to find horizontal (Gx) and vertical (Gy) gradients.
* **Optimized Math:** Multiplication by 2 is implemented via bit-shifts (<< 1), eliminating the need for DSP slices.
* **Signed 11-bit Logic:** Gx and Gy use signed 11-bit variables to prevent negative overflow and underflow wrap-around.
* **Absolute Magnitude:** Gradients are converted to absolute values and summed (|Gx| + |Gy|).
* **Saturation Clipping:** Values exceeding 255 are capped at 255 to maintain 8-bit grayscale compatibility.

### 5. Robust TLAST Generation
To ensure perfect DMA handshaking, a dedicated 18-bit absolute pixel counter is used.
* **Operation:** The counter increments only when a valid pixel exits the math pipeline.
* **Trigger:** When the count reaches exactly 65,535 (for a 256x256 frame), it forces m_axis_tlast high.
* **Result:** This eliminates system hangs by providing a clean end-of-frame signal to the DMA.
