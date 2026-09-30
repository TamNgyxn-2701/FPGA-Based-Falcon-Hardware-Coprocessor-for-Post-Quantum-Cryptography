`timescale 1ns/1ps

/*
 * fpc_sub.v
 *
 * Fixed-point complex subtraction.
 *
 * d = a - b
 *
 * d_re = a_re - b_re
 * d_im = a_im - b_im
 */

module FPC_SUB #(
    parameter FLOAT_PRECISION = 80,
    parameter FRAC_WIDTH      = 48
)(
    input  signed [FLOAT_PRECISION-1:0] a_re,
    input  signed [FLOAT_PRECISION-1:0] a_im,
    input  signed [FLOAT_PRECISION-1:0] b_re,
    input  signed [FLOAT_PRECISION-1:0] b_im,

    output signed [FLOAT_PRECISION-1:0] d_re,
    output signed [FLOAT_PRECISION-1:0] d_im
);

assign d_re = a_re - b_re;
assign d_im = a_im - b_im;

endmodule
