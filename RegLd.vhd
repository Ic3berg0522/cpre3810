-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- RegLd.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a behavioral 
-- enabled register. 
--
--


-- 1/14/18 by H3::Design created.
-- 1/16/25 by CWS::Switched from integer to std_logic_vector.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity RegLd is

  generic(DATA_WIDTH : integer := 32);

  port(iCLK             : in std_logic;
       iD               : in std_logic_vector(DATA_WIDTH-1 downto 0);
       iLd              : in std_logic;
       oQ               : out std_logic_vector(DATA_WIDTH-1 downto 0));

end RegLd;

architecture behavior of RegLd is
  -- signal to hold Q value
  signal sQ : std_logic_vector(DATA_WIDTH-1 downto 0);
begin

  process(iCLK, iLd, iD)
  begin
    if rising_edge(iCLK) then
      if (iLd = '1') then
        sQ <= iD;
      else
        sQ <= sQ;
      end if;
    end if;
  end process;

  oQ <= sQ; -- connect internal storage signal with final output
  
end behavior;
