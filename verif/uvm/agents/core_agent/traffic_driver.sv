
class traffic_driver extends uvm_driver #(core_item);

  `uvm_component_utils(traffic_driver)

  uvm_analysis_port #(core_item) executed_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    executed_ap = new("executed_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    core_item tr;

    forever begin
      seq_item_port.get_next_item(tr);

      repeat (tr.delay_cycles)
        @(posedge vif.clk);

      // TODO:
      // Drive cpu_valid, cpu_write, cpu_addr and cpu_wdata.
      // Wait for cpu_ready and capture cpu_rdata.
      // Publish the completed transaction only after acceptance.

      `uvm_info(
        get_type_name(),
        $sformatf("CORE%0d %s addr=%08h data=%08h",
          tr.core_id,
          tr.write ? "WRITE" : "READ",
          tr.addr,
          tr.data),
        UVM_MEDIUM
      )

      tr.accepted = 1'b1;
      executed_ap.write(tr);

      seq_item_port.item_done();
    end
  endtask

  // Declare virtual interface vif and retrieve it using
  // uvm_config_db in build_phase before simulation.

endclass
