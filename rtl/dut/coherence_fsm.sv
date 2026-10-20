
`timescale 1ns/1ps

package coherence_pkg;

  typedef enum logic [1:0] {
    MESI_I = 2'b00,
    MESI_S = 2'b01,
    MESI_E = 2'b10,
    MESI_M = 2'b11
  } mesi_state_e;

  typedef enum logic [1:0] {
    BUS_NONE = 2'b00,
    BUS_RD   = 2'b01,
    BUS_RDX  = 2'b10,
    BUS_WB   = 2'b11
  } bus_cmd_e;

endpackage


module coherence_fsm (
  input  logic clk,
  input  logic reset_n,

  input  logic local_read,
  input  logic local_write,

  input  logic snoop_rd,
  input  logic snoop_rdx,

  output coherence_pkg::mesi_state_e state
);

  import coherence_pkg::*;

  mesi_state_e state_q, state_d;

  always_comb begin
    state_d = state_q;

    if (snoop_rdx) begin
      state_d = MESI_I;
    end
    else if (snoop_rd &&
             (state_q == MESI_M ||
              state_q == MESI_E)) begin
      state_d = MESI_S;
    end
    else if (local_write) begin
      case (state_q)
        MESI_I: state_d = MESI_M;
        MESI_S: state_d = MESI_M;
        MESI_E: state_d = MESI_M;
        MESI_M: state_d = MESI_M;
        default: state_d = MESI_I;
      endcase
    end
    else if (local_read && state_q == MESI_I) begin
      state_d = MESI_E;
    end
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      state_q <= MESI_I;
    else
      state_q <= state_d;
  end

  assign state = state_q;

endmodule
