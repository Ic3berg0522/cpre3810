--Adder by Dylan Kramer
--Structural VHDL
--N-bit ripple-carry full adder

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity n_ripple_full_adder is
        generic(N: integer := 8);
	port(D0: in std_logic_vector(N-1 downto 0);
	     D1: in std_logic_vector(N-1 downto 0);
	     Cin: in std_logic;
	     S : out std_logic_vector(N-1 downto 0);
	     Cout: out std_logic);
end n_ripple_full_adder;

architecture structural of n_ripple_full_adder is
--Component here is just the onebit_full_adder because a ripple carry is multiple full adders together
--So, using the logic of the full adder
component onebit_full_adder is 
	port(D0: in std_logic;
	     D1: in std_logic;
	     Cin: in std_logic;
	     S : out std_logic;
	     Cout: out std_logic);
end component;

--I/O signals
signal f_C : std_logic_vector(N downto 0);

begin
     f_C(0) <= Cin;
--Instantiate the full adders
--Confused on the logic, used CHATGPT 5.0 to help explain logic so I could program this logic. 
  G_RCA : for i in 0 to N-1 generate --one full adder each bit
     full_adder : onebit_full_adder
	port map(
	  D0   => D0(i), --A bit i
	  D1   => D1(i), --B bit i
	  Cin  => f_C(i), --carry in bit
	  S    => S(i), --sum bit
	  Cout => f_C(i+1)); --carry out bit
   end generate;
	
    Cout <= f_C(N); --Final carry out bit

end structural;