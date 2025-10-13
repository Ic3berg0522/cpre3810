--Dylan Kramer
--Fetch logic
--Chooses between PC + 4, PC + immB (BRANCH), PC + immJ (JAL), rs1 + immI (JALR) or HALT
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.isa_pkg.all;

entity fetch_unit is
  generic ( G_RESET_VECTOR : unsigned(31 downto 0) := x"00000000" );
  port (
    i_clk: in  std_logic;
    i_rst : in  std_logic;
    i_halt : in  std_logic;
    --control
    i_pc_src: in  pc_src_t;-- SEQ, BR_TGT, JAL_TGT, JALR_TGT
    i_br_taken : in  std_logic;-- from branch_predict file
    --targets
    i_rs1_val : in  std_logic_vector(31 downto 0); -- for JALR
    i_immI: in  std_logic_vector(31 downto 0);
    i_immB: in  std_logic_vector(31 downto 0);
    i_immJ : in  std_logic_vector(31 downto 0);
    --outputs
    o_pc : out std_logic_vector(31 downto 0);
    o_pc_plus4: out std_logic_vector(31 downto 0);
    o_imem_addr: out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of fetch_unit is
  signal r_pc, pc_plus4, next_pc : unsigned(31 downto 0);
begin
  pc_plus4 <= r_pc + 4;

  --base next_pc
  process(all)
    variable br_tgt, j_tgt, jr_tgt : unsigned(31 downto 0);
  begin
    br_tgt := unsigned(std_logic_vector(signed(std_logic_vector(r_pc)) + signed(i_immB)));
    j_tgt  := unsigned(std_logic_vector(signed(std_logic_vector(r_pc)) + signed(i_immJ)));
    jr_tgt := unsigned(std_logic_vector(signed(i_rs1_val) + signed(i_immI)));
    jr_tgt := jr_tgt and not(to_unsigned(1,32)); -- clear bit 0

    case i_pc_src is
      when PC_SEQ      => next_pc <= pc_plus4;
      when PC_BR_TGT   => next_pc <= br_tgt; -- corrected by not-taken check below
      when PC_JAL_TGT  => next_pc <= j_tgt;
      when PC_JALR_TGT => next_pc <= jr_tgt;
    end case;
  end process;

  --PC register
  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst='1' then
        r_pc <= G_RESET_VECTOR;
      elsif i_halt='1' then
        r_pc <= r_pc; -- hold
      else
        if (i_pc_src = PC_BR_TGT) and (i_br_taken='0') then
          r_pc <= pc_plus4;
        else
          r_pc <= next_pc;
        end if;
      end if;
    end if;
  end process;

  o_pc        <= std_logic_vector(r_pc);
  o_pc_plus4  <= std_logic_vector(pc_plus4);
  o_imem_addr <= std_logic_vector(r_pc);
end architecture;