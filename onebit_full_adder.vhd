--Adder by Dylan Kramer
--Structural VHDL
--One bit full-adder

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity onebit_full_adder is
	port(D0: in std_logic;
	     D1: in std_logic;
	     Cin: in std_logic;
	     S : out std_logic;
	     Cout: out std_logic);
end onebit_full_adder;

architecture structural of onebit_full_adder is
--xor gate
component xorg2 is
  port(i_A          : in std_logic;
       i_B          : in std_logic;
       o_F          : out std_logic);
end component;
--AND gate
component andg2 is
 port(i_A          : in std_logic;
      i_B          : in std_logic;
      o_F          : out std_logic);
end component;
--OR gate
component org2 is
  port(i_A          : in std_logic;
       i_B          : in std_logic;
       o_F          : out std_logic);
end component;

--Signal wiring
signal s_x1 : std_logic; --D0 xor D1
signal s_c1 : std_logic; --D0 AND D1
signal s_c2 : std_logic; --Cin AND s_x1(D0 XOR D1)

begin
--First logic is x1. It has to do D0 XOR D1
f_X1 : xorg2 port map(i_A => D0,
		     i_B => D1,
 		     o_F => s_x1);

--Second logic is the sum, which is x1 xor Cin
f_S : xorg2 port map(i_A => s_x1,
		     i_B => Cin,
		     o_F => S);
--Third logic is for c1, which should be D0 AND D1
f_C1 : andg2 port map(i_A => D0,
		      i_B => D1,
		      o_F => s_c1);
--Fourth logic is for c2, which is Cin and x1
f_C2 : andg2 port map(i_A => Cin,
		      i_B => s_x1,
		      o_F => s_c2);
--Fifth and final logic is for the Carryout bit which is c1 or c2
f_CO: org2 port map(i_A => s_c1,
		    i_B => s_c2,
		    o_F => Cout);
--Final logic: S= (D0 XOR D1) XOR (Cin) as demonstrated in my circuit drawing in the lab report.
--Final logic cont: Cout = (D0 and D1) OR (Cin and (D0 XOR D1)


end structural;
