`timescale 1ns/1ps

module tb_rng_prim;

parameter MAX_BITS  = 320;
parameter LEN_WIDTH = 9;
parameter TEST_SEED = 32'h1234_5678;

reg clk;
reg rst_n;

initial begin
    clk = 1'b0;
end

always #5 clk = ~clk;

integer err;

//============================================================
// random_byte signals
//============================================================
reg        rb_req;
reg        rb_seed_en;
reg [31:0] rb_seed;
wire       rb_out_valid;
wire [7:0] rb_random_byte;

//============================================================
// uniform_bits signals
//============================================================
reg                         ub_start;
reg      [LEN_WIDTH-1:0]    ub_bit_len;
wire                        ub_byte_req;
reg                         ub_byte_valid;
reg      [7:0]              ub_byte_in;
wire                        ub_busy;
wire                        ub_out_valid;
wire     [MAX_BITS-1:0]     ub_random_bits;

integer ub_index;
reg [7:0] ub_mem [0:63];

//============================================================
// rng_wrapper signals
//============================================================
reg                         rw_req;
reg      [LEN_WIDTH-1:0]    rw_bit_len;
reg                         rw_seed_en;
reg      [31:0]             rw_seed;
wire                        rw_busy;
wire                        rw_out_valid;
wire     [MAX_BITS-1:0]     rw_random_out;

//============================================================
// DUT instances
//============================================================
random_byte u_random_byte (
    .clk         (clk),
    .rst_n       (rst_n),
    .req         (rb_req),
    .seed_en     (rb_seed_en),
    .seed        (rb_seed),
    .out_valid   (rb_out_valid),
    .random_byte (rb_random_byte)
);

uniform_bits #(
    .MAX_BITS  (MAX_BITS),
    .LEN_WIDTH (LEN_WIDTH)
) u_uniform_bits (
    .clk         (clk),
    .rst_n       (rst_n),
    .start       (ub_start),
    .bit_len     (ub_bit_len),
    .byte_req    (ub_byte_req),
    .byte_valid  (ub_byte_valid),
    .byte_in     (ub_byte_in),
    .busy        (ub_busy),
    .out_valid   (ub_out_valid),
    .random_bits (ub_random_bits)
);

rng_wrapper #(
    .MAX_BITS  (MAX_BITS),
    .LEN_WIDTH (LEN_WIDTH)
) u_rng_wrapper (
    .clk        (clk),
    .rst_n      (rst_n),
    .req        (rw_req),
    .bit_len    (rw_bit_len),
    .seed_en    (rw_seed_en),
    .seed       (rw_seed),
    .busy       (rw_busy),
    .out_valid  (rw_out_valid),
    .random_out (rw_random_out)
);

//============================================================
// Reference functions
//============================================================
function [31:0] ref_lfsr_next8;
    input [31:0] cur;

    reg [31:0] tmp;
    reg        feedback;
    integer    i;

    begin
        tmp = cur;

        for (i = 0; i < 8; i = i + 1) begin
            feedback = tmp[31] ^ tmp[21] ^ tmp[1] ^ tmp[0];
            tmp      = {tmp[30:0], feedback};
        end

        ref_lfsr_next8 = tmp;
    end
endfunction

function [MAX_BITS-1:0] ref_mask_to_len;
    input [MAX_BITS-1:0]  data;
    input [LEN_WIDTH-1:0] len;

    integer i;
    begin
        ref_mask_to_len = {MAX_BITS{1'b0}};

        for (i = 0; i < MAX_BITS; i = i + 1) begin
            if (i < len)
                ref_mask_to_len[i] = data[i];
        end
    end
endfunction

function [MAX_BITS-1:0] ref_wrapper_bits;
    input [31:0]          seed;
    input [LEN_WIDTH-1:0] bit_len;

    reg [31:0] lfsr_tmp;
    reg [MAX_BITS-1:0] acc;
    reg [MAX_BITS-1:0] byte_ext;
    integer total_bytes;
    integer i;

    begin
        lfsr_tmp = seed;
        acc = {MAX_BITS{1'b0}};
        total_bytes = (bit_len + 7) >> 3;

        for (i = 0; i < total_bytes; i = i + 1) begin
            lfsr_tmp = ref_lfsr_next8(lfsr_tmp);
            byte_ext = {{(MAX_BITS-8){1'b0}}, lfsr_tmp[7:0]};
            acc = acc | (byte_ext << (i * 8));
        end

        ref_wrapper_bits = ref_mask_to_len(acc, bit_len);
    end
endfunction

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

task check_bits;
    input [511:0] name;
    input [MAX_BITS-1:0] got;
    input [MAX_BITS-1:0] exp;
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
// uniform_bits byte driver
//============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ub_byte_valid <= 1'b0;
        ub_byte_in    <= 8'd0;
        ub_index      <= 0;
    end
    else begin
        ub_byte_valid <= 1'b0;

        if (ub_byte_req) begin
            ub_byte_in    <= ub_mem[ub_index];
            ub_byte_valid <= 1'b1;
            ub_index      <= ub_index + 1;
        end
    end
end

//============================================================
// Test random_byte
//============================================================
task test_random_byte;
    reg [31:0] ref_state;
    reg [31:0] ref_next;
    integer i;
    begin
        $display("========================================");
        $display("TEST random_byte");
        $display("========================================");

        @(negedge clk);
        rb_seed    = TEST_SEED;
        rb_seed_en = 1'b1;

        @(negedge clk);
        rb_seed_en = 1'b0;

        ref_state = TEST_SEED;

        for (i = 0; i < 4; i = i + 1) begin
            ref_next = ref_lfsr_next8(ref_state);

            @(negedge clk);
            rb_req = 1'b1;

            @(posedge clk);
            #1;

            check_bool("random_byte out_valid", rb_out_valid, 1'b1);
            check_u8  ("random_byte value",     rb_random_byte, ref_next[7:0]);

            @(negedge clk);
            rb_req = 1'b0;

            @(posedge clk);
            #1;

            check_bool("random_byte valid drop", rb_out_valid, 1'b0);

            ref_state = ref_next;
        end
    end
endtask

//============================================================
// Test uniform_bits
//============================================================
task test_uniform_bits;
    input [LEN_WIDTH-1:0] bit_len;
    input [MAX_BITS-1:0]  exp_value;
    input [511:0]         test_name;

    integer cycle_count;
    reg done_seen;
    begin
        $display("---- %0s ----", test_name);

        ub_index = 0;

        @(negedge clk);
        ub_bit_len = bit_len;
        ub_start   = 1'b1;

        cycle_count = 0;
        done_seen   = 1'b0;

        @(posedge clk);
        #1;

        if (ub_out_valid) begin
            done_seen = 1'b1;
            check_bits("uniform_bits result", ub_random_bits, exp_value);
        end

        @(negedge clk);
        ub_start = 1'b0;

        while ((cycle_count < 200) && (done_seen == 1'b0)) begin
            @(posedge clk);
            #1;

            if (ub_out_valid) begin
                done_seen = 1'b1;
                check_bits("uniform_bits result", ub_random_bits, exp_value);
            end

            cycle_count = cycle_count + 1;
        end

        check_bool("uniform_bits out_valid seen", done_seen, 1'b1);
    end
endtask

//============================================================
// Test rng_wrapper
//============================================================
task test_rng_wrapper;
    input [LEN_WIDTH-1:0] bit_len;
    input [511:0]         test_name;

    reg [MAX_BITS-1:0] exp_value;
    integer cycle_count;
    reg done_seen;
    begin
        $display("---- %0s ----", test_name);

        exp_value = ref_wrapper_bits(TEST_SEED, bit_len);

        @(negedge clk);
        rw_seed    = TEST_SEED;
        rw_seed_en = 1'b1;

        @(negedge clk);
        rw_seed_en = 1'b0;

        @(negedge clk);
        rw_bit_len = bit_len;
        rw_req     = 1'b1;

        cycle_count = 0;
        done_seen   = 1'b0;

        @(posedge clk);
        #1;

        if (rw_out_valid) begin
            done_seen = 1'b1;
            check_bits("rng_wrapper result", rw_random_out, exp_value);
        end

        @(negedge clk);
        rw_req = 1'b0;

        while ((cycle_count < 400) && (done_seen == 1'b0)) begin
            @(posedge clk);
            #1;

            if (rw_out_valid) begin
                done_seen = 1'b1;
                check_bits("rng_wrapper result", rw_random_out, exp_value);
            end

            cycle_count = cycle_count + 1;
        end

        check_bool("rng_wrapper out_valid seen", done_seen, 1'b1);
    end
endtask

//============================================================
// Main test
//============================================================
initial begin
    err = 0;

    $dumpfile("build_rng_prim/tb_rng_prim.vcd");
    $dumpvars(0, tb_rng_prim);

    ub_mem[0] = 8'hA5;
    ub_mem[1] = 8'h3C;
    ub_mem[2] = 8'hF0;
    ub_mem[3] = 8'h0F;
    ub_mem[4] = 8'h55;
    ub_mem[5] = 8'hAA;

    rst_n = 1'b0;

    rb_req     = 1'b0;
    rb_seed_en = 1'b0;
    rb_seed    = 32'd0;

    ub_start      = 1'b0;
    ub_bit_len    = {LEN_WIDTH{1'b0}};
    ub_byte_valid = 1'b0;
    ub_byte_in    = 8'd0;
    ub_index      = 0;

    rw_req     = 1'b0;
    rw_bit_len = {LEN_WIDTH{1'b0}};
    rw_seed_en = 1'b0;
    rw_seed    = 32'd0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    #1;

    test_random_byte();

    $display("========================================");
    $display("TEST uniform_bits");
    $display("========================================");

    test_uniform_bits(9'd0,  {MAX_BITS{1'b0}}, "UniformBits(0)");
    test_uniform_bits(9'd1,  {{(MAX_BITS-1){1'b0}}, 1'b1}, "UniformBits(1)");
    test_uniform_bits(9'd8,  {{(MAX_BITS-8){1'b0}}, 8'hA5}, "UniformBits(8)");
    test_uniform_bits(9'd9,  {{(MAX_BITS-9){1'b0}}, 9'h0A5}, "UniformBits(9)");
    test_uniform_bits(9'd16, {{(MAX_BITS-16){1'b0}}, 16'h3CA5}, "UniformBits(16)");

    $display("========================================");
    $display("TEST rng_wrapper");
    $display("========================================");

    test_rng_wrapper(9'd1,   "rng_wrapper UniformBits(1)");
    test_rng_wrapper(9'd8,   "rng_wrapper UniformBits(8)");
    test_rng_wrapper(9'd16,  "rng_wrapper UniformBits(16)");
    test_rng_wrapper(9'd72,  "rng_wrapper UniformBits(72)");
    test_rng_wrapper(9'd320, "rng_wrapper UniformBits(320)");

    $display("========================================");

    if (err == 0) begin
        $display("RNG PRIMITIVE TEST PASS");
    end
    else begin
        $display("RNG PRIMITIVE TEST FAIL: %0d errors", err);
    end

    $display("========================================");

    $finish;
end

endmodule
