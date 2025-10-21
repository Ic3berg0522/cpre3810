--One's complementor by Dylan Kramer
--Structural VHDL
--Used CHATGPT 5.0 to help me debug, was having a compilation error I couldn't find. On line 22 I forgot the "to" statement which messed up my code.

library IEEE;
use IEEE.std_logic_1164.all;
--Entity definition
entity ones_comp is
	generic(N: integer := 8);
	port(i_D0 : in std_logic_vector(N-1 downto 0);
	     o_O  : out std_logic_vector(N-1 downto 0));
end ones_comp;


architecture structural of ones_comp is
	component invg
 	 port(i_A          : in std_logic;
      	      o_F          : out std_logic);
	end component;
  
begin
	G_INV: for i in 0 to N-1 generate
	      U_INV: invg
		    port map(i_A => i_D0(i),
			     o_F => o_O(i));
	end generate G_INV;

end structural;