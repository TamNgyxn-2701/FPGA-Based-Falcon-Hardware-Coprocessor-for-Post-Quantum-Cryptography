`timescale 1ns/1ps
`include "falcon512_params.v"

module basis_ram (
    input  wire clk,

    input  wire we,
    input  wire [`ADDR_W-1:0] waddr,

    input  wire signed [`COEFF_W-1:0] w_b00,
    input  wire signed [`COEFF_W-1:0] w_b01,
    input  wire signed [`COEFF_W-1:0] w_b10,
    input  wire signed [`COEFF_W-1:0] w_b11,

    input  wire [`ADDR_W-1:0] raddr,

    output wire signed [`COEFF_W-1:0] r_b00,
    output wire signed [`COEFF_W-1:0] r_b01,
    output wire signed [`COEFF_W-1:0] r_b10,
    output wire signed [`COEFF_W-1:0] r_b11
);

    reg signed [`COEFF_W-1:0] mem_b00 [0:`FALCON_N-1];
    reg signed [`COEFF_W-1:0] mem_b01 [0:`FALCON_N-1];
    reg signed [`COEFF_W-1:0] mem_b10 [0:`FALCON_N-1];
    reg signed [`COEFF_W-1:0] mem_b11 [0:`FALCON_N-1];

    always @(posedge clk) begin
        if (we) begin
            mem_b00[waddr] <= w_b00;
            mem_b01[waddr] <= w_b01;
            mem_b10[waddr] <= w_b10;
            mem_b11[waddr] <= w_b11;
        end
    end

    assign r_b00 = mem_b00[raddr];
    assign r_b01 = mem_b01[raddr];
    assign r_b10 = mem_b10[raddr];
    assign r_b11 = mem_b11[raddr];

endmodule
