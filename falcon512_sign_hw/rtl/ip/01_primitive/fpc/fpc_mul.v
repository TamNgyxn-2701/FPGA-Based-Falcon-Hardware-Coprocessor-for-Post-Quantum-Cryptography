`timescale 1ns/1ps

/*
 * fpc_mul.v
 *
 * Fixed-point complex multiplication.
 *
 * a = a_re + j*a_im
 * b = b_re + j*b_im
 *
 * d = a * b
 *
 * d_re = a_re*b_re - a_im*b_im
 * d_im = a_re*b_im + a_im*b_re
 *
 * This module has 1 pipeline stage.
 */

module FPC_MUL #(
    parameter FLOAT_PRECISION = 80,
    parameter FRAC_WIDTH      = 48
)(
    input                                 clk,
    input                                 rst_n,
    input                                 in_valid,

    input  signed [FLOAT_PRECISION-1:0]  a_re,
    input  signed [FLOAT_PRECISION-1:0]  a_im,
    input  signed [FLOAT_PRECISION-1:0]  b_re,
    input  signed [FLOAT_PRECISION-1:0]  b_im,

    output reg                           mult_valid,
    output signed [FLOAT_PRECISION-1:0]  d_re,
    output signed [FLOAT_PRECISION-1:0]  d_im
);

wire signed [FLOAT_PRECISION-1:0] a_re_x_b_re;
wire signed [FLOAT_PRECISION-1:0] a_im_x_b_im;
wire signed [FLOAT_PRECISION-1:0] a_re_x_b_im;
wire signed [FLOAT_PRECISION-1:0] a_im_x_b_re;

reg signed [FLOAT_PRECISION-1:0] a_re_x_b_re_reg;
reg signed [FLOAT_PRECISION-1:0] a_im_x_b_im_reg;
reg signed [FLOAT_PRECISION-1:0] a_re_x_b_im_reg;
reg signed [FLOAT_PRECISION-1:0] a_im_x_b_re_reg;

//------------------------------------------------------------
// Fixed-point multipliers
//------------------------------------------------------------
FXP_MUL #(
    .DATA_WIDTH(FLOAT_PRECISION),
    .FRAC_WIDTH(FRAC_WIDTH)
) u_mul_re_re (
    .a (a_re),
    .b (b_re),
    .z (a_re_x_b_re)
);

FXP_MUL #(
    .DATA_WIDTH(FLOAT_PRECISION),
    .FRAC_WIDTH(FRAC_WIDTH)
) u_mul_im_im (
    .a (a_im),
    .b (b_im),
    .z (a_im_x_b_im)
);

FXP_MUL #(
    .DATA_WIDTH(FLOAT_PRECISION),
    .FRAC_WIDTH(FRAC_WIDTH)
) u_mul_re_im (
    .a (a_re),
    .b (b_im),
    .z (a_re_x_b_im)
);

FXP_MUL #(
    .DATA_WIDTH(FLOAT_PRECISION),
    .FRAC_WIDTH(FRAC_WIDTH)
) u_mul_im_re (
    .a (a_im),
    .b (b_re),
    .z (a_im_x_b_re)
);

//------------------------------------------------------------
// Complex multiply output
//------------------------------------------------------------
assign d_re = a_re_x_b_re_reg - a_im_x_b_im_reg;
assign d_im = a_re_x_b_im_reg + a_im_x_b_re_reg;

//------------------------------------------------------------
// Pipeline register
//------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mult_valid       <= 1'b0;
        a_re_x_b_re_reg  <= {FLOAT_PRECISION{1'b0}};
        a_im_x_b_im_reg  <= {FLOAT_PRECISION{1'b0}};
        a_re_x_b_im_reg  <= {FLOAT_PRECISION{1'b0}};
        a_im_x_b_re_reg  <= {FLOAT_PRECISION{1'b0}};
    end
    else begin
        mult_valid       <= in_valid;
        a_re_x_b_re_reg  <= a_re_x_b_re;
        a_im_x_b_im_reg  <= a_im_x_b_im;
        a_re_x_b_im_reg  <= a_re_x_b_im;
        a_im_x_b_re_reg  <= a_im_x_b_re;
    end
end

endmodule
