`timescale 1ns / 1ps

// =========================================================================
// DIRECTLY RECOVERED: Module Declaration, Parameters & AXI Ports
// =========================================================================
module sobel_edge_detection #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH  = 256,
    parameter IMG_HEIGHT = 256
)(
    input  wire                   axis_aclk,
    input  wire                   axis_aresetn, // Active Low Reset

    // Slave (Input from DMA)
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast, // Ignored to prevent sync bugs

    // Master (Output to DMA)
    output reg  [DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                    m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast
);

// =========================================================================
// DIRECTLY RECOVERED: Internal Registers & Line Buffers
// =========================================================================
reg [8:0] col_ptr;
reg [DATA_WIDTH-1:0] line_buff_0 [0:IMG_WIDTH-1];
reg [DATA_WIDTH-1:0] line_buff_1 [0:IMG_WIDTH-1];
reg [DATA_WIDTH-1:0] r0, r1, r2;
reg buff_valid;

reg signed [10:0] gx, gy;
reg calc_valid;

// The robust absolute output pixel counter (18 bits to safely hold 65,536)
reg [17:0] out_pixel_count;

// =========================================================================
// INFERRED/RECONSTRUCTED: Sliding Window Registers & Absolute Wires
// =========================================================================
reg [DATA_WIDTH-1:0] p11, p12, p13;
reg [DATA_WIDTH-1:0] p21, p22, p23;
reg [DATA_WIDTH-1:0] p31, p32, p33;

wire [10:0] abs_gx;
wire [10:0] abs_gy;
wire [10:0] sum_g;

// Simple ready assignment to prevent backpressure lockups
assign s_axis_tready = axis_aresetn;

// =========================================================================
// INFERRED/RECONSTRUCTED: Main Datapath Always Block
// =========================================================================
always @(posedge axis_aclk) begin
    if (!axis_aresetn) begin
        col_ptr <= 0;
        buff_valid <= 0;
        calc_valid <= 0;
        gx <= 0;
        gy <= 0;
    end else if (s_axis_tvalid && s_axis_tready) begin

        // 1. Line Buffers Read-Before-Write
        r2 <= line_buff_1[col_ptr];
        r1 <= line_buff_0[col_ptr];
        r0 <= s_axis_tdata;

        line_buff_1[col_ptr] <= line_buff_0[col_ptr];
        line_buff_0[col_ptr] <= s_axis_tdata;

        if (col_ptr == IMG_WIDTH - 1) begin
            col_ptr <= 0;
            buff_valid <= 1; // Asserted once buffers absorb initial rows
        end else begin
            col_ptr <= col_ptr + 1;
        end

        // 2. Sliding Window (Shift-Left Grid)
        p11 <= p12; p12 <= p13; p13 <= r2;
        p21 <= p22; p22 <= p23; p23 <= r1;
        p31 <= p32; p32 <= p33; p33 <= r0;

        // 3. Sobel Arithmetic Logic (Signed 11-bit logic)
        gx <= (p13 + 2*p23 + p33) - (p11 + 2*p21 + p31);
        gy <= (p11 + 2*p12 + p13) - (p31 + 2*p32 + p33);

        // Shift valid signal alongside pipeline calculations
        calc_valid <= buff_valid;
    end
end

// =========================================================================
// INFERRED/RECONSTRUCTED: Clipping & Absolute Value Logic
// =========================================================================
// Using wires avoids a 1-cycle pipeline delay lag between math and valid signal
assign abs_gx = (gx) ? -gx : gx;
assign abs_gy = (gy) ? -gy : gy;
assign sum_g = abs_gx + abs_gy;

always @(posedge axis_aclk) begin
    if (!axis_aresetn) begin
        m_axis_tdata <= 0;
        m_axis_tvalid <= 0;
    end else begin
        if (calc_valid) begin
            // Clipping logic capping sums > 255 back to 8-bit unsigned
            m_axis_tdata <= (sum_g > 255) ? 8'd255 : sum_g[7:0];
        end
        m_axis_tvalid <= calc_valid;
    end
end

// =========================================================================
// DIRECTLY RECOVERED: Robust Output Pixel Count & TLAST Logic
// =========================================================================
always @(posedge axis_aclk) begin
    if (!axis_aresetn) begin
        out_pixel_count <= 0;
    end else if (m_axis_tvalid && m_axis_tready) begin
        // Counts absolute valid output pixels independent of input timing
        if (out_pixel_count == (IMG_WIDTH*IMG_HEIGHT)-1)
            out_pixel_count <= 0;
        else
            out_pixel_count <= out_pixel_count + 1;
    end
end

// TLAST mathematically triggered on exactly the 65,536th valid pixel
assign m_axis_tlast = (out_pixel_count == (IMG_WIDTH*IMG_HEIGHT)-1);

endmodule

