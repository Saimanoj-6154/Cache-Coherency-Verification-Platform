
class bus_monitor extends uvm_component;

  `uvm_component_utils(bus_monitor)

  uvm_analysis_port #(core_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  // TODO:
  // Sample accepted bus transactions and snoop responses.
  // Publish observed events through ap.write(transaction).

endclass
