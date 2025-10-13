library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ShiftLeft2 is
    generic (
        WIDTH : integer := 32  
    );
    port(
        data_in  : in  std_logic_vector(WIDTH-1 downto 0);
        data_out : out std_logic_vector(WIDTH-1 downto 0)
    );
end ShiftLeft2;

architecture Behavioral of ShiftLeft2 is
begin
   
    data_out <= data_in(WIDTH-3 downto 0) & "00";
end Behavioral;