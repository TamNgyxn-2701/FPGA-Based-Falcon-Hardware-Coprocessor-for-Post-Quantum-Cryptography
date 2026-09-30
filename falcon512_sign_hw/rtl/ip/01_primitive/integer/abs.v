/*
 * abs.v
 * Absolute value for signed integer
 */

`timescale 1ns/1ps

module abs #(
    parameter WIDTH = 32
)(
    input  signed [WIDTH-1:0] a,
    output        [WIDTH-1:0] abs_out
);

assign abs_out = (a[WIDTH-1]) ? (~a + 1'b1) : a;

endmodule
