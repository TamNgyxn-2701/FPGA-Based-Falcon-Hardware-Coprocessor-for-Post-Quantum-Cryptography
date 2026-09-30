`timescale 1ns/1ps
/*
 * uniform_bits.v
 *
 * Collect random bytes and output uniform random bits.
 *
 * Example:
 *     bit_len = 9'd1    -> UniformBits(1)
 *     bit_len = 9'd8    -> UniformBits(8)
 *     bit_len = 9'd16   -> UniformBits(16)
 *     bit_len = 9'd72   -> UniformBits(72)
 *     bit_len = 9'd320  -> salt 320-bit
 */

module uniform_bits #(
    parameter MAX_BITS  = 320,
    parameter LEN_WIDTH = 9
)(
    clk,
    rst_n,
    start,
    bit_len,

    byte_req,
    byte_valid,
    byte_in,

    busy,
    out_valid,
    random_bits
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input                         clk;
input                         rst_n;
input                         start;
input      [LEN_WIDTH-1:0]    bit_len;

output reg                    byte_req;
input                         byte_valid;
input      [7:0]              byte_in;

output reg                    busy;
output reg                    out_valid;
output reg [MAX_BITS-1:0]     random_bits;

//---------------------------------------------------------------------
//   Localparam
//---------------------------------------------------------------------
localparam S_IDLE = 2'd0;
localparam S_REQ  = 2'd1;
localparam S_WAIT = 2'd2;

//---------------------------------------------------------------------
//   Reg
//---------------------------------------------------------------------
reg [1:0]             state;
reg [LEN_WIDTH-1:0]   bit_len_reg;
reg [LEN_WIDTH-1:0]   total_bytes;
reg [LEN_WIDTH-1:0]   byte_count;
reg [MAX_BITS-1:0]    bits_acc;

//---------------------------------------------------------------------
//   Function: insert one byte into accumulator
//---------------------------------------------------------------------
function [MAX_BITS-1:0] insert_byte;
    input [MAX_BITS-1:0]  base;
    input [7:0]           data;
    input [LEN_WIDTH-1:0] index;

    reg [MAX_BITS-1:0] data_ext;
    begin
        data_ext    = {{(MAX_BITS-8){1'b0}}, data};
        insert_byte = base | (data_ext << (index << 3));
    end
endfunction

//---------------------------------------------------------------------
//   Function: keep only bit_len lower bits
//---------------------------------------------------------------------
function [MAX_BITS-1:0] mask_to_len;
    input [MAX_BITS-1:0]  data;
    input [LEN_WIDTH-1:0] len;

    integer i;
    begin
        mask_to_len = {MAX_BITS{1'b0}};

        for (i = 0; i < MAX_BITS; i = i + 1) begin
            if (i < len)
                mask_to_len[i] = data[i];
        end
    end
endfunction

//---------------------------------------------------------------------
//   Sequential Logic
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state       <= S_IDLE;
        bit_len_reg <= {LEN_WIDTH{1'b0}};
        total_bytes <= {LEN_WIDTH{1'b0}};
        byte_count  <= {LEN_WIDTH{1'b0}};
        bits_acc    <= {MAX_BITS{1'b0}};
        random_bits <= {MAX_BITS{1'b0}};
        byte_req    <= 1'b0;
        busy        <= 1'b0;
        out_valid   <= 1'b0;
    end
    else begin
        byte_req  <= 1'b0;
        out_valid <= 1'b0;

        case (state)

            S_IDLE: begin
                busy <= 1'b0;

                if (start) begin
                    bits_acc    <= {MAX_BITS{1'b0}};
                    random_bits <= {MAX_BITS{1'b0}};
                    byte_count  <= {LEN_WIDTH{1'b0}};
                    bit_len_reg <= bit_len;

                    if (bit_len == 0) begin
                        random_bits <= {MAX_BITS{1'b0}};
                        out_valid   <= 1'b1;
                        busy        <= 1'b0;
                        state       <= S_IDLE;
                    end
                    else begin
                        total_bytes <= (bit_len + 7) >> 3;
                        busy        <= 1'b1;
                        state       <= S_REQ;
                    end
                end
            end

            S_REQ: begin
                busy     <= 1'b1;
                byte_req <= 1'b1;
                state    <= S_WAIT;
            end

            S_WAIT: begin
                busy <= 1'b1;

                if (byte_valid) begin
                    if ((byte_count + 1) >= total_bytes) begin
                        random_bits <= mask_to_len(
                            insert_byte(bits_acc, byte_in, byte_count),
                            bit_len_reg
                        );

                        out_valid <= 1'b1;
                        busy      <= 1'b0;
                        state     <= S_IDLE;
                    end
                    else begin
                        bits_acc   <= insert_byte(bits_acc, byte_in, byte_count);
                        byte_count <= byte_count + 1'b1;
                        state      <= S_REQ;
                    end
                end
            end

            default: begin
                state <= S_IDLE;
            end

        endcase
    end
end

endmodule
