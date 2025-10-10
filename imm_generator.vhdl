--Dylan Kramer
--Immediate generation module, needed because current BitWidthExtender is fixed to 12-bit cases.
--This will make sure all instruction types get the correct immediate
--Using my BitWidthExtender internally for I-Type and S-Type as they use 12-bit immediates
--Implements the immediates for R, I, S, SB, U and UJ types
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imm_generator is
  port(
    i_instr : in  std_logic_vector(31 downto 0); 
    i_kind  : in  std_logic_vector(2 downto 0); --3 bit select to know what format type we are using
    o_imm   : out std_logic_vector(31 downto 0)
  );
end entity;
--All signals are signed 32 bits because we use 2's complement signed immediates
architecture simple of imm_generator is
  signal imm_r : std_logic_vector(31 downto 0);
  signal imm_i : std_logic_vector(31 downto 0);
  signal imm_s : std_logic_vector(31 downto 0);
  signal imm_sb : std_logic_vector(31 downto 0);
  signal imm_u : std_logic_vector(31 downto 0);
  signal imm_uj : std_logic_vector(31 downto 0);
begin
  --R-type: no immediate, so set to 0
  imm_r  <= (others => '0');
  --I-type imm field is bits 31-20, sign extended to 32 bits
  imm_i <= std_logic_vector(resize(signed((i_instr(31 downto 20))), 32));
  --S-type immediate fields are 31-25 and 11-7, sign extended to 32
  imm_s <= std_logic_vector(resize(signed((i_instr(31 downto 25) & i_instr(11 downto 7))), 32));

  --SB-type immediate fields are 31-25 and 11-7, sign extended to 32 bits
  --i_instr(31) is imm[12], i_instr(7) is imm[11], 30 downto 25 is imm[10:5], i_instr(11 downto 8) is imm[4:1] and 0 is imm[0]
  imm_sb <= std_logic_vector(resize(signed(i_instr(31) & i_instr(7) & i_instr(30 downto 25) & i_instr(11 downto 8) & '0'), 32));

  --U-type immediate field is 31-12 sign extended to 32 bits
  imm_u <= std_logic_vector(resize(signed((i_instr(31 downto 12))), 32));

  --UJ-type immediate field is 31-12 sign extended to 32 bits
  --i_instr(31) is imm[20], i_instr(19 downto 12) is imm[19:12], i_instr(30 downto 21) is imm[10:1] and 0 is imm[0]
  imm_uj <= std_logic_vector(resize(signed(i_instr(31) & i_instr(19 downto 12) & i_instr(20) & i_instr(30 downto 21) & '0'), 32));

  -- Select correct immediate based on i_kind
  --000 is R-type, 001 is I-type, 010 is S-type, 011 is SB type, 100 is U-type, 101 is UJ-type
  with i_kind select
    o_imm <= imm_r   when "000",
             imm_i   when "001",
             imm_s   when "010",
             imm_sb  when "011",
             imm_u   when "100",
             imm_uj  when "101",
             (others => '0') when others;
end architecture;

