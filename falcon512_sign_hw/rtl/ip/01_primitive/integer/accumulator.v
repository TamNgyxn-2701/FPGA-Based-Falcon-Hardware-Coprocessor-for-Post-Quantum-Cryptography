/*
 * accumulator.v
 * Accumulate unsigned input values
 */

`timescale 1ns/1ps

module accumulator #(
    parameter IN_WIDTH  = 32,
    parameter ACC_WIDTH = 64
)(
    input                     clk,
    input                     rst_n,
    input                     ena,
    input                     clear,
    input                     in_valid,
    input  [IN_WIDTH-1:0]     data_in,
    output reg [ACC_WIDTH-1:0] acc_out,
    output reg                out_valid
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        acc_out   <= {ACC_WIDTH{1'b0}};
        out_valid <= 1'b0;
    end
    else begin
        if (clear) begin
            acc_out   <= {ACC_WIDTH{1'b0}};
            out_valid <= 1'b0;
        end
        else if (ena) begin
            if (in_valid) begin
                acc_out   <= acc_out + {{(ACC_WIDTH-IN_WIDTH){1'b0}}, data_in};
                out_valid <= 1'b1;
            end
            else begin
                out_valid <= 1'b0;
            end
        end
    end
end

endmodule
