--Dylan Kramer and Michael Berg
--Top level implementation of a single-cycle RISC-V processor
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0));

end  RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic;
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0);
  signal s_DMemData     : std_logic_vector(N-1 downto 0);
  signal s_DMemOut      : std_logic_vector(N-1 downto 0);
 
  -- Required register file signals 
  signal s_RegWr        : std_logic;
  signal s_RegWrAddr    : std_logic_vector(4 downto 0);
  signal s_RegWrData    : std_logic_vector(N-1 downto 0);

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0);
  signal s_NextInstAddr : std_logic_vector(N-1 downto 0);
  signal s_Inst         : std_logic_vector(N-1 downto 0) := (others=> '0');

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;

--PC Path signals
signal s_PC : std_logic_vector(N-1 downto 0) := x"00000000";
signal s_PCPlus4 : std_logic_vector(N-1 downto 0);
signal PCSrc : pc_src_t;
signal s_BrTaken : std_logic := '0';

--Decode fields
signal s_opcode  : std_logic_vector(6 downto 0);
signal s_funct3  : std_logic_vector(2 downto 0);
signal s_funct7  : std_logic_vector(6 downto 0);
signal s_rs1     : std_logic_vector(4 downto 0);
signal s_rs2     : std_logic_vector(4 downto 0);
signal s_rd      : std_logic_vector(4 downto 0);

--Register signals
signal s_rs1_val : std_logic_vector(N-1 downto 0) := (others=>'0');
signal s_rs2_val : std_logic_vector(N-1 downto 0) := (others=>'0');

--Immediate signals
signal s_ImmKind : std_logic_vector(2 downto 0);
signal s_immI : std_logic_vector(N-1 downto 0) := (others => '0');
signal s_immB : std_logic_vector(31 downto 0) := (others => '0');
signal s_immJ : std_logic_vector(31 downto 0) := (others => '0');

--ALU signals
signal s_ALUSrcA : std_logic := '0'; -- NEW: 0=rs1, 1=PC (for AUIPC)
signal s_ALUSrcSel : std_logic := '0';
signal s_ALUInA : std_logic_vector(N-1 downto 0); -- NEW: ALU input A (muxed)
signal s_ALUInB : std_logic_vector(N-1 downto 0);
signal s_ALURes : std_logic_vector(N-1 downto 0);
signal s_ALUCtrl : std_logic_vector(3 downto 0) := (others=>'0');
signal s_ALUOvfl : std_logic;
signal s_ALU2BitControl : std_logic_vector(1 downto 0);
signal s_ALUShiftAmt : std_logic_vector(4 downto 0);
signal s_ALUZero : std_logic := '0';

--Writeback signals
signal s_WBSel : std_logic := '0';
signal s_WBData : std_logic_vector(31 downto 0);

--Load/Store control signals
signal s_MemRead : std_logic;
signal s_MemWrite : std_logic;
signal s_LdByte : std_logic;
signal s_LdHalf : std_logic;
signal s_LdUnsigned : std_logic;
signal s_StByte : std_logic;
signal s_StHalf : std_logic;

--Load/Store unit signals
signal s_LSUBEn : std_logic_vector(3 downto 0);
signal s_LoadedData : std_logic_vector(31 downto 0);
signal s_RegWrLoad : std_logic;
signal s_RegWr_Final : std_logic;

--Control unit instantiation
  component ControlUnit is
    port(
      opcode     : in  std_logic_vector(6 downto 0);
      funct3     : in  std_logic_vector(2 downto 0);
      funct7     : in  std_logic_vector(6 downto 0);
      ALUSrcA    : out std_logic; -- NEW: 0=rs1, 1=PC
      ALUSrc     : out std_logic;
      ALUControl : out std_logic_vector(1 downto 0);
      ImmType    : out std_logic_vector(2 downto 0);
      ResultSrc  : out std_logic;
      MemWrite   : out std_logic;
      RegWrite   : out std_logic;
      ALU_op     : out std_logic_vector(3 downto 0);
      Halt       : out std_logic;
      MemRead    : out std_logic;
      LdByte     : out std_logic;
      LdHalf     : out std_logic;
      LdUnsigned : out std_logic;
      StByte     : out std_logic;
      StHalf     : out std_logic
    );
end component;

--N carry ripple full adder instantiation
  component n_ripple_full_adder is
    generic(N: integer := 8);
    port(
      D0   : in  std_logic_vector(N-1 downto 0);
      D1   : in  std_logic_vector(N-1 downto 0);
      Cin  : in  std_logic;
      S    : out std_logic_vector(N-1 downto 0);
      Cout : out std_logic
    );
