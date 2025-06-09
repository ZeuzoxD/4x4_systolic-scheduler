module tb_systolic_scheduler();

    // Parameters
    parameter DELAY = 10;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Testbench signals
    reg clk;
    reg rst;
    reg start;
    
    // Matrix A inputs
    reg [DATA_WIDTH-1:0] mat_a_00, mat_a_01, mat_a_02, mat_a_03;
    reg [DATA_WIDTH-1:0] mat_a_10, mat_a_11, mat_a_12, mat_a_13;
    reg [DATA_WIDTH-1:0] mat_a_20, mat_a_21, mat_a_22, mat_a_23;
    reg [DATA_WIDTH-1:0] mat_a_30, mat_a_31, mat_a_32, mat_a_33;
    
    // Matrix B inputs
    reg [DATA_WIDTH-1:0] mat_b_00, mat_b_01, mat_b_02, mat_b_03;
    reg [DATA_WIDTH-1:0] mat_b_10, mat_b_11, mat_b_12, mat_b_13;
    reg [DATA_WIDTH-1:0] mat_b_20, mat_b_21, mat_b_22, mat_b_23;
    reg [DATA_WIDTH-1:0] mat_b_30, mat_b_31, mat_b_32, mat_b_33;
    
    // Outputs
    wire [DATA_WIDTH-1:0] a_out0, a_out1, a_out2, a_out3;
    wire [DATA_WIDTH-1:0] b_out0, b_out1, b_out2, b_out3;
    wire valid;
    wire done;

    // Test variables
    integer cycle_count;
    integer valid_count;
    integer error_count;
    
    // Expected output arrays for verification
    reg [DATA_WIDTH-1:0] expected_a_out [0:3][0:6]; // [output_port][step]
    reg [DATA_WIDTH-1:0] expected_b_out [0:3][0:6];
    reg expected_valid [0:6];

    // Instantiate DUT
    systolic_scheduler #(
        .DELAY(DELAY),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mat_a_00(mat_a_00), .mat_a_01(mat_a_01), .mat_a_02(mat_a_02), .mat_a_03(mat_a_03),
        .mat_a_10(mat_a_10), .mat_a_11(mat_a_11), .mat_a_12(mat_a_12), .mat_a_13(mat_a_13),
        .mat_a_20(mat_a_20), .mat_a_21(mat_a_21), .mat_a_22(mat_a_22), .mat_a_23(mat_a_23),
        .mat_a_30(mat_a_30), .mat_a_31(mat_a_31), .mat_a_32(mat_a_32), .mat_a_33(mat_a_33),
        .mat_b_00(mat_b_00), .mat_b_01(mat_b_01), .mat_b_02(mat_b_02), .mat_b_03(mat_b_03),
        .mat_b_10(mat_b_10), .mat_b_11(mat_b_11), .mat_b_12(mat_b_12), .mat_b_13(mat_b_13),
        .mat_b_20(mat_b_20), .mat_b_21(mat_b_21), .mat_b_22(mat_b_22), .mat_b_23(mat_b_23),
        .mat_b_30(mat_b_30), .mat_b_31(mat_b_31), .mat_b_32(mat_b_32), .mat_b_33(mat_b_33),
        .a_out0(a_out0), .a_out1(a_out1), .a_out2(a_out2), .a_out3(a_out3),
        .b_out0(b_out0), .b_out1(b_out1), .b_out2(b_out2), .b_out3(b_out3),
        .valid(valid),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Initialize test matrices
    task init_matrices;
        begin
            // Matrix A - simple incremental pattern
            mat_a_00 = 32'h01; mat_a_01 = 32'h02; mat_a_02 = 32'h03; mat_a_03 = 32'h04;
            mat_a_10 = 32'h05; mat_a_11 = 32'h06; mat_a_12 = 32'h07; mat_a_13 = 32'h08;
            mat_a_20 = 32'h09; mat_a_21 = 32'h0A; mat_a_22 = 32'h0B; mat_a_23 = 32'h0C;
            mat_a_30 = 32'h0D; mat_a_31 = 32'h0E; mat_a_32 = 32'h0F; mat_a_33 = 32'h10;
            
            // Matrix B - different pattern
            mat_b_00 = 32'h11; mat_b_01 = 32'h12; mat_b_02 = 32'h13; mat_b_03 = 32'h14;
            mat_b_10 = 32'h15; mat_b_11 = 32'h16; mat_b_12 = 32'h17; mat_b_13 = 32'h18;
            mat_b_20 = 32'h19; mat_b_21 = 32'h1A; mat_b_22 = 32'h1B; mat_b_23 = 32'h1C;
            mat_b_30 = 32'h1D; mat_b_31 = 32'h1E; mat_b_32 = 32'h1F; mat_b_33 = 32'h20;
        end
    endtask

    // Calculate expected outputs based on systolic feeding pattern
    task calculate_expected;
        integer step, port;
        begin
            // Initialize all to zero
            for (step = 0; step <= 6; step = step + 1) begin
                for (port = 0; port <= 3; port = port + 1) begin
                    expected_a_out[port][step] = 0;
                    expected_b_out[port][step] = 0;
                end
                expected_valid[step] = 1; // Valid should be high during feeding
            end
            
            // Row 0: feeds at steps 0,1,2,3
            expected_a_out[0][0] = mat_a_00; expected_b_out[0][0] = mat_b_00;
            expected_a_out[0][1] = mat_a_01; expected_b_out[0][1] = mat_b_10;
            expected_a_out[0][2] = mat_a_02; expected_b_out[0][2] = mat_b_20;
            expected_a_out[0][3] = mat_a_03; expected_b_out[0][3] = mat_b_30;
            
            // Row 1: feeds at steps 1,2,3,4 (offset by 1)
            expected_a_out[1][1] = mat_a_10; expected_b_out[1][1] = mat_b_01;
            expected_a_out[1][2] = mat_a_11; expected_b_out[1][2] = mat_b_11;
            expected_a_out[1][3] = mat_a_12; expected_b_out[1][3] = mat_b_21;
            expected_a_out[1][4] = mat_a_13; expected_b_out[1][4] = mat_b_31;
            
            // Row 2: feeds at steps 2,3,4,5 (offset by 2)
            expected_a_out[2][2] = mat_a_20; expected_b_out[2][2] = mat_b_02;
            expected_a_out[2][3] = mat_a_21; expected_b_out[2][3] = mat_b_12;
            expected_a_out[2][4] = mat_a_22; expected_b_out[2][4] = mat_b_22;
            expected_a_out[2][5] = mat_a_23; expected_b_out[2][5] = mat_b_32;
            
            // Row 3: feeds at steps 3,4,5,6 (offset by 3)
            expected_a_out[3][3] = mat_a_30; expected_b_out[3][3] = mat_b_03;
            expected_a_out[3][4] = mat_a_31; expected_b_out[3][4] = mat_b_13;
            expected_a_out[3][5] = mat_a_32; expected_b_out[3][5] = mat_b_23;
            expected_a_out[3][6] = mat_a_33; expected_b_out[3][6] = mat_b_33;
        end
    endtask

    // Check outputs against expected values
    task check_outputs;
        input integer step;
        begin
            if (valid) begin
                $display("Step %0d - Checking outputs:", step);
                
                // Check A outputs
                if (a_out0 !== expected_a_out[0][step]) begin
                    $display("ERROR: a_out0 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_a_out[0][step], a_out0);
                    error_count = error_count + 1;
                end
                if (a_out1 !== expected_a_out[1][step]) begin
                    $display("ERROR: a_out1 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_a_out[1][step], a_out1);
                    error_count = error_count + 1;
                end
                if (a_out2 !== expected_a_out[2][step]) begin
                    $display("ERROR: a_out2 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_a_out[2][step], a_out2);
                    error_count = error_count + 1;
                end
                if (a_out3 !== expected_a_out[3][step]) begin
                    $display("ERROR: a_out3 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_a_out[3][step], a_out3);
                    error_count = error_count + 1;
                end
                
                // Check B outputs
                if (b_out0 !== expected_b_out[0][step]) begin
                    $display("ERROR: b_out0 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_b_out[0][step], b_out0);
                    error_count = error_count + 1;
                end
                if (b_out1 !== expected_b_out[1][step]) begin
                    $display("ERROR: b_out1 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_b_out[1][step], b_out1);
                    error_count = error_count + 1;
                end
                if (b_out2 !== expected_b_out[2][step]) begin
                    $display("ERROR: b_out2 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_b_out[2][step], b_out2);
                    error_count = error_count + 1;
                end
                if (b_out3 !== expected_b_out[3][step]) begin
                    $display("ERROR: b_out3 mismatch at step %0d. Expected: %h, Got: %h", 
                             step, expected_b_out[3][step], b_out3);
                    error_count = error_count + 1;
                end
                
                $display("  A_out: %h %h %h %h", a_out0, a_out1, a_out2, a_out3);
                $display("  B_out: %h %h %h %h", b_out0, b_out1, b_out2, b_out3);
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("Starting Systolic Scheduler Testbench");
        $display("DELAY = %0d, DATA_WIDTH = %0d", DELAY, DATA_WIDTH);
        
        // Initialize
        cycle_count = 0;
        valid_count = 0;
        error_count = 0;
        
        rst = 1;
        start = 0;
        init_matrices();
        calculate_expected();
        
        // Reset sequence
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);
        
        $display("\n=== Test 1: Basic Operation ===");
        
        // Start operation
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Monitor for 7 steps * DELAY cycles + some extra
        begin : monitor_loop1
            repeat(7 * DELAY + 20) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                
                if (valid) begin
                    check_outputs(valid_count);
                    valid_count = valid_count + 1;
                end
                
                if (done) begin
                    $display("Done signal asserted at cycle %0d", cycle_count);
                    disable monitor_loop1;
                end
            end
        end
        
        // Verify we got the right number of valid cycles
        if (valid_count !== 7) begin
            $display("ERROR: Expected 7 valid cycles, got %0d", valid_count);
            error_count = error_count + 1;
        end
        
        $display("\n=== Test 2: Reset During Operation ===");
        
        // Start another operation
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Wait a few cycles then reset
        repeat(3 * DELAY) @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        
        // Check that outputs are zero after reset
        if (valid !== 0 || done !== 0) begin
            $display("ERROR: valid or done not cleared after reset");
            error_count = error_count + 1;
        end
        
        $display("\n=== Test 3: Back-to-back Operations ===");
        
        // First operation
        start = 1;
        @(posedge clk);
        start = 0;
        $display("Started first operation");
        
        // Wait for completion
        wait(done);
        $display("First operation completed, done=%b", done);
        @(posedge clk);
        
        // Acknowledge completion by pulsing start while done is high
        // This clears the done flag without starting a new operation (due to !done condition)
        $display("Acknowledging completion with done=%b", done);
        start = 1;
        @(posedge clk);
        start = 0;
        $display("After acknowledgment: done=%b", done);
        
        // Wait for done to clear
        wait(!done);
        @(posedge clk);
        
        // Now start second operation 
        $display("Starting second operation with done=%b", done);
        start = 1;
        @(posedge clk);
        $display("After start pulse: done=%b, feeding=%b", done, dut.feeding);
        start = 0;
        
        // Monitor second operation
        valid_count = 0;
        begin : monitor_loop2
            repeat(7 * DELAY + 10) begin
                @(posedge clk);
                if (valid) valid_count = valid_count + 1;
                if (done) disable monitor_loop2;
            end
        end
        
        if (valid_count !== 7) begin
            $display("ERROR: Back-to-back operation failed. Expected 7 valid cycles, got %0d", valid_count);
            error_count = error_count + 1;
        end
        
        // Test Summary
        $display("\n=== Test Summary ===");
        if (error_count == 0) begin
            $display("✓ All tests PASSED!");
        end else begin
            $display("✗ %0d errors found", error_count);
        end
        
        $display("Total simulation cycles: %0d", cycle_count);
        $finish;
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 1000); // 1000 cycle timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Optional: Waveform dumping (uncomment if needed)
     initial begin
         $dumpfile("systolic_scheduler.vcd");
         $dumpvars(0, tb_systolic_scheduler);
     end

endmodule
