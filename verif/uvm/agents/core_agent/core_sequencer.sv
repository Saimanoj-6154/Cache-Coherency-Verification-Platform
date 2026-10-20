class core_sequencer extends uvm_sequencer #(core_item);

  `uvm_component_utils(core_sequencer)

function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
