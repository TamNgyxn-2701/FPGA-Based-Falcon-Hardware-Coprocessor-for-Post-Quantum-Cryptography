`timescale 1ns/1ps
`include "falcon512_params.v"

module falcon512_sign_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,

    output wire       busy,
    output wire       done,
    output wire       fail,
    output wire [3:0] phase,

    output wire       basis_valid,
    output wire [`ADDR_W-1:0] basis_addr,
    output wire signed [`COEFF_W-1:0] basis_b00,
    output wire signed [`COEFF_W-1:0] basis_b01,
    output wire signed [`COEFF_W-1:0] basis_b10,
    output wire signed [`COEFF_W-1:0] basis_b11,

    output wire       gram_valid,
    output wire [`ADDR_W-1:0] gram_addr,
    output wire signed [`GRAM_W-1:0] gram00,
    output wire signed [`GRAM_W-1:0] gram01,
    output wire signed [`GRAM_W-1:0] gram10,
    output wire signed [`GRAM_W-1:0] gram11,

    output wire       target_valid,
    output wire [`ADDR_W-1:0] target_addr,
    output wire signed [`TARGET_W-1:0] target_t0,
    output wire signed [`TARGET_W-1:0] target_t1,

    output wire       ff_valid,
    output wire [`ADDR_W-1:0] ff_addr,
    output wire signed [`SAMPLE_W-1:0] sample_z0,
    output wire signed [`SAMPLE_W-1:0] sample_z1,

    output wire       sign_valid,
    output wire [`ADDR_W-1:0] sign_addr,
    output wire signed [`SIGN_W-1:0] sig_s0,
    output wire signed [`SIGN_W-1:0] sig_s1,

    output wire       norm_valid,
    output wire [`ADDR_W-1:0] norm_addr,
    output wire [`NORM_W-1:0] norm_value,
    output wire       norm_ok
);

    wire basis_start;
    wire basis_done;

    wire gram_start;
    wire gram_done;

    wire target_start;
    wire target_done;
    wire target_busy;

    wire ff_start;
    wire ff_done;
    wire ff_busy;

    wire sign_start;
    wire sign_done;
    wire sign_busy;

    wire norm_start;
    wire norm_done;
    wire norm_busy;

    wire [`ADDR_W-1:0] key_addr;

    wire [`ADDR_W-1:0] basis_raddr_gram;
    wire [`ADDR_W-1:0] basis_raddr_target;
    wire [`ADDR_W-1:0] basis_raddr_sign;
    wire [`ADDR_W-1:0] basis_raddr_mux;

    wire [`ADDR_W-1:0] hm_raddr;

    wire [`ADDR_W-1:0] target_raddr_ff;
    wire [`ADDR_W-1:0] target_raddr_sign;
    wire [`ADDR_W-1:0] target_raddr_mux;

    wire [`ADDR_W-1:0] sample_raddr_sign;

    wire [`ADDR_W-1:0] signature_raddr_norm;

    wire signed [`COEFF_W-1:0] f_q;
    wire signed [`COEFF_W-1:0] g_q;
    wire signed [`COEFF_W-1:0] F_q;
    wire signed [`COEFF_W-1:0] G_q;

    wire signed [`COEFF_W-1:0] basis_r_b00;
    wire signed [`COEFF_W-1:0] basis_r_b01;
    wire signed [`COEFF_W-1:0] basis_r_b10;
    wire signed [`COEFF_W-1:0] basis_r_b11;

    wire signed [`HM_W-1:0] hm_q;

    wire signed [`TARGET_W-1:0] target_r_t0;
    wire signed [`TARGET_W-1:0] target_r_t1;

    wire signed [`SAMPLE_W-1:0] sample_r_z0;
    wire signed [`SAMPLE_W-1:0] sample_r_z1;

    wire signed [`SIGN_W-1:0] signature_r_s0;
    wire signed [`SIGN_W-1:0] signature_r_s1;

    assign basis_raddr_mux =
        sign_busy   ? basis_raddr_sign   :
        target_busy ? basis_raddr_target :
                      basis_raddr_gram;

    assign target_raddr_mux =
        sign_busy ? target_raddr_sign :
                    target_raddr_ff;

    sign_main_ctrl u_sign_main_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),

        .basis_done   (basis_done),
        .basis_start  (basis_start),

        .gram_done    (gram_done),
        .gram_start   (gram_start),

        .target_done  (target_done),
        .target_start (target_start),

        .ff_done      (ff_done),
        .ff_start     (ff_start),

        .sign_done    (sign_done),
        .sign_start   (sign_start),

        .norm_done    (norm_done),
        .norm_ok      (norm_ok),
        .norm_start   (norm_start),

        .busy         (busy),
        .done         (done),
        .fail         (fail),
        .phase        (phase)
    );

    key_ram u_key_ram (
        .raddr (key_addr),
        .f_q   (f_q),
        .g_q   (g_q),
        .F_q   (F_q),
        .G_q   (G_q)
    );

    hm_ram u_hm_ram (
        .raddr (hm_raddr),
        .hm_q  (hm_q)
    );

    basis_build_ctrl u_basis_build_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (basis_start),

        .busy       (),
        .done       (basis_done),
        .valid      (basis_valid),

        .key_addr   (key_addr),

        .f_in       (f_q),
        .g_in       (g_q),
        .F_in       (F_q),
        .G_in       (G_q),

        .basis_addr (basis_addr),
        .b00        (basis_b00),
        .b01        (basis_b01),
        .b10        (basis_b10),
        .b11        (basis_b11)
    );

    basis_ram u_basis_ram (
        .clk    (clk),

        .we     (basis_valid),
        .waddr  (basis_addr),

        .w_b00  (basis_b00),
        .w_b01  (basis_b01),
        .w_b10  (basis_b10),
        .w_b11  (basis_b11),

        .raddr  (basis_raddr_mux),

        .r_b00  (basis_r_b00),
        .r_b01  (basis_r_b01),
        .r_b10  (basis_r_b10),
        .r_b11  (basis_r_b11)
    );

    gram_build_ctrl u_gram_build_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (gram_start),

        .busy        (),
        .done        (gram_done),
        .valid       (gram_valid),

        .basis_raddr (basis_raddr_gram),
        .gram_addr   (gram_addr),

        .b00_in      (basis_r_b00),
        .b01_in      (basis_r_b01),
        .b10_in      (basis_r_b10),
        .b11_in      (basis_r_b11),

        .gram00      (gram00),
        .gram01      (gram01),
        .gram10      (gram10),
        .gram11      (gram11)
    );

    target_build_ctrl u_target_build_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (target_start),

        .busy        (target_busy),
        .done        (target_done),
        .valid       (target_valid),

        .basis_raddr (basis_raddr_target),
        .hm_raddr    (hm_raddr),
        .target_addr (target_addr),

        .b01_in      (basis_r_b01),
        .b11_in      (basis_r_b11),
        .hm_in       (hm_q),

        .target_t0   (target_t0),
        .target_t1   (target_t1)
    );

    target_ram u_target_ram (
        .clk    (clk),

        .we     (target_valid),
        .waddr  (target_addr),

        .w_t0   (target_t0),
        .w_t1   (target_t1),

        .raddr  (target_raddr_mux),

        .r_t0   (target_r_t0),
        .r_t1   (target_r_t1)
    );

    ff_sampling_ctrl u_ff_sampling_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (ff_start),

        .busy         (ff_busy),
        .done         (ff_done),
        .valid        (ff_valid),

        .target_raddr (target_raddr_ff),
        .sample_addr  (ff_addr),

        .target_t0_in (target_r_t0),
        .target_t1_in (target_r_t1),

        .sample_z0    (sample_z0),
        .sample_z1    (sample_z1)
    );

    sample_ram u_sample_ram (
        .clk    (clk),

        .we     (ff_valid),
        .waddr  (ff_addr),

        .w_z0   (sample_z0),
        .w_z1   (sample_z1),

        .raddr  (sample_raddr_sign),

        .r_z0   (sample_r_z0),
        .r_z1   (sample_r_z1)
    );

    sign_compute_ctrl u_sign_compute_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (sign_start),

        .busy         (sign_busy),
        .done         (sign_done),
        .valid        (sign_valid),

        .basis_raddr  (basis_raddr_sign),
        .target_raddr (target_raddr_sign),
        .sample_raddr (sample_raddr_sign),
        .sign_addr    (sign_addr),

        .b00_in       (basis_r_b00),
        .b01_in       (basis_r_b01),
        .b10_in       (basis_r_b10),
        .b11_in       (basis_r_b11),

        .target_t0_in (target_r_t0),
        .target_t1_in (target_r_t1),

        .sample_z0_in (sample_r_z0),
        .sample_z1_in (sample_r_z1),

        .sig_s0       (sig_s0),
        .sig_s1       (sig_s1)
    );

    signature_ram u_signature_ram (
        .clk    (clk),

        .we     (sign_valid),
        .waddr  (sign_addr),

        .w_s0   (sig_s0),
        .w_s1   (sig_s1),

        .raddr  (signature_raddr_norm),

        .r_s0   (signature_r_s0),
        .r_s1   (signature_r_s1)
    );

    norm_check_ctrl u_norm_check_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (norm_start),

        .busy       (norm_busy),
        .done       (norm_done),
        .valid      (norm_valid),

        .sign_raddr (signature_raddr_norm),
        .norm_addr  (norm_addr),

        .sig_s0_in  (signature_r_s0),
        .sig_s1_in  (signature_r_s1),

        .norm_value (norm_value),
        .norm_ok    (norm_ok)
    );

endmodule
