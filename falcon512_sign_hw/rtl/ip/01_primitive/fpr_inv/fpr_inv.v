`timescale 1ns/1ps

/*
 * fpr_inv.v
 *
 * Fixed-point reciprocal:
 *   z = 1 / b
 *
 * Format:
 *   Q32.48 fixed-point
 *
 * DATA_WIDTH = 80
 * FRAC_WIDTH = 48
 *
 * This version does NOT use Synopsys DesignWare.
 * It uses sequential unsigned long division.
 *
 * Formula:
 *   b_real = b / 2^FRAC_WIDTH
 *   z_real = 1 / b_real
 *   z_fixed = 2^(2*FRAC_WIDTH) / b
 */

module fpr_inv #(
    parameter FLOAT_PRECISION = 80,
    parameter FRAC_WIDTH      = 48
)(
    input                                  clk,
    input                                  rst_n,
    input                                  in_valid,
    input  signed [FLOAT_PRECISION-1:0]   b,

    output reg                             out_valid,
    output reg signed [FLOAT_PRECISION-1:0] z
);

//============================================================
// Local parameters
//============================================================
localparam NUM_WIDTH = (2 * FRAC_WIDTH) + 1;

localparam signed [FLOAT_PRECISION-1:0] MAX_POS =
    {1'b0, {(FLOAT_PRECISION-1){1'b1}}};

localparam signed [FLOAT_PRECISION-1:0] MIN_NEG =
    {1'b1, {(FLOAT_PRECISION-1){1'b0}}};

localparam [NUM_WIDTH-1:0] NUM_ONE =
    ({{(NUM_WIDTH-1){1'b0}}, 1'b1} << (2 * FRAC_WIDTH));

//============================================================
// Internal registers
//============================================================
reg busy;
reg sign_reg;

reg [FLOAT_PRECISION-1:0] denom_abs_reg;
reg [NUM_WIDTH-1:0]       numerator_reg;
reg [NUM_WIDTH-1:0]       quotient_reg;
reg [NUM_WIDTH:0]         remainder_reg;
reg [15:0]                count;

//============================================================
// Absolute value of input
//============================================================
wire [FLOAT_PRECISION-1:0] b_abs;

assign b_abs = b[FLOAT_PRECISION-1] ? (~b + {{(FLOAT_PRECISION-1){1'b0}}, 1'b1}) : b;

//============================================================
// Division combinational step
//============================================================
wire [NUM_WIDTH:0] denom_ext;
wire [NUM_WIDTH:0] rem_shift;
wire               rem_ge_denom;
wire [NUM_WIDTH:0] rem_sub;
wire [NUM_WIDTH:0] rem_next;
wire [NUM_WIDTH-1:0] quotient_next;

assign denom_ext    = {{(NUM_WIDTH+1-FLOAT_PRECISION){1'b0}}, denom_abs_reg};
assign rem_shift    = {remainder_reg[NUM_WIDTH-1:0], numerator_reg[NUM_WIDTH-1]};
assign rem_ge_denom = (rem_shift >= denom_ext);
assign rem_sub      = rem_shift - denom_ext;
assign rem_next     = rem_ge_denom ? rem_sub : rem_shift;
assign quotient_next = {quotient_reg[NUM_WIDTH-2:0], rem_ge_denom};

//============================================================
// Output conversion
//============================================================
wire overflow_next;
wire [FLOAT_PRECISION-1:0] q_mag;
wire [FLOAT_PRECISION-1:0] q_neg;

assign overflow_next = |quotient_next[NUM_WIDTH-1:FLOAT_PRECISION-1];
assign q_mag = quotient_next[FLOAT_PRECISION-1:0];
assign q_neg = ~q_mag + {{(FLOAT_PRECISION-1){1'b0}}, 1'b1};

//============================================================
// Sequential logic
//============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy          <= 1'b0;
        sign_reg      <= 1'b0;
        denom_abs_reg <= {FLOAT_PRECISION{1'b0}};
        numerator_reg <= {NUM_WIDTH{1'b0}};
        quotient_reg  <= {NUM_WIDTH{1'b0}};
        remainder_reg <= {(NUM_WIDTH+1){1'b0}};
        count         <= 16'd0;
        out_valid     <= 1'b0;
        z             <= {FLOAT_PRECISION{1'b0}};
    end
    else begin
        out_valid <= 1'b0;

        if (busy) begin
            numerator_reg <= {numerator_reg[NUM_WIDTH-2:0], 1'b0};
            quotient_reg  <= quotient_next;
            remainder_reg <= rem_next;

            if (count == (NUM_WIDTH - 1)) begin
                busy      <= 1'b0;
                out_valid <= 1'b1;

                if (overflow_next) begin
                    z <= sign_reg ? MIN_NEG : MAX_POS;
                end
                else begin
                    z <= sign_reg ? q_neg : q_mag;
                end
            end
            else begin
                count <= count + 16'd1;
            end
        end
        else begin
            if (in_valid) begin
                if (b_abs == {FLOAT_PRECISION{1'b0}}) begin
                    out_valid <= 1'b1;
                    z         <= MAX_POS;
                end
                else begin
                    busy          <= 1'b1;
                    sign_reg      <= b[FLOAT_PRECISION-1];
                    denom_abs_reg <= b_abs;
                    numerator_reg <= NUM_ONE;
                    quotient_reg  <= {NUM_WIDTH{1'b0}};
                    remainder_reg <= {(NUM_WIDTH+1){1'b0}};
                    count         <= 16'd0;
                end
            end
        end
    end
end

endmodule
