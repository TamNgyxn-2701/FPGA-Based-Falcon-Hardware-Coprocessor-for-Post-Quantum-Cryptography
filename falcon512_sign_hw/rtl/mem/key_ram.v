`timescale 1ns/1ps
`include "falcon512_params.v"

module key_ram (
    input  wire [`ADDR_W-1:0] raddr,

    output reg signed [`COEFF_W-1:0] f_q,
    output reg signed [`COEFF_W-1:0] g_q,
    output reg signed [`COEFF_W-1:0] F_q,
    output reg signed [`COEFF_W-1:0] G_q
);

    reg [7:0] f_mem [0:`FALCON_N-1];
    reg [7:0] g_mem [0:`FALCON_N-1];
    reg [7:0] F_mem [0:`FALCON_N-1];
    reg [7:0] G_mem [0:`FALCON_N-1];

    initial begin
        $readmemh("/home/ltk/FALCON/hardware_controller_falcon/falcon512_sign_hw/vectors/input_key/f_small.memh", f_mem);
        $readmemh("/home/ltk/FALCON/hardware_controller_falcon/falcon512_sign_hw/vectors/input_key/g_small.memh", g_mem);
        $readmemh("/home/ltk/FALCON/hardware_controller_falcon/falcon512_sign_hw/vectors/input_key/F_big.memh", F_mem);
        $readmemh("/home/ltk/FALCON/hardware_controller_falcon/falcon512_sign_hw/vectors/input_key/G_big.memh", G_mem);
    end

    always @(*) begin
        f_q = {{8{f_mem[raddr][7]}}, f_mem[raddr]};
        g_q = {{8{g_mem[raddr][7]}}, g_mem[raddr]};
        F_q = {{8{F_mem[raddr][7]}}, F_mem[raddr]};
        G_q = {{8{G_mem[raddr][7]}}, G_mem[raddr]};
    end

endmodule
