--Dylan Kramer
--Implements BEQ,BNE,BLT,BGE,BLTU,BGEU
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.isa_pkg.all;

entity branch_pred is
  port (
    i_funct3 : in  std_logic_vector(2 downto 0);
    i_rs1    : in  std_logic_vector(31 downto 0);
    i_rs2    : in  std_logic_vector(31 downto 0);
    o_taken  : out std_logic
  );
end entity;

architecture structural of branch_pred is
  signal eq   : std_logic;
  signal lt_s : std_logic;
  signal ge_s : std_logic;
  signal lt_u : std_logic;
  signal ge_u : std_logic;
begin
  -- Precompute compares (drive 0/1, never leave 'U')
  eq   <= '1' when i_rs1 =  i_rs2 else '0';
  lt_s <= '1' when signed(i_rs1)  <  signed(i_rs2) else '0';
  ge_s <= '1' when signed(i_rs1)  >= signed(i_rs2) else '0';
  lt_u <= '1' when unsigned(i_rs1) <  unsigned(i_rs2) else '0';
  ge_u <= '1' when unsigned(i_rs1) >= unsigned(i_rs2) else '0';

  -- Final decision (default '0'); no temps, no processes
  o_taken <=
      '1' when (i_funct3 = F3_BEQ  and eq   = '1') else
      '1' when (i_funct3 = F3_BNE  and eq   = '0') else
      '1' when (i_funct3 = F3_BLT  and lt_s = '1') else
      '1' when (i_funct3 = F3_BGE  and ge_s = '1') else
      '1' when (i_funct3 = F3_BLTU and lt_u = '1') else
      '1' when (i_funct3 = F3_BGEU and ge_u = '1') else
      '0';
end architecture;
