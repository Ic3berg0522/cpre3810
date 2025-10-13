--Michael Berg
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALUUnit is
  port (
    A        : in  std_logic_vector(31 downto 0);
    B        : in  std_logic_vector(31 downto 0);
    shift_amt    : in  std_logic_vector(4 downto 0);
    ALU_op  : in  std_logic_vector(3 downto 0);  -- ALU operation select
    F        : out std_logic_vector(31 downto 0); -- ALU result
    Zero     : out std_logic;                     -- Zero flag
    Overflow : out std_logic                      -- Overflow flag
  );
end entity;

architecture structural of ALUUnit is


  -- Internal signals
  signal sum, diff : std_logic_vector(31 downto 0);
  signal and_out, or_out, xor_out, nor_out : std_logic_vector(31 downto 0);
  signal shifter_out : std_logic_vector(31 downto 0);
  signal slt_bit : std_logic;

  signal sh_mode : std_logic_vector(1 downto 0);
  signal overflow_add, overflow_sub : std_logic;

  -- Barrel Shifter component declaration
  component barrel_shifter
    port (
      data_in   : in  std_logic_vector(31 downto 0);
      shift_amt : in  std_logic_vector(4 downto 0);
      mode      : in  std_logic_vector(1 downto 0); -- 00 SLL, 01 SRL, 10 SRA
      data_out  : out std_logic_vector(31 downto 0)
    );
  end component;

begin

  -- Arithmetic operations
  sum  <= std_logic_vector(signed(A) + signed(B));
  diff <= std_logic_vector(signed(A) - signed(B));


  -- Overflow detection
  overflow_add <= '1' when ((A(31) = B(31)) and (A(31) /= sum(31))) else '0';
  overflow_sub <= '1' when ((A(31) /= B(31)) and (A(31) /= diff(31))) else '0';

 
  -- Logical operations
 
  and_out <= A and B;
  or_out  <= A or B;
  xor_out <= A xor B;
  nor_out <= not (A or B);

  
  -- Select shift mode for barrel shifter (00=SLL, 01=SRL, 10=SRA)
  
  with ALU_op select
    sh_mode <= "00" when "0110",  -- SLL
                "01" when "0111",  -- SRL
                "10" when "1000",  -- SRA
                "00" when others;  -- default

  
  -- Instantiate barrel shifter
  
  shift_unit: barrel_shifter
    port map (
      data_in   => A,
      shift_amt => shift_amt,
      mode      => sh_mode,
      data_out  => shifter_out
    );

  
  -- SLT (Set Less Than)
  
  slt_bit <= diff(31) xor overflow_sub;

  
  -- Final ALU output multiplexer
  
  with ALU_op select
    F <= sum                          when "0000",  -- ADD
         diff                         when "0001",  -- SUB
         and_out                      when "0010",  -- AND
         or_out                       when "0011",  -- OR
         xor_out                      when "0100",  -- XOR
         nor_out                      when "0101",  -- NOR
         shifter_out                  when "0110",  -- SLL
         shifter_out                  when "0111",  -- SRL
         shifter_out                  when "1000",  -- SRA
         (31 downto 1 => '0') & slt_bit when "1001",  -- SLT
         (others => '0')              when others;  -- Default

  
  -- Zero flag logic
  
  Zero <= '1' when F = x"00000000" else '0';

  
  -- Overflow flag logic
  
  with ALU_op select
    Overflow <= overflow_add when "0000",  -- ADD
                 overflow_sub when "0001",  -- SUB
                 '0'           when others;

end architecture;
