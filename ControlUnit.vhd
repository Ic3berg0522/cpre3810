--GitHubControlUnit
--Michael Berg
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.RISCV_types.all;

entity ControlUnit is
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
        ALU_op     : out std_logic_vector(3 downto 0);
        Halt       : out std_logic;
        MemRead    : out std_logic;
        LdByte     : out std_logic;
        LdHalf     : out std_logic;
        LdUnsigned : out std_logic;
        StByte     : out std_logic;
        StHalf     : out std_logic;
        ASel       : out std_logic_vector(1 downto 0);
        Branch     : out std_logic;
        PCSrc      : out pc_src_t
        );
end ControlUnit;

architecture Behavioral of ControlUnit is
begin
    -- ALUSrc
    ALUSrc <= '1' when (opcode = "0010011" or opcode = "0000011" or opcode = "0100011" or 
                        opcode = "0110111" or opcode = "0010111" or opcode = "1101111" or 
                        opcode = "1100111") else '0';
    
    -- RegWrite
    RegWrite <= '1' when (opcode = "0010011" or opcode = "0110011" or opcode = "0000011" or 
                          opcode = "0110111" or opcode = "0010111" or opcode = "1101111" or 
                          opcode = "1100111") else '0';
    
    -- ResultSrc
    ResultSrc <= '1' when (opcode = "0000011") else '0';
    
    -- MemWrite
    MemWrite <= '1' when (opcode = "0100011") else '0';
    
    -- MemRead
    MemRead <= '1' when (opcode = "0000011") else '0';
    
    -- Branch
    Branch <= '1' when (opcode = "1100011") else '0';
    
    -- Halt
    Halt <= '1' when (opcode = "1110011") else '0';
    
    -- PCSrc
    PCSrc <= PC_BR_TGT when (opcode = "1100011") else PC_SEQ;
    
    -- ASel
    ASel <= "01" when (opcode = "0010111") else "00";
    
    -- ImmType
    ImmType <= "001" when (opcode = "0010011" or opcode = "0000011" or opcode = "1100111") else
               "010" when (opcode = "0100011") else
               "011" when (opcode = "1100011") else
               "100" when (opcode = "0110111" or opcode = "0010111") else
               "101" when (opcode = "1101111") else
               "000";
    
    -- ALU_op
    ALU_op <= "0000" when (opcode = "0010011" and funct3 = "000") else  -- addi
              "0010" when (opcode = "0010011" and funct3 = "111") else  -- andi
              "0100" when (opcode = "0010011" and funct3 = "100") else  -- xori
              "0011" when (opcode = "0010011" and funct3 = "110") else  -- ori
              "0110" when (opcode = "0010011" and funct3 = "010") else  -- slti
              "1011" when (opcode = "0010011" and funct3 = "011") else  -- sltiu
              "0111" when (opcode = "0010011" and funct3 = "001") else  -- slli
              "1001" when (opcode = "0010011" and funct3 = "101" and funct7 = "0100000") else  -- srai
              "1000" when (opcode = "0010011" and funct3 = "101") else  -- srli
              "0001" when (opcode = "0110011" and funct3 = "000" and funct7 = "0100000") else  -- sub
              "0000" when (opcode = "0110011" and funct3 = "000") else  -- add
              "0010" when (opcode = "0110011" and funct3 = "111") else  -- and
              "0100" when (opcode = "0110011" and funct3 = "100") else  -- xor
              "0011" when (opcode = "0110011" and funct3 = "110") else  -- or
              "0110" when (opcode = "0110011" and funct3 = "010") else  -- slt
              "0111" when (opcode = "0110011" and funct3 = "001") else  -- sll
              "1001" when (opcode = "0110011" and funct3 = "101" and funct7 = "0100000") else  -- sra
              "1000" when (opcode = "0110011" and funct3 = "101") else  -- srl
              "0000" when (opcode = "0000011") else  -- loads
              "0000" when (opcode = "0100011") else  -- stores
              "0001" when (opcode = "1100011") else  -- branches
              "0000" when (opcode = "0110111") else  -- lui
              "0000" when (opcode = "0010111") else  -- auipc
              "1111" when (opcode = "1110011") else  -- wfi
              "0000";
    
    -- Load/Store signals
    LdByte <= '1' when (opcode = "0000011" and (funct3 = "000" or funct3 = "100")) else '0';
    LdHalf <= '1' when (opcode = "0000011" and (funct3 = "001" or funct3 = "101")) else '0';
    LdUnsigned <= '1' when (opcode = "0000011" and (funct3 = "100" or funct3 = "101")) else '0';
    
    StByte <= '1' when (opcode = "0100011" and funct3 = "000") else '0';
    StHalf <= '1' when (opcode = "0100011" and funct3 = "001") else '0';
    
    -- ALUControl (not used much but keeping for compatibility)
    ALUControl <= "00";
    
end Behavioral;