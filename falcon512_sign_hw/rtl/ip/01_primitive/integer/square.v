/*
 * square.v
 * Square of signed integer
 */

`timescale 1ns/1ps

module square #(
    parameter WIDTH = 32
)(
    input  signed [WIDTH-1:0] a,
    output        [2*WIDTH-1:0] square_out
);

assign square_out = a * a;

endmodule
