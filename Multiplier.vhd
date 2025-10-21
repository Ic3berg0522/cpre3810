-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- Multiplier.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a behavioral 
-- multiplier operating on std_logic_vector inputs. 
--
--
-- NOTES: We use the numeric_std library's signed datatype for this operation.
-- The resulting output is twice the width of the input size.


-- 8/19/09 by JAZ::Design created.
-- 1/16/25 by CWS::Switched from integer to std_logic_vector and numeric_std.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Multiplier is

  generic(DATA_WIDTH : integer := 8);

  port(iCLK             : in std_logic;
       iA               : in std_logic_vector(DATA_WIDTH-1 downto 0);
       iB               : in std_logic_vector(DATA_WIDTH-1 downto 0);
       oC               : out std_logic_vector(2*DATA_WIDTH-1 downto 0));

end Multiplier;

architecture behavior of Multiplier is
begin

  process(iCLK, iA, iB)
  begin
    if rising_edge(iCLK) then
	   oC <= std_logic_vector(signed(iA) * signed(iB));
    end if;
  end process;
  
end behavior;
