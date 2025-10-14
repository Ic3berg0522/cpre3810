--Dylan Kramer and Michael Berg
--Top Level implementation

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.RISCV_types.all;   -- expects DATA_WIDTH, ADDR_WIDTH, pc_src_t (SEQ, BR_TGT, JAL_TGT, JALR_TGT)

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(
    iCLK      : in  std_logic;
    iRST      : in  std_logic;
    iInstLd   : in  std_logic;
    iInstAddr : in  std_logic_vector(N-1 downto 0);
    iInstExt  : in  std_logic_vector(N-1 downto 0);
    oALUOut   : out std_logic_vector(N-1 downto 0)
  );
end  RISCV_Processor;

architecture structure of RISCV_Processor is
  --Instruction and data memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0);
  signal s_NextInstAddr : std_logic_vector(N-1 downto 0);
  signal s_Inst         : std_logic_vector(N-1 downto 0);

  signal s_DMemWr       : std_logic;
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0);
  signal s_DMemData     : std_logic_vector(N-1 downto 0);
  signal s_DMemOut      : std_logic_vector(N-1 downto 0);

  --Signals for PC fetch
  signal s_pc           : std_logic_vector(31 downto 0);
  signal s_pc_plus4     : std_logic_vector(31 downto 0);
  signal s_pc_src       : pc_src_t;
  signal s_br_taken     : std_logic := '0';

  --Decoding signals
  signal s_rs1_addr     : std_logic_vector(4 downto 0);
  signal s_rs2_addr     : std_logic_vector(4 downto 0);
  signal s_rd_addr      : std_logic_vector(4 downto 0);
  signal s_opcode       : std_logic_vector(6 downto 0);
  signal s_funct3       : std_logic_vector(2 downto 0);
  signal s_funct7       : std_logic_vector(6 downto 0);

  --signals for reg file
  signal s_RegWr        : std_logic;
  signal s_RegWrAddr    : std_logic_vector(4 downto 0);
  signal s_RegWrData    : std_logic_vector(31 downto 0);
  signal s_rs1_val      : std_logic_vector(31 downto 0);
  signal s_rs2_val      : std_logic_vector(31 downto 0);

 --control unit output signals
  signal s_ALUSrc       : std_logic;                    -- 1: B=immI, 0: B=rs2
  signal s_ALUControl   : std_logic_vector(1 downto 0); -- kept for compatibility
  signal s_ImmType      : std_logic_vector(2 downto 0); -- "000"=I, "111"=R, "001"=S, "010"=SB, "011"=U, "100"=UJ
  signal s_ResultSrc    : std_logic;                    -- 0=ALU, 1=DMem
  signal s_RegWriteCU   : std_logic;
  signal s_ALUop        : std_logic_vector(3 downto 0); -- to ALUUnit

--immediate signals
  signal s_immI         : std_logic_vector(31 downto 0); -- I-type
  signal s_immB         : std_logic_vector(31 downto 0); -- SB-type
  signal s_immU         : std_logic_vector(31 downto 0); -- U-type
  signal s_immJ         : std_logic_vector(31 downto 0); -- UJ-type

--alu signals
  signal s_ALU_A        : std_logic_vector(31 downto 0);
  signal s_ALU_B        : std_logic_vector(31 downto 0);
  signal s_shift_amt    : std_logic_vector(4 downto 0);
  signal s_ALU_Y        : std_logic_vector(31 downto 0);
  signal s_ALU_Zero     : std_logic;
  signal s_ALU_Ovfl     : std_logic;

--load and store control signals
  signal s_is_load      : std_logic;
  signal s_is_store     : std_logic;
  signal s_lsu_we       : std_logic;
  signal s_lsu_addr     : std_logic_vector(31 downto 0);
  signal s_lsu_wdata    : std_logic_vector(31 downto 0);
  signal s_lsu_rdata    : std_logic_vector(31 downto 0);

--jump, lui and auipc helper signals
  signal s_is_branch    : std_logic;
  signal s_is_jal       : std_logic;
  signal s_is_jalr      : std_logic;
  signal s_is_lui       : std_logic;
  signal s_is_auipc     : std_logic;
  signal s_auipc_res    : std_logic_vector(31 downto 0);

--included mem
  component mem is
    generic(ADDR_WIDTH : integer; DATA_WIDTH : integer);
    port(
      clk  : in  std_logic;
      addr : in  std_logic_vector((ADDR_WIDTH-1) downto 0);
      data : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      we   : in  std_logic := '1';
      q    : out std_logic_vector((DATA_WIDTH-1) downto 0)
    );
  end component;
