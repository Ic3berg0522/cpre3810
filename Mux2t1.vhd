--Dylan Kramer
--Structural 2:1 MUX 
library IEEE;
use IEEE.std_logic_1164.all;


entity mux2t1 is
	port(i_D0 : in std_logic;
	     i_D1 : in std_logic;
             i_S  : in std_logic;
             o_O  : out std_logic);
end mux2t1;

architecture structmux of mux2t1 is 
	--Pulled andg2 from lab files
	component andg2 is

  	   port(i_A          : in std_logic;
       		i_B          : in std_logic;
       		o_F          : out std_logic);

	end component;
	--pulled org2 from lab files
	component org2 is

  		port(i_A          : in std_logic;
       		     i_B          : in std_logic;
       		     o_F          : out std_logic);

	end component;
	--Signal definitions. s_not, w0 and w1.
	signal s_not : std_logic; --not select
	signal w0    : std_logic; --D0 and NOT select
	signal w1    : std_logic; --D1 and S

begin
--Invert s_not signal so its actually NOT i_S
s_not <= not i_S;
--First and gate port mapping- iA is input 0 (D0), iB is NOT s, and o_F (output) is w0 (D0 and NOT S).
AND0 : andg2 port map(i_A => i_D0,
       		        i_B => s_not,        
       		        o_F => w0);          
--Second and gate port mapping
AND1 : andg2 port map (i_A => i_D1,
			    i_B => i_S,
		         o_F => w1);
--First and only or gate port mapping
OR1  : org2 port map ( i_A => w0, 
		       i_B => w1,
		       o_F => o_O);
end structmux;

	
	