`timescale 1ns/1ps
`include "falcon512_params.v"

module falcon512_sign_wrapper_v7 (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output wire busy,
    output wire done,
    output wire fail,
    output wire [3:0] phase,

    output reg  accept,
    output reg  retry,
    output reg  final_valid,
    output reg  [3:0] retry_count,

    output wire basis_valid,
    output wire [`ADDR_W-1:0] basis_addr,
    output wire signed [`COEFF_W-1:0] basis_b00,
    output wire signed [`COEFF_W-1:0] basis_b01,
    output wire signed [`COEFF_W-1:0] basis_b10,
    output wire signed [`COEFF_W-1:0] basis_b11,

    output wire gram_valid,
    output wire [`ADDR_W-1:0] gram_addr,
    output wire signed [`GRAM_W-1:0] gram00,
    output wire signed [`GRAM_W-1:0] gram01,
    output wire signed [`GRAM_W-1:0] gram10,
    output wire signed [`GRAM_W-1:0] gram11,

    output wire target_valid,
    output wire [`ADDR_W-1:0] target_addr,
    output wire signed [`TARGET_W-1:0] target_t0,
    output wire signed [`TARGET_W-1:0] target_t1,

    output wire ff_valid,
    output wire [`ADDR_W-1:0] ff_addr,
    output wire signed [`SAMPLE_W-1:0] sample_z0,
    output wire signed [`SAMPLE_W-1:0] sample_z1,

    output wire sign_valid,
    output wire [`ADDR_W-1:0] sign_addr,
    output wire signed [`SIGN_W-1:0] sig_s0,
    output wire signed [`SIGN_W-1:0] sig_s1,

    output wire norm_valid,
    output wire [`ADDR_W-1:0] norm_addr,
    output wire [`NORM_W-1:0] norm_value,
    output wire norm_ok
);

    falcon512_sign_top u_core (
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

    /*
        Version 7 wrapper skeleton:

        Nếu core done và norm_ok = 1:
            accept = 1
            final_valid = 1

        Nếu core done nhưng norm_ok = 0 hoặc fail = 1:
            retry = 1
            retry_count tăng lên

        Đây mới là retry placeholder, chưa tự chạy lại toàn bộ signing.
    */

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accept      <= 1'b0;
            retry       <= 1'b0;
            final_valid <= 1'b0;
            retry_count <= 4'd0;
        end else begin
            final_valid <= 1'b0;
            retry       <= 1'b0;

            if (start) begin
                accept      <= 1'b0;
                retry       <= 1'b0;
                final_valid <= 1'b0;
                retry_count <= 4'd0;
            end else begin
                if (done) begin
                    if ((fail == 1'b0) && (norm_ok == 1'b1)) begin
                        accept      <= 1'b1;
                        retry       <= 1'b0;
                        final_valid <= 1'b1;
                    end else begin
                        accept      <= 1'b0;
                        retry       <= 1'b1;
                        final_valid <= 1'b0;

                        if (retry_count != 4'hF) begin
                            retry_count <= retry_count + 1'b1;
                        end
                    end
                end
            end
        end
    end

endmodule
