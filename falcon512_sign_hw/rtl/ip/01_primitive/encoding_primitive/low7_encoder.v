/*
 * low7_encoder.v
 *
 * Split absolute coefficient value into:
 *
 *     low7 = abs_value mod 128
 *     high = abs_value >> 7
 *
 * In Falcon compression:
 *     low7 is encoded with 7 bits
 *     high is encoded with unary code
 */

`timescale 1ns/1ps
module low7_encoder #(
    parameter COEFF_WIDTH = 16,
    parameter HIGH_WIDTH  = 9
)(
    abs_value,
    low7,
    high
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input  [COEFF_WIDTH-1:0] abs_value;

output [6:0]             low7;
output [HIGH_WIDTH-1:0]  high;

//---------------------------------------------------------------------
//   Combinational Logic
//---------------------------------------------------------------------
assign low7 = abs_value[6:0];
assign high = abs_value[COEFF_WIDTH-1:7];

endmodule