--reg file
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
--Immediate generator
  component imm_generator is
    port(
      i_instr : in  std_logic_vector(31 downto 0);
      i_kind  : in  std_logic_vector(2 downto 0);  -- 000=R,001=I,010=S,011=SB,100=U,101=UJ
      o_imm   : out std_logic_vector(31 downto 0)
    );
  end component;
--PC fetch unit
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
--Load and store unit instantiation
  component load_store_unit is
    port (
      i_addr      : in  std_logic_vector(31 downto 0);
      i_wdata     : in  std_logic_vector(31 downto 0);
      i_load      : in  std_logic;
      i_store     : in  std_logic;
      i_funct3    : in  std_logic_vector(2 downto 0);
      o_mem_we    : out std_logic;
      o_mem_addr  : out std_logic_vector(31 downto 0);
      o_mem_wdata : out std_logic_vector(31 downto 0);
      i_mem_rdata : in  std_logic_vector(31 downto 0);
      o_load_data : out std_logic_vector(31 downto 0)
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

  -- Small wires for adders/muxes we?ll use explicitly
  signal s_auipc_cout : std_logic;
  signal s_wb_from_mem: std_logic_vector(31 downto 0);
  signal s_wb_core    : std_logic_vector(31 downto 0);
  signal s_wb_jlink   : std_logic_vector(31 downto 0);

begin
--IMEM address selection logic
  IMEM_ADDR_SEL: mux2t1_N
    generic map (N => N)
    port map(
      i_S  => iInstLd,
      i_D0 => s_NextInstAddr,
      i_D1 => iInstAddr,
      o_O  => s_IMemAddr
    );

  --IMEM logic
  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH, DATA_WIDTH => N)
    port map(
      clk  => iCLK,
      addr => s_IMemAddr(11 downto 2),
      data => iInstExt,
      we   => iInstLd,
      q    => s_Inst
    );

  --DMEM logic
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH, DATA_WIDTH => N)
    port map(
      clk  => iCLK,
      addr => s_DMemAddr(11 downto 2),
      data => s_DMemData,
      we   => s_DMemWr,
      q    => s_DMemOut
    );

--PC fetch logic
  U_PC: PCFetch
    generic map ( G_RESET_VECTOR => to_unsigned(0,32) )
    port map (
      i_clk       => iCLK,
      i_rst       => iRST,
      i_halt      => '0',
      i_pc_src    => s_pc_src,
      i_br_taken  => s_br_taken,
      i_rs1_val   => s_rs1_val,   -- JALR base
      i_immI      => s_immI,
      i_immB      => s_immB,
      i_immJ      => s_immJ,
      o_pc        => s_pc,
      o_pc_plus4  => s_pc_plus4,
      o_imem_addr => s_NextInstAddr
    );

  ----------------------------------------------------------------------------
  -- Decode fields (RV32I)
  ----------------------------------------------------------------------------
  s_rs1_addr <= s_Inst(19 downto 15);
  s_rs2_addr <= s_Inst(24 downto 20);
  s_rd_addr  <= s_Inst(11 downto 7);
  s_opcode   <= s_Inst(6 downto 0);
  s_funct3   <= s_Inst(14 downto 12);
  s_funct7   <= s_Inst(31 downto 25);

  ----------------------------------------------------------------------------
  -- Control Unit
  ----------------------------------------------------------------------------
  U_CTRL: ControlUnit
    port map(
      opcode     => s_opcode,
      funct3     => s_funct3,
      funct7     => s_funct7,
      ALUSrc     => s_ALUSrc,
      ALUControl => s_ALUControl,
      ImmType    => s_ImmType,
      ResultSrc  => s_ResultSrc,   -- 1 for loads
      MemWrite   => open,          -- LSU will control DMem write (more precise)
      RegWrite   => s_RegWriteCU,
      ALU_op     => s_ALUop
    );

--generates immediates for I, SB, U and J type
  U_IMM_I: imm_generator  port map ( i_instr => s_Inst, i_kind => "001", o_imm => s_immI ); -- I
  U_IMM_B: imm_generator  port map ( i_instr => s_Inst, i_kind => "011", o_imm => s_immB ); -- SB
  U_IMM_U: imm_generator  port map ( i_instr => s_Inst, i_kind => "100", o_imm => s_immU ); -- U
  U_IMM_J: imm_generator  port map ( i_instr => s_Inst, i_kind => "101", o_imm => s_immJ ); -- UJ

  ----------------------------------------------------------------------------
  -- Register file
  ----------------------------------------------------------------------------
  regFile : reg
    generic map (N => DATA_WIDTH)
    port map(
      RS1      => s_rs1_addr,
      RS2      => s_rs2_addr,
      DATA_IN  => s_RegWrData,
      W_SEL    => s_RegWrAddr,
      WE       => s_RegWr,
      RST      => iRST,
      CLK      => iCLK,
      RS1_OUT  => s_rs1_val,
      RS2_OUT  => s_rs2_val
    );

