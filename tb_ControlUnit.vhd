--Michael Berg
--Testbench for RISC-V Control Unit
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_ControlUnit is
end tb_ControlUnit;

architecture Behavioral of tb_ControlUnit is
    -- Component Declaration
    component ControlUnit is
        port(
            opcode    : in  std_logic_vector(6 downto 0);
            funct3    : in  std_logic_vector(2 downto 0);
            funct7    : in  std_logic_vector(6 downto 0);
            ALUSrc    : out std_logic;
            ALUControl: out std_logic_vector(1 downto 0);
            ImmType   : out std_logic_vector(2 downto 0);
            ResultSrc : out std_logic;
            MemWrite  : out std_logic;
            RegWrite  : out std_logic
        );
    end component;

    -- Test signals
    signal opcode    : std_logic_vector(6 downto 0) := (others => '0');
    signal funct3    : std_logic_vector(2 downto 0) := (others => '0');
    signal funct7    : std_logic_vector(6 downto 0) := (others => '0');
    signal ALUSrc    : std_logic;
    signal ALUControl: std_logic_vector(1 downto 0);
    signal ImmType   : std_logic_vector(2 downto 0);
    signal ResultSrc : std_logic;
    signal MemWrite  : std_logic;
    signal RegWrite  : std_logic;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: ControlUnit port map (
        opcode     => opcode,
        funct3     => funct3,
        funct7     => funct7,
        ALUSrc     => ALUSrc,
        ALUControl => ALUControl,
        ImmType    => ImmType,
        ResultSrc  => ResultSrc,
        MemWrite   => MemWrite,
        RegWrite   => RegWrite
    );

    -- Stimulus process
    stim_proc: process
    begin
        -- Test ADDI (I-type: opcode=0010011, funct3=000)
        report "Testing ADDI";
        opcode <= "0010011";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test ANDI (I-type: opcode=0010011, funct3=111)
        report "Testing ANDI";
        opcode <= "0010011";
        funct3 <= "111";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test XORI (I-type: opcode=0010011, funct3=100)
        report "Testing XORI";
        opcode <= "0010011";
        funct3 <= "100";
        funct7 <= "0000000";
        wait for 10 ns;
       

        -- Test ORI (I-type: opcode=0010011, funct3=110)
        report "Testing ORI";
        opcode <= "0010011";
        funct3 <= "110";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test SLTI (I-type: opcode=0010011, funct3=010)
        report "Testing SLTI";
        opcode <= "0010011";
        funct3 <= "010";
        funct7 <= "0000000";
        wait for 10 ns;
       

        -- Test ADD (R-type: opcode=0110011, funct3=000, funct7=0000000)
        report "Testing ADD";
        opcode <= "0110011";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
       

        -- Test SUB (R-type: opcode=0110011, funct3=000, funct7=0100000)
        report "Testing SUB";
        opcode <= "0110011";
        funct3 <= "000";
        funct7 <= "0100000";
        wait for 10 ns;
        

        -- Test AND (R-type: opcode=0110011, funct3=111)
        report "Testing AND";
        opcode <= "0110011";
        funct3 <= "111";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test OR (R-type: opcode=0110011, funct3=110)
        report "Testing OR";
        opcode <= "0110011";
        funct3 <= "110";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test XOR (R-type: opcode=0110011, funct3=100)
        report "Testing XOR";
        opcode <= "0110011";
        funct3 <= "100";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test SLT (R-type: opcode=0110011, funct3=010)
        report "Testing SLT";
        opcode <= "0110011";
        funct3 <= "010";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test SLL (R-type: opcode=0110011, funct3=001)
        report "Testing SLL";
        opcode <= "0110011";
        funct3 <= "001";
        funct7 <= "0000000";
        wait for 10 ns;
      

        -- Test LW (Load: opcode=0000011, funct3=010)
        report "Testing LW";
        opcode <= "0000011";
        funct3 <= "010";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test LB (Load: opcode=0000011, funct3=000)
        report "Testing LB";
        opcode <= "0000011";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
    

        -- Test SW (Store: opcode=0100011)
        report "Testing SW";
        opcode <= "0100011";
        funct3 <= "010";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test JAL (Jump: opcode=1101111)
        report "Testing JAL";
        opcode <= "1101111";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
        
        -- Test JALR (Jump: opcode=1100111)
        report "Testing JALR";
        opcode <= "1100111";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
       
        -- Test AUIPC (opcode=0010111)
        report "Testing AUIPC";
        opcode <= "0010111";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test BEQ (Branch: opcode=1100011, funct3=000)
        report "Testing BEQ";
        opcode <= "1100011";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
     

        -- Test BNE (Branch: opcode=1100011, funct3=001)
        report "Testing BNE";
        opcode <= "1100011";
        funct3 <= "001";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test BLT (Branch: opcode=1100011, funct3=100)
        report "Testing BLT";
        opcode <= "1100011";
        funct3 <= "100";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test WFI (opcode=1110011)
        report "Testing WFI";
        opcode <= "1110011";
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
        

        -- Test default/NOP case
        report "Testing NOP/Default";
        opcode <= "1111111";  -- Invalid opcode
        funct3 <= "000";
        funct7 <= "0000000";
        wait for 10 ns;
        

      
        wait;
    end process;

end Behavioral;