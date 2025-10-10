--Dylan Kramer
--ISA Package to make sure we don't mess up using constants and cause bugs!

library ieee;
use ieee.std_logic_1164.all;

package isa_pkg is
  -- RV32I opcodes (7-bit)
  constant OPC_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OPC_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
  constant OPC_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OPC_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OPC_BRANCH : std_logic_vector(6 downto 0) := "1100011";
  constant OPC_LOAD   : std_logic_vector(6 downto 0) := "0000011";
  constant OPC_STORE  : std_logic_vector(6 downto 0) := "0100011";
  constant OPC_OPIMM  : std_logic_vector(6 downto 0) := "0010011";
  constant OPC_OP     : std_logic_vector(6 downto 0) := "0110011";
  constant OPC_SYSTEM : std_logic_vector(6 downto 0) := "1110011";

  -- funct3 (branches)
  constant F3_BEQ  : std_logic_vector(2 downto 0) := "000";
  constant F3_BNE  : std_logic_vector(2 downto 0) := "001";
  constant F3_BLT  : std_logic_vector(2 downto 0) := "100";
  constant F3_BGE  : std_logic_vector(2 downto 0) := "101";
  constant F3_BLTU : std_logic_vector(2 downto 0) := "110";
  constant F3_BGEU : std_logic_vector(2 downto 0) := "111";

  -- funct3 (loads)
  constant F3_LB   : std_logic_vector(2 downto 0) := "000";
  constant F3_LH   : std_logic_vector(2 downto 0) := "001";
  constant F3_LW   : std_logic_vector(2 downto 0) := "010";
  constant F3_LBU  : std_logic_vector(2 downto 0) := "100";
  constant F3_LHU  : std_logic_vector(2 downto 0) := "101";

  -- funct3 (stores)
  constant F3_SB   : std_logic_vector(2 downto 0) := "000";
  constant F3_SH   : std_logic_vector(2 downto 0) := "001";
  constant F3_SW   : std_logic_vector(2 downto 0) := "010";

  -- Immediate kind (for imm_gen)
  type imm_type_t is (IMM_X, IMM_I, IMM_S, IMM_B, IMM_U, IMM_J);

  -- ALU function selector
  type alu_fn_t is (
    ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
    ALU_SLT, ALU_SLTU, ALU_SLL, ALU_SRL, ALU_SRA,
    ALU_PASS_IMM 
  );

  -- Next-PC source
  type pc_src_t is (PC_SEQ, PC_BR_TGT, PC_JAL_TGT, PC_JALR_TGT);
end package;

package body isa_pkg is end package body;