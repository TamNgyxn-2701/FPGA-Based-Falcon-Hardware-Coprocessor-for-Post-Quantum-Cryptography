`timescale 1ns/1ps
`include "falcon512_params.v"

module norm_check_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output reg  busy,
    output reg  done,
    output reg  valid,

    output reg  [`ADDR_W-1:0] sign_raddr,
    output reg  [`ADDR_W-1:0] norm_addr,

    input  wire signed [`SIGN_W-1:0] sig_s0_in,
    input  wire signed [`SIGN_W-1:0] sig_s1_in,

    output reg  [`NORM_W-1:0] norm_value,
    output reg  norm_ok
);

    localparam S_IDLE = 1'b0;
    localparam S_RUN  = 1'b1;

    reg state;
    reg [`ADDR_W-1:0] addr_cnt;

    reg [`NORM_W-1:0] norm_sum;

    wire [`SIGN_W-1:0] abs_s0;
    wire [`SIGN_W-1:0] abs_s1;

    wire [(2*`SIGN_W)-1:0] square_s0;
    wire [(2*`SIGN_W)-1:0] square_s1;

    wire [`NORM_W-1:0] square_s0_ext;
    wire [`NORM_W-1:0] square_s1_ext;

    wire [`NORM_W-1:0] norm_next;

    assign abs_s0 = sig_s0_in[`SIGN_W-1] ? (~sig_s0_in + 1'b1) : sig_s0_in;
    assign abs_s1 = sig_s1_in[`SIGN_W-1] ? (~sig_s1_in + 1'b1) : sig_s1_in;

    assign square_s0 = abs_s0 * abs_s0;
    assign square_s1 = abs_s1 * abs_s1;

    assign square_s0_ext = square_s0;
    assign square_s1_ext = square_s1;

    assign norm_next = norm_sum + square_s0_ext + square_s1_ext;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            addr_cnt   <= 0;
            sign_raddr <= 0;
            norm_addr  <= 0;

            busy       <= 0;
            done       <= 0;
            valid      <= 0;

            norm_sum   <= 0;
            norm_value <= 0;
            norm_ok    <= 0;
        end else begin
            done <= 0;

            case (state)
                S_IDLE: begin
                    busy       <= 0;
                    valid      <= 0;
                    sign_raddr <= 0;
                    norm_addr  <= 0;

                    if (start) begin
                        state      <= S_RUN;
                        busy       <= 1;
                        addr_cnt   <= 0;
                        sign_raddr <= 0;
			norm_sum   <= 0;
			norm_value <= 0;
			norm_ok    <= 0;
                    end
                end

                S_RUN: begin
                    busy       <= 1;
                    valid      <= 1;
                    norm_addr  <= addr_cnt;

                    norm_sum   <= norm_next;
                    norm_value <= norm_next;

                    if (addr_cnt == (`FALCON_N - 1)) begin
                        state      <= S_IDLE;
                        busy       <= 0;
                        done       <= 1;
                        sign_raddr <= 0;

                        if (norm_next <= `FALCON_BETA2) begin
                            norm_ok <= 1'b1;
                        end else begin
                            norm_ok <= 1'b0;
                        end
                    end else begin
                        addr_cnt   <= addr_cnt + 1'b1;
                        sign_raddr <= addr_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
