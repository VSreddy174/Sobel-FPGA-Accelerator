`timescale 1ns/1ps

module tb_sobel_verilator;

    parameter DATA_WIDTH = 8;
    parameter IMG_WIDTH  = 256;
    parameter IMG_HEIGHT = 256;

    localparam TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT;

    reg axis_aclk;
    reg axis_aresetn;

    reg  [DATA_WIDTH-1:0] s_axis_tdata;
    reg                   s_axis_tvalid;
    wire                  s_axis_tready;
    reg                   s_axis_tlast;

    wire [DATA_WIDTH-1:0] m_axis_tdata;
    wire                  m_axis_tvalid;
    reg                   m_axis_tready;
    wire                  m_axis_tlast;

    integer input_count;
    integer output_count;

    sobel_edge_detection #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
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

    initial begin
        $dumpfile("sobel.vcd");
        $dumpvars(0, tb_sobel_verilator);
    end

    initial begin
        axis_aclk = 0;
    end

    always #5 axis_aclk = ~axis_aclk;

    initial begin

        axis_aresetn  = 0;

        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;

        m_axis_tready = 1;

        input_count   = 0;
        output_count  = 0;

        #100;

        axis_aresetn = 1;

        @(posedge axis_aclk);

        for(input_count = 0;
            input_count < TOTAL_PIXELS;
            input_count = input_count + 1) begin

            @(posedge axis_aclk);

            s_axis_tvalid <= 1;

            s_axis_tdata <= input_count % 256;

            if(input_count == TOTAL_PIXELS-1)
                s_axis_tlast <= 1;
            else
                s_axis_tlast <= 0;
        end

        @(posedge axis_aclk);

        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;

        #50000;

        $finish;
    end

    always @(posedge axis_aclk) begin

        if(m_axis_tvalid && m_axis_tready) begin

            output_count <= output_count + 1;

            if(output_count % 5000 == 0)
                $display("Output Count = %0d", output_count);

            if(m_axis_tlast) begin

                $display("Simulation Finished");
                $display("Total Output Pixels = %0d", output_count);

                #100;
                $finish;
            end
        end
    end

endmodule
