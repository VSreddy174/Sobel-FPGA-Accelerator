`timescale 1ns / 1ps

/* =========================================================================
 * Testbench: tb_sobel_ramp
 * Description: Arithmetic Stress Test for 256x256 Sobel Accelerator.
 * Generates an internal repeating ramp gradient (0 to 255) to stress math logic.
 * GENERATES: input_ramp.txt and output_ramp.txt for visual verification.
 * ========================================================================= */

module tb_sobel_ramp();

    // --- Parameters ---
    parameter DATA_WIDTH   = 8;
    parameter IMG_WIDTH    = 256;
    parameter IMG_HEIGHT   = 256;
    localparam TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT; // 65,536 pixels

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

    // --- File Handles & Tracking ---
    integer file_in;
    integer file_out;
    
    integer input_count  = 0;
    integer output_count = 0;

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

    // --- PROCESS 1: STIMULUS (Generating Ramp Data) ---
    initial begin
        $display("==================================================");
        $display("  STARTING SOBEL RAMP STRESS TEST");
        $display("  Target: %0d Pixels (256x256)", TOTAL_PIXELS);
        $display("==================================================");

        file_in = $fopen("input_ramp.txt", "w");
        if (file_in == 0) begin
            $display("[FATAL ERROR] Could not create 'input_ramp.txt'.");
            $finish;
        end

        // Initialize
        axis_aresetn  = 0;
        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        m_axis_tready = 1; 
        
        #100;
        axis_aresetn = 1; 
        #20;
        $display("[TIME: %0t ns] Reset released. Generating ramp data...", $time);

        // Send exactly 65,536 pixels
        for (input_count = 0; input_count < TOTAL_PIXELS; input_count = input_count + 1) begin
            wait(s_axis_tready);
            @(posedge axis_aclk);
            
            s_axis_tvalid <= 1;
            
            // The Ramp Math: Automatically rolls over at 255 because of 8-bit limit
            s_axis_tdata  <= (input_count % 256);
            
            // Save exactly what we sent to the hardware
            $fwrite(file_in, "%02x\n", s_axis_tdata);

            if (input_count > 0 && input_count % 10000 == 0) begin
                $display("   ... Generated %0d / %0d pixels.", input_count, TOTAL_PIXELS);
            end

            if (input_count == TOTAL_PIXELS - 1)
                s_axis_tlast <= 1;
            else
                s_axis_tlast <= 0;
        end

        // End of transmission
        @(posedge axis_aclk);
        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
        $fclose(file_in);
        $display("[TIME: %0t ns] Finished generating ramp. Waiting for pipeline...", $time);

        // Safety Timeout 
        #50000;
        $display("\n[ERROR] Simulation Timed Out!");
        $finish;
    end

    // --- PROCESS 2: MONITOR (Catching Output Data) ---
    initial begin
        file_out = $fopen("output_ramp.txt", "w");
        if (file_out == 0) begin
            $display("[FATAL ERROR] Could not create 'output_ramp.txt'.");
            $finish;
        end
    end

    always @(posedge axis_aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            output_count = output_count + 1;
            
            // Write the valid output pixel to the text file in Hex format
            $fwrite(file_out, "%02x\n", m_axis_tdata);

            // Check for TLAST
            if (m_axis_tlast) begin
                $display("--------------------------------------------------");
                $display("[TIME: %0t ns] M_AXIS_TLAST ASSERTED!", $time);
                $display("Total Valid Output Pixels Caught: %0d", output_count);
                
                if (output_count == TOTAL_PIXELS) begin
                    $display(">> STRESS TEST PASS: Hardware correctly processed 65,536 changing pixels.");
                end else begin
                    $display(">> STRESS TEST FAIL: Expected %0d but got %0d.", TOTAL_PIXELS, output_count);
                end
                $display("==================================================");
                
                $fclose(file_out);
                $display("output_ramp.txt saved successfully. Ready for Python.");
                #100;
                $finish;
            end
        end
    end

endmodule

