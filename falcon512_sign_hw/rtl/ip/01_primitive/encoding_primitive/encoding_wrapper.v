/*
 * encoding_wrapper.v
 *
 * Encode one signed Falcon coefficient and pack encoded bits into bytes.
 *
 * Encoding format for one coefficient:
 *
 *     sign | low7 | unary(high)
 *
 * where:
 *
 *     sign = 1 if coeff < 0, else 0
 *     abs_value = |coeff|
 *     low7 = abs_value[6:0]
 *     high = abs_value >> 7
 *
 * Unary encoding:
 *
 *     high = 0 -> 1
 *     high = 1 -> 01
 *     high = 2 -> 001
 *
 * Bit order:
 *     sign is emitted first.
 *     low7 is emitted from bit[6] down to bit[0].
 *     unary bits are emitted after low7.
 */

`timescale 1ns/1ps
module encoding_wrapper #(
    parameter COEFF_WIDTH = 16,
    parameter HIGH_WIDTH  = 9
)(
    clk,
    rst_n,

    start,
    coeff,
    last_coeff,

    clear,

    busy,
    coeff_done,

    byte_valid,
    byte_out
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input                         clk;
input                         rst_n;

input                         start;
input signed [COEFF_WIDTH-1:0] coeff;
input                         last_coeff;

input                         clear;

output reg                    busy;
output reg                    coeff_done;

output                        byte_valid;
output [7:0]                  byte_out;

//---------------------------------------------------------------------
//   State
//---------------------------------------------------------------------
localparam S_IDLE        = 3'd0;
localparam S_SEND_SIGN   = 3'd1;
localparam S_SEND_LOW7   = 3'd2;
localparam S_START_UNARY = 3'd3;
localparam S_SEND_UNARY  = 3'd4;
localparam S_FLUSH       = 3'd5;
localparam S_DONE        = 3'd6;

//---------------------------------------------------------------------
//   Reg
//---------------------------------------------------------------------
reg [2:0] state;

reg signed [COEFF_WIDTH-1:0] coeff_reg;
reg                          last_coeff_reg;

reg [2:0] low7_idx;

reg pack_bit_valid;
reg pack_bit;
reg pack_flush;

reg unary_start;

//---------------------------------------------------------------------
//   Wire
//---------------------------------------------------------------------
wire                         sign;
wire [COEFF_WIDTH-1:0]        abs_value;
wire [6:0]                    low7;
wire [HIGH_WIDTH-1:0]         high;

wire                          unary_busy;
wire                          unary_out_valid;
wire                          unary_out_bit;
wire                          unary_done;

wire [2:0]                    pack_bit_count;

//---------------------------------------------------------------------
//   Submodule: sign and absolute value
//---------------------------------------------------------------------
sign_bit #(
    .COEFF_WIDTH (COEFF_WIDTH)
) u_sign_bit (
    .coeff     (coeff_reg),
    .sign      (sign),
    .abs_value (abs_value)
);

//---------------------------------------------------------------------
//   Submodule: low7 and high split
//---------------------------------------------------------------------
low7_encoder #(
    .COEFF_WIDTH (COEFF_WIDTH),
    .HIGH_WIDTH  (HIGH_WIDTH)
) u_low7_encoder (
    .abs_value (abs_value),
    .low7      (low7),
    .high      (high)
);

//---------------------------------------------------------------------
//   Submodule: unary encoder
//---------------------------------------------------------------------
unary_encoder #(
    .HIGH_WIDTH (HIGH_WIDTH)
) u_unary_encoder (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (unary_start),
    .high      (high),

    .busy      (unary_busy),
    .out_valid (unary_out_valid),
    .out_bit   (unary_out_bit),
    .done      (unary_done)
);

//---------------------------------------------------------------------
//   Submodule: bit packer
//---------------------------------------------------------------------
bit_packer u_bit_packer (
    .clk        (clk),
    .rst_n      (rst_n),
    .clear      (clear),

    .bit_valid  (pack_bit_valid),
    .bit_in     (pack_bit),

    .flush      (pack_flush),

    .byte_valid (byte_valid),
    .byte_out   (byte_out),
    .bit_count  (pack_bit_count)
);

//---------------------------------------------------------------------
//   Sequential Logic
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state          <= S_IDLE;
        coeff_reg      <= {COEFF_WIDTH{1'b0}};
        last_coeff_reg <= 1'b0;
        low7_idx       <= 3'd0;

        busy           <= 1'b0;
        coeff_done     <= 1'b0;

        pack_bit_valid <= 1'b0;
        pack_bit       <= 1'b0;
        pack_flush     <= 1'b0;

        unary_start    <= 1'b0;
    end
    else begin
        coeff_done     <= 1'b0;
        pack_bit_valid <= 1'b0;
        pack_bit       <= 1'b0;
        pack_flush     <= 1'b0;
        unary_start    <= 1'b0;

        if (clear) begin
            state          <= S_IDLE;
            coeff_reg      <= {COEFF_WIDTH{1'b0}};
            last_coeff_reg <= 1'b0;
            low7_idx       <= 3'd0;

            busy           <= 1'b0;
            coeff_done     <= 1'b0;
        end
        else begin
            case (state)

                S_IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        coeff_reg      <= coeff;
                        last_coeff_reg <= last_coeff;
                        low7_idx       <= 3'd0;
                        busy           <= 1'b1;
                        state          <= S_SEND_SIGN;
                    end
                end

                S_SEND_SIGN: begin
                    busy           <= 1'b1;
                    pack_bit_valid <= 1'b1;
                    pack_bit       <= sign;
                    state          <= S_SEND_LOW7;
                end

                S_SEND_LOW7: begin
                    busy           <= 1'b1;
                    pack_bit_valid <= 1'b1;

                    case (low7_idx)
                        3'd0: pack_bit <= low7[6];
                        3'd1: pack_bit <= low7[5];
                        3'd2: pack_bit <= low7[4];
                        3'd3: pack_bit <= low7[3];
                        3'd4: pack_bit <= low7[2];
                        3'd5: pack_bit <= low7[1];
                        3'd6: pack_bit <= low7[0];
                        default: pack_bit <= 1'b0;
                    endcase

                    if (low7_idx == 3'd6) begin
                        low7_idx <= 3'd0;
                        state    <= S_START_UNARY;
                    end
                    else begin
                        low7_idx <= low7_idx + 1'b1;
                    end
                end

                S_START_UNARY: begin
                    busy        <= 1'b1;
                    unary_start <= 1'b1;
                    state       <= S_SEND_UNARY;
                end

                S_SEND_UNARY: begin
                    busy <= 1'b1;

                    if (unary_out_valid) begin
                        pack_bit_valid <= 1'b1;
                        pack_bit       <= unary_out_bit;
                    end

                    if (unary_done) begin
                        if (last_coeff_reg) begin
                            state <= S_FLUSH;
                        end
                        else begin
                            state <= S_DONE;
                        end
                    end
                end

                S_FLUSH: begin
                    busy       <= 1'b1;
                    pack_flush <= 1'b1;
                    state      <= S_DONE;
                end

                S_DONE: begin
                    busy       <= 1'b0;
                    coeff_done <= 1'b1;
                    state      <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end
end

endmodule
