`timescale 1ns/1ps

module tb_encoding;

//============================================================
// Parameters
//============================================================
parameter COEFF_WIDTH = 16;
parameter HIGH_WIDTH  = 9;

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
// sign_bit signals
//============================================================
reg signed [COEFF_WIDTH-1:0] coeff_sign;
wire                         sign;
wire [COEFF_WIDTH-1:0]       abs_value;

//============================================================
// low7_encoder signals
//============================================================
reg  [COEFF_WIDTH-1:0] abs_in;
wire [6:0]             low7;
wire [HIGH_WIDTH-1:0]  high;

//============================================================
// unary_encoder signals
//============================================================
reg                    unary_start;
reg  [HIGH_WIDTH-1:0]  unary_high;
wire                   unary_busy;
wire                   unary_out_valid;
wire                   unary_out_bit;
wire                   unary_done;

//============================================================
// bit_packer signals
//============================================================
reg        pack_clear;
reg        pack_bit_valid;
reg        pack_bit_in;
reg        pack_flush;
wire       pack_byte_valid;
wire [7:0] pack_byte_out;
wire [2:0] pack_bit_count;

//============================================================
// encoding_wrapper signals
//============================================================
reg                          wrap_start;
reg signed [COEFF_WIDTH-1:0] wrap_coeff;
reg                          wrap_last_coeff;
reg                          wrap_clear;

wire                         wrap_busy;
wire                         wrap_coeff_done;
wire                         wrap_byte_valid;
wire [7:0]                   wrap_byte_out;

//============================================================
// DUT instances
//============================================================
sign_bit #(
    .COEFF_WIDTH(COEFF_WIDTH)
) u_sign_bit (
    .coeff     (coeff_sign),
    .sign      (sign),
    .abs_value (abs_value)
);

low7_encoder #(
    .COEFF_WIDTH(COEFF_WIDTH),
    .HIGH_WIDTH (HIGH_WIDTH)
) u_low7_encoder (
    .abs_value (abs_in),
    .low7      (low7),
    .high      (high)
);

unary_encoder #(
    .HIGH_WIDTH(HIGH_WIDTH)
) u_unary_encoder (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (unary_start),
    .high      (unary_high),
    .busy      (unary_busy),
    .out_valid (unary_out_valid),
    .out_bit   (unary_out_bit),
    .done      (unary_done)
);

bit_packer u_bit_packer (
    .clk        (clk),
    .rst_n      (rst_n),
    .clear      (pack_clear),
    .bit_valid  (pack_bit_valid),
    .bit_in     (pack_bit_in),
    .flush      (pack_flush),
    .byte_valid (pack_byte_valid),
    .byte_out   (pack_byte_out),
    .bit_count  (pack_bit_count)
);

encoding_wrapper #(
    .COEFF_WIDTH(COEFF_WIDTH),
    .HIGH_WIDTH (HIGH_WIDTH)
) u_encoding_wrapper (
    .clk        (clk),
    .rst_n      (rst_n),
    .start      (wrap_start),
    .coeff      (wrap_coeff),
    .last_coeff (wrap_last_coeff),
    .clear      (wrap_clear),
    .busy       (wrap_busy),
    .coeff_done (wrap_coeff_done),
    .byte_valid (wrap_byte_valid),
    .byte_out   (wrap_byte_out)
);

//============================================================
// Check tasks
//============================================================
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

task check_u16;
    input [511:0] name;
    input [15:0] got;
    input [15:0] exp;
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

task check_u9;
    input [511:0] name;
    input [8:0] got;
    input [8:0] exp;
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

task check_u8;
    input [511:0] name;
    input [7:0] got;
    input [7:0] exp;
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

//============================================================
// Helper tasks
//============================================================
task reset_all;
    begin
        rst_n          = 1'b0;

        coeff_sign     = 16'sd0;
        abs_in         = 16'd0;

        unary_start    = 1'b0;
        unary_high     = 9'd0;

        pack_clear     = 1'b0;
        pack_bit_valid = 1'b0;
        pack_bit_in    = 1'b0;
        pack_flush     = 1'b0;

        wrap_start     = 1'b0;
        wrap_coeff     = 16'sd0;
        wrap_last_coeff = 1'b0;
        wrap_clear     = 1'b0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;
    end
endtask

task clear_packer;
    begin
        @(negedge clk);
        pack_clear = 1'b1;
        pack_bit_valid = 1'b0;
        pack_flush = 1'b0;

        @(posedge clk);
        #1;

        @(negedge clk);
        pack_clear = 1'b0;
    end
endtask

task send_pack_bit;
    input bit_value;
    begin
        @(negedge clk);
        pack_bit_valid = 1'b1;
        pack_bit_in    = bit_value;
        pack_flush     = 1'b0;

        @(posedge clk);
        #1;

        @(negedge clk);
        pack_bit_valid = 1'b0;
    end
endtask

task flush_packer;
    begin
        @(negedge clk);
        pack_flush = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        pack_flush = 1'b0;
    end
endtask

task test_unary;
    input [8:0] high_value;
    integer bit_index;
    integer cycle_count;
    reg expected_bit;
    reg done_seen;
    begin
        $display("---- Test unary high = %0d ----", high_value);

        @(negedge clk);
        unary_high  = high_value;
        unary_start = 1'b1;

        @(negedge clk);
        unary_start = 1'b0;

        bit_index   = 0;
        cycle_count = 0;
        done_seen   = 1'b0;

        while ((cycle_count < 40) && (done_seen == 1'b0)) begin
            @(posedge clk);
            #1;

            if (unary_out_valid) begin
                if (bit_index < high_value)
                    expected_bit = 1'b0;
                else
                    expected_bit = 1'b1;

                check_bool("unary output bit", unary_out_bit, expected_bit);
                bit_index = bit_index + 1;
            end

            if (unary_done) begin
                done_seen = 1'b1;
            end

            cycle_count = cycle_count + 1;
        end

        check_bool("unary done seen", done_seen, 1'b1);

        if (bit_index !== (high_value + 1)) begin
            $display("[FAIL] unary bit count: got = %0d, expected = %0d",
                     bit_index, high_value + 1);
            err = err + 1;
        end
        else begin
            $display("[PASS] unary bit count: %0d", bit_index);
        end
    end
endtask

task clear_wrapper;
    begin
        @(negedge clk);
        wrap_clear = 1'b1;
        wrap_start = 1'b0;

        @(posedge clk);
        #1;

        @(negedge clk);
        wrap_clear = 1'b0;
    end
endtask

task test_wrapper_coeff;
    input signed [15:0] coeff_value;
    input [7:0] exp_byte0;
    input [7:0] exp_byte1;
    input integer exp_count;

    integer byte_count;
    integer cycle_count;
    reg done_seen;
    begin
        $display("---- Test encoding_wrapper coeff = %0d ----", coeff_value);

        clear_wrapper();

        @(negedge clk);
        wrap_coeff      = coeff_value;
        wrap_last_coeff = 1'b1;
        wrap_start      = 1'b1;

        @(negedge clk);
        wrap_start      = 1'b0;

        byte_count  = 0;
        cycle_count = 0;
        done_seen   = 1'b0;

        while ((cycle_count < 100) && (done_seen == 1'b0)) begin
            @(posedge clk);
            #1;

            if (wrap_byte_valid) begin
                if (byte_count == 0) begin
                    check_u8("wrapper byte0", wrap_byte_out, exp_byte0);
                end
                else if (byte_count == 1) begin
                    check_u8("wrapper byte1", wrap_byte_out, exp_byte1);
                end
                else begin
                    $display("[FAIL] wrapper extra byte: %h", wrap_byte_out);
                    err = err + 1;
                end

                byte_count = byte_count + 1;
            end

            if (wrap_coeff_done) begin
                done_seen = 1'b1;
            end

            cycle_count = cycle_count + 1;
        end

        check_bool("wrapper coeff_done", done_seen, 1'b1);

        if (byte_count !== exp_count) begin
            $display("[FAIL] wrapper byte count: got = %0d, expected = %0d",
                     byte_count, exp_count);
            err = err + 1;
        end
        else begin
            $display("[PASS] wrapper byte count: %0d", byte_count);
        end
    end
endtask

//============================================================
// Main test
//============================================================
initial begin
    err = 0;

    $dumpfile("build_encoding/tb_encoding.vcd");
    $dumpvars(0, tb_encoding);

    reset_all();

    //========================================================
    // Test sign_bit
    //========================================================
    $display("========================================");
    $display("TEST sign_bit");
    $display("========================================");

    coeff_sign = 16'sd0;
    #1;
    check_bool("sign 0", sign, 1'b0);
    check_u16 ("abs 0",  abs_value, 16'd0);

    coeff_sign = 16'sd5;
    #1;
    check_bool("sign 5", sign, 1'b0);
    check_u16 ("abs 5",  abs_value, 16'd5);

    coeff_sign = -16'sd5;
    #1;
    check_bool("sign -5", sign, 1'b1);
    check_u16 ("abs -5",  abs_value, 16'd5);

    coeff_sign = 16'sh8000; // -32768
    #1;
    check_bool("sign -32768", sign, 1'b1);
    check_u16 ("abs -32768",  abs_value, 16'd32768);

    //========================================================
    // Test low7_encoder
    //========================================================
    $display("========================================");
    $display("TEST low7_encoder");
    $display("========================================");

    abs_in = 16'd0;
    #1;
    check_u16("low7 0", {9'd0, low7}, 16'd0);
    check_u9 ("high 0", high, 9'd0);

    abs_in = 16'd5;
    #1;
    check_u16("low7 5", {9'd0, low7}, 16'd5);
    check_u9 ("high 5", high, 9'd0);

    abs_in = 16'd127;
    #1;
    check_u16("low7 127", {9'd0, low7}, 16'd127);
    check_u9 ("high 127", high, 9'd0);

    abs_in = 16'd128;
    #1;
    check_u16("low7 128", {9'd0, low7}, 16'd0);
    check_u9 ("high 128", high, 9'd1);

    abs_in = 16'd300;
    #1;
    check_u16("low7 300", {9'd0, low7}, 16'd44);
    check_u9 ("high 300", high, 9'd2);

    abs_in = 16'd32768;
    #1;
    check_u16("low7 32768", {9'd0, low7}, 16'd0);
    check_u9 ("high 32768", high, 9'd256);

    //========================================================
    // Test unary_encoder
    //========================================================
    $display("========================================");
    $display("TEST unary_encoder");
    $display("========================================");

    test_unary(9'd0); // expected: 1
    test_unary(9'd1); // expected: 01
    test_unary(9'd2); // expected: 001
    test_unary(9'd5); // expected: 000001

    //========================================================
    // Test bit_packer
    //========================================================
    $display("========================================");
    $display("TEST bit_packer");
    $display("========================================");

    clear_packer();

    // Send bits: 1 0 1 0 1 1 0 0 = 8'hAC
    send_pack_bit(1'b1);
    send_pack_bit(1'b0);
    send_pack_bit(1'b1);
    send_pack_bit(1'b0);
    send_pack_bit(1'b1);
    send_pack_bit(1'b1);
    send_pack_bit(1'b0);
    send_pack_bit(1'b0);

    check_bool("packer byte_valid full", pack_byte_valid, 1'b1);
    check_u8  ("packer byte AC",         pack_byte_out, 8'hAC);

    clear_packer();

    // Send partial bits: 1 0 1, then flush => 10100000 = 8'hA0
    send_pack_bit(1'b1);
    send_pack_bit(1'b0);
    send_pack_bit(1'b1);

    flush_packer();

    check_bool("packer byte_valid flush", pack_byte_valid, 1'b1);
    check_u8  ("packer byte A0",          pack_byte_out, 8'hA0);

    //========================================================
    // Test encoding_wrapper
    //========================================================
    $display("========================================");
    $display("TEST encoding_wrapper");
    $display("========================================");

    // coeff = 5
    // sign = 0, low7 = 0000101 -> first byte = 00000101 = 05
    // high = 0 -> unary = 1 -> flush byte = 10000000 = 80
    test_wrapper_coeff(16'sd5, 8'h05, 8'h80, 2);

    // coeff = -5
    // sign = 1, low7 = 0000101 -> first byte = 10000101 = 85
    // high = 0 -> unary = 1 -> flush byte = 80
    test_wrapper_coeff(-16'sd5, 8'h85, 8'h80, 2);

    // coeff = 300
    // abs = 300, low7 = 44 = 0101100, high = 2
    // first byte = 0_0101100 = 2C
    // unary high=2 -> 001, flush => 00100000 = 20
    test_wrapper_coeff(16'sd300, 8'h2C, 8'h20, 2);

    // coeff = -300
    // first byte = 1_0101100 = AC
    // unary high=2 -> 001, flush => 20
    test_wrapper_coeff(-16'sd300, 8'hAC, 8'h20, 2);

    //========================================================
    // Final result
    //========================================================
    $display("========================================");

    if (err == 0) begin
        $display("ENCODING PRIMITIVE TEST PASS");
    end
    else begin
        $display("ENCODING PRIMITIVE TEST FAIL: %0d errors", err);
    end

    $display("========================================");

    $finish;
end

endmodule
