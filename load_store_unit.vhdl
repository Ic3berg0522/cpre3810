--Dylan Kramer
--load and store logic
--lw,lh,lb,lhu,lbu,sw,sh,sb implementation/logic
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity load_store_unit is
  port (
    -- address + store data
    i_addr        : in  std_logic_vector(31 downto 0);
    i_rs2_wdata   : in  std_logic_vector(31 downto 0);

    -- control
    i_mem_read    : in  std_logic;
    i_mem_write   : in  std_logic;
    i_ld_byte     : in  std_logic;
    i_ld_half     : in  std_logic;
    i_ld_unsigned : in  std_logic;  -- 1: zero-extend, 0: sign-extend
    i_st_byte     : in  std_logic;
    i_st_half     : in  std_logic;

    -- memory interface (word + byte enables)
    o_mem_addr    : out std_logic_vector(31 downto 0);
    o_mem_wdata   : out std_logic_vector(31 downto 0);
    o_mem_be      : out std_logic_vector(3 downto 0);
    o_mem_re      : out std_logic;
    o_mem_we      : out std_logic;

    -- readback
    i_mem_rdata   : in  std_logic_vector(31 downto 0);

    -- to writeback
    o_load_data   : out std_logic_vector(31 downto 0)
  );
end entity;

architecture structural of load_store_unit is
  -- small helpers
  signal ofs          : std_logic_vector(1 downto 0);
  signal addr_aligned : std_logic_vector(31 downto 0);

  -- store control/data
  signal be_sb, be_sh, be_sw, be_sel : std_logic_vector(3 downto 0);
  signal w_sb,  w_sh,  w_sw,  w_sel  : std_logic_vector(31 downto 0);

  -- load select/extend
  signal b_sel  : std_logic_vector(7  downto 0);
  signal h_sel  : std_logic_vector(15 downto 0);
  signal lb_ext : std_logic_vector(31 downto 0);
  signal lh_ext : std_logic_vector(31 downto 0);
begin
  ------------------------------------------------------------------------------
  -- address + commands
  ------------------------------------------------------------------------------
  ofs          <= i_addr(1 downto 0);
  addr_aligned <= std_logic_vector(unsigned(i_addr) and not(to_unsigned(3, 32)));

  o_mem_addr <= addr_aligned;
  o_mem_we   <= i_mem_write;
  o_mem_re   <= i_mem_read;

  ------------------------------------------------------------------------------
  -- STORE: byte enables
  ------------------------------------------------------------------------------
  with ofs select
    be_sb <= "0001" when "00",
             "0010" when "01",
             "0100" when "10",
             "1000" when others;

  be_sh <= "0011" when ofs(1) = '0' else
           "1100";

  be_sw <= "1111";

  be_sel <= be_sb when i_st_byte = '1' else
            be_sh when i_st_half = '1' else
            be_sw;

  -- mute when not writing (optional)
  o_mem_be <= be_sel when i_mem_write = '1' else "0000";

  ------------------------------------------------------------------------------
  -- STORE: data alignment (each case is exactly 32 bits)
  ------------------------------------------------------------------------------
  -- SB: place low 8 bits of rs2 into addressed byte lane
  with ofs select
    w_sb <= (31 downto  8 => '0') & i_rs2_wdata(7 downto 0)                              when "00", -- bits [7:0]
            (31 downto 16 => '0') & i_rs2_wdata(7 downto 0) & (7  downto 0  => '0')      when "01", -- bits [15:8]
            (31 downto 24 => '0') & i_rs2_wdata(7 downto 0) & (15 downto 0  => '0')      when "10", -- bits [23:16]
            i_rs2_wdata(7 downto 0) & (23 downto 0 => '0')                                when others; -- bits [31:24]

  -- SH: place low 16 bits of rs2 into low/high half
  w_sh <= (31 downto 16 => '0') & i_rs2_wdata(15 downto 0) when ofs(1) = '0' else
          i_rs2_wdata(15 downto 0) & (15 downto 0 => '0');

  -- SW: full word
  w_sw <= i_rs2_wdata;

  -- final store data select
  w_sel <= w_sb when i_st_byte = '1' else
           w_sh when i_st_half = '1' else
           w_sw;

  o_mem_wdata <= w_sel;

  ------------------------------------------------------------------------------
  -- LOAD: subword select and extend
  ------------------------------------------------------------------------------
  -- select byte/half from returned 32-bit word using address offset
  with ofs select
    b_sel <= i_mem_rdata(7  downto 0)  when "00",
             i_mem_rdata(15 downto 8)  when "01",
             i_mem_rdata(23 downto 16) when "10",
             i_mem_rdata(31 downto 24) when others;

  h_sel <= i_mem_rdata(15 downto 0) when ofs(1) = '0' else
           i_mem_rdata(31 downto 16);

  -- zero/sign extend to 32 bits
  lb_ext <= (31 downto 8  => '0')      & b_sel  when i_ld_unsigned = '1' else
            (31 downto 8  => b_sel(7)) & b_sel;

  lh_ext <= (31 downto 16 => '0')      & h_sel  when i_ld_unsigned = '1' else
            (31 downto 16 => h_sel(15))& h_sel;

  -- final load data
  o_load_data <= lb_ext       when i_ld_byte = '1' else
                 lh_ext       when i_ld_half = '1' else
                 i_mem_rdata; -- LW
end architecture;