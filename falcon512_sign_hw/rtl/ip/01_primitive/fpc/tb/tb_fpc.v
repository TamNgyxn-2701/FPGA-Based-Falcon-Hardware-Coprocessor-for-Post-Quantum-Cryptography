`timescale 1ns/1ps

module tb_fpc;

//============================================================
// Parameters for Q32.48 fixed-point
//============================================================
parameter DATA_WIDTH = 80;
parameter FRAC_WIDTH = 48;

//============================================================
// Clock / Reset
//============================================================
reg clk;
reg rst_n;

initial begin
    clk = 1'b0;
end

always #5 clk = ~clk;

//============================================================
// Error counter
//============================================================
integer err;

//============================================================
// Fixed-point Q32.48 constants
// value = real_value * 2^48
//============================================================
localparam signed [DATA_WIDTH-1:0] FX_0    = 80'h0000_0000_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_0_5  = 80'h0000_0000_8000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_1    = 80'h0000_0001_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_1_5  = 80'h0000_0001_8000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_2    = 80'h0000_0002_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_3    = 80'h0000_0003_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_3_5  = 80'h0000_0003_8000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_4    = 80'h0000_0004_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_5    = 80'h0000_0005_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_6    = 80'h0000_0006_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_7    = 80'h0000_0007_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_10   = 80'h0000_000A_0000_0000_0000;

localparam signed [DATA_WIDTH-1:0] FX_N0_5 = 80'hFFFF_FFFF_8000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_N1   = 80'hFFFF_FFFF_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_N1_5 = 80'hFFFF_FFFE_8000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_N2   = 80'hFFFF_FFFE_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_N5   = 80'hFFFF_FFFB_0000_0000_0000;

//============================================================
// FPC_ADD signals
//============================================================
reg  signed [DATA_WIDTH-1:0] add_a_re;
reg  signed [DATA_WIDTH-1:0] add_a_im;
reg  signed [DATA_WIDTH-1:0] add_b_re;
reg  signed [DATA_WIDTH-1:0] add_b_im;

wire signed [DATA_WIDTH-1:0] add_d_re;
wire signed [DATA_WIDTH-1:0] add_d_im;

//============================================================
// FPC_SUB signals
//============================================================
reg  signed [DATA_WIDTH-1:0] sub_a_re;
reg  signed [DATA_WIDTH-1:0] sub_a_im;
reg  signed [DATA_WIDTH-1:0] sub_b_re;
reg  signed [DATA_WIDTH-1:0] sub_b_im;

wire signed [DATA_WIDTH-1:0] sub_d_re;
wire signed [DATA_WIDTH-1:0] sub_d_im;

//============================================================
// FPC_MUL signals
//============================================================
reg                          mul_in_valid;
reg  signed [DATA_WIDTH-1:0] mul_a_re;
reg  signed [DATA_WIDTH-1:0] mul_a_im;
reg  signed [DATA_WIDTH-1:0] mul_b_re;
reg  signed [DATA_WIDTH-1:0] mul_b_im;

wire                         mul_valid;
wire signed [DATA_WIDTH-1:0] mul_d_re;
wire signed [DATA_WIDTH-1:0] mul_d_im;

//============================================================
// DUT instances
//============================================================
FPC_ADD #(
    .FLOAT_PRECISION(DATA_WIDTH),
    .FRAC_WIDTH     (FRAC_WIDTH)
) u_fpc_add (
    .a_re (add_a_re),
    .a_im (add_a_im),
    .b_re (add_b_re),
    .b_im (add_b_im),
    .d_re (add_d_re),
    .d_im (add_d_im)
);

FPC_SUB #(
    .FLOAT_PRECISION(DATA_WIDTH),
    .FRAC_WIDTH     (FRAC_WIDTH)
) u_fpc_sub (
    .a_re (sub_a_re),
    .a_im (sub_a_im),
    .b_re (sub_b_re),
    .b_im (sub_b_im),
    .d_re (sub_d_re),
    .d_im (sub_d_im)
);

FPC_MUL #(
    .FLOAT_PRECISION(DATA_WIDTH),
    .FRAC_WIDTH     (FRAC_WIDTH)
) u_fpc_mul (
    .clk        (clk),
    .rst_n      (rst_n),
    .in_valid   (mul_in_valid),
    .a_re       (mul_a_re),
    .a_im       (mul_a_im),
    .b_re       (mul_b_re),
    .b_im       (mul_b_im),
    .mult_valid (mul_valid),
    .d_re       (mul_d_re),
    .d_im       (mul_d_im)
);

//============================================================
// Check tasks
//============================================================
task check_hex;
    input [511:0] name;
    input [DATA_WIDTH-1:0] got;
    input [DATA_WIDTH-1:0] exp;
    begin
        if (got !== exp) begin
            $display("[FAIL] %0s: got = %h, expected = %h", name, got, exp);
            err = err + 1;
        end
        else begin
            $display("[PASS] %0s: %h", name, got);
        end
    end
endtask

task check_bool;
    input [511:0] name;
    input got;
    input exp;
    begin
        if (got !== exp) begin
            $display("[FAIL] %0s: got = %0b, expected = %0b", name, got, exp);
            err = err + 1;
        end
        else begin
            $display("[PASS] %0s: %0b", name, got);
        end
    end
endtask

//============================================================
// Test complex multiplication
//============================================================
task test_mul;
    input signed [DATA_WIDTH-1:0] a_re;
    input signed [DATA_WIDTH-1:0] a_im;
    input signed [DATA_WIDTH-1:0] b_re;
    input signed [DATA_WIDTH-1:0] b_im;
    input signed [DATA_WIDTH-1:0] exp_re;
    input signed [DATA_WIDTH-1:0] exp_im;
    input [511:0]                 test_name;
    begin
        $display("---- %0s ----", test_name);

        @(negedge clk);
        mul_a_re     = a_re;
        mul_a_im     = a_im;
        mul_b_re     = b_re;
        mul_b_im     = b_im;
        mul_in_valid = 1'b1;

        @(posedge clk);
        #1;

        check_bool("FPC_MUL mult_valid", mul_valid, 1'b1);
        check_hex ("FPC_MUL real",       mul_d_re, exp_re);
        check_hex ("FPC_MUL imag",       mul_d_im, exp_im);

        @(negedge clk);
        mul_in_valid = 1'b0;

        @(posedge clk);
        #1;

        check_bool("FPC_MUL valid drop", mul_valid, 1'b0);
    end
endtask

//============================================================
// Main test
//============================================================
initial begin
    err = 0;

    $dumpfile("build_fpc/tb_fpc_q32_48.vcd");
    $dumpvars(0, tb_fpc);

    rst_n        = 1'b0;
    mul_in_valid = 1'b0;

    add_a_re = FX_0;
    add_a_im = FX_0;
    add_b_re = FX_0;
    add_b_im = FX_0;

    sub_a_re = FX_0;
    sub_a_im = FX_0;
    sub_b_re = FX_0;
    sub_b_im = FX_0;

    mul_a_re = FX_0;
    mul_a_im = FX_0;
    mul_b_re = FX_0;
    mul_b_im = FX_0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    #1;

    //========================================================
    // Test FPC_ADD
    //========================================================
    $display("========================================");
    $display("TEST FPC_ADD FIXED Q32.48");
    $display("========================================");

    // (1 + 2j) + (3 + 4j) = 4 + 6j
    add_a_re = FX_1;
    add_a_im = FX_2;
    add_b_re = FX_3;
    add_b_im = FX_4;
    #1;

    check_hex("FPC_ADD real 1+3=4", add_d_re, FX_4);
    check_hex("FPC_ADD imag 2+4=6", add_d_im, FX_6);

    // (-1 + 0.5j) + (3 - 2j) = 2 - 1.5j
    add_a_re = FX_N1;
    add_a_im = FX_0_5;
    add_b_re = FX_3;
    add_b_im = FX_N2;
    #1;

    check_hex("FPC_ADD real -1+3=2",     add_d_re, FX_2);
    check_hex("FPC_ADD imag 0.5-2=-1.5", add_d_im, FX_N1_5);

    //========================================================
    // Test FPC_SUB
    //========================================================
    $display("========================================");
    $display("TEST FPC_SUB FIXED Q32.48");
    $display("========================================");

    // (5 + 7j) - (2 + 3j) = 3 + 4j
    sub_a_re = FX_5;
    sub_a_im = FX_7;
    sub_b_re = FX_2;
    sub_b_im = FX_3;
    #1;

    check_hex("FPC_SUB real 5-2=3", sub_d_re, FX_3);
    check_hex("FPC_SUB imag 7-3=4", sub_d_im, FX_4);

    // (1 + 0.5j) - (3 + 1j) = -2 - 0.5j
    sub_a_re = FX_1;
    sub_a_im = FX_0_5;
    sub_b_re = FX_3;
    sub_b_im = FX_1;
    #1;

    check_hex("FPC_SUB real 1-3=-2",     sub_d_re, FX_N2);
    check_hex("FPC_SUB imag 0.5-1=-0.5", sub_d_im, FX_N0_5);

    //========================================================
    // Test FPC_MUL
    //========================================================
    $display("========================================");
    $display("TEST FPC_MUL FIXED Q32.48");
    $display("========================================");

    // (1 + 2j) * (3 + 4j)
    // real = 1*3 - 2*4 = -5
    // imag = 1*4 + 2*3 = 10
    test_mul(
        FX_1, FX_2,
        FX_3, FX_4,
        FX_N5, FX_10,
        "MUL integer values"
    );

    // (1.5 + 0.5j) * (2 - 1j)
    // real = 1.5*2 - 0.5*(-1) = 3.5
    // imag = 1.5*(-1) + 0.5*2 = -0.5
    test_mul(
        FX_1_5, FX_0_5,
        FX_2,   FX_N1,
        FX_3_5, FX_N0_5,
        "MUL fractional values"
    );

    // (-1 + 2j) * (3 - 1j)
    // real = (-1)*3 - 2*(-1) = -1
    // imag = (-1)*(-1) + 2*3 = 7
    test_mul(
        FX_N1, FX_2,
        FX_3,  FX_N1,
        FX_N1, FX_7,
        "MUL signed values"
    );

    //========================================================
    // Final result
    //========================================================
    $display("========================================");

    if (err == 0) begin
        $display("FPC FIXED Q32.48 PRIMITIVE TEST PASS");
    end
    else begin
        $display("FPC FIXED Q32.48 PRIMITIVE TEST FAIL: %0d errors", err);
    end

    $display("========================================");

    $finish;
end

endmodule
