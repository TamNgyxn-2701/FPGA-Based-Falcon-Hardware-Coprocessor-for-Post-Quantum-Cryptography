`timescale 1ns/1ps
`include "falcon512_params.v"

module target_build_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output reg  busy,
    output reg  done,
    output reg  valid,

    output reg  [`ADDR_W-1:0] basis_raddr,
    output reg  [`ADDR_W-1:0] hm_raddr,
    output reg  [`ADDR_W-1:0] target_addr,

    input  wire signed [`COEFF_W-1:0] b01_in,
    input  wire signed [`COEFF_W-1:0] b11_in,
    input  wire signed [`HM_W-1:0]    hm_in,

    output reg  signed [`TARGET_W-1:0] target_t0,
    output reg  signed [`TARGET_W-1:0] target_t1
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
            hm_raddr    <= 0;
            target_addr <= 0;
            busy        <= 0;
            done        <= 0;
            valid       <= 0;
            target_t0   <= 0;
            target_t1   <= 0;
        end else begin
            done <= 0;

            case (state)
                S_IDLE: begin
                    busy        <= 0;
                    valid       <= 0;
                    basis_raddr <= 0;
                    hm_raddr    <= 0;

                    if (start) begin
                        state       <= S_RUN;
                        busy        <= 1;
                        addr_cnt    <= 0;
                        basis_raddr <= 0;
                        hm_raddr    <= 0;
                    end
                end

                S_RUN: begin
                    busy        <= 1;
                    valid       <= 1;
                    target_addr <= addr_cnt;

                    /*
                        Version 3 skeleton:

                        b01 = -f  => f = -b01
                        b11 = -F  => F = -b11

                        Falcon target:
                        t0 = -hm * F / q
                        t1 =  hm * f / q

                        Substitute:
                        t0 = hm * b11 / q
                        t1 = -hm * b01 / q
                    */

                    target_t0 <= (hm_in * b11_in) / `FALCON_Q;
                    target_t1 <= -(hm_in * b01_in) / `FALCON_Q;

                    if (addr_cnt == (`FALCON_N - 1)) begin
                        state       <= S_IDLE;
                        busy        <= 0;
                        done        <= 1;
                        basis_raddr <= 0;
                        hm_raddr    <= 0;
                    end else begin
                        addr_cnt    <= addr_cnt + 1'b1;
                        basis_raddr <= addr_cnt + 1'b1;
                        hm_raddr    <= addr_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
