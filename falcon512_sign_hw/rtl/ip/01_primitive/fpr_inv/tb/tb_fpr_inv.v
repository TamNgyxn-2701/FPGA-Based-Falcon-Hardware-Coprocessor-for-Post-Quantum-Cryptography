`timescale 1ns/1ps

module tb_fpr_inv;

//============================================================
// Parameters
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
// Q32.48 constants
//============================================================
localparam signed [DATA_WIDTH-1:0] FX_0     = 80'h0000_0000_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_0_25  = 80'h0000_0000_4000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_0_5   = 80'h0000_0000_8000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_1     = 80'h0000_0001_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_2     = 80'h0000_0002_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_4     = 80'h0000_0004_0000_0000_0000;

localparam signed [DATA_WIDTH-1:0] FX_N0_5  = 80'hFFFF_FFFF_8000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_N1    = 80'hFFFF_FFFF_0000_0000_0000;
localparam signed [DATA_WIDTH-1:0] FX_N2    = 80'hFFFF_FFFE_0000_0000_0000;

localparam signed [DATA_WIDTH-1:0] FX_MAX_POS = 80'h7FFF_FFFF_FFFF_FFFF_FFFF;

//============================================================
// DUT signals
//============================================================
reg                          in_valid;
reg  signed [DATA_WIDTH-1:0] b;

wire                         out_valid;
wire signed [DATA_WIDTH-1:0] z;

//============================================================
// DUT
//============================================================
fpr_inv #(
    .FLOAT_PRECISION(DATA_WIDTH),
    .FRAC_WIDTH     (FRAC_WIDTH)
) u_fpr_inv (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (in_valid),
    .b         (b),
    .out_valid (out_valid),
    .z         (z)
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
// Test one reciprocal
//============================================================
task test_inv;
    input signed [DATA_WIDTH-1:0] in_value;
    input signed [DATA_WIDTH-1:0] exp_value;
    input [511:0]                 test_name;

    integer cycle_count;
    reg done_seen;
    begin
        $display("---- %0s ----", test_name);

        @(negedge clk);
        b        = in_value;
        in_valid = 1'b1;

        cycle_count = 0;
        done_seen   = 1'b0;

        // Check ngay posedge dau tien de khong bi lo out_valid
        @(posedge clk);
        #1;

        if (out_valid) begin
            done_seen = 1'b1;
            check_hex("fpr_inv result", z, exp_value);
        end

        @(negedge clk);
        in_valid = 1'b0;

        // Neu chua xong, tiep tuc cho ket qua
        while ((cycle_count < 200) && (done_seen == 1'b0)) begin
            @(posedge clk);
            #1;

            if (out_valid) begin
                done_seen = 1'b1;
                check_hex("fpr_inv result", z, exp_value);
            end

            cycle_count = cycle_count + 1;
        end

        check_bool("fpr_inv out_valid seen", done_seen, 1'b1);
    end
endtask

//============================================================
// Main test
//============================================================
initial begin
    err = 0;

    $dumpfile("build_fpr_inv/tb_fpr_inv.vcd");
    $dumpvars(0, tb_fpr_inv);

    rst_n    = 1'b0;
    in_valid = 1'b0;
    b        = FX_0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    #1;

    $display("========================================");
    $display("TEST fpr_inv FIXED Q32.48");
    $display("========================================");

    test_inv(FX_1,    FX_1,       "1 / 1.0 = 1.0");
    test_inv(FX_2,    FX_0_5,     "1 / 2.0 = 0.5");
    test_inv(FX_4,    FX_0_25,    "1 / 4.0 = 0.25");
    test_inv(FX_0_5,  FX_2,       "1 / 0.5 = 2.0");
    test_inv(FX_N1,   FX_N1,      "1 / -1.0 = -1.0");
    test_inv(FX_N2,   FX_N0_5,    "1 / -2.0 = -0.5");

    // Divide by zero: saturate to MAX_POS
    test_inv(FX_0,    FX_MAX_POS, "1 / 0 = MAX_POS");

    $display("========================================");

    if (err == 0) begin
        $display("FPR_INV FIXED Q32.48 TEST PASS");
    end
    else begin
        $display("FPR_INV FIXED Q32.48 TEST FAIL: %0d errors", err);
    end

    $display("========================================");

    $finish;
end

endmodule
