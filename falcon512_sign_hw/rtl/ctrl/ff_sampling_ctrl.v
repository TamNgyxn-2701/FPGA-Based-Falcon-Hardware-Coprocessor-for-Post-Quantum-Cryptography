`timescale 1ns/1ps
`include "falcon512_params.v"

module ff_sampling_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output reg  busy,
    output reg  done,
    output reg  valid,

    output reg  [`ADDR_W-1:0] target_raddr,
    output reg  [`ADDR_W-1:0] sample_addr,

    input  wire signed [`TARGET_W-1:0] target_t0_in,
    input  wire signed [`TARGET_W-1:0] target_t1_in,

    output reg  signed [`SAMPLE_W-1:0] sample_z0,
    output reg  signed [`SAMPLE_W-1:0] sample_z1
);

    localparam S_IDLE = 1'b0;
    localparam S_RUN  = 1'b1;

    reg state;
    reg [`ADDR_W-1:0] addr_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            addr_cnt     <= 0;
            target_raddr <= 0;
            sample_addr  <= 0;
            busy         <= 0;
            done         <= 0;
            valid        <= 0;
            sample_z0    <= 0;
            sample_z1    <= 0;
        end else begin
            done <= 0;

            case (state)
                S_IDLE: begin
                    busy         <= 0;
                    valid        <= 0;
                    target_raddr <= 0;

                    if (start) begin
                        state        <= S_RUN;
                        busy         <= 1;
                        addr_cnt     <= 0;
                        target_raddr <= 0;
                    end
                end

                S_RUN: begin
                    busy        <= 1;
                    valid       <= 1;
                    sample_addr <= addr_cnt;

                    /*
                        Version 4 skeleton ffSampling:

                        Falcon thật:
                            z = ffSampling(t, Gram)

                        Ở bản skeleton:
                            z0, z1 được tạo gần target_t0, target_t1
                            cộng thêm nhiễu nhỏ giả lập theo địa chỉ.

                        Mục tiêu:
                            kiểm tra controller + dataflow target -> sample.
                    */

                    case (addr_cnt[1:0])
                        2'd0: begin
                            sample_z0 <= target_t0_in - 1;
                            sample_z1 <= target_t1_in + 1;
                        end

                        2'd1: begin
                            sample_z0 <= target_t0_in;
                            sample_z1 <= target_t1_in - 1;
                        end

                        2'd2: begin
                            sample_z0 <= target_t0_in + 1;
                            sample_z1 <= target_t1_in;
                        end

                        default: begin
                            sample_z0 <= target_t0_in;
                            sample_z1 <= target_t1_in + 1;
                        end
                    endcase

                    if (addr_cnt == (`FALCON_N - 1)) begin
                        state        <= S_IDLE;
                        busy         <= 0;
                        done         <= 1;
                        target_raddr <= 0;
                    end else begin
                        addr_cnt     <= addr_cnt + 1'b1;
                        target_raddr <= addr_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
