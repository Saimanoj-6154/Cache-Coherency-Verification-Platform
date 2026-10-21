module invalid_no_data_assertions (
    input logic       clk,
    input logic       reset_n,

input logic       valid_core0,
    input logic       valid_core1,

input logic [1:0] state_core0,
    input logic [1:0] state_core1
);

    localparam logic [1:0] MESI_I = 2'b00;

property p_invalid_not_valid_core0;
        @(posedge clk)
        disable iff (!reset_n)
        (state_core0 == MESI_I) |-> !valid_core0;
    endproperty

property p_invalid_not_valid_core1;
        @(posedge clk)
        disable iff (!reset_n)
        (state_core1 == MESI_I) |-> !valid_core1;
    endproperty

a_invalid_core0:
        assert property (p_invalid_not_valid_core0)
        else $error(
            "Core 0: Invalid cache line marked valid"
        );

a_invalid_core1:
        assert property (p_invalid_not_valid_core1)
        else $error(
            "Core 1: Invalid cache line marked valid"
        );

endmodule
