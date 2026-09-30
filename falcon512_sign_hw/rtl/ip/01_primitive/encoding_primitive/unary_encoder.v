/*
 * unary_encoder.v
 *
 * Generate unary code for high value.
 *
 * Falcon unary rule:
 *
 *     high = 0  -> 1
 *     high = 1  -> 01
 *     high = 2  -> 001
 *     high = 3  -> 0001
 *
 * This module outputs one unary bit per clock cycle.
 */

`timescale 1ns/1ps
module unary_encoder #(
    parameter HIGH_WIDTH = 9
)(
    clk,
    rst_n,
    start,
    high,

    busy,
    out_valid,
    out_bit,
    done
);

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input                    clk;
input                    rst_n;
input                    start;
input  [HIGH_WIDTH-1:0]  high;

output reg               busy;
output reg               out_valid;
output reg               out_bit;
output reg               done;

//---------------------------------------------------------------------
//   Reg
//---------------------------------------------------------------------
reg [HIGH_WIDTH-1:0] high_reg;
reg [HIGH_WIDTH-1:0] count;

//---------------------------------------------------------------------
//   Sequential Logic
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy      <= 1'b0;
        out_valid <= 1'b0;
        out_bit   <= 1'b0;
        done      <= 1'b0;
        high_reg  <= {HIGH_WIDTH{1'b0}};
        count     <= {HIGH_WIDTH{1'b0}};
    end
    else begin
        out_valid <= 1'b0;
        out_bit   <= 1'b0;
        done      <= 1'b0;

        if (start && !busy) begin
            busy     <= 1'b1;
            high_reg <= high;
            count    <= {HIGH_WIDTH{1'b0}};
        end
        else if (busy) begin
            out_valid <= 1'b1;

            if (count < high_reg) begin
                out_bit <= 1'b0;
                count   <= count + 1'b1;
            end
            else begin
                out_bit <= 1'b1;
                done    <= 1'b1;
                busy    <= 1'b0;
            end
        end
    end
end

endmodule
