--Dylan Kramer
--Fetch logic
--Chooses between PC + 4, PC + immB (BRANCH), PC + immJ (JAL), rs1 + immI (JALR) or HALT
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity PCFetch is
generic (G_RESET_VECTOR : unsigned(31 downto 0) := x"00000000" );
port (
 i_clk: in std_logic;
 i_rst : in std_logic;
 i_halt : in std_logic;
--control
 i_pc_src: in pc_src_t;-- SEQ, BR_TGT, JAL_TGT, JALR_TGT
 i_br_taken : in std_logic;-- from branch_predict file
--targets
 i_rs1_val : in std_logic_vector(31 downto 0); -- for JALR
 i_immI: in std_logic_vector(31 downto 0);
 i_immB: in std_logic_vector(31 downto 0);
 i_immJ : in std_logic_vector(31 downto 0);
--outputs
 o_pc : out std_logic_vector(31 downto 0);
 o_pc_plus4: out std_logic_vector(31 downto 0);
 o_imem_addr: out std_logic_vector(31 downto 0)
 );
end entity;

architecture rtl of PCFetch is
signal r_pc: unsigned(31 downto 0) := G_RESET_VECTOR;
signal pc_plus4, next_pc : unsigned(31 downto 0);
signal br_tgt, j_tgt, jr_tgt : unsigned(31 downto 0);
begin
 -- PC + 4
 pc_plus4 <= r_pc + 4;
 
 -- Branch target (PC + immB)
 br_tgt <= unsigned(std_logic_vector(signed(std_logic_vector(r_pc)) + signed(i_immB)));
 
 -- Jump target (PC + immJ)
 j_tgt <= unsigned(std_logic_vector(signed(std_logic_vector(r_pc)) + signed(i_immJ)));
 
 -- JALR target (rs1 + immI) with bit 0 cleared
 jr_tgt <= (unsigned(std_logic_vector(signed(i_rs1_val) + signed(i_immI)))) and not(to_unsigned(1,32));
 
 -- Next PC calculation
 next_pc <= pc_plus4 when i_pc_src = PC_SEQ else
            br_tgt when (i_pc_src = PC_BR_TGT and i_br_taken = '1') else
            pc_plus4 when (i_pc_src = PC_BR_TGT and i_br_taken = '0') else
            j_tgt when i_pc_src = PC_JAL_TGT else
            jr_tgt when i_pc_src = PC_JALR_TGT else
            pc_plus4;
 
 --PC register (concurrent clocked statement)
 r_pc <= G_RESET_VECTOR when (i_clk'event and i_clk = '1' and i_rst = '1') else
         r_pc when (i_clk'event and i_clk = '1' and i_halt = '1') else
         next_pc when (i_clk'event and i_clk = '1') else
         r_pc;
 
 -- Outputs
 o_pc <= std_logic_vector(r_pc);
 o_pc_plus4 <= std_logic_vector(pc_plus4);
 o_imem_addr <= std_logic_vector(r_pc);
 
end architecture;