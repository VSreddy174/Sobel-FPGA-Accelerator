# Theory of Operation: Sobel Edge Detection

The Sobel operator is a discrete differentiation algorithm used to compute an approximation of the gradient of an image intensity function. In this project, it is used to detect edges by identifying areas of high spatial frequency.

## Convolution Kernels
The algorithm utilizes two 3x3 convolution kernels to calculate approximations of the derivatives, one for horizontal changes ($G_x$) and one for vertical changes ($G_y$).

**Horizontal Kernel ($G_x$)**
This kernel is designed to detect vertical edges by measuring the horizontal gradient.


$$
G_x = \begin{bmatrix}
-1 & 0 & 1 \\
-2 & 0 & 2 \\
-1 & 0 & 1
\end{bmatrix}
$$


**Vertical Kernel ($G_y$)**
This kernel is designed to detect horizontal edges by measuring the vertical gradient.


$$
G_y = \begin{bmatrix}
1 & 2 & 1 \\
0 & 0 & 0 \\
-1 & -2 & -1
\end{bmatrix}
$$


## Gradient Magnitude Calculation
In standard software implementations, the exact gradient magnitude ($G$) is calculated using the Euclidean distance:
$$G = \sqrt{G_x^2 + G_y^2}$$

However, square root and squaring operations are computationally expensive in hardware. To optimize for silicon area and throughput on the Zynq-7000 SoC, this implementation utilizes the 

**Absolute Magnitude Approximation**:
$$G \approx |G_x| + |G_y|$$

This approximation allows the math core to rely solely on additions and absolute value logic, significantly reducing latency and hardware resource consumption.

## Hardware Implementation Details

### 1. Arithmetic Bit-Width
While the input pixels are 8-bit unsigned values (0-255), the convolution process involves subtractions that can result in negative values. To prevent catastrophic integer underflow or wrap-around, $G_x$ and $G_y$ are calculated using **signed 11-bit arithmetic**.
* **Input:** 8-bit Unsigned.
* **Intermediate Gradients:** 11-bit Signed (`reg signed [10:0]`).

### 2. Saturation Clipping
The final sum of the absolute gradients ($|G_x| + |G_y|$) can reach a maximum value of 1020. Since the output must be returned to an 8-bit grayscale format for the DMA transfer, a thresholding mechanism is used:
* If $G > 255$, the output is capped at **255**.
* Otherwise, the lower 8 bits of the sum are used.

### 3. Optimization without DSPs
To minimize resource utilization, multiplications by 2 in the kernels are implemented using **bit-shifts** (e.g., `p23 << 1`), allowing the design to use 0 DSP slices while maintaining high performance.
