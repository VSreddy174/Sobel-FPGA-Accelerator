`timescale 1ns / 1ps

/* =========================================================================
 * Module: sobel_edge_detection
 * Description: AXI-Stream Hardware Accelerator for Sobel Edge Detection.
 * Implements a 3x3 sliding window using 2 line buffers. Uses 11-bit signed 
 * arithmetic to prevent overflow during gradient calculation and features 
 * a robust pixel counter for precise TLAST generation.
 * Target Board: PYNQ-Z2 (Zynq-7000 SoC)
 * ========================================================================= */

module sobel_edge_detection #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH  = 256,
    parameter IMG_HEIGHT = 256
)(
    input  wire                   axis_aclk,
    input  wire                   axis_aresetn,
    
    // --- Slave Interface (Input from DMA) ---
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast, // Ignored to prevent sync issues
    
    // --- Master Interface (Output to DMA) ---
    output reg  [DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                    m_axis_tvalid,
    input  wire                   m_axis_tready,
    output reg                    m_axis_tlast
);

    // --- Internal Constants ---
    localparam TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT;

    // --- Line Buffers (Row N-1 and Row N-2) ---
    reg [8:0] col_ptr;
    reg [DATA_WIDTH-1:0] line_buff_0 [0:IMG_WIDTH-1]; 
    reg [DATA_WIDTH-1:0] line_buff_1 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] r0, r1, r2;
    reg buff_valid;

    // --- Buffer Write Logic ---
    // Reads incoming pixels and pushes them through the line buffers
    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            col_ptr <= 0;
            buff_valid <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            // Extract vertical column for the 3x3 window
            r0 <= s_axis_tdata;
            r1 <= line_buff_0[col_ptr];
            r2 <= line_buff_1[col_ptr];
            
            // Shift rows upward
            line_buff_0[col_ptr] <= s_axis_tdata;
            line_buff_1[col_ptr] <= line_buff_0[col_ptr];
            
            // Update column pointer, wrap around at end of row
            col_ptr <= (col_ptr == IMG_WIDTH - 1) ? 0 : col_ptr + 1;
            
            // Assert valid immediately to ensure synchronous 1:1 pixel throughput
            buff_valid <= 1'b1;
        end else begin
            buff_valid <= 1'b0;
        end
    end
    
    // DMA is always ready to receive data as long as reset is inactive
    assign s_axis_tready = axis_aresetn; 

    // --- 3x3 Sliding Window & Sobel Arithmetic ---
    reg [DATA_WIDTH-1:0] p11, p12, p13, p21, p22, p23, p31, p32, p33;
    reg signed [10:0] gx, gy;
    reg calc_valid;

    always @(posedge axis_aclk) begin
        if (buff_valid) begin
            // Shift Window Left
            p11<=p12; p21<=p22; p31<=p32;
            p12<=p13; p22<=p23; p32<=p33;
            p13<=r2;  p23<=r1;  p33<=r0;
            
            // Calculate Gradients (Signed 11-bit to handle negative results)
            gx <= (p13 + (p23<<1) + p33) - (p11 + (p21<<1) + p31);
            gy <= (p11 + (p12<<1) + p13) - (p31 + (p32<<1) + p33);
            calc_valid <= 1'b1;
        end else begin
            calc_valid <= 1'b0;
        end
    end

    // --- Output Logic, Clipping, & Pixel Counter ---
    reg [17:0] out_pixel_count; // Sufficiently sized for 256*256 = 65,536
    
    // Fast absolute value approximation (Two's complement if negative)
    wire [10:0] abs_gx = (gx[10]) ? (~gx+1) : gx;
    wire [10:0] abs_gy = (gy[10]) ? (~gy+1) : gy;
    wire [10:0] sum = abs_gx + abs_gy;

    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            m_axis_tvalid <= 0;
            m_axis_tlast  <= 0;
            out_pixel_count <= 0;
        end else if (calc_valid) begin
            m_axis_tvalid <= 1'b1;
            // Clip values at 255 to prevent 8-bit overflow (white saturation)
            m_axis_tdata  <= (sum > 255) ? 8'hFF : sum[7:0];
            
            // FORCE TLAST exactly at the last pixel of the frame
            if (out_pixel_count == TOTAL_PIXELS - 1) begin
                m_axis_tlast <= 1'b1;
                out_pixel_count <= 0;
            end else begin
                m_axis_tlast <= 1'b0;
                out_pixel_count <= out_pixel_count + 1;
            end
        end else begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end
    end
endmodule