`timescale 1ns/1ps
`include "falcon512_params.v"

module basis_build_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output reg  busy,
    output reg  done,
    output reg  valid,

    output reg  [`ADDR_W-1:0] key_addr,

    input  wire signed [`COEFF_W-1:0] f_in,
    input  wire signed [`COEFF_W-1:0] g_in,
    input  wire signed [`COEFF_W-1:0] F_in,
    input  wire signed [`COEFF_W-1:0] G_in,

    output reg  [`ADDR_W-1:0] basis_addr,
    output reg  signed [`COEFF_W-1:0] b00,
    output reg  signed [`COEFF_W-1:0] b01,
    output reg  signed [`COEFF_W-1:0] b10,
    output reg  signed [`COEFF_W-1:0] b11
);

    localparam S_IDLE = 1'b0;
    localparam S_RUN  = 1'b1;

    reg state;
    reg [`ADDR_W-1:0] addr_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            addr_cnt   <= 0;
            key_addr   <= 0;
            basis_addr <= 0;
            busy       <= 0;
            done       <= 0;
            valid      <= 0;
            b00        <= 0;
            b01        <= 0;
            b10        <= 0;
            b11        <= 0;
        end else begin
            done <= 0;

            case (state)
                S_IDLE: begin
                    busy  <= 0;
                    valid <= 0;
                    key_addr <= 0;

                    if (start) begin
                        state    <= S_RUN;
                        busy     <= 1;
                        addr_cnt <= 0;
                        key_addr <= 0;
                    end
                end

                S_RUN: begin
                    busy       <= 1;
                    valid      <= 1;
                    basis_addr <= addr_cnt;

                    b00 <= g_in;
                    b01 <= -f_in;
                    b10 <= G_in;
                    b11 <= -F_in;

                    if (addr_cnt == (`FALCON_N - 1)) begin
                        state    <= S_IDLE;
                        busy     <= 0;
                        done     <= 1;
                        key_addr <= 0;
                    end else begin
                        addr_cnt <= addr_cnt + 1'b1;
                        key_addr <= addr_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
