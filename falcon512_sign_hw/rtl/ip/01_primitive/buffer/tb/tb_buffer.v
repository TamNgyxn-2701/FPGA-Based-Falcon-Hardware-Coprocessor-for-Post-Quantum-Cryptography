`timescale 1ns/1ps

module tb_buffer;

//============================================================
// Parameter
//============================================================
parameter WIDTH = 32;

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
// Common input signals
//============================================================
reg ena;
reg i_valid;
reg [WIDTH-1:0] di_re;
reg [WIDTH-1:0] di_im;

//============================================================
// DELAY_BUFFER outputs
//============================================================
wire o_valid_d1;
wire [WIDTH-1:0] do_re_d1;
wire [WIDTH-1:0] do_im_d1;

wire o_valid_d3;
wire [WIDTH-1:0] do_re_d3;
wire [WIDTH-1:0] do_im_d3;

//============================================================
// valid_delay outputs
//============================================================
wire o_valid_v0;
wire o_valid_v1;
wire o_valid_v3;

//============================================================
// Error counter
//============================================================
integer err;

//============================================================
// DUT instances
//============================================================

// Delay data + valid by 1 cycle
DELAY_BUFFER #(
    .FLOAT_PRECISION(WIDTH),
    .DEPTH(1)
) u_delay_buffer_d1 (
    .clk     (clk),
    .rst_n   (rst_n),
    .ena     (ena),
    .i_valid (i_valid),
    .di_re   (di_re),
    .di_im   (di_im),
    .o_valid (o_valid_d1),
    .do_re   (do_re_d1),
    .do_im   (do_im_d1)
);

// Delay data + valid by 3 cycles
DELAY_BUFFER #(
    .FLOAT_PRECISION(WIDTH),
    .DEPTH(3)
) u_delay_buffer_d3 (
    .clk     (clk),
    .rst_n   (rst_n),
    .ena     (ena),
    .i_valid (i_valid),
    .di_re   (di_re),
    .di_im   (di_im),
    .o_valid (o_valid_d3),
    .do_re   (do_re_d3),
    .do_im   (do_im_d3)
);

// valid_delay DEPTH = 0, bypass
valid_delay #(
    .DEPTH(0)
) u_valid_delay_d0 (
    .clk     (clk),
    .rst_n   (rst_n),
    .ena     (ena),
    .i_valid (i_valid),
    .o_valid (o_valid_v0)
);

// valid_delay DEPTH = 1
valid_delay #(
    .DEPTH(1)
) u_valid_delay_d1 (
    .clk     (clk),
    .rst_n   (rst_n),
    .ena     (ena),
    .i_valid (i_valid),
    .o_valid (o_valid_v1)
);

// valid_delay DEPTH = 3
valid_delay #(
    .DEPTH(3)
) u_valid_delay_d3 (
    .clk     (clk),
    .rst_n   (rst_n),
    .ena     (ena),
    .i_valid (i_valid),
    .o_valid (o_valid_v3)
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

task check_u32;
    input [511:0] name;
    input [31:0] got;
    input [31:0] exp;
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
// Reset task
//============================================================
task apply_reset;
    begin
        rst_n   = 1'b0;
        ena     = 1'b1;
        i_valid = 1'b0;
        di_re   = {WIDTH{1'b0}};
        di_im   = {WIDTH{1'b0}};

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;
    end
endtask

//============================================================
// Main test
//============================================================
initial begin
    err = 0;

    $dumpfile("build_buffer/tb_buffer.vcd");
    $dumpvars(0, tb_buffer);

    apply_reset();

    $display("========================================");
    $display("TEST reset output");
    $display("========================================");

    check_bool("DELAY_BUFFER D1 valid reset", o_valid_d1, 1'b0);
    check_bool("DELAY_BUFFER D3 valid reset", o_valid_d3, 1'b0);
    check_bool("valid_delay D1 reset",        o_valid_v1, 1'b0);
    check_bool("valid_delay D3 reset",        o_valid_v3, 1'b0);

    check_u32("DELAY_BUFFER D1 re reset", do_re_d1, 32'h00000000);
    check_u32("DELAY_BUFFER D1 im reset", do_im_d1, 32'h00000000);
    check_u32("DELAY_BUFFER D3 re reset", do_re_d3, 32'h00000000);
    check_u32("DELAY_BUFFER D3 im reset", do_im_d3, 32'h00000000);

    $display("========================================");
    $display("TEST valid_delay DEPTH = 0 bypass");
    $display("========================================");

    i_valid = 1'b1;
    #1;
    check_bool("valid_delay D0 bypass valid=1", o_valid_v0, 1'b1);

    i_valid = 1'b0;
    #1;
    check_bool("valid_delay D0 bypass valid=0", o_valid_v0, 1'b0);

    $display("========================================");
    $display("TEST DELAY_BUFFER DEPTH = 1 and 3");
    $display("========================================");

    // Cycle 1: input data 1
    ena     = 1'b1;
    i_valid = 1'b1;
    di_re   = 32'hAAAA0001;
    di_im   = 32'hBBBB0001;
    @(posedge clk);
    #1;

    // DEPTH=1 outputs data 1 immediately after first accepted clock
    check_bool("D1 valid data1", o_valid_d1, 1'b1);
    check_u32 ("D1 re data1",    do_re_d1,   32'hAAAA0001);
    check_u32 ("D1 im data1",    do_im_d1,   32'hBBBB0001);

    // DEPTH=3 not yet valid
    check_bool("D3 valid after cycle1", o_valid_d3, 1'b0);
    check_bool("valid_delay D3 after cycle1", o_valid_v3, 1'b0);

    // Cycle 2: input data 2
    i_valid = 1'b1;
    di_re   = 32'hAAAA0002;
    di_im   = 32'hBBBB0002;
    @(posedge clk);
    #1;

    check_bool("D1 valid data2", o_valid_d1, 1'b1);
    check_u32 ("D1 re data2",    do_re_d1,   32'hAAAA0002);
    check_u32 ("D1 im data2",    do_im_d1,   32'hBBBB0002);

    check_bool("D3 valid after cycle2", o_valid_d3, 1'b0);
    check_bool("valid_delay D3 after cycle2", o_valid_v3, 1'b0);

    // Cycle 3: input data 3
    i_valid = 1'b1;
    di_re   = 32'hAAAA0003;
    di_im   = 32'hBBBB0003;
    @(posedge clk);
    #1;

    check_bool("D1 valid data3", o_valid_d1, 1'b1);
    check_u32 ("D1 re data3",    do_re_d1,   32'hAAAA0003);
    check_u32 ("D1 im data3",    do_im_d1,   32'hBBBB0003);

    // DEPTH=3 now outputs data 1
    check_bool("D3 valid data1", o_valid_d3, 1'b1);
    check_u32 ("D3 re data1",    do_re_d3,   32'hAAAA0001);
    check_u32 ("D3 im data1",    do_im_d3,   32'hBBBB0001);
    check_bool("valid_delay D3 data1", o_valid_v3, 1'b1);

    // Cycle 4: invalid input data 4
    i_valid = 1'b0;
    di_re   = 32'hAAAA0004;
    di_im   = 32'hBBBB0004;
    @(posedge clk);
    #1;

    // DEPTH=1 has data4 but valid = 0
    check_bool("D1 invalid data4", o_valid_d1, 1'b0);
    check_u32 ("D1 re data4",      do_re_d1,   32'hAAAA0004);
    check_u32 ("D1 im data4",      do_im_d1,   32'hBBBB0004);

    // DEPTH=3 outputs previous data2, still valid
    check_bool("D3 valid data2", o_valid_d3, 1'b1);
    check_u32 ("D3 re data2",    do_re_d3,   32'hAAAA0002);
    check_u32 ("D3 im data2",    do_im_d3,   32'hBBBB0002);

    // Cycle 5: invalid input data 5
    i_valid = 1'b0;
    di_re   = 32'hAAAA0005;
    di_im   = 32'hBBBB0005;
    @(posedge clk);
    #1;

    // DEPTH=3 outputs data3, still valid
    check_bool("D3 valid data3", o_valid_d3, 1'b1);
    check_u32 ("D3 re data3",    do_re_d3,   32'hAAAA0003);
    check_u32 ("D3 im data3",    do_im_d3,   32'hBBBB0003);

    // Cycle 6: invalid input data 6
    i_valid = 1'b0;
    di_re   = 32'hAAAA0006;
    di_im   = 32'hBBBB0006;
    @(posedge clk);
    #1;

    // DEPTH=3 now outputs data4 but valid = 0
    check_bool("D3 invalid data4", o_valid_d3, 1'b0);
    check_u32 ("D3 re data4",      do_re_d3,   32'hAAAA0004);
    check_u32 ("D3 im data4",      do_im_d3,   32'hBBBB0004);

    $display("========================================");
    $display("TEST ena = 0 hold behavior");
    $display("========================================");

    apply_reset();

	// Fill pipeline with 3 valid data
	ena     = 1'b1;
	i_valid = 1'b1;

	di_re = 32'h11110001;
	di_im = 32'h22220001;
	@(posedge clk);
	#1;

	di_re = 32'h11110002;
	di_im = 32'h22220002;
	@(posedge clk);
	#1;

	di_re = 32'h11110003;
	di_im = 32'h22220003;
	@(posedge clk);
	#1;

	// At this point, D3 output should be first data
	check_bool("D3 valid before hold", o_valid_d3, 1'b1);
	check_u32 ("D3 re before hold",    do_re_d3,   32'h11110001);
	check_u32 ("D3 im before hold",    do_im_d3,   32'h22220001);

	// Disable ena and change input. Output must hold.
	ena     = 1'b0;
	i_valid = 1'b1;
	di_re   = 32'hDEAD0001;
	di_im   = 32'hBEEF0001;

	@(posedge clk);
	#1;
	@(posedge clk);
	#1;

	check_bool("D3 valid hold when ena=0", o_valid_d3, 1'b1);
	check_u32 ("D3 re hold when ena=0",    do_re_d3,   32'h11110001);
	check_u32 ("D3 im hold when ena=0",    do_im_d3,   32'h22220001);

	check_bool("D1 valid hold when ena=0", o_valid_d1, 1'b1);
	check_u32 ("D1 re hold when ena=0",    do_re_d1,   32'h11110003);
	check_u32 ("D1 im hold when ena=0",    do_im_d1,   32'h22220003);

    $display("========================================");

    if (err == 0) begin
        $display("BUFFER PRIMITIVE TEST PASS");
    end
    else begin
        $display("BUFFER PRIMITIVE TEST FAIL: %0d errors", err);
    end

    $display("========================================");

    $finish;
end

endmodule
