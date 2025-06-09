/*********************************************************************************
  Systolic Array Scheduler for 4x4 Matrix Multiplication
**********************************************************************************
* DESCRIPTION:
*   This module implements a data scheduler for a 4x4 systolic array processor
*   used in matrix multiplication. It generates the proper timing and sequencing
*   to feed matrix elements in a diagonal wave pattern, ensuring optimal 
*   utilization of processing elements.
*
* OPERATION:
*   - Takes two 4x4 input matrices (A and B) as flattened inputs
*   - Feeds data to systolic array in 7 sequential steps (0-6)
*   - Each row is offset by one step to create diagonal data flow
*   - Configurable delay between feeding steps for timing control
*
* INTERFACES:
*   - start: Initiates feeding sequence
*   - valid: Indicates when output data is valid
*   - done: Asserted when complete feeding sequence is finished
*   - a_out[0:3], b_out[0:3]: Data streams to systolic array rows
*
* PARAMETERS:
*   - DELAY: Clock cycles between each feeding step (default: 10)
*   - DATA_WIDTH: Bit width of matrix elements (default: 32)
*
* AUTHOR: [ZeuzoxD]
******************************************************************************************/

module systolic_scheduler#(
  parameter DELAY = 10,
  parameter DATA_WIDTH = 32
) (
  input clk,
  input rst,
  input start,

  input [DATA_WIDTH-1:0] mat_a_00, mat_a_01, mat_a_02, mat_a_03,
  input [DATA_WIDTH-1:0] mat_a_10, mat_a_11, mat_a_12, mat_a_13,
  input [DATA_WIDTH-1:0] mat_a_20, mat_a_21, mat_a_22, mat_a_23,
  input [DATA_WIDTH-1:0] mat_a_30, mat_a_31, mat_a_32, mat_a_33,

  input [DATA_WIDTH-1:0] mat_b_00, mat_b_01, mat_b_02, mat_b_03,
  input [DATA_WIDTH-1:0] mat_b_10, mat_b_11, mat_b_12, mat_b_13,
  input [DATA_WIDTH-1:0] mat_b_20, mat_b_21, mat_b_22, mat_b_23,
  input [DATA_WIDTH-1:0] mat_b_30, mat_b_31, mat_b_32, mat_b_33,

  output reg [DATA_WIDTH-1:0] a_out0, a_out1, a_out2, a_out3,
  output reg [DATA_WIDTH-1:0] b_out0, b_out1, b_out2, b_out3,

  output reg valid,
  output reg done
);

  reg [3:0] step; //Current feeding step (0-6)
  reg [$clog2(DELAY+1)-1:0] delay_counter; //Delay timing counter
  reg feeding; //Feeding state flag

  wire [DATA_WIDTH-1:0] mat_a [0:3][0:3];
  wire [DATA_WIDTH-1:0] mat_b [0:3][0:3];

  assign mat_a[0][0] = mat_a_00; assign mat_a[0][1] = mat_a_01; assign mat_a[0][2] = mat_a_02; assign mat_a[0][3] = mat_a_03;
  assign mat_a[1][0] = mat_a_10; assign mat_a[1][1] = mat_a_11; assign mat_a[1][2] = mat_a_12; assign mat_a[1][3] = mat_a_13;
  assign mat_a[2][0] = mat_a_20; assign mat_a[2][1] = mat_a_21; assign mat_a[2][2] = mat_a_22; assign mat_a[2][3] = mat_a_23;
  assign mat_a[3][0] = mat_a_30; assign mat_a[3][1] = mat_a_31; assign mat_a[3][2] = mat_a_32; assign mat_a[3][3] = mat_a_33;

  assign mat_b[0][0] = mat_b_00; assign mat_b[0][1] = mat_b_01; assign mat_b[0][2] = mat_b_02; assign mat_b[0][3] = mat_b_03;
  assign mat_b[1][0] = mat_b_10; assign mat_b[1][1] = mat_b_11; assign mat_b[1][2] = mat_b_12; assign mat_b[1][3] = mat_b_13;
  assign mat_b[2][0] = mat_b_20; assign mat_b[2][1] = mat_b_21; assign mat_b[2][2] = mat_b_22; assign mat_b[2][3] = mat_b_23;
  assign mat_b[3][0] = mat_b_30; assign mat_b[3][1] = mat_b_31; assign mat_b[3][2] = mat_b_32; assign mat_b[3][3] = mat_b_33;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      step <= 0;
      delay_counter <= 0;
      valid <= 0;
      done <= 0;
      feeding <= 0;
      a_out0 <= 0; a_out1 <= 0; a_out2 <= 0; a_out3 <= 0;
      b_out0 <= 0; b_out1 <= 0; b_out2 <= 0; b_out3 <= 0;
    end else begin

    // Start condition: Begin feeding when start asserted and system is idle
    if (start && !feeding && !done) begin
        feeding <= 1;
        step <= 0;
        delay_counter <= 0;
        done <= 0;
        valid <= 0;
      end

      if (feeding) begin
        // Delay timer: Controls feeding rate
        if (delay_counter == DELAY-1) begin
            delay_counter <= 0;
            valid <= 1;
            /***************************************************************
               * Systolic Data Feeding Pattern
               * Each row feeds during a 4-step window, offset by row number
            ***************************************************************/
            // Row 0: Active during steps 0,1,2,3
            if (step <= 3) begin
              a_out0 <= mat_a[0][step];
              b_out0 <= mat_b[step][0];
            end else begin
              a_out0 <= 0;
              b_out0 <= 0;
            end

            // Row 1: Active during steps 1,2,3,4 (offset +1)
            if (step >= 1 && step <= 4) begin
              a_out1 <= mat_a[1][step-1];
              b_out1 <= mat_b[step-1][1];
            end else begin
              a_out1 <= 0;
              b_out1 <= 0;
            end

            // Row 2: Active during steps 2,3,4,5 (offset +2)
            if (step >= 2 && step <= 5) begin
              a_out2 <= mat_a[2][step-2];
              b_out2 <= mat_b[step-2][2];
            end else begin
              a_out2 <= 0;  
              b_out2 <= 0;
            end

            // Row 3: Active during steps 3,4,5,6 (offset +3)
            if (step >= 3 && step <= 6) begin
              a_out3 <= mat_a[3][step-3];
              b_out3 <= mat_b[step-3][3];
            end else begin
              a_out3 <= 0;
              b_out3 <= 0;
            end

            // Sequence completion: Done after step 6 is processed
            if (step == 7) begin
              feeding <= 0;
              done <= 1;
              valid <= 0;
            end else begin
              step <= step + 1;
            end

        end else begin
          delay_counter <= delay_counter + 1;
          valid <= 0;
        end
      end else if (done) begin
          valid <= 0;
          if (start) begin
              done <= 0; //clear done when starting new operation
          end
      end else begin
        // Idle state 
        valid <= 0;
      end
    end
  end
endmodule
