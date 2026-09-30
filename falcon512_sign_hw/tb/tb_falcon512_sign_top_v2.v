`timescale 1ns/1ps

module tb_falcon512_sign_top_v2;

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

    integer basis_count;
    integer gram_count;

    integer basis_csv;
    integer gram_csv;

    falcon512_sign_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),

        .busy        (busy),
        .done        (done),
        .fail        (fail),
        .phase       (phase),

        .basis_valid (basis_valid),
        .basis_addr  (basis_addr),
        .basis_b00   (basis_b00),
        .basis_b01   (basis_b01),
        .basis_b10   (basis_b10),
        .basis_b11   (basis_b11),

        .gram_valid  (gram_valid),
        .gram_addr   (gram_addr),
        .gram00      (gram00),
        .gram01      (gram01),
        .gram10      (gram10),
        .gram11      (gram11)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $vcdplusfile("v2_wave.vpd");
        $vcdpluson(0, tb_falcon512_sign_top_v2);

        $dumpfile("v2_wave.vcd");
        $dumpvars(0, tb_falcon512_sign_top_v2);

        basis_csv = $fopen("basis_v2.csv", "w");
        gram_csv  = $fopen("gram_v2.csv", "w");

        if (basis_csv == 0) begin
            $display("ERROR: Cannot open basis_v2.csv");
            $finish;
        end

        if (gram_csv == 0) begin
            $display("ERROR: Cannot open gram_v2.csv");
            $finish;
        end

        $fwrite(basis_csv, "index,b00,b01,b10,b11\n");
        $fwrite(gram_csv,  "index,gram00,gram01,gram10,gram11\n");

        rst_n = 1'b0;
        start = 1'b0;
        basis_count = 0;
        gram_count = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (2) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        @(posedge clk);

        if ((basis_count == 512) && (gram_count == 512) && (fail == 1'b0)) begin
            $display("VERSION 2 PASS: basis_count = %0d, gram_count = %0d",
                     basis_count, gram_count);
        end else begin
            $display("VERSION 2 FAIL: basis_count = %0d, gram_count = %0d, fail = %b",
                     basis_count, gram_count, fail);
        end

        $fclose(basis_csv);
        $fclose(gram_csv);

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

    always @(posedge clk) begin
        if (basis_valid) begin
            $fwrite(basis_csv, "%0d,%0d,%0d,%0d,%0d\n",
                    basis_addr,
                    basis_b00,
                    basis_b01,
                    basis_b10,
                    basis_b11);

            $display("basis[%0d]: b00=%0d b01=%0d b10=%0d b11=%0d",
                     basis_addr,
                     basis_b00,
                     basis_b01,
                     basis_b10,
                     basis_b11);
        end
    end

    always @(posedge clk) begin
        if (gram_valid) begin
            $fwrite(gram_csv, "%0d,%0d,%0d,%0d,%0d\n",
                    gram_addr,
                    gram00,
                    gram01,
                    gram10,
                    gram11);

            $display("gram[%0d]: g00=%0d g01=%0d g10=%0d g11=%0d",
                     gram_addr,
                     gram00,
                     gram01,
                     gram10,
                     gram11);
        end
    end

    initial begin
        #20000000;
        $display("VERSION 2 TIMEOUT");

        $fclose(basis_csv);
        $fclose(gram_csv);

        $vcdplusoff;
        $finish;
    end

endmodule
