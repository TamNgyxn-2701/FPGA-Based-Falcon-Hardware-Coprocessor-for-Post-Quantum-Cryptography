`timescale 1ns/1ps
`include "falcon512_params.v"
`include "task_opcode.v"

module sign_main_ctrl (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,

    input  wire       basis_done,
    output reg        basis_start,

    input  wire       gram_done,
    output reg        gram_start,

    input  wire       target_done,
    output reg        target_start,

    input  wire       ff_done,
    output reg        ff_start,

    input  wire       sign_done,
    output reg        sign_start,

    input  wire       norm_done,
    input  wire       norm_ok,
    output reg        norm_start,

    output reg        busy,
    output reg        done,
    output reg        fail,
    output reg [3:0]  phase
);

    localparam S_IDLE        = 4'd0;
    localparam S_LOAD_KEY    = 4'd1;
    localparam S_LOAD_HM     = 4'd2;
    localparam S_BUILD_BASIS = 4'd3;
    localparam S_GRAM        = 4'd4;
    localparam S_TARGET      = 4'd5;
    localparam S_FFSAMPLING  = 4'd6;
    localparam S_SIGN        = 4'd7;
    localparam S_NORM        = 4'd8;
    localparam S_DONE        = 4'd9;

    reg [3:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;

            basis_start  <= 1'b0;
            gram_start   <= 1'b0;
            target_start <= 1'b0;
            ff_start     <= 1'b0;
            sign_start   <= 1'b0;
            norm_start   <= 1'b0;

            busy         <= 1'b0;
            done         <= 1'b0;
            fail         <= 1'b0;
            phase        <= `TASK_IDLE;
        end else begin
            done         <= 1'b0;

            basis_start  <= 1'b0;
            gram_start   <= 1'b0;
            target_start <= 1'b0;
            ff_start     <= 1'b0;
            sign_start   <= 1'b0;
            norm_start   <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy  <= 1'b0;
                    phase <= `TASK_IDLE;

                    if (start) begin
                        fail  <= 1'b0;
                        busy  <= 1'b1;
                        phase <= `TASK_LOAD_KEY;
                        state <= S_LOAD_KEY;
                    end
                end

                S_LOAD_KEY: begin
                    busy  <= 1'b1;
                    phase <= `TASK_LOAD_KEY;
                    state <= S_LOAD_HM;
                end

                S_LOAD_HM: begin
                    busy        <= 1'b1;
                    phase       <= `TASK_LOAD_HM;
                    basis_start <= 1'b1;
                    state       <= S_BUILD_BASIS;
                end

                S_BUILD_BASIS: begin
                    busy  <= 1'b1;
                    phase <= `TASK_BUILD_BASIS;

                    if (basis_done) begin
                        gram_start <= 1'b1;
                        state      <= S_GRAM;
                    end
                end

                S_GRAM: begin
                    busy  <= 1'b1;
                    phase <= `TASK_GRAM;

                    if (gram_done) begin
                        target_start <= 1'b1;
                        state        <= S_TARGET;
                    end
                end

                S_TARGET: begin
                    busy  <= 1'b1;
                    phase <= `TASK_TARGET;

                    if (target_done) begin
                        ff_start <= 1'b1;
                        state    <= S_FFSAMPLING;
                    end
                end

                S_FFSAMPLING: begin
                    busy  <= 1'b1;
                    phase <= `TASK_FFSAMPLING;

                    if (ff_done) begin
                        sign_start <= 1'b1;
                        state      <= S_SIGN;
                    end
                end

                S_SIGN: begin
                    busy  <= 1'b1;
                    phase <= `TASK_SIGN;

                    if (sign_done) begin
                        norm_start <= 1'b1;
                        state      <= S_NORM;
                    end
                end

                S_NORM: begin
                    busy  <= 1'b1;
                    phase <= `TASK_NORM;

                    if (norm_done) begin
                        if (norm_ok) begin
                            fail <= 1'b0;
                        end else begin
                            fail <= 1'b1;
                        end

                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    phase <= `TASK_DONE;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
