`timescale 1ns/1ps

module tb_falcon512_sign_top_v1;

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

    integer basis_count;
    integer basis_csv;

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
        .basis_b11   (basis_b11)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("v1_wave.vcd");
        $dumpvars(0, tb_falcon512_sign_top_v1);

        basis_csv = $fopen("basis_v1.csv", "w");

        if (basis_csv == 0) begin
            $display("ERROR: Cannot open basis_v1.csv");
            $finish;
        end

        $fwrite(basis_csv, "index,b00_g,b01_neg_f,b10_G,b11_neg_F\n");

        rst_n = 1'b0;
        start = 1'b0;
        basis_count = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (2) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        @(posedge clk);

        if ((basis_count == 512) && (fail == 1'b0)) begin
            $display("VERSION 1 PASS: basis build completed, basis_count = %0d", basis_count);
        end else begin
            $display("VERSION 1 FAIL: basis_count = %0d fail = %b", basis_count, fail);
        end

        $fclose(basis_csv);
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

    always @(posedge clk) begin
        if (basis_valid) begin
            $fwrite(basis_csv, "%0d,%0d,%0d,%0d,%0d\n",
                    basis_addr, basis_b00, basis_b01, basis_b10, basis_b11);

            if (basis_addr < 512) begin
                $display("basis[%0d]: b00=g=%0d b01=-f=%0d b10=G=%0d b11=-F=%0d",
                         basis_addr, basis_b00, basis_b01, basis_b10, basis_b11);
            end
        end
    end

endmodule
