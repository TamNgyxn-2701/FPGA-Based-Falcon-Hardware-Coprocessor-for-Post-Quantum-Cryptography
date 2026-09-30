`timescale 1ns/1ps

module tb_falcon512_sign_wrapper_v7;

    reg clk;
    reg rst_n;
    reg start;

    wire busy;
    wire done;
    wire fail;
    wire [3:0] phase;

    wire accept;
    wire retry;
    wire final_valid;
    wire [3:0] retry_count;

    wire basis_valid;
    wire [8:0] basis_addr;
    wire signed [15:0] basis_b00;
    wire signed [15:0] basis_b01;
    wire signed [15:0] basis_b10;
    wire signed [15:0] basis_b11;

    wire gram_valid;
    wire [8:0] gram_addr;
    wire signed [39:0] gram00;
    wire signed [39:0] gram01;
    wire signed [39:0] gram10;
    wire signed [39:0] gram11;

    wire target_valid;
    wire [8:0] target_addr;
    wire signed [39:0] target_t0;
    wire signed [39:0] target_t1;

    wire ff_valid;
    wire [8:0] ff_addr;
    wire signed [39:0] sample_z0;
    wire signed [39:0] sample_z1;

    wire sign_valid;
    wire [8:0] sign_addr;
    wire signed [63:0] sig_s0;
    wire signed [63:0] sig_s1;

    wire norm_valid;
    wire [8:0] norm_addr;
    wire [127:0] norm_value;
    wire norm_ok;

    integer basis_count;
    integer gram_count;
    integer target_count;
    integer ff_count;
    integer sign_count;
    integer norm_count;

    integer sign_csv;
    integer norm_csv;
    integer result_csv;

    reg final_valid_seen;

    falcon512_sign_wrapper_v7 dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),

        .busy         (busy),
        .done         (done),
        .fail         (fail),
        .phase        (phase),

        .accept       (accept),
        .retry        (retry),
        .final_valid  (final_valid),
        .retry_count  (retry_count),

        .basis_valid  (basis_valid),
        .basis_addr   (basis_addr),
        .basis_b00    (basis_b00),
        .basis_b01    (basis_b01),
        .basis_b10    (basis_b10),
        .basis_b11    (basis_b11),

        .gram_valid   (gram_valid),
        .gram_addr    (gram_addr),
        .gram00       (gram00),
        .gram01       (gram01),
        .gram10       (gram10),
        .gram11       (gram11),

        .target_valid (target_valid),
        .target_addr  (target_addr),
        .target_t0    (target_t0),
        .target_t1    (target_t1),

        .ff_valid     (ff_valid),
        .ff_addr      (ff_addr),
        .sample_z0    (sample_z0),
        .sample_z1    (sample_z1),

        .sign_valid   (sign_valid),
        .sign_addr    (sign_addr),
        .sig_s0       (sig_s0),
        .sig_s1       (sig_s1),

        .norm_valid   (norm_valid),
        .norm_addr    (norm_addr),
        .norm_value   (norm_value),
        .norm_ok      (norm_ok)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $vcdplusfile("v7_wave.vpd");
        $vcdpluson(0, tb_falcon512_sign_wrapper_v7);

        $dumpfile("v7_wave.vcd");
        $dumpvars(0, tb_falcon512_sign_wrapper_v7);

        sign_csv   = $fopen("signature_v7.csv", "w");
        norm_csv   = $fopen("norm_v7.csv", "w");
        result_csv = $fopen("result_v7.csv", "w");

        if (sign_csv == 0) begin
            $display("ERROR: Cannot open signature_v7.csv");
            $finish;
        end

        if (norm_csv == 0) begin
            $display("ERROR: Cannot open norm_v7.csv");
            $finish;
        end

        if (result_csv == 0) begin
            $display("ERROR: Cannot open result_v7.csv");
            $finish;
        end

        $fwrite(sign_csv,   "index,sig_s0,sig_s1\n");
        $fwrite(norm_csv,   "index,norm_value\n");
        $fwrite(result_csv, "accept,fail,retry,final_valid_seen,retry_count,norm_ok,norm_value\n");

        rst_n = 1'b0;
        start = 1'b0;

        basis_count = 0;
        gram_count = 0;
        target_count = 0;
        ff_count = 0;
        sign_count = 0;
        norm_count = 0;
        final_valid_seen = 1'b0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (2) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        wait (final_valid == 1'b1);

        repeat (2) @(posedge clk);
        #1;

        $fwrite(result_csv, "%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
                accept,
                fail,
                retry,
                final_valid_seen,
                retry_count,
                norm_ok,
                norm_value);

        $display("FINAL RESULT");
        $display("------------");
        $display("FINAL NORM        = %0d", norm_value);
        $display("NORM OK           = %b", norm_ok);
        $display("ACCEPT            = %b", accept);
        $display("FAIL              = %b", fail);
        $display("RETRY             = %b", retry);
        $display("RETRY COUNT       = %0d", retry_count);
        $display("FINAL VALID SEEN  = %b", final_valid_seen);

        if ((basis_count == 512) &&
            (gram_count == 512) &&
            (target_count == 512) &&
            (ff_count == 512) &&
            (sign_count == 512) &&
            (norm_count == 512) &&
            (norm_ok == 1'b1) &&
            (accept == 1'b1) &&
            (fail == 1'b0) &&
            (final_valid_seen == 1'b1)) begin
            $display("VERSION 7 PASS: full wrapper integration completed");
        end else begin
            $display("VERSION 7 FAIL: basis=%0d gram=%0d target=%0d ff=%0d sign=%0d norm=%0d accept=%b fail=%b norm_ok=%b final_valid_seen=%b",
                     basis_count,
                     gram_count,
                     target_count,
                     ff_count,
                     sign_count,
                     norm_count,
                     accept,
                     fail,
                     norm_ok,
                     final_valid_seen);
        end

        $fclose(sign_csv);
        $fclose(norm_csv);
        $fclose(result_csv);

        $vcdplusoff;
        $finish;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) basis_count <= 0;
        else if (basis_valid) basis_count <= basis_count + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) gram_count <= 0;
        else if (gram_valid) gram_count <= gram_count + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) target_count <= 0;
        else if (target_valid) target_count <= target_count + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ff_count <= 0;
        else if (ff_valid) ff_count <= ff_count + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) sign_count <= 0;
        else if (sign_valid) sign_count <= sign_count + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) norm_count <= 0;
        else if (norm_valid) norm_count <= norm_count + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) final_valid_seen <= 1'b0;
        else if (final_valid) final_valid_seen <= 1'b1;
    end

    always @(posedge clk) begin
        if (sign_valid) begin
            $fwrite(sign_csv, "%0d,%0d,%0d\n",
                    sign_addr,
                    sig_s0,
                    sig_s1);
        end
    end

    always @(posedge clk) begin
        if (norm_valid) begin
            $fwrite(norm_csv, "%0d,%0d\n",
                    norm_addr,
                    norm_value);
        end
    end

    initial begin
        #70000000;
        $display("VERSION 7 TIMEOUT");

        $fclose(sign_csv);
        $fclose(norm_csv);
        $fclose(result_csv);

        $vcdplusoff;
        $finish;
    end

endmodule
