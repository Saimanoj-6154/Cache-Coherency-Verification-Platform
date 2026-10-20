
`timescale 1ns/1ps

module cache_core #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32
) (
  input logic clk,
  input logic reset_n,

  input logic cpu_valid,
  input logic cpu_write,
  input logic [ADDR_W-1:0] cpu_addr,
  input logic [DATA_W-1:0] cpu_wdata,

  output logic cpu_ready,
  output logic [DATA_W-1:0] cpu_rdata,

  input logic snoop_valid,
  input logic snoop_write,
  input logic [ADDR_W-1:0] snoop_addr,

  output logic bus_req,
  output logic bus_req_write,
  output logic [ADDR_W-1:0] bus_req_addr,
  output logic [DATA_W-1:0] bus_req_wdata,

  output logic [1:0] state_dbg
);

  import coherence_pkg::*;

  mesi_state_e state_q;

  logic [ADDR_W-1:0] tag_q;
  logic [DATA_W-1:0] data_q;
  logic valid_q;

  logic hit;

  assign hit = valid_q && (tag_q == cpu_addr);

  assign state_dbg = state_q;

  assign bus_req =
      cpu_valid &&
      (!hit || (cpu_write && state_q == MESI_S));

  assign bus_req_write = cpu_write;
  assign bus_req_addr  = cpu_addr;
  assign bus_req_wdata = cpu_wdata;

  always_comb begin
    cpu_ready = 1'b0;
    cpu_rdata = '0;

    if (cpu_valid && hit &&
        (!cpu_write ||
         state_q == MESI_M ||
         state_q == MESI_E)) begin

      cpu_ready = 1'b1;
      cpu_rdata = data_q;
    end
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_q <= MESI_I;
      tag_q   <= '0;
      data_q  <= '0;
      valid_q <= 1'b0;
    end
    else begin

      if (snoop_valid && valid_q &&
          tag_q == snoop_addr && snoop_write) begin
        state_q <= MESI_I;
        valid_q <= 1'b0;
      end

      if (cpu_valid && hit && cpu_write &&
          (state_q == MESI_M ||
           state_q == MESI_E)) begin
        data_q  <= cpu_wdata;
        state_q <= MESI_M;
      end

      if (cpu_valid && !hit) begin
        // Placeholder refill. Replace with a real bus response.
        tag_q   <= cpu_addr;
        valid_q <= 1'b1;
        data_q  <= '0;
        state_q <= MESI_E;
      end
    end
  end

endmodule
