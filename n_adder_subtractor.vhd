--N-bit strucutral VHDL adder/subtractor
--Dylan Kramer

library IEEE;
use IEEE.std_logic_1164.all;

entity n_adder_subtractor is
	generic(N : integer := 32);
	port(A : in std_logic_vector(N-1 downto 0);
	     B : in std_logic_vector(N-1 downto 0);
	     nAdd_sub : in std_logic; --If this is 1 we are are subtracting, if it's zero we add
	     S   : out std_logic_vector(N-1 downto 0);
	     Cout: out std_logic);

end n_adder_subtractor;

architecture structural of n_adder_subtractor is

--2:1 MUX component
component mux2t1_N is 
	generic(N: integer := 32);
	  port(i_S   : in std_logic;
       	       i_D0  : in std_logic_vector(N-1 downto 0);
               i_D1 : in std_logic_vector(N-1 downto 0);
               o_O : out std_logic_vector(N-1 downto 0));

end component;

--One's complementor component (inverter)
component ones_comp is
	generic(N: integer := 32);
	port(i_D0 : in std_logic_vector(N-1 downto 0);
	     o_O  : out std_logic_vector(N-1 downto 0));
end component;


--N-Bit full adder component
component n_ripple_full_adder is
	generic(N: integer := 32);
	port(D0: in std_logic_vector(N-1 downto 0);
	     D1: in std_logic_vector(N-1 downto 0);
	     Cin: in std_logic;
	     S : out std_logic_vector(N-1 downto 0);
	     Cout: out std_logic);
end component;

--Signal declarations
signal n_B : std_logic_vector(N-1 downto 0); --NOT D1 signal
signal add_in : std_logic_vector(N-1 downto 0); --Output of the 2:1 MUX (Either D1 or NOT D1)

begin

--First thing is to invert D1 (B)
INV_D1 : ones_comp
	generic map (N => N)
	port map(i_D0 => B,
		 o_O => n_B);

--Next, select B input for adder (It will either be B or NOT B)
MUX_IN : mux2t1_N
	generic map(N => N)
	port map(i_D0 => B,
		 i_D1 => n_B,
		 i_S => nAdd_sub,
		 o_O => add_in);

--Now we do the actual addition or subtraction using the full adder
ADD_SUB : n_ripple_full_adder
	generic map (N => N)
	port map(D0 => A,
		 D1 => add_in,
		 Cin => nAdd_sub, --This determines whether we add or subtract (0 or 1)
	         S   => S,
		 Cout => Cout);
end architecture;
--Actual logic

