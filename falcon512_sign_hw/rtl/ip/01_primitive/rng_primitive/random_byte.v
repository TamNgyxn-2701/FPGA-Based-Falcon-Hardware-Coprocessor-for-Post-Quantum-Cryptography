`timescale 1ns/1ps
/*
 * random_byte.v
 *
 * Simple pseudo-random byte generator using 32-bit LFSR.
 *
 * Note:
 * This module is suitable for simulation / control-flow testing.
 * For real cryptographic Falcon hardware, replace this block with
 * a TRNG / CSPRNG / SHAKE-based DRBG.
 */

module random_byte #(
    parameter DEFAULT_SEED = 32'h1ACE_B00C
)(
    clk,
    rst_n,
    req,
    seed_en,
    seed,
    out_valid,
    random_byte
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input        clk;
input        rst_n;
input        req;
input        seed_en;
input [31:0] seed;

output reg       out_valid;
output reg [7:0] random_byte;

//---------------------------------------------------------------------
//   Reg & Wire
//---------------------------------------------------------------------
reg  [31:0] lfsr;
wire [31:0] next_lfsr;

//---------------------------------------------------------------------
//   Function: advance LFSR by 8 steps
//---------------------------------------------------------------------
function [31:0] lfsr_next8;
    input [31:0] cur;

    reg [31:0] tmp;
    reg        feedback;
    integer    i;

    begin
        tmp = cur;

        for (i = 0; i < 8; i = i + 1) begin
            feedback = tmp[31] ^ tmp[21] ^ tmp[1] ^ tmp[0];
            tmp      = {tmp[30:0], feedback};
        end

        lfsr_next8 = tmp;
    end
endfunction

assign next_lfsr = lfsr_next8(lfsr);

//---------------------------------------------------------------------
//   Sequential Logic
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lfsr        <= DEFAULT_SEED;
        random_byte <= 8'd0;
        out_valid   <= 1'b0;
    end
    else begin
        out_valid <= 1'b0;

        if (seed_en) begin
            if (seed == 32'd0)
                lfsr <= DEFAULT_SEED;
            else
                lfsr <= seed;

            random_byte <= 8'd0;
            out_valid   <= 1'b0;
        end
        else if (req) begin
            lfsr        <= next_lfsr;
            random_byte <= next_lfsr[7:0];
            out_valid   <= 1'b1;
        end
    end
end

endmodule
