`timescale 1ns/1ps
/*
 * montymul_core.v
 *
 * Montgomery multiplication core for Falcon q = 12289.
 *
 * Function:
 *     z = x * y * R^(-1) mod q
 *
 * with:
 *     q = 12289
 *     R = 2^16
 *     Q0I = -q^(-1) mod 2^16 = 12287
 *
 * Input x, y must be in range:
 *     0 <= x, y < q
 *
 * Latency:
 *     1 clock cycle
 */

module montymul_core (
    clk,
    rst_n,
    in_valid,
    x,
    y,
    out_valid,
    z
);

//---------------------------------------------------------------------
//   Parameter
//---------------------------------------------------------------------
localparam Q_WIDTH = 14;
localparam Q       = 14'd12289;
localparam Q0I     = 16'd12287;

//---------------------------------------------------------------------
//   Input & Output
//---------------------------------------------------------------------
input                  clk;
input                  rst_n;
input                  in_valid;
input  [Q_WIDTH-1:0]   x;
input  [Q_WIDTH-1:0]   y;

output reg             out_valid;
output reg [Q_WIDTH-1:0] z;

//---------------------------------------------------------------------
//   Reg & Wire
//---------------------------------------------------------------------
wire [27:0] product;
wire [43:0] product_q0i;
wire [15:0] m;
wire [29:0] mq;
wire [30:0] sum;
wire [14:0] u;
wire [14:0] u_sub_q;
wire [Q_WIDTH-1:0] z_next;

reg  [27:0] product_reg;
reg  [29:0] mq_reg;
reg         valid_reg;

//---------------------------------------------------------------------
//   Combinational Logic - Stage 0
//---------------------------------------------------------------------
// product = x * y
assign product     = x * y;

// m = (product * Q0I) mod 2^16
assign product_q0i = product * Q0I;
assign m           = product_q0i[15:0];

// mq = m * q
assign mq          = m * Q;

//---------------------------------------------------------------------
//   Combinational Logic - Stage 1
//---------------------------------------------------------------------
// u = (product + m*q) >> 16
assign sum     = {3'b000, product_reg} + {1'b0, mq_reg};
assign u       = sum[30:16];

// if u >= q, subtract q
assign u_sub_q = u - {1'b0, Q};

assign z_next  = (u >= Q) ? u_sub_q[Q_WIDTH-1:0]
                          : u[Q_WIDTH-1:0];

//---------------------------------------------------------------------
//   Sequential Logic
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        product_reg <= 28'd0;
        mq_reg      <= 30'd0;
        valid_reg   <= 1'b0;
        z           <= {Q_WIDTH{1'b0}};
        out_valid   <= 1'b0;
    end
    else begin
        product_reg <= product;
        mq_reg      <= mq;
        valid_reg   <= in_valid;

        z           <= z_next;
        out_valid   <= valid_reg;
    end
end

endmodule
