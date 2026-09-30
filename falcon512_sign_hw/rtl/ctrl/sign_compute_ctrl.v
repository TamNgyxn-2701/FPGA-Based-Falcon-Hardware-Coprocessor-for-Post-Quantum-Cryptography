`timescale 1ns/1ps
`include "falcon512_params.v"

module sign_compute_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output reg  busy,
    output reg  done,
    output reg  valid,

    output reg  [`ADDR_W-1:0] basis_raddr,
    output reg  [`ADDR_W-1:0] target_raddr,
    output reg  [`ADDR_W-1:0] sample_raddr,
    output reg  [`ADDR_W-1:0] sign_addr,

    input  wire signed [`COEFF_W-1:0] b00_in,
    input  wire signed [`COEFF_W-1:0] b01_in,
    input  wire signed [`COEFF_W-1:0] b10_in,
    input  wire signed [`COEFF_W-1:0] b11_in,

    input  wire signed [`TARGET_W-1:0] target_t0_in,
    input  wire signed [`TARGET_W-1:0] target_t1_in,

    input  wire signed [`SAMPLE_W-1:0] sample_z0_in,
    input  wire signed [`SAMPLE_W-1:0] sample_z1_in,

    output reg  signed [`SIGN_W-1:0] sig_s0,
    output reg  signed [`SIGN_W-1:0] sig_s1
);

    localparam S_IDLE = 1'b0;
    localparam S_RUN  = 1'b1;

    reg state;
    reg [`ADDR_W-1:0] addr_cnt;

    wire signed [`TARGET_W-1:0] delta0;
    wire signed [`TARGET_W-1:0] delta1;

    wire signed [`SIGN_W-1:0] delta0_ext;
    wire signed [`SIGN_W-1:0] delta1_ext;

    wire signed [`SIGN_W-1:0] b00_ext;
    wire signed [`SIGN_W-1:0] b01_ext;
    wire signed [`SIGN_W-1:0] b10_ext;
    wire signed [`SIGN_W-1:0] b11_ext;

    assign delta0 = target_t0_in - sample_z0_in;
    assign delta1 = target_t1_in - sample_z1_in;

    assign delta0_ext = {{(`SIGN_W-`TARGET_W){delta0[`TARGET_W-1]}}, delta0};
    assign delta1_ext = {{(`SIGN_W-`TARGET_W){delta1[`TARGET_W-1]}}, delta1};

    assign b00_ext = {{(`SIGN_W-`COEFF_W){b00_in[`COEFF_W-1]}}, b00_in};
    assign b01_ext = {{(`SIGN_W-`COEFF_W){b01_in[`COEFF_W-1]}}, b01_in};
    assign b10_ext = {{(`SIGN_W-`COEFF_W){b10_in[`COEFF_W-1]}}, b10_in};
    assign b11_ext = {{(`SIGN_W-`COEFF_W){b11_in[`COEFF_W-1]}}, b11_in};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            addr_cnt     <= 0;

            basis_raddr  <= 0;
            target_raddr <= 0;
            sample_raddr <= 0;
            sign_addr    <= 0;

            busy         <= 0;
            done         <= 0;
            valid        <= 0;

            sig_s0       <= 0;
            sig_s1       <= 0;
        end else begin
            done <= 0;

            case (state)
                S_IDLE: begin
                    busy         <= 0;
                    valid        <= 0;
                    basis_raddr  <= 0;
                    target_raddr <= 0;
                    sample_raddr <= 0;

                    if (start) begin
                        state        <= S_RUN;
                        busy         <= 1;
                        addr_cnt     <= 0;
                        basis_raddr  <= 0;
                        target_raddr <= 0;
                        sample_raddr <= 0;
                    end
                end

                S_RUN: begin
                    busy      <= 1;
                    valid     <= 1;
                    sign_addr <= addr_cnt;

                    /*
                        Version 5 skeleton:

                        delta = target - sample

                        sig_s0 = delta0*b00 + delta1*b10
                        sig_s1 = delta0*b01 + delta1*b11

                        Đây là coefficient-domain skeleton,
                        chưa phải chữ ký Falcon đầy đủ.
                    */

                    sig_s0 <= (delta0_ext * b00_ext) + (delta1_ext * b10_ext);
                    sig_s1 <= (delta0_ext * b01_ext) + (delta1_ext * b11_ext);

                    if (addr_cnt == (`FALCON_N - 1)) begin
                        state        <= S_IDLE;
                        busy         <= 0;
                        done         <= 1;

                        basis_raddr  <= 0;
                        target_raddr <= 0;
                        sample_raddr <= 0;
                    end else begin
                        addr_cnt     <= addr_cnt + 1'b1;

                        basis_raddr  <= addr_cnt + 1'b1;
                        target_raddr <= addr_cnt + 1'b1;
                        sample_raddr <= addr_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
