`timescale 1ns/1ps
`include "falcon512_params.v"

module gram_build_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output reg  busy,
    output reg  done,
    output reg  valid,

    output reg  [`ADDR_W-1:0] basis_raddr,
    output reg  [`ADDR_W-1:0] gram_addr,

    input  wire signed [`COEFF_W-1:0] b00_in,
    input  wire signed [`COEFF_W-1:0] b01_in,
    input  wire signed [`COEFF_W-1:0] b10_in,
    input  wire signed [`COEFF_W-1:0] b11_in,

    output reg  signed [`GRAM_W-1:0] gram00,
    output reg  signed [`GRAM_W-1:0] gram01,
    output reg  signed [`GRAM_W-1:0] gram10,
    output reg  signed [`GRAM_W-1:0] gram11
);

    localparam S_IDLE = 1'b0;
    localparam S_RUN  = 1'b1;

    reg state;
    reg [`ADDR_W-1:0] addr_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            addr_cnt    <= 0;
            basis_raddr <= 0;
            gram_addr   <= 0;
            busy        <= 0;
            done        <= 0;
            valid       <= 0;
            gram00      <= 0;
            gram01      <= 0;
            gram10      <= 0;
            gram11      <= 0;
        end else begin
            done <= 0;

            case (state)
                S_IDLE: begin
                    busy        <= 0;
                    valid       <= 0;
                    basis_raddr <= 0;

                    if (start) begin
                        state       <= S_RUN;
                        busy        <= 1;
                        addr_cnt    <= 0;
                        basis_raddr <= 0;
                    end
                end

                S_RUN: begin
                    busy      <= 1;
                    valid     <= 1;
                    gram_addr <= addr_cnt;

                    gram00 <= (b00_in * b00_in) + (b01_in * b01_in);
                    gram01 <= (b00_in * b10_in) + (b01_in * b11_in);
                    gram10 <= (b10_in * b00_in) + (b11_in * b01_in);
                    gram11 <= (b10_in * b10_in) + (b11_in * b11_in);

                    if (addr_cnt == (`FALCON_N - 1)) begin
                        state       <= S_IDLE;
                        busy        <= 0;
                        done        <= 1;
                        basis_raddr <= 0;
                    end else begin
                        addr_cnt    <= addr_cnt + 1'b1;
                        basis_raddr <= addr_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