--ADD BRANCH OP LOGIC


--ALU ops
  s_ALU_A <= s_rs1_val;
  s_ALU_B <= s_immI when s_ALUSrc = '1' else s_rs2_val;

  -- shift amount: rs2[4:0] for R-type shifts; instr[24:20] for shift-immediates
  s_shift_amt <= s_Inst(24 downto 20) when (s_opcode = "0010011" and (s_funct3 = "001" or s_funct3 = "101"))
                 else s_rs2_val(4 downto 0);

--ALU logic
  U_ALU: ALUUnit
    port map(
      A         => s_ALU_A,
      B         => s_ALU_B,
      shift_amt => s_shift_amt,
      ALU_op    => s_ALUop,     -- ensure ControlUnit encoding matches ALUUnit
      F         => s_ALU_Y,
      Zero      => s_ALU_Zero,
      Overflow  => s_ALU_Ovfl
    );

--RE ADD LOAD/STORE

  ----------------------------------------------------------------------------
  -- Jumps / LUI / AUIPC detection and results
  ----------------------------------------------------------------------------
  s_is_jal   <= '1' when s_opcode = "1101111" else '0';
  s_is_jalr  <= '1' when s_opcode = "1100111" else '0';
  s_is_lui   <= '1' when s_opcode = "0110111" else '0';
  s_is_auipc <= '1' when s_opcode = "0010111" else '0';

  -- AUIPC result = PC + U-imm (use your n_ripple_full_adder)
  AUIPC_ADD: n_ripple_full_adder
    generic map ( N => 32 )
    port map (
      D0   => s_pc,
      D1   => s_immU,
      Cin  => '0',
      S    => s_auipc_res,
      Cout => s_auipc_cout
    );

  ----------------------------------------------------------------------------
  -- PC source select (no branch_pred; use inline s_br_taken)
  ----------------------------------------------------------------------------
  s_pc_src <=
    PC_JAL_TGT   when s_is_jal  = '1' else
    PC_JALR_TGT  when s_is_jalr = '1' else
    PC_BR_TGT    when (s_is_branch = '1' and s_br_taken = '1') else
    PC_SEQ;

  ----------------------------------------------------------------------------
  -- Writeback data select using your mux2t1_N chain (priority):
  --   1) JAL/JALR write back PC+4
  --   2) LOADs write back LSU data
  --   3) LUI writes U-immediate
  --   4) AUIPC writes PC+U-imm
  --   5) otherwise ALU result
  ----------------------------------------------------------------------------
  -- ALU vs DMem (ResultSrc)
  WB_ALU_vs_MEM: mux2t1_N
    generic map ( N => 32 )
    port map (
      i_S  => s_ResultSrc,          -- 1 = MEM
      i_D0 => s_ALU_Y,
      i_D1 => s_lsu_rdata,
      o_O  => s_wb_from_mem         -- ALU or MEM
    );

  -- LUI override
  WB_LUI: mux2t1_N
    generic map ( N => 32 )
    port map (
      i_S  => s_is_lui,
      i_D0 => s_wb_from_mem,
      i_D1 => s_immU,
      o_O  => s_wb_core
    );

  -- AUIPC override
  WB_AUIPC: mux2t1_N
    generic map ( N => 32 )
    port map (
      i_S  => s_is_auipc,
      i_D0 => s_wb_core,
      i_D1 => s_auipc_res,
      o_O  => s_wb_jlink
    );

  -- JAL/JALR final override: rd = PC+4
  WB_JAL_JALR: mux2t1_N
    generic map ( N => 32 )
    port map (
      i_S  => (s_is_jal or s_is_jalr),
      i_D0 => s_wb_jlink,
      i_D1 => s_pc_plus4,
      o_O  => s_RegWrData
    );

  -- RegWrite from ControlUnit, but block x0
  s_RegWr     <= '1' when (s_RegWriteCU = '1' and s_rd_addr /= "00000") else '0';
  s_RegWrAddr <= s_rd_addr;

  ----------------------------------------------------------------------------
  -- Hook LSU address/data to DMem and expose ALU result
  ----------------------------------------------------------------------------
  oALUOut <= s_ALU_Y;    -- synthesis anchor (keeps datapath from being optimized away)

end structure;

