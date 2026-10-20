class coherence_env_config extends uvm_object;

  `uvm_object_utils(coherence_env_config)

int unsigned num_cores = 2;
  bit enable_coverage = 1;
  bit enable_scoreboard = 1;

function new(string name = "coherence_env_config");
    super.new(name);
  endfunction

endclass
