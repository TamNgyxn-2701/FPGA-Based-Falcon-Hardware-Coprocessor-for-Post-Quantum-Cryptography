/*
 * bit_packer.v
 *
 * Pack input bits into output bytes.
 *
 * Bit order:
 *     The first input bit is stored at byte_out[7].
 *     The next input bit is stored at byte_out[6].
 *     ...
 *     The eighth input bit is stored at byte_out[0].
 *
 * If flush = 1 and current byte is not full, remaining bits are padded
 * with zero and byte_out is emitted.
 */

`timescale 1ns/1ps
module bit_packer (
    clk,
    rst_n,
    clear,

    bit_valid,
    bit_in,

    flush,

    byte_valid,
    byte_out,
    bit_count
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input        clk;
input        rst_n;
input        clear;

input        bit_valid;
input        bit_in;

input        flush;

output reg       byte_valid;
output reg [7:0] byte_out;
output reg [2:0] bit_count;

//---------------------------------------------------------------------
//   Reg
//---------------------------------------------------------------------
reg [7:0] byte_buf;

//---------------------------------------------------------------------
//   Sequential Logic
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        byte_buf   <= 8'd0;
        byte_out   <= 8'd0;
        byte_valid <= 1'b0;
        bit_count  <= 3'd0;
    end
    else begin
        byte_valid <= 1'b0;

        if (clear) begin
            byte_buf   <= 8'd0;
            byte_out   <= 8'd0;
            byte_valid <= 1'b0;
            bit_count  <= 3'd0;
        end
        else if (bit_valid) begin
            byte_buf[3'd7 - bit_count] <= bit_in;

            if (bit_count == 3'd7) begin
                byte_out               <= byte_buf;
                byte_out[0]            <= bit_in;
                byte_valid             <= 1'b1;
                byte_buf               <= 8'd0;
                bit_count              <= 3'd0;
            end
            else begin
                bit_count <= bit_count + 1'b1;
            end
        end
        else if (flush) begin
            if (bit_count != 3'd0) begin
                byte_out   <= byte_buf;
                byte_valid <= 1'b1;
                byte_buf   <= 8'd0;
                bit_count  <= 3'd0;
            end
        end
    end
end

endmodule
