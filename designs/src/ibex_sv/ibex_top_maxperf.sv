module ibex_top_maxperf (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_en_i,
  input  logic [31:0] hart_id_i,
  input  logic [31:0] boot_addr_i,

  input  logic fetch_enable_i,

  // instruction interface
  output logic instr_req_o,
  input  logic instr_gnt_i,
  input  logic instr_rvalid_i,
  output logic [31:0] instr_addr_o,
  input  logic [31:0] instr_rdata_i,
  input  logic instr_err_i,

  // data interface
  output logic data_req_o,
  input  logic data_gnt_i,
  input  logic data_rvalid_i,
  output logic data_we_o,
  output logic [3:0] data_be_o,
  output logic [31:0] data_addr_o,
  output logic [31:0] data_wdata_o,
  input  logic [31:0] data_rdata_i,
  input  logic data_err_i,

  // interrupts
  input logic irq_software_i,
  input logic irq_timer_i,
  input logic irq_external_i,
  input logic [14:0] irq_fast_i,
  input logic irq_nm_i,

  input logic debug_req_i,

  output logic alert_minor_o,
  output logic alert_major_o,
  output logic core_sleep_o
);

  ibex_core #(
    .RV32E           (1'b0),
    .RV32M           (ibex_pkg::RV32MSingleCycle),
    .RV32B           (ibex_pkg::RV32BFull),

    .BranchTargetALU (1'b1),
    .WritebackStage  (1'b1),
    .BranchPredictor (1'b1),

    .PMPEnable       (1'b1),
    .PMPNumRegions   (16)
  ) u_ibex (
    .*
  );

endmodule
