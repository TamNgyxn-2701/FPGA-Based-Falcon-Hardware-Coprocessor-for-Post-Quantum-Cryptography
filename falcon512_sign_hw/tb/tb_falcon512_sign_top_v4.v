`timescale 1ns/1ps

module tb_falcon512_sign_top_v4;

    reg clk;
    reg rst_n;
    reg start;

    wire busy;
    wire done;
    wire fail;
    wire [3:0] phase;

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

    integer basis_count;
    integer gram_count;
    integer target_count;
    integer ff_count;

    integer basis_csv;
    integer gram_csv;
    integer target_csv;
    integer sample_csv;

    falcon512_sign_top dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),

        .busy         (busy),
        .done         (done),
        .fail         (fail),
        .phase        (phase),

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
        .sample_z1    (sample_z1)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $vcdplusfile("v4_wave.vpd");
        $vcdpluson(0, tb_falcon512_sign_top_v4);

        $dumpfile("v4_wave.vcd");
        $dumpvars(0, tb_falcon512_sign_top_v4);

        basis_csv  = $fopen("basis_v4.csv", "w");
        gram_csv   = $fopen("gram_v4.csv", "w");
        target_csv = $fopen("target_v4.csv", "w");
        sample_csv = $fopen("sample_v4.csv", "w");

        if (basis_csv == 0) begin
            $display("ERROR: Cannot open basis_v4.csv");
            $finish;
        end

        if (gram_csv == 0) begin
            $display("ERROR: Cannot open gram_v4.csv");
            $finish;
        end

        if (target_csv == 0) begin
            $display("ERROR: Cannot open target_v4.csv");
            $finish;
        end

        if (sample_csv == 0) begin
            $display("ERROR: Cannot open sample_v4.csv");
            $finish;
        end

        $fwrite(basis_csv,  "index,b00,b01,b10,b11\n");
        $fwrite(gram_csv,   "index,gram00,gram01,gram10,gram11\n");
        $fwrite(target_csv, "index,t0,t1\n");
        $fwrite(sample_csv, "index,z0,z1\n");

        rst_n = 1'b0;
        start = 1'b0;

        basis_count = 0;
        gram_count = 0;
        target_count = 0;
        ff_count = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (2) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        @(posedge clk);

        if ((basis_count == 512) &&
            (gram_count == 512) &&
            (target_count == 512) &&
            (ff_count == 512) &&
            (fail == 1'b0)) begin
            $display("VERSION 4 PASS: basis_count=%0d gram_count=%0d target_count=%0d ff_count=%0d",
                     basis_count, gram_count, target_count, ff_count);
        end else begin
            $display("VERSION 4 FAIL: basis_count=%0d gram_count=%0d target_count=%0d ff_count=%0d fail=%b",
                     basis_count, gram_count, target_count, ff_count, fail);
        end

        $fclose(basis_csv);
        $fclose(gram_csv);
        $fclose(target_csv);
        $fclose(sample_csv);

        $vcdplusoff;
        $finish;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            basis_count <= 0;
        end else begin
            if (basis_valid) begin
                basis_count <= basis_count + 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gram_count <= 0;
        end else begin
            if (gram_valid) begin
                gram_count <= gram_count + 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            target_count <= 0;
        end else begin
            if (target_valid) begin
                target_count <= target_count + 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ff_count <= 0;
        end else begin
            if (ff_valid) begin
                ff_count <= ff_count + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (basis_valid) begin
            $fwrite(basis_csv, "%0d,%0d,%0d,%0d,%0d\n",
                    basis_addr, basis_b00, basis_b01, basis_b10, basis_b11);

            $display("basis[%0d]: b00=%0d b01=%0d b10=%0d b11=%0d",
                     basis_addr, basis_b00, basis_b01, basis_b10, basis_b11);
        end
    end

    always @(posedge clk) begin
        if (gram_valid) begin
            $fwrite(gram_csv, "%0d,%0d,%0d,%0d,%0d\n",
                    gram_addr, gram00, gram01, gram10, gram11);

            $display("gram[%0d]: g00=%0d g01=%0d g10=%0d g11=%0d",
                     gram_addr, gram00, gram01, gram10, gram11);
        end
    end

    always @(posedge clk) begin
        if (target_valid) begin
            $fwrite(target_csv, "%0d,%0d,%0d\n",
                    target_addr, target_t0, target_t1);

            $display("target[%0d]: t0=%0d t1=%0d",
                     target_addr, target_t0, target_t1);
        end
    end

    always @(posedge clk) begin
        if (ff_valid) begin
            $fwrite(sample_csv, "%0d,%0d,%0d\n",
                    ff_addr, sample_z0, sample_z1);

            $display("ffsample[%0d]: z0=%0d z1=%0d",
                     ff_addr, sample_z0, sample_z1);
        end
    end

    initial begin
        #40000000;
        $display("VERSION 4 TIMEOUT");

        $fclose(basis_csv);
        $fclose(gram_csv);
        $fclose(target_csv);
        $fclose(sample_csv);

        $vcdplusoff;
        $finish;
    end

endmodule
