/*
 * int_add.v
 * Integer adder
 */

`timescale 1ns/1ps

module int_add #(
    parameter WIDTH = 32
)(
    input  signed [WIDTH-1:0] a,
    input  signed [WIDTH-1:0] b,
    output signed [WIDTH:0]   sum
);

assign sum = {a[WIDTH-1], a} + {b[WIDTH-1], b};

endmodule
