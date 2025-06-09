`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maverick
//
// Create Date: 2025-05-31 12:04:43
// Design Name:  Alpha0.0
// Module Name:  block
// Project Name: Acc_Array
// Target Devices:
// Tool Versions:
// Description: PE (Processing Element)
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module block(inp_north, inp_west, clk, rst, outp_south, outp_east, result);
    input [31:0] inp_north, inp_west;
    input clk, rst;
    output reg [31:0] outp_south, outp_east;
    output reg [63:0] result;
    
    wire [63:0] multi;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            result <= 64'b0;
            outp_east <= 32'b0;
            outp_south <= 32'b0;
        end
        else begin
            result <= result + multi;
            outp_east <= inp_west;
            outp_south <= inp_north;
        end
    end
    
    assign multi = inp_north * inp_west;
    
endmodule
