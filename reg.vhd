--Dylan Kramer
--REGISTER FILE (hardened against meta select lines)
library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity reg is
  generic(N : integer := DATA_WIDTH);
  port(
       RS1      : in  std_logic_vector(4 downto 0);
       RS2      : in  std_logic_vector(4 downto 0);
       DATA_IN  : in  std_logic_vector(N-1 downto 0); 
       W_SEL    : in  std_logic_vector(4 downto 0);
       WE       : in  std_logic;
       RST      : in  std_logic;
       CLK      : in  std_logic;
       RS1_OUT  : out std_logic_vector(N-1 downto 0);
       RS2_OUT  : out std_logic_vector(N-1 downto 0)
       );
end reg;

architecture structural of reg is 

  component decoder5t32
    port(
      DIN : in  std_logic_vector(4 downto 0);
      EN  : in  std_logic;
      Y   : out std_logic_vector(31 downto 0)
    );
  end component;

  component mux32t1
    port (
      i_S     : in  std_logic_vector(4 downto 0);
      data_in : in  bus_32;
      o_O     : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component N_reg
    port(
      Data_in  : in  std_logic_vector(N-1 downto 0);
      CLK      : in  std_logic;
      WE       : in  std_logic;
      RST      : in  std_logic;
      Data_out : out std_logic_vector(N-1 downto 0)
    );
  end component;

  -- Helper: sanitize a 5-bit select (force any meta to '0')
  function sanitize5(a : std_logic_vector(4 downto 0)) return std_logic_vector is
    variable r : std_logic_vector(4 downto 0);
  begin
    for i in 0 to 4 loop
      if (a(i) = '0') or (a(i) = '1') then
        r(i) := a(i);
      else
        r(i) := '0';
      end if;
    end loop;
    return r;
  end function;

  -- Write decoder and register array
  signal s_decoder : std_logic_vector(31 downto 0);
  signal s_reg     : bus_32;

  -- Sanitized read-selects (prevents to_integer meta warnings inside mux32t1)
  signal rs1_sel_safe : std_logic_vector(4 downto 0);
  signal rs2_sel_safe : std_logic_vector(4 downto 0);

begin

  -- Sanitize read addresses to avoid meta indexing during reset/load
  rs1_sel_safe <= sanitize5(RS1);
  rs2_sel_safe <= sanitize5(RS2);

  -- Write decoder
  DECODER: decoder5t32
    port map(
      DIN => W_SEL,
      EN  => WE,
      Y   => s_decoder
    );

  -- x0 register: hard-wired to zero via constant reset '1'
  NREG0: entity work.N_reg
    port map(
      Data_in  => DATA_IN,
      CLK      => CLK,
      WE       => s_decoder(0),
      RST      => '1',           -- keep x0 at zero
      Data_out => s_reg(0)
    );

  -- x1..x31 normal registers
  NREG1TO31: for i in 1 to 31 generate
    REGI: N_reg
      port map(
        Data_in  => DATA_IN,
        CLK      => CLK,
        WE       => s_decoder(i),
        RST      => RST,
        Data_out => s_reg(i)
      );
  end generate NREG1TO31;

  -- Read muxes with sanitized selects
  MUX32T1FIRST: mux32t1
    port map(
      i_S     => rs1_sel_safe,
      data_in => s_reg,
      o_O     => RS1_OUT
    );

  MUX32T1SECOND: mux32t1
    port map(
      i_S     => rs2_sel_safe,
      data_in => s_reg,
      o_O     => RS2_OUT
    );

end structural;