end component;

--ALU unit instantiation
  component ALUUnit is
    port (
      A         : in  std_logic_vector(31 downto 0);
      B         : in  std_logic_vector(31 downto 0);
      shift_amt : in  std_logic_vector(4 downto 0);
      ALU_op    : in  std_logic_vector(3 downto 0);
      F         : out std_logic_vector(31 downto 0);
      Zero      : out std_logic;
      Overflow  : out std_logic
    );
end component;

--reg file instantiation
  component reg is
    generic(N : integer := DATA_WIDTH);
    port(
      RS1     : in  std_logic_vector(4 downto 0);
      RS2     : in  std_logic_vector(4 downto 0);
      DATA_IN : in  std_logic_vector(N-1 downto 0);
      W_SEL   : in  std_logic_vector(4 downto 0);
      WE      : in  std_logic;
      RST     : in  std_logic;
      CLK     : in  std_logic;
      RS1_OUT : out std_logic_vector(N-1 downto 0);
      RS2_OUT : out std_logic_vector(N-1 downto 0)
    );
end component;

--N-bit 2t1 mux instantiation
  component mux2t1_N is
    generic(N : integer := 32);
    port(
      i_S  : in  std_logic;
      i_D0 : in  std_logic_vector(N-1 downto 0);
      i_D1 : in  std_logic_vector(N-1 downto 0);
      o_O  : out std_logic_vector(N-1 downto 0)
    );
end component;

--Immediate generator instantiation
  component imm_generator is
    port(
      i_instr : in  std_logic_vector(31 downto 0);
      i_kind  : in  std_logic_vector(2 downto 0);
      o_imm   : out std_logic_vector(31 downto 0)
    );
end component;

--PC Fetch component instantiation
  component PCFetch is
    generic (G_RESET_VECTOR : unsigned(31 downto 0) := x"00000000");
    port (
      i_clk       : in  std_logic;
      i_rst       : in  std_logic;
      i_halt      : in  std_logic;
      i_pc_src    : in  pc_src_t;
      i_br_taken  : in  std_logic;
      i_rs1_val   : in  std_logic_vector(31 downto 0);
      i_immI      : in  std_logic_vector(31 downto 0);
      i_immB      : in  std_logic_vector(31 downto 0);
      i_immJ      : in  std_logic_vector(31 downto 0);
      o_pc        : out std_logic_vector(31 downto 0);
      o_pc_plus4  : out std_logic_vector(31 downto 0);
      o_imem_addr : out std_logic_vector(31 downto 0)
    );
  end component;

--Load and store unit instantiation
component load_store_unit is
    port (
      i_addr        : in  std_logic_vector(31 downto 0);
      i_rs2_wdata   : in  std_logic_vector(31 downto 0);
      i_mem_read    : in  std_logic;
      i_mem_write   : in  std_logic;
      i_ld_byte     : in  std_logic;
      i_ld_half     : in  std_logic;
      i_ld_unsigned : in  std_logic;
      i_st_byte     : in  std_logic;
      i_st_half     : in  std_logic;
      i_mem_rdata   : in  std_logic_vector(31 downto 0);
      o_mem_addr    : out std_logic_vector(31 downto 0);
      o_mem_wdata   : out std_logic_vector(31 downto 0);
      o_mem_be      : out std_logic_vector(3 downto 0);
      o_mem_re      : out std_logic;
      o_mem_we      : out std_logic;
      o_load_data   : out std_logic_vector(31 downto 0)
    );
  end component;

begin

  with iInstLd select
    s_IMemAddr <= s_NextInstAddr when '0',
      iInstAddr when others;

  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst);
  
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

-- ========= 1) Decode fields =========
s_opcode <= s_Inst(6  downto 0);
s_rd     <= s_Inst(11 downto 7);
s_funct3 <= s_Inst(14 downto 12);
s_rs1    <= s_Inst(19 downto 15);
s_rs2    <= s_Inst(24 downto 20);
s_funct7 <= s_Inst(31 downto 25);

-- Destination register (rd) for regfile writeback
s_RegWrAddr <= s_rd;

-- Shift amount: R-type uses rs2 *value*; I-type uses shamt field
s_ALUShiftAmt <= s_rs2_val(4 downto 0) when (s_opcode = "0110011" and (s_funct3 = "001" or s_funct3 = "101")) else
                 s_Inst(24 downto 20)  when (s_opcode = "0010011" and (s_funct3 = "001" or s_funct3 = "101")) else
                 (others => '0');

