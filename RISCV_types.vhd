-------------------------------------------------------------------------
-- Author: Braedon Giblin
-- Date: 2022.02.12
-- Files: RISCV_types.vhd
-------------------------------------------------------------------------
-- Description: This file contains a skeleton for some types that 381 students
-- may want to use. This file is guarenteed to compile first, so if any types,
-- constants, functions, etc., etc., are wanted, students should declare them
-- here.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package RISCV_types is
  -- Example Constants. Declare more as needed
  constant DATA_WIDTH : integer := 32;
  constant ADDR_WIDTH : integer := 10;

  -- Example record type. Declare whatever types you need here
  type control_t is record
    reg_wr : std_logic;
    reg_to_mem : std_logic;
  end record control_t;
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

      constant four_bit_zero : std_logic_vector := "0000";
	type bus_32 is array (0 to 31) of std_logic_vector(31 downto 0);


end package RISCV_types;

package body RISCV_types is
  -- Probably won't need anything here... function bodies, etc.
end package body RISCV_types;
