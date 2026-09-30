`timescale 1ns/1ps
/*
 * reduce_mod_q.v
 *
 * Reduce 16-bit input to modulo q = 12289.
 *
 * d = a mod q
 *
 * This version is optimized for 16-bit input.
 * Since a <= 65535 and q = 12289:
 *
 *     5*q = 61445
 *     6*q = 73734 > 65535
 *
 * Therefore, subtracting 5q, 4q, 3q, 2q, or q is enough.
 */

module reduce_mod_q (
    a,
    d
);

//---------------------------------------------------------------------
//   Parameter
//---------------------------------------------------------------------
localparam IN_WIDTH = 16;
localparam Q_WIDTH  = 14;

localparam Q  = 16'd12289;
localparam Q2 = 16'd24578;
localparam Q3 = 16'd36867;
localparam Q4 = 16'd49156;
localparam Q5 = 16'd61445;

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input  [IN_WIDTH-1:0] a;
output [Q_WIDTH-1:0]  d;

//---------------------------------------------------------------------
//   Reg
//---------------------------------------------------------------------
reg [IN_WIDTH-1:0] d_reg;

//---------------------------------------------------------------------
//   Combinational Logic
//---------------------------------------------------------------------
always @(*) begin
    if (a >= Q5)
        d_reg = a - Q5;
    else if (a >= Q4)
        d_reg = a - Q4;
    else if (a >= Q3)
        d_reg = a - Q3;
    else if (a >= Q2)
        d_reg = a - Q2;
    else if (a >= Q)
        d_reg = a - Q;
    else
        d_reg = a;
end

assign d = d_reg[Q_WIDTH-1:0];

endmodule
