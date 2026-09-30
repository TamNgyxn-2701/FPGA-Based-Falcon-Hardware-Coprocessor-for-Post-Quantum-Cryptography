`timescale 1ns/1ps
/*
 * mq_montymul_wrapper.v
 *
 * Wrapper for Montgomery multiplication modulo q = 12289.
 *
 * This wrapper calls montymul_core.
 *
 * Function:
 *     d = a * b * R^(-1) mod q
 *
 * with:
 *     q = 12289
 *     R = 2^16
 */

module mq_montymul_wrapper (
    clk,
    rst_n,
    in_valid,
    a,
    b,
    out_valid,
    d
);

//---------------------------------------------------------------------
//   Parameter
//---------------------------------------------------------------------
localparam Q_WIDTH = 14;

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input                  clk;
input                  rst_n;
input                  in_valid;
input  [Q_WIDTH-1:0]   a;
input  [Q_WIDTH-1:0]   b;

output                 out_valid;
output [Q_WIDTH-1:0]   d;

//---------------------------------------------------------------------
//   Submodule
//---------------------------------------------------------------------
montymul_core u_montymul_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (in_valid),
    .x         (a),
    .y         (b),
    .out_valid (out_valid),
    .z         (d)
);

endmodule