-- ========= 2) PC Fetch Unit =========
  PCU: PCFetch
    generic map(G_RESET_VECTOR => x"00000000")
    port map(
      i_clk       => iCLK,
      i_rst       => iRST,
      i_halt      => s_Halt,
      i_pc_src    => PCSrc,
      i_br_taken  => s_BrTaken,
      i_rs1_val   => s_rs1_val,
      i_immI      => s_immI,
      i_immB      => (others => '0'),
      i_immJ      => (others => '0'),
      o_pc        => s_PC,
      o_pc_plus4  => s_PCPlus4,
      o_imem_addr => s_NextInstAddr
    );

-- ========= 3) Immediate Generator =========
U_IMM: imm_generator
   port map(
    i_instr => s_Inst,
    i_kind  => s_ImmKind,
    o_imm   => s_immI
   );

-- ========= 4) Control Unit =========
  U_CTRL: ControlUnit
    port map(
      opcode     => s_opcode,
      funct3     => s_funct3,
      funct7     => s_funct7,
      ALUSrcA    => s_ALUSrcA,    -- NEW: selects PC for AUIPC
      ALUSrc     => s_ALUSrcSel,
      ALUControl => open,
      ImmType    => s_ImmKind, 
      ResultSrc  => s_WBSel,
      MemWrite   => s_MemWrite,    
      RegWrite   => s_RegWr,
      ALU_op     => s_ALUCtrl,
      Halt       => s_Halt,
      MemRead    => s_MemRead,
      LdByte     => s_LdByte,
      LdHalf     => s_LdHalf,
      LdUnsigned => s_LdUnsigned,
      StByte     => s_StByte,
      StHalf     => s_StHalf
    );

-- ========= 5) Register File =========
REGFILE: reg
   generic map(N => 32)
   port map(
    RS1     => s_rs1,
    RS2     => s_rs2,
    DATA_IN => s_RegWrData,
    W_SEL   => s_RegWrAddr,
    WE      => s_RegWr,
    RST     => iRST,
    CLK     => iCLK,
    RS1_OUT => s_rs1_val,
    RS2_OUT => s_rs2_val
   );

-- ========= 6) ALU Input A MUX (NEW - for AUIPC support) =========
MUX_ALU_A: mux2t1_N
  generic map(N => 32)
  port map(
    i_S  => s_ALUSrcA,    -- 0 = rs1, 1 = PC (for AUIPC)
    i_D0 => s_rs1_val,    -- rs1 value (normal operations)
    i_D1 => s_PC,         -- PC value (for AUIPC)
    o_O  => s_ALUInA      -- goes to ALU port A
  );

-- ========= 7) ALU Input B MUX =========
MUX_ALU_B: mux2t1_N
  generic map(N => 32)
  port map(
    i_S  => s_ALUSrcSel,  -- 0 = rs2, 1 = immI
    i_D0 => s_rs2_val,    -- rs2 value (R-type)
    i_D1 => s_immI,       -- immediate (I-type)
    o_O  => s_ALUInB      -- goes to ALU port B
  );

-- ========= 8) ALU =========
ALU0: ALUUnit
  port map(
    A         => s_ALUInA,      -- CHANGED: now uses muxed input (rs1 or PC)
    B         => s_ALUInB,
    shift_amt => s_ALUShiftAmt,
    ALU_op    => s_ALUCtrl,    
    F         => s_ALURes,
    Zero      => s_ALUZero,
    Overflow  => s_ALUOvfl
  );

-- ========= 9) Load/Store Unit =========
LSU: load_store_unit
  port map(
    i_addr        => s_ALURes,
    i_rs2_wdata   => s_rs2_val,
    i_mem_read    => s_MemRead,
    i_mem_write   => s_MemWrite,
    i_ld_byte     => s_LdByte,
    i_ld_half     => s_LdHalf,
    i_ld_unsigned => s_LdUnsigned,
    i_st_byte     => s_StByte,
    i_st_half     => s_StHalf,
    o_mem_addr    => s_DMemAddr,
    o_mem_wdata   => s_DMemData,
    o_mem_be      => s_LSUBEn,
    o_mem_re      => open,
    o_mem_we      => s_DMemWr,
    i_mem_rdata   => s_DMemOut,
    o_load_data   => s_LoadedData
  );

-- ========= 10) Writeback MUX =========
MUX_WB: mux2t1_N
    generic map(N => 32)
    port map(
    i_S  => s_WBSel,
    i_D0 => s_ALURes,
    i_D1 => s_LoadedData,
    o_O  => s_WBData
    );

-- ========= 11) Connect writeback data =========
s_RegWrData <= s_WBData;

-- ========= 12) Output signals =========
oALUOut <= s_ALURes;
s_Ovfl  <= s_ALUOvfl;

end structure;