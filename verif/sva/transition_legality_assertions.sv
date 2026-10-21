
`timescale 1ns/1ps

module transition_legality_assertions (
    input logic       clk,
    input logic       reset_n,

    input logic [1:0] state,
    input logic       transition_valid
);

    property p_known_state;
        @(posedge clk)
        disable iff (!reset_n)
        !$isunknown(state);
    endproperty

    a_known_state:
        assert property (p_known_state)
        else $error(
            "Unknown or X value detected in MESI state"
        );

    // All four 2-bit encodings are valid MESI states.
    // Add event-specific assertions for BusRd, BusRdX,
    // local writes, and snoop-induced state transitions.

endmodule
