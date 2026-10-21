
`timescale 1ns/1ps

module single_writer_assertions (
    input logic       clk,
    input logic       reset_n,
    input logic [1:0] state_core0,
    input logic [1:0] state_core1
);

    localparam logic [1:0] MESI_M = 2'b11;

    property p_single_writer;
        @(posedge clk)
        disable iff (!reset_n)
        !((state_core0 == MESI_M) &&
          (state_core1 == MESI_M));
    endproperty

    a_single_writer:
        assert property (p_single_writer)
        else $error(
            "MESI violation: both cores hold Modified state"
        );

endmodule
