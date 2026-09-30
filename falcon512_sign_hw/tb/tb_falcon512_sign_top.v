`timescale 1ns/1ps

module tb_falcon512_sign_top;

    reg clk;
    reg rst_n;
    reg start;

    wire busy;
    wire done;
    wire fail;
    wire [3:0] phase;

    falcon512_sign_top dut (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .busy  (busy),
        .done  (done),
        .fail  (fail),
        .phase (phase)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("sim/v0_wave.vcd");
        $dumpvars(0, tb_falcon512_sign_top);

        rst_n = 1'b0;
        start = 1'b0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (2) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        @(posedge clk);

        if (fail == 1'b0) begin
            $display("VERSION 0 PASS: skeleton top/control compile and run OK");
        end else begin
            $display("VERSION 0 FAIL");
        end

        $finish;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            $display("time=%0t start=%b busy=%b done=%b fail=%b phase=%0d",
                     $time, start, busy, done, fail, phase);
        end
    end

endmodule