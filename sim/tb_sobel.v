`timescale 1ns / 1ps
module tb_sobel();

    // Reconstructed: Parameters and Signals
    reg axis_aclk;
    reg axis_aresetn;

    reg [7:0] s_axis_tdata;
    reg s_axis_tvalid;
    wire s_axis_tready;
    reg s_axis_tlast;

    wire [7:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire m_axis_tlast;

    integer i;

    // Reconstructed: Device Under Test (DUT) Instantiation
    sobel_edge_detection #(
        .DATA_WIDTH(8),
        .IMG_WIDTH(10),   // Reduced to 10x10 for small sample test
        .IMG_HEIGHT(10)
    ) dut (
        .axis_aclk(axis_aclk),
        .axis_aresetn(axis_aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Reconstructed: Clock Generation (100MHz)
    initial begin
        axis_aclk = 0;
        forever #5 axis_aclk = ~axis_aclk;
    end

    // Reconstructed: Reset and AXI-Stream Stimulus
    initial begin
        axis_aresetn = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;

        #100;
        axis_aresetn = 1; // Release reset
        #20;

        // Simulating a 10x10 image with a vertical edge
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge axis_aclk);
            while (!s_axis_tready) @(posedge axis_aclk); // Wait for DUT to be ready

            s_axis_tvalid = 1;

            // Dummy logic: Create an edge halfway through the row
            if ((i % 10) > 4)
                s_axis_tdata = 8'hFF; // White
            else
                s_axis_tdata = 8'h00; // Black

            // Assert TLAST on the very last pixel
            if (i == 99) s_axis_tlast = 1;
            else s_axis_tlast = 0;
        end

        @(posedge axis_aclk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;

        // Wait to capture all outputs
        #5000;
        $finish;
    end
endmodule



