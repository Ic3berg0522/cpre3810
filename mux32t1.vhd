--Dylan Kramer
--32 to 1 Multiplexer
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity mux32t1 is
    generic(N : integer := 32);
  port (
        i_S     : in std_logic_vector(4 downto 0);
        data_in : in bus_32;
        o_O     : out std_logic_vector(N-1 downto 0)
    );
end mux32t1;

architecture dataflow of mux32t1 is 
begin
	o_O <= data_in(to_integer(unsigned(i_S)));
end dataflow;


	
