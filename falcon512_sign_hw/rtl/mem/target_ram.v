`timescale 1ns/1ps
`include "falcon512_params.v"

module target_ram (
    input  wire clk,

    input  wire we,
    input  wire [`ADDR_W-1:0] waddr,

    input  wire signed [`TARGET_W-1:0] w_t0,
    input  wire signed [`TARGET_W-1:0] w_t1,

    input  wire [`ADDR_W-1:0] raddr,

    output wire signed [`TARGET_W-1:0] r_t0,
    output wire signed [`TARGET_W-1:0] r_t1
);

    reg signed [`TARGET_W-1:0] mem_t0 [0:`FALCON_N-1];
    reg signed [`TARGET_W-1:0] mem_t1 [0:`FALCON_N-1];

    always @(posedge clk) begin
        if (we) begin
            mem_t0[waddr] <= w_t0;
            mem_t1[waddr] <= w_t1;
        end
    end

    assign r_t0 = mem_t0[raddr];
    assign r_t1 = mem_t1[raddr];

endmodule
