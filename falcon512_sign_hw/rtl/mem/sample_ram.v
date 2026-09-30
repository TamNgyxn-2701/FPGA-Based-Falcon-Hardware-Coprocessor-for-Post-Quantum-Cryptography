`timescale 1ns/1ps
`include "falcon512_params.v"

module sample_ram (
    input  wire clk,

    input  wire we,
    input  wire [`ADDR_W-1:0] waddr,

    input  wire signed [`SAMPLE_W-1:0] w_z0,
    input  wire signed [`SAMPLE_W-1:0] w_z1,

    input  wire [`ADDR_W-1:0] raddr,

    output wire signed [`SAMPLE_W-1:0] r_z0,
    output wire signed [`SAMPLE_W-1:0] r_z1
);

    reg signed [`SAMPLE_W-1:0] mem_z0 [0:`FALCON_N-1];
    reg signed [`SAMPLE_W-1:0] mem_z1 [0:`FALCON_N-1];

    always @(posedge clk) begin
        if (we) begin
            mem_z0[waddr] <= w_z0;
            mem_z1[waddr] <= w_z1;
        end
    end

    assign r_z0 = mem_z0[raddr];
    assign r_z1 = mem_z1[raddr];

endmodule
