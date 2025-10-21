--Bit width extender
--Dylan Kramer
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BitWidthExtender is
	port(D_IN : in std_logic_vector(11 downto 0);
             ZERO_ONE : in std_logic; --1 to sign extend, 0 to zero extend
	     D_OUT : out std_logic_vector(31 downto 0));
end entity;

architecture behavioral of BitWidthExtender is 
begin
  with ZERO_ONE select
     D_OUT <= std_logic_vector(resize(signed(D_IN), 32)) when '1', 
              std_logic_vector(resize(unsigned(D_IN), 32)) when others;
end behavioral;