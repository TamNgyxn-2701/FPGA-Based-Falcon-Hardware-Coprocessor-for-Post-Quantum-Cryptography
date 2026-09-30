`timescale 1ns/1ps
`include "falcon512_params.v"

module hm_ram (
    input  wire [`ADDR_W-1:0] raddr,
    output reg  signed [`HM_W-1:0] hm_q
);

    reg [`HM_W-1:0] hm_mem [0:`FALCON_N-1];

    initial begin
        $readmemh("/home/ltk/FALCON/hardware_controller_falcon/falcon512_sign_hw/vectors/input_hm/hm.memh", hm_mem);
    end

    always @(*) begin
        hm_q = hm_mem[raddr];
    end

endmodule
