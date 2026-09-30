`timescale 1ns/1ps

module tb_modq;

//============================================================
// Parameters
//============================================================
localparam Q_WIDTH = 14;
localparam IN_WIDTH = 16;
localparam Q = 12289;
localparam RINV = 2304;

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
// reduce_mod_q signals
//============================================================
reg  [IN_WIDTH-1:0] red_a;
wire [Q_WIDTH-1:0]  red_d;

//============================================================
// mq_add signals
//============================================================
reg  [Q_WIDTH-1:0] add_a;
reg  [Q_WIDTH-1:0] add_b;
wire [Q_WIDTH-1:0] add_d;

//============================================================
// mq_sub signals
//============================================================
reg  [Q_WIDTH-1:0] sub_a;
reg  [Q_WIDTH-1:0] sub_b;
wire [Q_WIDTH-1:0] sub_d;

//============================================================
// mq_montymul signals
//============================================================
reg                 mul_in_valid;
reg  [Q_WIDTH-1:0] mul_a;
reg  [Q_WIDTH-1:0] mul_b;
wire                mul_out_valid;
wire [Q_WIDTH-1:0] mul_d;

//============================================================
// DUT instances
//============================================================
reduce_mod_q u_reduce_mod_q (
    .a (red_a),
    .d (red_d)
);

mq_add u_mq_add (
    .a (add_a),
    .b (add_b),
    .d (add_d)
);

mq_sub u_mq_sub (
    .a (sub_a),
    .b (sub_b),
    .d (sub_d)
);

mq_montymul_wrapper u_mq_montymul_wrapper (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (mul_in_valid),
    .a         (mul_a),
    .b         (mul_b),
    .out_valid (mul_out_valid),
    .d         (mul_d)
);

//============================================================
// Reference functions
//============================================================
function [Q_WIDTH-1:0] ref_reduce;
    input [IN_WIDTH-1:0] value;
    begin
        ref_reduce = value % Q;
    end
endfunction

function [Q_WIDTH-1:0] ref_add;
    input [Q_WIDTH-1:0] a;
    input [Q_WIDTH-1:0] b;
    reg [31:0] tmp;
    begin
        tmp = a + b;
        ref_add = tmp % Q;
    end
endfunction

function [Q_WIDTH-1:0] ref_sub;
    input [Q_WIDTH-1:0] a;
    input [Q_WIDTH-1:0] b;
    reg signed [31:0] tmp;
    begin
        tmp = a - b;

        if (tmp < 0)
            tmp = tmp + Q;

        ref_sub = tmp[Q_WIDTH-1:0];
    end
endfunction

function [Q_WIDTH-1:0] ref_montymul;
    input [Q_WIDTH-1:0] a;
    input [Q_WIDTH-1:0] b;
    reg [63:0] tmp;
    begin
        tmp = a;
        tmp = tmp * b;
        tmp = tmp * RINV;
        ref_montymul = tmp % Q;
    end
endfunction

//============================================================
// Check tasks
//============================================================
task check_u14;
    input [511:0] name;
    input [Q_WIDTH-1:0] got;
    input [Q_WIDTH-1:0] exp;
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
// Test tasks
//============================================================
task test_reduce;
    input [IN_WIDTH-1:0] value;
    begin
        red_a = value;
        #1;
        check_u14("reduce_mod_q", red_d, ref_reduce(value));
    end
endtask

task test_add;
    input [Q_WIDTH-1:0] a;
    input [Q_WIDTH-1:0] b;
    begin
        add_a = a;
        add_b = b;
        #1;
        check_u14("mq_add", add_d, ref_add(a, b));
    end
endtask

task test_sub;
    input [Q_WIDTH-1:0] a;
    input [Q_WIDTH-1:0] b;
    begin
        sub_a = a;
        sub_b = b;
        #1;
        check_u14("mq_sub", sub_d, ref_sub(a, b));
    end
endtask

task test_montymul;
    input [Q_WIDTH-1:0] a;
    input [Q_WIDTH-1:0] b;

    reg [Q_WIDTH-1:0] exp;
    begin
        exp = ref_montymul(a, b);

        $display("---- mq_montymul a=%0d b=%0d ----", a, b);

        @(negedge clk);
        mul_a        = a;
        mul_b        = b;
        mul_in_valid = 1'b1;

        @(negedge clk);
        mul_in_valid = 1'b0;

        @(posedge clk);
        #1;

        check_bool("mq_montymul out_valid", mul_out_valid, 1'b1);
        check_u14 ("mq_montymul result",    mul_d, exp);

        @(posedge clk);
        #1;

        check_bool("mq_montymul valid drop", mul_out_valid, 1'b0);
    end
endtask

//============================================================
// Main test
//============================================================
initial begin
    err = 0;

    $dumpfile("build_modq/tb_modq.vcd");
    $dumpvars(0, tb_modq);

    rst_n        = 1'b0;
    mul_in_valid = 1'b0;

    red_a = 16'd0;

    add_a = 14'd0;
    add_b = 14'd0;

    sub_a = 14'd0;
    sub_b = 14'd0;

    mul_a = 14'd0;
    mul_b = 14'd0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    #1;

    //========================================================
    // Test reduce_mod_q
    //========================================================
    $display("========================================");
    $display("TEST reduce_mod_q");
    $display("========================================");

    test_reduce(16'd0);
    test_reduce(16'd1);
    test_reduce(16'd12288);
    test_reduce(16'd12289);
    test_reduce(16'd12290);
    test_reduce(16'd24577);
    test_reduce(16'd24578);
    test_reduce(16'd61444);
    test_reduce(16'd61445);
    test_reduce(16'd65535);

    //========================================================
    // Test mq_add
    //========================================================
    $display("========================================");
    $display("TEST mq_add");
    $display("========================================");

    test_add(14'd1,     14'd2);
    test_add(14'd12288, 14'd1);
    test_add(14'd7000,  14'd6000);
    test_add(14'd0,     14'd12288);
    test_add(14'd10000, 14'd3000);

    //========================================================
    // Test mq_sub
    //========================================================
    $display("========================================");
    $display("TEST mq_sub");
    $display("========================================");

    test_sub(14'd5,     14'd3);
    test_sub(14'd3,     14'd5);
    test_sub(14'd0,     14'd1);
    test_sub(14'd0,     14'd12288);
    test_sub(14'd12288, 14'd12288);
    test_sub(14'd1000,  14'd9000);

    //========================================================
    // Test mq_montymul_wrapper
    //========================================================
    $display("========================================");
    $display("TEST mq_montymul_wrapper");
    $display("========================================");

    test_montymul(14'd1,     14'd1);
    test_montymul(14'd2,     14'd3);
    test_montymul(14'd100,   14'd200);
    test_montymul(14'd12288, 14'd12288);
    test_montymul(14'd1234,  14'd5678);
    test_montymul(14'd5000,  14'd7000);

    //========================================================
    // Final result
    //========================================================
    $display("========================================");

    if (err == 0) begin
        $display("MODQ PRIMITIVE TEST PASS");
    end
    else begin
        $display("MODQ PRIMITIVE TEST FAIL: %0d errors", err);
    end

    $display("========================================");

    $finish;
end

endmodule
