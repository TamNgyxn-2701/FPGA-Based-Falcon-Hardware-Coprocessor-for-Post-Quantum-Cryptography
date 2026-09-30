/*
 * valid_delay.v
 *
 * Delay signal valid theo so chu ky pipeline.
 * Dung de can chinh in_valid voi data da qua pipeline.
 */

`timescale 1ns/1ps

module valid_delay #(
    parameter DEPTH = 1
)(
    clk,
    rst_n,
    ena,
    i_valid,
    o_valid
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input  clk;
input  rst_n;
input  ena;
input  i_valid;

output o_valid;

//---------------------------------------------------------------------
//   Generate Logic
//---------------------------------------------------------------------
generate
    if (DEPTH == 0) begin : GEN_VALID_BYPASS

        assign o_valid = i_valid;

    end
    else begin : GEN_VALID_DELAY

        reg [DEPTH-1:0] valid_shift;
        integer i;

        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                valid_shift <= {DEPTH{1'b0}};
            end
            else begin
                if (ena) begin
                    valid_shift[0] <= i_valid;

                    for (i = 1; i < DEPTH; i = i + 1) begin
                        valid_shift[i] <= valid_shift[i-1];
                    end
                end
                else begin
                    valid_shift <= valid_shift;
                end
            end
        end

        assign o_valid = valid_shift[DEPTH-1];

    end
endgenerate

endmodule
