`timescale 1ns / 1ps

module tb_sobel_10x10();

    // --- Parameters ---
    parameter DATA_WIDTH   = 8;
    parameter IMG_WIDTH    = 10;
    parameter IMG_HEIGHT   = 10;
    localparam TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT; // 100 pixels

    // --- Signals ---
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

    // --- Tracking Integers & File Handles ---
    integer input_count  = 0;
    integer output_count = 0;
    integer col_index    = 0;
    
    integer file_in;
    integer file_out;

    // --- DUT Instantiation ---
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

    // --- Clock Generation (100 MHz) ---
    initial begin
        axis_aclk = 0;
        forever #5 axis_aclk = ~axis_aclk;
    end

    // --- PROCESS 1: STIMULUS (Processor sending data) ---
    initial begin
        $display("==================================================");
        $display("  STARTING 10x10 SOBEL SIMULATION");
        $display("  Total Pixels to Process: %0d", TOTAL_PIXELS);
        $display("==================================================");

        file_in = $fopen("input_10x10.txt", "w");

        // Initialize
        axis_aresetn  = 0;
        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        m_axis_tready = 1; 
        
        #100;
        axis_aresetn = 1; 
        #20;

        // Send exactly 100 pixels
        for (input_count = 0; input_count < TOTAL_PIXELS; input_count = input_count + 1) begin
            wait(s_axis_tready);
            @(posedge axis_aclk);
            s_axis_tvalid <= 1;
            
            // Create vertical edge: Left 5 pixels Black, Right 5 pixels White
            col_index = input_count % IMG_WIDTH;
            if (col_index < 5) begin
                s_axis_tdata <= 8'h00; 
                $fwrite(file_in, "00\n");
            end else begin
                s_axis_tdata <= 8'hFF; 
                $fwrite(file_in, "ff\n");
            end

            // Assert Input TLAST on the very last pixel
            if (input_count == TOTAL_PIXELS - 1)
                s_axis_tlast <= 1;
            else
                s_axis_tlast <= 0;
        end

        // End of transmission: Drop valid signal
        @(posedge axis_aclk);
        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
        $fclose(file_in);

        // Safety Timeout 
        #2000;
        $display("\n[ERROR] Simulation Timed Out!");
        $finish;
    end

    // --- PROCESS 2: MONITOR (DMA receiving data) ---
    initial begin
        file_out = $fopen("output_10x10.txt", "w");
    end

    always @(posedge axis_aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            output_count = output_count + 1;
            $fwrite(file_out, "%02x\n", m_axis_tdata);

            // Check for TLAST from your hardware
            if (m_axis_tlast) begin
                $display("--------------------------------------------------");
                $display("[TIME: %0t ns] M_AXIS_TLAST ASSERTED!", $time);
                $display("Total Valid Output Pixels Caught: %0d", output_count);
                
                if (output_count == TOTAL_PIXELS) begin
                    $display(">> VERIFICATION PASS: TLAST fired exactly on pixel %0d.", TOTAL_PIXELS);
                end else begin
                    $display(">> VERIFICATION FAIL: Expected %0d but got %0d.", TOTAL_PIXELS, output_count);
                end
                $display("==================================================");
                
                $fclose(file_out);
                #100;
                $finish;
            end
        end
    end

endmodule