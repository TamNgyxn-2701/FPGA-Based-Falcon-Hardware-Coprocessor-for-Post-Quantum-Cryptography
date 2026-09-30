`timescale 1ns/1ps
/*
 * rng_wrapper.v
 *
 * Wrapper for RNG primitive.
 *
 * This wrapper connects:
 *     random_byte  -> generate 8-bit random data
 *     uniform_bits -> collect random bytes into k-bit random value
 *
 * Supported examples:
 *     bit_len = 1    : UniformBits(1)
 *     bit_len = 8    : UniformBits(8)
 *     bit_len = 16   : UniformBits(16)
 *     bit_len = 72   : BaseSampler
 *     bit_len = 320  : Falcon salt
 */

module rng_wrapper #(
    parameter MAX_BITS  = 320,
    parameter LEN_WIDTH = 9
)(
    clk,
    rst_n,

    req,
    bit_len,

    seed_en,
    seed,

    busy,
    out_valid,
    random_out
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input                         clk;
input                         rst_n;

input                         req;
input      [LEN_WIDTH-1:0]    bit_len;

input                         seed_en;
input      [31:0]             seed;

output                        busy;
output                        out_valid;
output     [MAX_BITS-1:0]     random_out;

//---------------------------------------------------------------------
//   Wire
//---------------------------------------------------------------------
wire       byte_req;
wire       byte_valid;
wire [7:0] byte_data;

//---------------------------------------------------------------------
//   Submodule: random byte generator
//---------------------------------------------------------------------
random_byte u_random_byte (
    .clk         (clk),
    .rst_n       (rst_n),
    .req         (byte_req),
    .seed_en     (seed_en),
    .seed        (seed),
    .out_valid   (byte_valid),
    .random_byte (byte_data)
);

//---------------------------------------------------------------------
//   Submodule: uniform bits collector
//---------------------------------------------------------------------
uniform_bits #(
    .MAX_BITS  (MAX_BITS),
    .LEN_WIDTH (LEN_WIDTH)
) u_uniform_bits (
    .clk         (clk),
    .rst_n       (rst_n),
    .start       (req),
    .bit_len     (bit_len),

    .byte_req    (byte_req),
    .byte_valid  (byte_valid),
    .byte_in     (byte_data),

    .busy        (busy),
    .out_valid   (out_valid),
    .random_bits (random_out)
);

endmodule
