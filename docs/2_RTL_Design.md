# RTL Design: Hardware Architecture

The core of the accelerator is designed to transform a sequential 1D pixel stream into a 2D spatial neighborhood using a pipelined datapath. The design is hard-coded for a 256x256 image size to optimize Block RAM usage.

## 1. Line Buffer Architecture (Row Caching)
To perform 3x3 convolution on a streaming input, the hardware must access three vertical pixels simultaneously. This is achieved using two RAM arrays acting as FIFOs called Line Buffers.

* **Structure:** `line_buff_0` stores the previous row (Row N-1), and `line_buff_1` stores the row before that (Row N-2).
* **Read-Before-Write Logic:** As a new pixel arrives, the hardware simultaneously reads the oldest pixels from the buffers into column registers (`r1`, `r2`) while passing the new incoming pixel into `r0`.
* **Shift Mechanism:** Immediately after reading, the pixel from `line_buff_0` is shifted into `line_buff_1`, and the current input pixel is written into `line_buff_0`.

## 2. 3x3 Sliding Window Registers
The spatial neighborhood is formed by a grid of 9 registers, named `p11` through `p33`.

* **Vertical Insertion:** The three vertical pixels extracted from the line buffers enter the rightmost column of the window: `p13` (top-right), `p23` (middle-right), and `p33` (bottom-right).
* **Shift-Left Grid:** Every clock cycle, the existing pixels shift one position to the left (e.g., `p12` moves to `p11`, `p13` moves to `p12`).
* **Neighborhood Maintenance:** This continuous shifting maintains a perfect 9-pixel neighborhood around the target pixel for the math core to process.

## 3. Sobel Arithmetic Core
The arithmetic logic applies the kernels directly to the sliding window registers using combinational logic to minimize pipeline stages.

* **Gradient Formulas:**
    * $G_x = (p_{13} + 2p_{23} + p_{33}) - (p_{11} + 2p_{21} + p_{31})$
    * $G_y = (p_{11} + 2p_{12} + p_{13}) - (p_{31} + 2p_{32} + p_{33})$
* **Bit-Width Management:** All intermediate calculations are performed using 11-bit signed variables (`reg signed [10:0]`) to prevent integer underflow wrap-around.
* **Magnitude and Clipping:** The absolute values are summed ($|G_x| + |G_y|$). If the sum exceeds 255, it is capped at 255 using a ternary operator to maintain 8-bit grayscale format.

## 4. Pipeline Control and Valid Logic
Because the line buffers require time to fill, the hardware implements a tiered valid signal strategy.

* **buff_valid:** This signal tracks when the line buffers have absorbed the first two full rows (512 pixels) of an image.
* **calc_valid:** This signal shifts alongside the math calculations to ensure `m_axis_tvalid` is only asserted when the pipeline contains valid edge data.
* **Output Counter:** An 18-bit absolute pixel counter (`out_pixel_count`) tracks the number of valid output pixels.
* **TLAST Generation:** The counter triggers `m_axis_tlast` high on exactly the 65,536th pixel, ensuring a perfect DMA handshake.
