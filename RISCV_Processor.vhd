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
       oALUOut         : out std_logic_vector(N-1 downto 0)); -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.

end  RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
  -- Required register file signals 
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_NextInstAddr instead
  signal s_NextInstAddr : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0) := (others=> '0'); -- TODO: use this signal as the instruction signal 

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Opcode: 01 0100)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- TODO: this signal indicates an overflow exception would have been initiated

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

  -- TODO: You may add any additional signals or components your implementation 
  --       requires below this comment

--PC Path signals
signal s_PC : std_logic_vector(N-1 downto 0) := x"00000000";
signal s_PCPlus4 : std_logic_vector(N-1 downto 0);
signal PCSrc : pc_src_t;
signal s_BrTaken : std_logic := '0'; --Branch taken 0 or 1


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
signal s_ImmKind : std_logic_vector(2 downto 0); -- 000=R...., Selects what instruction type for control unit
signal s_immI : std_logic_vector(N-1 downto 0) := (others => '0');
signal s_immB : std_logic_vector(31 downto 0) := (others => '0');
signal s_immJ : std_logic_vector(31 downto 0) := (others => '0');

--ALU signals
signal s_ALUSrcSel : std_logic := '0'; --0: rs2, 1: immI
signal s_ALUInB : std_logic_vector(N-1 downto 0) := (others => '0'); --second ALU input
signal s_ALURes : std_logic_vector(N-1 downto 0); --ALU Result signal
signal s_ALUCtrl : std_logic_vector(3 downto 0) := (others=>'0');
signal s_ALUOvfl : std_logic;
signal s_ALU2BitControl : std_logic_vector(1 downto 0);
signal s_ALUShiftAmt : std_logic_vector(4 downto 0) := (others=>'0');
signal s_ALUZero : std_logic := '0'; --Zero flag signal

--Writeback signals
signal s_WBSel : std_logic := '0';
signal s_WBData : std_logic_vector(31 downto 0) := (others=> '0');


--Control unit instantiation
  component ControlUnit is
    port(
      opcode     : in  std_logic_vector(6 downto 0);
      funct3     : in  std_logic_vector(2 downto 0);
      funct7     : in  std_logic_vector(6 downto 0);
      ALUSrc     : out std_logic;
      ALUControl : out std_logic_vector(1 downto 0);
      ImmType    : out std_logic_vector(2 downto 0);
      ResultSrc  : out std_logic;
      MemWrite   : out std_logic;
      RegWrite   : out std_logic;
      ALU_op     : out std_logic_vector(3 downto 0)
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
      ALU_op    : in  std_logic_vector(3 downto 0);  -- matches your fixed encodings
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
      i_kind  : in  std_logic_vector(2 downto 0);  -- 000=R,001=I,010=S,011=SB,100=U,101=UJ
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
      i_pc_src    : in  pc_src_t;    -- SEQ, BR_TGT, JAL_TGT, JALR_TGT
      i_br_taken  : in  std_logic;
      i_rs1_val   : in  std_logic_vector(31 downto 0); -- for JALR
      i_immI      : in  std_logic_vector(31 downto 0);
      i_immB      : in  std_logic_vector(31 downto 0);
      i_immJ      : in  std_logic_vector(31 downto 0);
      o_pc        : out std_logic_vector(31 downto 0);
      o_pc_plus4  : out std_logic_vector(31 downto 0);
      o_imem_addr : out std_logic_vector(31 downto 0)
    );
  end component;



begin

  -- TODO: This is required to be your final input to your instruction memory. This provides a feasible method to externally load the memory module which means that the synthesis tool must assume it knows nothing about the values stored in the instruction memory. If this is not included, much, if not all of the design is optimized out because the synthesis tool will believe the memory to be all zeros.
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

  -- TODO: Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 01 0100)
  -- TODO: Ensure that s_Ovfl is connected to the overflow output of your ALU

  -- TODO: Implement the rest of your processor below this comment! 
-- ========= 1) Decode fields (must be before ControlUnit) =========
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


  PCU: PCFetch
    generic map(G_RESET_VECTOR => to_unsigned(16#00100100#, 32))
    port map(
      i_clk=> iCLK,
      i_rst=> iRST,
      i_halt=> s_Halt,
      i_pc_src => PCSrc,
      i_br_taken => s_BrTaken, --NEEDS TO BE IMPLEMENTED
      -- targets (only immI matters for JALR later; tie B/J to zero for now)
      i_rs1_val   => s_rs1_val,
      i_immI      => s_immI,
      i_immB      => (others => '0'), --WILL BE CHANGED WHEN FURTHER IMPLEMENTING
      i_immJ      => (others => '0'), --WILL BE CHANGED WHEN FURTHER IMPLEMENTING
      o_pc        => s_PC, --Current PC
      o_pc_plus4  => s_PCPlus4, --PC + 4
      o_imem_addr => s_NextInstAddr    -- Feeds IMEM the addr
    );



--Immediate generator
U_IMM: imm_generator
   port map(
	i_instr => s_Inst,
	i_kind => s_ImmKind,
	o_imm => s_ImmI
	);
--Control unit
  U_CTRL: ControlUnit
    port map(
      opcode     => s_opcode,
      funct3     => s_funct3,
      funct7     => s_funct7,
      ALUSrc     => s_ALUSrcSel,
      ALUControl => open, --MIGHT NOT BE RIGHT
      ImmType    => s_ImmKind, 
      ResultSrc  => s_WBSel,   --Reading from mem
      MemWrite   => s_DMemWr,    
      RegWrite   => s_RegWr,
      ALU_op     => s_ALUCtrl --OUTPUT of ctrl unit which is 4-bit control for ALU
    );
--Reg file logic
REGFILE: reg
   generic map(N => 32)
   port map(
	RS1 => s_rs1,
	RS2 => s_rs2,
	DATA_IN => s_RegWrData, --From WB Mux
	W_SEL => s_RegWrAddr, --RD 
	WE => s_RegWr,
	RST => iRST,
	CLK => iCLK,
	RS1_OUT => s_rs1_val,
	RS2_OUT => s_rs2_val
        );
	

--ALU operand B-select MUX. This calculates branch address before going into the ALU
MUX_ALU_B: mux2t1_N
  generic map(N => 32)
  port map(
    i_S  => s_ALUSrcSel,  -- control: 0 = rs2, 1 = immI
    i_D0 => s_rs2_val,    -- rs2 value (R-type)
    i_D1 => s_immI,       -- immediate (I-type)
    o_O  => s_ALUInB      -- goes into ALU.B
  );


--ALU logic
ALU0: ALUUnit
  port map(
    A         => s_rs1_val,
    B         => s_ALUInB,
    shift_amt => s_ALUShiftAmt,
    ALU_op    => s_ALUCtrl,    
    F         => s_ALURes, --ALU Result
    Zero      => s_ALUZero,
    Overflow  => s_ALUOvfl);


--Writeback MUX
MUX_WB: mux2t1_N
    generic map(N => 32)
    port map(
	i_S => s_WBSel,
	i_D0 => s_ALURes,
	i_D1 => s_DMemOut, --In the future will need to support loads
	o_O => s_WBData
	);

 s_RegWrData <= s_WBData;


-- Synthesis keep-alive and flags
oALUOut <= s_ALURes;
s_Ovfl  <= s_ALUOvfl;

-- Sequential PC defaults (already good)
s_Halt    <= '0';
PCSrc     <= PC_SEQ;
s_BrTaken <= '0';

end structure;
