`timescale 1ns / 1ps
module tb_sobel_file();

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

    integer file_in, file_out, scan_file;
    integer pixel_count;

    // Reconstructed: DUT Instantiation (256x256 limit)
    sobel_edge_detection #(
        .DATA_WIDTH(8),
        .IMG_WIDTH(256),
        .IMG_HEIGHT(256)
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

    // Reconstructed: AXI-Stream Input Generation (input_image.txt handling)
    initial begin
        axis_aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        s_axis_tdata = 0;
        pixel_count = 0;

        file_in = $fopen("input_image.txt", "r");
        if (file_in == 0) begin
            $display("ERROR: Could not open input_image.txt");
            $finish;
        end

        #100;
        axis_aresetn = 1;
        #20;

        while (!$feof(file_in)) begin
            @(posedge axis_aclk);
            if (s_axis_tready) begin
                scan_file = $fscanf(file_in, "%h\n", s_axis_tdata);
                if (scan_file == 1) begin
                    s_axis_tvalid = 1;
                    pixel_count = pixel_count + 1;
                end
            end else begin
                s_axis_tvalid = 0;
            end
        end

        @(posedge axis_aclk);
        s_axis_tvalid = 0;
        $fclose(file_in);
    end

    // Reconstructed: Output Capture Logic (output_image.txt handling)
    initial begin
        m_axis_tready = 1;
        file_out = $fopen("output_image.txt", "w");

        forever begin
            @(posedge axis_aclk);
            // Simulation Valid Signal Logic
            if (m_axis_tvalid && m_axis_tready) begin
                $fwrite(file_out, "%02x\n", m_axis_tdata);
            end

            // Simulation stop condition (based on the 50us run instruction or specific valid count)
            if (m_axis_tlast) begin
                $fclose(file_out);
                #1000;
                $finish;
            end
        end
    end
endmodule

