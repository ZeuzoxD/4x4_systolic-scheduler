module tb_systolic_with_scheduler();

    // Clock and reset
    reg clk;
    reg rst;
    
    // Scheduler control signals
    reg start;
    wire valid;
    wire sched_done;
    
    // Systolic array done signal
    wire array_done;
    
    // Test matrices (4x4 each) - matching your testbench pattern
    reg [31:0] mat_a [0:3][0:3];
    reg [31:0] mat_b [0:3][0:3];
    
    // Flattened matrix inputs for scheduler
    wire [31:0] mat_a_00, mat_a_01, mat_a_02, mat_a_03;
    wire [31:0] mat_a_10, mat_a_11, mat_a_12, mat_a_13;
    wire [31:0] mat_a_20, mat_a_21, mat_a_22, mat_a_23; 
    wire [31:0] mat_a_30, mat_a_31, mat_a_32, mat_a_33;
    
    wire [31:0] mat_b_00, mat_b_01, mat_b_02, mat_b_03;
    wire [31:0] mat_b_10, mat_b_11, mat_b_12, mat_b_13;
    wire [31:0] mat_b_20, mat_b_21, mat_b_22, mat_b_23;
    wire [31:0] mat_b_30, mat_b_31, mat_b_32, mat_b_33;
    
    // Data streams from scheduler to systolic array
    wire [31:0] a_out0, a_out1, a_out2, a_out3;
    wire [31:0] b_out0, b_out1, b_out2, b_out3;
    
    // Final result monitoring - create registers to capture final results
    reg [63:0] final_results [0:15];
    reg results_captured;
    
    // Map 2D arrays to flat wires for scheduler
    assign mat_a_00 = mat_a[0][0]; assign mat_a_01 = mat_a[0][1]; assign mat_a_02 = mat_a[0][2]; assign mat_a_03 = mat_a[0][3];
    assign mat_a_10 = mat_a[1][0]; assign mat_a_11 = mat_a[1][1]; assign mat_a_12 = mat_a[1][2]; assign mat_a_13 = mat_a[1][3];
    assign mat_a_20 = mat_a[2][0]; assign mat_a_21 = mat_a[2][1]; assign mat_a_22 = mat_a[2][2]; assign mat_a_23 = mat_a[2][3];
    assign mat_a_30 = mat_a[3][0]; assign mat_a_31 = mat_a[3][1]; assign mat_a_32 = mat_a[3][2]; assign mat_a_33 = mat_a[3][3];
    
    assign mat_b_00 = mat_b[0][0]; assign mat_b_01 = mat_b[0][1]; assign mat_b_02 = mat_b[0][2]; assign mat_b_03 = mat_b[0][3];
    assign mat_b_10 = mat_b[1][0]; assign mat_b_11 = mat_b[1][1]; assign mat_b_12 = mat_b[1][2]; assign mat_b_13 = mat_b[1][3];
    assign mat_b_20 = mat_b[2][0]; assign mat_b_21 = mat_b[2][1]; assign mat_b_22 = mat_b[2][2]; assign mat_b_23 = mat_b[2][3];
    assign mat_b_30 = mat_b[3][0]; assign mat_b_31 = mat_b[3][1]; assign mat_b_32 = mat_b[3][2]; assign mat_b_33 = mat_b[3][3];
    
    // Instantiate the scheduler with correct delay to match your testbench timing
    systolic_scheduler #(
        .DELAY(1),          // 1 cycle delay to match 10ns steps in your testbench
        .DATA_WIDTH(32)
    ) scheduler (
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
        .done(sched_done)
    );
    
    // Instantiate the systolic array
    systolic_array array (
        .inp_west0(a_out0),
        .inp_west4(a_out1), 
        .inp_west8(a_out2),
        .inp_west12(a_out3),
        .inp_north0(b_out0),
        .inp_north1(b_out1),
        .inp_north2(b_out2),
        .inp_north3(b_out3),
        .clk(clk),
        .rst(rst),
        .done(array_done)
    );
    
    // Clock generation - 10ns period to match your testbench
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Capture final results when array is done
    always @(posedge clk) begin
        if (array_done && !results_captured) begin
            #30; //let outputs settle
            final_results[0] = array.result0;   final_results[1] = array.result1;   
            final_results[2] = array.result2;   final_results[3] = array.result3;
            final_results[4] = array.result4;   final_results[5] = array.result5;   
            final_results[6] = array.result6;   final_results[7] = array.result7;
            final_results[8] = array.result8;   final_results[9] = array.result9;   
            final_results[10] = array.result10; final_results[11] = array.result11;
            final_results[12] = array.result12; final_results[13] = array.result13; 
            final_results[14] = array.result14; final_results[15] = array.result15;
            results_captured = 1;
            
            $display("*** RESULTS CAPTURED AT TIME %t ***", $time);
            $display("Final Results Matrix:");
            $display("Row 0: %3d %3d %3d %3d", final_results[0], final_results[1], final_results[2], final_results[3]);
            $display("Row 1: %3d %3d %3d %3d", final_results[4], final_results[5], final_results[6], final_results[7]);
            $display("Row 2: %3d %3d %3d %3d", final_results[8], final_results[9], final_results[10], final_results[11]);
            $display("Row 3: %3d %3d %3d %3d", final_results[12], final_results[13], final_results[14], final_results[15]);
        end
    end
    
    // Continuous monitoring of results for GTKWave
    always @(posedge clk) begin
        if ($time > 100) begin // Start monitoring after initial setup
            // Log current state of all results for waveform viewing
            // These will show up as signals in GTKWave
        end
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst = 1;
        start = 0;
        results_captured = 0;
        
        // Initialize test matrices to match your testbench pattern
        // Matrix A (from your testbench west inputs)
        mat_a[0][0] = 3;  mat_a[0][1] = 2;  mat_a[0][2] = 1;  mat_a[0][3] = 0;
        mat_a[1][0] = 7;  mat_a[1][1] = 6;  mat_a[1][2] = 5;  mat_a[1][3] = 4;
        mat_a[2][0] = 11; mat_a[2][1] = 10; mat_a[2][2] = 9;  mat_a[2][3] = 8;
        mat_a[3][0] = 15; mat_a[3][1] = 14; mat_a[3][2] = 13; mat_a[3][3] = 12;
        
        // Matrix B (from your testbench north inputs)
        mat_b[0][0] = 12; mat_b[0][1] = 8;  mat_b[0][2] = 4;  mat_b[0][3] = 0;
        mat_b[1][0] = 13; mat_b[1][1] = 9;  mat_b[1][2] = 5;  mat_b[1][3] = 1;
        mat_b[2][0] = 14; mat_b[2][1] = 10; mat_b[2][2] = 6;  mat_b[2][3] = 2;
        mat_b[3][0] = 15; mat_b[3][1] = 11; mat_b[3][2] = 7;  mat_b[3][3] = 3;
        
        $display("=== Systolic Array with Scheduler Test ===");
        $display("Matrix A:");
        $display("%2d %2d %2d %2d", mat_a[0][0], mat_a[0][1], mat_a[0][2], mat_a[0][3]);
        $display("%2d %2d %2d %2d", mat_a[1][0], mat_a[1][1], mat_a[1][2], mat_a[1][3]);
        $display("%2d %2d %2d %2d", mat_a[2][0], mat_a[2][1], mat_a[2][2], mat_a[2][3]);
        $display("%2d %2d %2d %2d", mat_a[3][0], mat_a[3][1], mat_a[3][2], mat_a[3][3]);
        
        $display("Matrix B:");
        $display("%2d %2d %2d %2d", mat_b[0][0], mat_b[0][1], mat_b[0][2], mat_b[0][3]);
        $display("%2d %2d %2d %2d", mat_b[1][0], mat_b[1][1], mat_b[1][2], mat_b[1][3]);
        $display("%2d %2d %2d %2d", mat_b[2][0], mat_b[2][1], mat_b[2][2], mat_b[2][3]);
        $display("%2d %2d %2d %2d", mat_b[3][0], mat_b[3][1], mat_b[3][2], mat_b[3][3]);
        
        // Calculate and display expected results
        $display("\nExpected Results (A × B):");
        $display("Row 0: %3d %3d %3d %3d", 76, 52, 28, 4);
        $display("Row 1: %3d %3d %3d %3d", 292, 204, 116, 28);
        $display("Row 2: %3d %3d %3d %3d", 508, 356, 204, 52);
        $display("Row 3: %3d %3d %3d %3d", 724, 508, 292, 76);
        
        // Release reset
        #15 rst = 0;
        #10;
        
        // Start the operation
        $display("\n=== Starting Matrix Multiplication at time %t ===", $time);
        start = 1;
        #10 start = 0;
        
        // Wait for scheduler to complete
        wait(sched_done);
        $display("\n=== Scheduler Completed at time %t ===", $time);
        
        // Wait for systolic array to complete
        wait(array_done);
        $display("\n=== Systolic Array Completed at time %t ===", $time);
        
        // Wait additional time for all results to stabilize
        #100;
        
        // Final verification
        $display("\n=== FINAL VERIFICATION ===");
        $display("Actual Results:");
        $display("Row 0: %3d %3d %3d %3d", array.result0, array.result1, array.result2, array.result3);
        $display("Row 1: %3d %3d %3d %3d", array.result4, array.result5, array.result6, array.result7);
        $display("Row 2: %3d %3d %3d %3d", array.result8, array.result9, array.result10, array.result11);
        $display("Row 3: %3d %3d %3d %3d", array.result12, array.result13, array.result14, array.result15);
        
        $display("\nExpected Results:");
        $display("Row 0: %3d %3d %3d %3d", 76, 52, 28, 4);
        $display("Row 1: %3d %3d %3d %3d", 292, 204, 116, 28);
        $display("Row 2: %3d %3d %3d %3d", 508, 356, 204, 52);
        $display("Row 3: %3d %3d %3d %3d", 724, 508, 292, 76);
        
        // Check for errors
        $display("\n=== ERROR ANALYSIS ===");
        if (array.result0 != 76) $display("ERROR: P0 = %d, expected 76", array.result0);
        if (array.result1 != 52) $display("ERROR: P1 = %d, expected 52", array.result1);
        if (array.result2 != 28) $display("ERROR: P2 = %d, expected 28", array.result2);
        if (array.result3 != 4)  $display("ERROR: P3 = %d, expected 4", array.result3);
        if (array.result7 != 28) $display("ERROR: P7 = %d, expected 28", array.result7);
        if (array.result11 != 52) $display("ERROR: P11 = %d, expected 52", array.result11);
        if (array.result15 != 76) $display("ERROR: P15 = %d, expected 76", array.result15);
        
        $display("\n=== Test Completed ===");
        $finish;
    end
    
    // Enhanced monitoring for debugging
    always @(posedge clk) begin
        if (valid && $time > 20) begin
            $display("Time %0t: Feeding - West=[%0d,%0d,%0d,%0d] North=[%0d,%0d,%0d,%0d]", 
                     $time, a_out0, a_out1, a_out2, a_out3, b_out0, b_out1, b_out2, b_out3);
        end
    end
    
    // Monitor systolic array internal count for timing debug
    always @(posedge clk) begin
        if (array.count > 0 && array.count < 12) begin
            $display("Time %0t: Array count = %d, done = %b", $time, array.count, array_done);
        end
    end
    
    // Timeout safety
    initial begin
        #3000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Enhanced VCD dump for GTKWave with all signals
    initial begin
        $dumpfile("systolic_debug.vcd");
        $dumpvars(0, tb_systolic_with_scheduler);
        
        // Explicitly dump array results for better visibility in GTKWave
        $dumpvars(1, array.result0, array.result1, array.result2, array.result3);
        $dumpvars(1, array.result4, array.result5, array.result6, array.result7);
        $dumpvars(1, array.result8, array.result9, array.result10, array.result11);
        $dumpvars(1, array.result12, array.result13, array.result14, array.result15);
        
        // Dump final captured results
        $dumpvars(1, final_results[0], final_results[1], final_results[2], final_results[3]);
        $dumpvars(1, final_results[4], final_results[5], final_results[6], final_results[7]);
        $dumpvars(1, final_results[8], final_results[9], final_results[10], final_results[11]);
        $dumpvars(1, final_results[12], final_results[13], final_results[14], final_results[15]);
        
        // Dump scheduler and array internal signals
        $dumpvars(2, scheduler);
        $dumpvars(2, array);
    end

endmodule
