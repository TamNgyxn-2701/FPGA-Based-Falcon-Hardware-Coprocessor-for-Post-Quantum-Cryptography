`timescale 1ns/1ps

/*
 * fxp_mul.v
 *
 * Signed fixed-point multiplier.
 *
 * Format:
 *   Q32.48 when DATA_WIDTH = 80, FRAC_WIDTH = 48
 *
 * Formula:
 *   z = (a * b) >>> FRAC_WIDTH
 */

module FXP_MUL #(
    parameter DATA_WIDTH = 80,
    parameter FRAC_WIDTH = 48
)(
    input  signed [DATA_WIDTH-1:0] a,
    input  signed [DATA_WIDTH-1:0] b,
    output signed [DATA_WIDTH-1:0] z
);

wire signed [(2*DATA_WIDTH)-1:0] product;
wire signed [(2*DATA_WIDTH)-1:0] shifted;

assign product = a * b;
assign shifted = product >>> FRAC_WIDTH;
assign z       = shifted[DATA_WIDTH-1:0];

endmodule
