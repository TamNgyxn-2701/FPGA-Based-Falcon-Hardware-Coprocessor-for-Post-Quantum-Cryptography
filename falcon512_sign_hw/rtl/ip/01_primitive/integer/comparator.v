/*
 * comparator.v
 * Unsigned comparator
 */

`timescale 1ns/1ps

module comparator #(
    parameter WIDTH = 64
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output             lt,
    output             le,
    output             eq,
    output             ge,
    output             gt
);

assign lt = (a <  b);
assign le = (a <= b);
assign eq = (a == b);
assign ge = (a >= b);
assign gt = (a >  b);

endmodule
