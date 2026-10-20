`timescale 1ns/1ps

module snoop_bus #(
  parameter int N_CORES = 2,
  parameter int ADDR_W  = 32,
  parameter int DATA_W  = 32
) (
  input  logic clk,
  input  logic reset_n,

input  logic [N_CORES-1:0] req_valid,
  input  logic [N_CORES-1:0] req_write,

input  logic [N_CORES-1:0][ADDR_W-1:0] req_addr,
  input  logic [N_CORES-1:0][DATA_W-1:0] req_wdata,

output logic bus_valid,
  output logic [$clog2(N_CORES)-1:0] bus_owner,

output logic [ADDR_W-1:0] bus_addr,
  output logic bus_write,
  output logic [DATA_W-1:0] bus_wdata
);

  integer i;

always_comb begin
    bus_valid = 1'b0;
    bus_owner = '0;
    bus_addr  = '0;
    bus_write = 1'b0;
    bus_wdata = '0;

// Fixed-priority arbitration.
    for (i = N_CORES-1; i >= 0; i = i-1) begin
      if (req_valid[i]) begin
        bus_valid = 1'b1;
        bus_owner = i[$clog2(N_CORES)-1:0];
        bus_addr  = req_addr[i];
        bus_write = req_write[i];
        bus_wdata = req_wdata[i];
      end
    end
  end

endmodule
