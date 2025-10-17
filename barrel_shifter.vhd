--Dylan Kramer
--Barrel shifter (Structural)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity barrel_shifter is
port (
  data_in : in std_logic_vector(31 downto 0);
  shift_amt : in std_logic_vector(4 downto 0);
  mode : in std_logic_vector(1 downto 0); -- 00 SLL, 01 SRL, 10 SRA
  data_out : out std_logic_vector(31 downto 0)
);
end entity;

architecture structural of barrel_shifter is

  signal sll_result : std_logic_vector(31 downto 0);
  signal srl_result : std_logic_vector(31 downto 0);
  signal sra_result : std_logic_vector(31 downto 0);
  signal sign_ext : std_logic_vector(31 downto 0);

begin

  -- SLL: Shift left logical
  with shift_amt select
    sll_result <= data_in                           when "00000",
                  data_in(30 downto 0) & "0"       when "00001",
                  data_in(29 downto 0) & "00"      when "00010",
                  data_in(28 downto 0) & "000"     when "00011",
                  data_in(27 downto 0) & "0000"    when "00100",
                  data_in(26 downto 0) & "00000"   when "00101",
                  data_in(25 downto 0) & "000000"  when "00110",
                  data_in(24 downto 0) & "0000000" when "00111",
                  data_in(23 downto 0) & x"00"     when "01000",
                  data_in(22 downto 0) & "000000000" when "01001",
                  data_in(21 downto 0) & "0000000000" when "01010",
                  data_in(20 downto 0) & "00000000000" when "01011",
                  data_in(19 downto 0) & "000000000000" when "01100",
                  data_in(18 downto 0) & "0000000000000" when "01101",
                  data_in(17 downto 0) & "00000000000000" when "01110",
                  data_in(16 downto 0) & "000000000000000" when "01111",
                  data_in(15 downto 0) & x"0000"   when "10000",
                  (others => '0') when others;

  -- SRL: Shift right logical
  with shift_amt select
    srl_result <= data_in                           when "00000",
                  "0" & data_in(31 downto 1)       when "00001",
                  "00" & data_in(31 downto 2)      when "00010",
                  "000" & data_in(31 downto 3)     when "00011",
                  "0000" & data_in(31 downto 4)    when "00100",
                  "00000" & data_in(31 downto 5)   when "00101",
                  "000000" & data_in(31 downto 6)  when "00110",
                  "0000000" & data_in(31 downto 7) when "00111",
                  x"00" & data_in(31 downto 8)     when "01000",
                  "000000000" & data_in(31 downto 9) when "01001",
                  "0000000000" & data_in(31 downto 10) when "01010",
                  "00000000000" & data_in(31 downto 11) when "01011",
                  "000000000000" & data_in(31 downto 12) when "01100",
                  "0000000000000" & data_in(31 downto 13) when "01101",
                  "00000000000000" & data_in(31 downto 14) when "01110",
                  "000000000000000" & data_in(31 downto 15) when "01111",
                  x"0000" & data_in(31 downto 16)  when "10000",
                  (others => '0') when others;

  -- Sign extension for SRA
  sign_ext <= (others => data_in(31));

  -- SRA: Shift right arithmetic
  with shift_amt select
    sra_result <= data_in                                        when "00000",
                  data_in(31) & data_in(31 downto 1)             when "00001",
                  data_in(31) & data_in(31) & data_in(31 downto 2) when "00010",
                  sign_ext(31 downto 29) & data_in(31 downto 3)  when "00011",
                  sign_ext(31 downto 28) & data_in(31 downto 4)  when "00100",
                  sign_ext(31 downto 27) & data_in(31 downto 5)  when "00101",
                  sign_ext(31 downto 26) & data_in(31 downto 6)  when "00110",
                  sign_ext(31 downto 25) & data_in(31 downto 7)  when "00111",
                  sign_ext(31 downto 24) & data_in(31 downto 8)  when "01000",
                  sign_ext(31 downto 23) & data_in(31 downto 9)  when "01001",
                  sign_ext(31 downto 22) & data_in(31 downto 10) when "01010",
                  sign_ext(31 downto 21) & data_in(31 downto 11) when "01011",
                  sign_ext(31 downto 20) & data_in(31 downto 12) when "01100",
                  sign_ext(31 downto 19) & data_in(31 downto 13) when "01101",
                  sign_ext(31 downto 18) & data_in(31 downto 14) when "01110",
                  sign_ext(31 downto 17) & data_in(31 downto 15) when "01111",
                  sign_ext(31 downto 16) & data_in(31 downto 16) when "10000",
                  (others => data_in(31)) when others;

  -- Select output based on mode
  with mode select
    data_out <= sll_result when "00",
                srl_result when "01",
                sra_result when "10",
                sra_result when "11",
                data_in when others;

end architecture;