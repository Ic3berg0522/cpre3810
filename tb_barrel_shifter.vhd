--Dylan Kramer
--TB For barrel shifter
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_barrel_shifter is end entity;

architecture sim of tb_barrel_shifter is
  -- DUT signals (match your entity exactly)
  signal data_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal shift_amt: std_logic_vector(4 downto 0)  := (others => '0');  -- 0..31
  signal mode     : std_logic_vector(1 downto 0)  := "00";             -- 00=SLL,01=SRL,10=SRA
  signal data_out : std_logic_vector(31 downto 0);

  procedure step(constant t: time := 20 ns) is
  begin
    wait for t;
  end procedure;
begin
  -- DUT
  UUT: entity work.barrel_shifter
    port map (
      data_in   => data_in,
      shift_amt => shift_amt,
      mode      => mode,
      data_out  => data_out
    );

  -- Manual stimulus: read 'data_out' in the waveform and compare to EXPECT comments
  stim: process
  begin
    ----------------------------------------------------------------
    -- SLL (logical left)  mode = "00"
    ----------------------------------------------------------------
    -- Case 1: shift 0 ? unchanged
    data_in   <= x"00000001";  shift_amt <= "00000";  mode <= "00";
    -- EXPECT data_out = 00000001
    step;

    -- Case 2: shift 1
    data_in   <= x"00000001";  shift_amt <= "00001";  mode <= "00";
    -- EXPECT data_out = 00000002
    step;

    -- Case 3: shift 4
    data_in   <= x"00000010";  shift_amt <= "00100";  mode <= "00";
    -- EXPECT data_out = 00000100 (0x10 << 4 = 0x100)
    step;

    -- Case 4: MSB involvement (overflow drops)
    data_in   <= x"80000001";  shift_amt <= "00001";  mode <= "00";
    -- EXPECT data_out = 00000002
    step;

    -- Case 5: shift 31
    data_in   <= x"00000001";  shift_amt <= "11111";  mode <= "00";
    -- EXPECT data_out = 80000000
    step;

    ----------------------------------------------------------------
    -- SRL (logical right, zero-fill)  mode = "01"
    ----------------------------------------------------------------
    -- Case 6: shift 0
    data_in   <= x"80000001";  shift_amt <= "00000";  mode <= "01";
    -- EXPECT data_out = 80000001
    step;

    -- Case 7: shift 1 (zero fills on left)
    data_in   <= x"80000001";  shift_amt <= "00001";  mode <= "01";
    -- EXPECT data_out = 40000000
    step;

    -- Case 8: shift 4
    data_in   <= x"F0000000";  shift_amt <= "00100";  mode <= "01";
    -- EXPECT data_out = 0F000000
    step;

    -- Case 9: shift 31 (only msb drops into bit0)
    data_in   <= x"80000000";  shift_amt <= "11111";  mode <= "01";
    -- EXPECT data_out = 00000001
    step;

    ----------------------------------------------------------------
    -- SRA (arithmetic right, sign-fill)  mode = "10"
    -- NOTE: Requires DUT fix: use data_signed in shift_right for SRA
    ----------------------------------------------------------------
    -- Case 10: positive value ? same as SRL (left fills 0)
    data_in   <= x"10000000";  shift_amt <= "00001";  mode <= "10";
    -- EXPECT data_out = 08000000
    step;

    -- Case 11: negative value (msb=1) ? sign bit replicated
    data_in   <= x"80000000";  shift_amt <= "00001";  mode <= "10";
    -- EXPECT data_out = C0000000
    step;

    -- Case 12: negative, big shift (>>12)
    data_in   <= x"F0000001";  shift_amt <= "01100";  mode <= "10";
    -- EXPECT data_out = 0xFFF00000 >> 12 with sign-fill ? FFF000? (observe upper ones)
    step;

    -- Case 13: shift 31 ? all bits become sign bit
    data_in   <= x"80001234";  shift_amt <= "11111";  mode <= "10";
    -- EXPECT data_out = FFFFFFFF
    step;

    -- Case 14: shift 31 with positive value
    data_in   <= x"7FFFFFFF";  shift_amt <= "11111";  mode <= "10";
    -- EXPECT data_out = 00000000
    step;

    ----------------------------------------------------------------
    -- Quick mode flip comparison on same input
    ----------------------------------------------------------------
    data_in   <= x"FFFF0000";  shift_amt <= "00100";  mode <= "01";  -- SRL by 4
    -- EXPECT data_out = 0FFF_F000
    step;

    mode      <= "10";  -- SRA by 4
    -- EXPECT data_out = FFFF_F000  (sign-fill)
    step;

    mode      <= "00";  -- SLL by 4
    -- EXPECT data_out = FFF0_0000
    step;

    wait;
  end process;
end architecture;

