`timescale 1ns/1ps

module tb_integer;

//============================================================
// Parameter for larger integer test
//============================================================
parameter WIDTH     = 16;
parameter IN_WIDTH  = 32;
parameter ACC_WIDTH = 64;

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
integer i;

//============================================================
// Signals for int_add, int_sub, abs, square
//============================================================
reg  signed [WIDTH-1:0] a;
reg  signed [WIDTH-1:0] b;

wire signed [WIDTH:0]       sum;
wire signed [WIDTH:0]       diff;
wire        [WIDTH-1:0]     abs_out;
wire        [2*WIDTH-1:0]   square_out;

// Convert outputs to 64-bit for checking
wire signed [63:0] sum_s64;
wire signed [63:0] diff_s64;
wire        [63:0] abs_u64;
wire        [63:0] square_u64;

assign sum_s64    = {{(64-(WIDTH+1)){sum[WIDTH]}}, sum};
assign diff_s64   = {{(64-(WIDTH+1)){diff[WIDTH]}}, diff};
assign abs_u64    = {{(64-WIDTH){1'b0}}, abs_out};
assign square_u64 = {{(64-(2*WIDTH)){1'b0}}, square_out};

//============================================================
// Signals for comparator
//============================================================
reg  [ACC_WIDTH-1:0] comp_a;
reg  [ACC_WIDTH-1:0] comp_b;

wire lt;
wire le;
wire eq;
wire ge;
wire gt;

//============================================================
// Signals for accumulator
//============================================================
reg                  acc_ena;
reg                  acc_clear;
reg                  acc_in_valid;
reg  [IN_WIDTH-1:0]  acc_data_in;

wire [ACC_WIDTH-1:0] acc_out;
wire                 acc_out_valid;

//============================================================
// DUT instances
//============================================================
int_add #(
    .WIDTH(WIDTH)
) u_int_add (
    .a   (a),
    .b   (b),
    .sum (sum)
);

int_sub #(
    .WIDTH(WIDTH)
) u_int_sub (
    .a    (a),
    .b    (b),
    .diff (diff)
);

abs #(
    .WIDTH(WIDTH)
) u_abs (
    .a       (a),
    .abs_out (abs_out)
);

square #(
    .WIDTH(WIDTH)
) u_square (
    .a          (a),
    .square_out (square_out)
);

comparator #(
    .WIDTH(ACC_WIDTH)
) u_comparator (
    .a  (comp_a),
    .b  (comp_b),
    .lt (lt),
    .le (le),
    .eq (eq),
    .ge (ge),
    .gt (gt)
);

accumulator #(
    .IN_WIDTH  (IN_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
) u_accumulator (
    .clk       (clk),
    .rst_n     (rst_n),
    .ena       (acc_ena),
    .clear     (acc_clear),
    .in_valid  (acc_in_valid),
    .data_in   (acc_data_in),
    .acc_out   (acc_out),
    .out_valid (acc_out_valid)
);

//============================================================
// Check tasks
//============================================================
task check_s64;
    input [255:0] name;
    input signed [63:0] got;
    input signed [63:0] exp;
    begin
        if (got !== exp) begin
            $display("[FAIL] %0s: got = %0d, expected = %0d", name, got, exp);
            err = err + 1;
        end
        else begin
            $display("[PASS] %0s: %0d", name, got);
        end
    end
endtask

task check_u64;
    input [255:0] name;
    input [63:0] got;
    input [63:0] exp;
    begin
        if (got !== exp) begin
            $display("[FAIL] %0s: got = %0d, expected = %0d", name, got, exp);
            err = err + 1;
        end
        else begin
            $display("[PASS] %0s: %0d", name, got);
        end
    end
endtask

task check_bool;
    input [255:0] name;
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
// Main test
//============================================================
initial begin
    err = 0;

    $dumpfile("build_integer/tb_integer_large.vcd");
    $dumpvars(0, tb_integer);

    rst_n        = 1'b0;
    acc_ena      = 1'b0;
    acc_clear    = 1'b0;
    acc_in_valid = 1'b0;
    acc_data_in  = {IN_WIDTH{1'b0}};

    a = 0;
    b = 0;
    comp_a = 0;
    comp_b = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    #1;

    $display("========================================");
    $display("TEST int_add / int_sub / abs / square");
    $display("WIDTH = 16 signed");
    $display("========================================");

    // 0 case
    a = 16'sd0;
    b = 16'sd0;
    #1;
    check_s64("int_add 0 + 0",        sum_s64,       64'sd0);
    check_s64("int_sub 0 - 0",        diff_s64,      64'sd0);
    check_u64("abs 0",                abs_u64,       64'd0);
    check_u64("square 0",             square_u64,    64'd0);

    // Small positive / negative
    a = 16'sd5;
    b = 16'sd3;
    #1;
    check_s64("int_add 5 + 3",        sum_s64,       64'sd8);
    check_s64("int_sub 5 - 3",        diff_s64,      64'sd2);
    check_u64("abs 5",                abs_u64,       64'd5);
    check_u64("square 5",             square_u64,    64'd25);

    a = -16'sd5;
    b = 16'sd3;
    #1;
    check_s64("int_add -5 + 3",       sum_s64,       -64'sd2);
    check_s64("int_sub -5 - 3",       diff_s64,      -64'sd8);
    check_u64("abs -5",               abs_u64,       64'd5);
    check_u64("square -5",            square_u64,    64'd25);

    // Large positive values
    a = 16'sd30000;
    b = 16'sd2000;
    #1;
    check_s64("int_add 30000 + 2000", sum_s64,       64'sd32000);
    check_s64("int_sub 30000 - 2000", diff_s64,      64'sd28000);
    check_u64("abs 30000",            abs_u64,       64'd30000);
    check_u64("square 30000",         square_u64,    64'd900000000);

    // Boundary max: signed 16-bit max = 32767
    a = 16'sd32767;
    b = 16'sd1;
    #1;
    check_s64("int_add 32767 + 1",    sum_s64,       64'sd32768);
    check_s64("int_sub 32767 - 1",    diff_s64,      64'sd32766);
    check_u64("abs 32767",            abs_u64,       64'd32767);
    check_u64("square 32767",         square_u64,    64'd1073676289);

    // Boundary min: signed 16-bit min = -32768
    a = 16'sh8000;
    b = 16'sd1;
    #1;
    check_s64("int_add -32768 + 1",   sum_s64,       -64'sd32767);
    check_s64("int_sub -32768 - 1",   diff_s64,      -64'sd32769);
    check_u64("abs -32768",           abs_u64,       64'd32768);
    check_u64("square -32768",        square_u64,    64'd1073741824);

    // Extreme subtraction range
    a = 16'sd32767;
    b = 16'sh8000;
    #1;
    check_s64("int_sub 32767 - -32768", diff_s64,    64'sd65535);

    a = 16'sh8000;
    b = 16'sd32767;
    #1;
    check_s64("int_sub -32768 - 32767", diff_s64,    -64'sd65535);

    $display("========================================");
    $display("TEST comparator");
    $display("WIDTH = 64 unsigned");
    $display("========================================");

    comp_a = 64'd10;
    comp_b = 64'd20;
    #1;
    check_bool("10 < 20",  lt, 1'b1);
    check_bool("10 <= 20", le, 1'b1);
    check_bool("10 == 20", eq, 1'b0);
    check_bool("10 >= 20", ge, 1'b0);
    check_bool("10 > 20",  gt, 1'b0);

    comp_a = 64'd1099511627776;
    comp_b = 64'd1099511627776;
    #1;
    check_bool("large equal lt", lt, 1'b0);
    check_bool("large equal le", le, 1'b1);
    check_bool("large equal eq", eq, 1'b1);
    check_bool("large equal ge", ge, 1'b1);
    check_bool("large equal gt", gt, 1'b0);

    comp_a = 64'd1099511627777;
    comp_b = 64'd1099511627776;
    #1;
    check_bool("large greater lt", lt, 1'b0);
    check_bool("large greater le", le, 1'b0);
    check_bool("large greater eq", eq, 1'b0);
    check_bool("large greater ge", ge, 1'b1);
    check_bool("large greater gt", gt, 1'b1);

    comp_a = 64'hFFFF_FFFF_FFFF_FFFF;
    comp_b = 64'd0;
    #1;
    check_bool("max64 > 0", gt, 1'b1);
    check_bool("max64 == 0", eq, 1'b0);
    check_bool("max64 < 0", lt, 1'b0);

    $display("========================================");
    $display("TEST accumulator");
    $display("IN_WIDTH = 32, ACC_WIDTH = 64");
    $display("========================================");

    check_u64("acc reset", acc_out, 64'd0);

    // Add large 32-bit values
    acc_ena      = 1'b1;
    acc_in_valid = 1'b1;

    acc_data_in  = 32'd1073741824;
    @(posedge clk);
    #1;
    check_u64("acc add 1073741824", acc_out, 64'd1073741824);
    check_bool("acc valid 1", acc_out_valid, 1'b1);

    acc_data_in  = 32'd900000000;
    @(posedge clk);
    #1;
    check_u64("acc add 900000000", acc_out, 64'd1973741824);
    check_bool("acc valid 2", acc_out_valid, 1'b1);

    acc_data_in  = 32'd4000000000;
    @(posedge clk);
    #1;
    check_u64("acc add 4000000000", acc_out, 64'd5973741824);
    check_bool("acc valid 3", acc_out_valid, 1'b1);

    // Hold when in_valid = 0
    acc_in_valid = 1'b0;
    acc_data_in  = 32'd123456789;
    @(posedge clk);
    #1;
    check_u64("acc hold when in_valid=0", acc_out, 64'd5973741824);
    check_bool("acc valid when in_valid=0", acc_out_valid, 1'b0);

    // Hold when ena = 0
    acc_ena      = 1'b0;
    acc_in_valid = 1'b1;
    acc_data_in  = 32'd100;
    @(posedge clk);
    #1;
    check_u64("acc hold when ena=0", acc_out, 64'd5973741824);

    // Clear
    acc_ena      = 1'b1;
    acc_clear    = 1'b1;
    acc_in_valid = 1'b0;
    @(posedge clk);
    #1;
    check_u64("acc clear", acc_out, 64'd0);
    check_bool("acc valid after clear", acc_out_valid, 1'b0);

    acc_clear = 1'b0;

    $display("========================================");
    $display("TEST accumulator repeated Falcon-like sum");
    $display("1024 times max 16-bit square");
    $display("========================================");

    // This imitates summing many squared coefficients:
    // 1024 * 1073741824 = 1099511627776
    acc_ena      = 1'b1;
    acc_in_valid = 1'b1;
    acc_data_in  = 32'd1073741824;

    for (i = 0; i < 1024; i = i + 1) begin
        @(posedge clk);
    end

    #1;
    check_u64("acc 1024 * 1073741824", acc_out, 64'd1099511627776);
    check_bool("acc valid repeated", acc_out_valid, 1'b1);

    $display("========================================");

    if (err == 0) begin
        $display("INTEGER LARGE TEST PASS");
    end
    else begin
        $display("INTEGER LARGE TEST FAIL: %0d errors", err);
    end

    $display("========================================");

    $finish;
end

endmodule
