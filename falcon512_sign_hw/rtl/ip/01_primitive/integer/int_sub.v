/*
 * int_sub.v
 * Integer subtractor
 */

`timescale 1ns/1ps

module int_sub #(
    parameter WIDTH = 32
)(
    input  signed [WIDTH-1:0] a,
    input  signed [WIDTH-1:0] b,
    output signed [WIDTH:0]   diff
);

assign diff = {a[WIDTH-1], a} - {b[WIDTH-1], b};

endmodule
