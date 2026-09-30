`timescale 1ns/1ps
`include "falcon512_params.v"

module signature_ram (
    input  wire clk,

    input  wire we,
    input  wire [`ADDR_W-1:0] waddr,

    input  wire signed [`SIGN_W-1:0] w_s0,
    input  wire signed [`SIGN_W-1:0] w_s1,

    input  wire [`ADDR_W-1:0] raddr,

    output wire signed [`SIGN_W-1:0] r_s0,
    output wire signed [`SIGN_W-1:0] r_s1
);

    reg signed [`SIGN_W-1:0] mem_s0 [0:`FALCON_N-1];
    reg signed [`SIGN_W-1:0] mem_s1 [0:`FALCON_N-1];

    always @(posedge clk) begin
        if (we) begin
            mem_s0[waddr] <= w_s0;
            mem_s1[waddr] <= w_s1;
        end
    end

    assign r_s0 = mem_s0[raddr];
    assign r_s1 = mem_s1[raddr];

endmodule
