/*
 * sign_bit.v
 *
 * Get sign bit and absolute value of a signed coefficient.
 *
 * Falcon encoding rule:
 *     sign = 1 if coeff < 0
 *     sign = 0 if coeff >= 0
 *
 * For zero, sign must be 0.
 */

`timescale 1ns/1ps
module sign_bit #(
    parameter COEFF_WIDTH = 16
)(
    coeff,
    sign,
    abs_value
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input  signed [COEFF_WIDTH-1:0] coeff;

output                         sign;
output [COEFF_WIDTH-1:0]        abs_value;

//---------------------------------------------------------------------
//   Wire
//---------------------------------------------------------------------
wire is_negative;
wire is_zero;

//---------------------------------------------------------------------
//   Combinational Logic
//---------------------------------------------------------------------
assign is_negative = coeff[COEFF_WIDTH-1];
assign is_zero     = (coeff == {COEFF_WIDTH{1'b0}});

assign sign = is_negative & (~is_zero);

assign abs_value = is_negative ? (~coeff + 1'b1) : coeff;

endmodule
