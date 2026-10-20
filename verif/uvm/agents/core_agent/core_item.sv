`ifndef CORE_ITEM_SV
`define CORE_ITEM_SV

class core_item extends uvm_sequence_item;

rand int unsigned core_id;
  rand bit write;
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand int unsigned delay_cycles;

bit [31:0] observed_data;
  bit accepted;

constraint c_core {
    core_id inside {[0:1]};
  }

constraint c_align {
    addr[1:0] == 2'b00;
  }

constraint c_delay {
    delay_cycles inside {[0:5]};
  }

`uvm_object_utils_begin(core_item)
    `uvm_field_int(core_id, UVM_ALL_ON)
    `uvm_field_int(write, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(delay_cycles, UVM_ALL_ON)
    `uvm_field_int(observed_data, UVM_ALL_ON)
    `uvm_field_int(accepted, UVM_ALL_ON)
  `uvm_object_utils_end

function new(string name = "core_item");
    super.new(name);
  endfunction

endclass

`endif
