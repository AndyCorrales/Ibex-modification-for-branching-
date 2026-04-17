/**
 * Dynamic Branch Predictor — 2-bit Saturating Counter BHT
 *
 * Implementa un predictor dinámico con una Branch History Table (BHT)
 * de 64 entradas. Cada entrada contiene un contador de 2 bits:
 *
 *   2'b00 = Strongly Not Taken
 *   2'b01 = Weakly Not Taken
 *   2'b10 = Weakly Taken
 *   2'b11 = Strongly Taken
 *
 * Predicción:  counter[1] == 1 → Taken
 * Índice BHT:  fetch_pc_i[7:2]  (6 bits → 64 entradas)
 *
 * Para jumps (JAL/C.JAL/C.J) siempre predice Taken (igual que el estático).
 * Para branches condicionales usa la BHT.
 * JALR no se predice (target desconocido en IF).
 *
 * Interfaz idéntica a ibex_branch_predict más puertos de actualización.
 */

`include "prim_assert.sv"

module ibex_branch_predict_dynamic (
  input  logic        clk_i,
  input  logic        rst_ni,

  // ── Instrucción desde fetch stage ──────────────────────────────────────
  input  logic [31:0] fetch_rdata_i,
  input  logic [31:0] fetch_pc_i,
  input  logic        fetch_valid_i,

  // ── Predicción para la instrucción actual ──────────────────────────────
  output logic        predict_branch_taken_o,
  output logic [31:0] predict_branch_pc_o,

  // ── Feedback desde ID/EX: resultado real del branch ────────────────────
  // Estos puertos no existen en el predictor estático.
  // Se activan un ciclo después de que el branch se resuelve en EX.
  input  logic        branch_update_valid_i,   // resultado válido este ciclo
  input  logic [31:0] branch_update_pc_i,      // PC del branch resuelto
  input  logic        branch_update_taken_i    // 1=taken, 0=not taken
);

  import ibex_pkg::*;

  // ── Parámetros de la BHT ───────────────────────────────────────────────
  localparam int unsigned BHT_SIZE     = 64;   // número de entradas
  localparam int unsigned BHT_ADDR_W   = 6;    // log2(64) = 6 bits de índice

  // ── Branch History Table ───────────────────────────────────────────────
  // 64 entradas × 2 bits = 128 bits de estado total
  logic [1:0] bht_q [BHT_SIZE];   // estado actual (registrado)
  logic [1:0] bht_d [BHT_SIZE];   // próximo estado (combinacional)

  // ── Decodificación de la instrucción (igual que el estático) ──────────
  logic [31:0] imm_j_type;
  logic [31:0] imm_b_type;
  logic [31:0] imm_cj_type;
  logic [31:0] imm_cb_type;
  logic [31:0] branch_imm;
  logic [31:0] instr;

  logic instr_j;    // JAL (uncompressed)
  logic instr_b;    // BRANCH (uncompressed: beq, bne, blt, bge...)
  logic instr_cj;   // C.JAL / C.J (compressed jump)
  logic instr_cb;   // C.BEQZ / C.BNEZ (compressed branch)

  assign instr = fetch_rdata_i;

  // Extrae y sign-extend los inmediatos de cada tipo de instrucción
  assign imm_j_type  = { {12{instr[31]}}, instr[19:12], instr[20],
                          instr[30:21], 1'b0 };
  assign imm_b_type  = { {19{instr[31]}}, instr[31], instr[7],
                          instr[30:25], instr[11:8], 1'b0 };
  assign imm_cj_type = { {20{instr[12]}}, instr[12], instr[8], instr[10:9],
                          instr[6], instr[7], instr[2], instr[11],
                          instr[5:3], 1'b0 };
  assign imm_cb_type = { {23{instr[12]}}, instr[12], instr[6:5], instr[2],
                          instr[11:10], instr[4:3], 1'b0 };

  // Detecta el tipo de instrucción
  assign instr_b  = opcode_e'(instr[6:0]) == OPCODE_BRANCH;
  assign instr_j  = opcode_e'(instr[6:0]) == OPCODE_JAL;
  assign instr_cb = (instr[1:0] == 2'b01) &
                    ((instr[15:13] == 3'b110) | (instr[15:13] == 3'b111));
  assign instr_cj = (instr[1:0] == 2'b01) &
                    ((instr[15:13] == 3'b101) | (instr[15:13] == 3'b001));

  // Selecciona el inmediato correcto para calcular el target
  always_comb begin
    branch_imm = imm_b_type;
    unique case (1'b1)
      instr_j  : branch_imm = imm_j_type;
      instr_b  : branch_imm = imm_b_type;
      instr_cj : branch_imm = imm_cj_type;
      instr_cb : branch_imm = imm_cb_type;
      default  : ;
    endcase
  end

  // ── Índices en la BHT ─────────────────────────────────────────────────
  // Usamos los bits [7:2] del PC → ignora los 2 LSBs (instrucciones
  // alineadas a 2 bytes mínimo) y usa 6 bits → 64 entradas
  logic [BHT_ADDR_W-1:0] fetch_idx;
  logic [BHT_ADDR_W-1:0] update_idx;

  assign fetch_idx  = fetch_pc_i[BHT_ADDR_W+1:2];
  assign update_idx = branch_update_pc_i[BHT_ADDR_W+1:2];

  // ── Predicción: consulta la BHT ───────────────────────────────────────
  // El bit[1] del contador es la predicción:
  //   counter >= 2'b10 → Taken
  //   counter <= 2'b01 → Not Taken
  logic bht_taken;
  assign bht_taken = bht_q[fetch_idx][1];

  // Para jumps incondicionales siempre Taken (el target ya lo calculamos)
  // Para branches condicionales usamos la BHT
  // JALR no se puede predecir (target = rs1 + imm, desconocido en IF)
  assign predict_branch_taken_o = fetch_valid_i &
                                   (instr_j | instr_cj |
                                    ((instr_b | instr_cb) & bht_taken));

  // Target: PC + offset (igual que el estático)
  assign predict_branch_pc_o = fetch_pc_i + branch_imm;

  // ── Update: actualiza la BHT con el resultado real ────────────────────
  // Lógica del contador saturante de 2 bits:
  //   Taken    → incrementa hasta 2'b11 (Strongly Taken)
  //   Not Taken → decrementa hasta 2'b00 (Strongly Not Taken)
  always_comb begin
    // Por defecto mantiene todos los valores
    bht_d = bht_q;

    if (branch_update_valid_i) begin
      if (branch_update_taken_i) begin
        // Taken: incrementa saturando en 11
        bht_d[update_idx] = (bht_q[update_idx] == 2'b11) ?
                             2'b11 : bht_q[update_idx] + 2'b01;
      end else begin
        // Not Taken: decrementa saturando en 00
        bht_d[update_idx] = (bht_q[update_idx] == 2'b00) ?
                             2'b00 : bht_q[update_idx] - 2'b01;
      end
    end
  end

  // ── Registros de la BHT ───────────────────────────────────────────────
  // En reset inicializa todos los contadores a Weakly Not Taken (2'b01)
  // para un comportamiento conservador al arranque
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < BHT_SIZE; i++) begin
        bht_q[i] <= 2'b01;  // Weakly Not Taken
      end
    end else begin
      bht_q <= bht_d;
    end
  end

  // ── Assertions ────────────────────────────────────────────────────────
  `ASSERT_IF(BranchInsTypeOneHot,
    $onehot0({instr_j, instr_b, instr_cj, instr_cb}), fetch_valid_i)

endmodule