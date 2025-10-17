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
        --Load/Store control signals
        MemRead    : out std_logic;
        LdByte     : out std_logic;
        LdHalf     : out std_logic;
        LdUnsigned : out std_logic;
        StByte     : out std_logic;
        StHalf     : out std_logic;
        --Needed for AUIPC
        ASel       : out std_logic_vector(1 downto 0)
        );
end ControlUnit;

architecture Behavioral of ControlUnit is
begin
    process(opcode, funct3, funct7)
    begin
        -- defaults
        ALUSrc     <= '0';
        ALUControl <= "00";
        ImmType    <= "000"; --Default R-type
        ResultSrc  <= '0';
        MemWrite   <= '0';
        RegWrite   <= '0';
        ALU_op     <= "0000"; --Do add by default
        Halt       <= '0';
        MemRead    <= '0';
        LdByte     <= '0';
        LdHalf     <= '0';
        LdUnsigned <= '0';
        StByte     <= '0';
        StHalf     <= '0';
        ASel       <= "00";

        -- I type functions
        if opcode = "0010011" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "001";          

            if funct3 = "000" then        -- addi
                ALUControl <= "00";
                ALU_op     <= "0000";
            elsif funct3 = "111" then     -- andi
                ALUControl <= "10";
                ALU_op     <= "0010";
            elsif funct3 = "100" then     -- xori
                ALUControl <= "10";
                ALU_op     <= "0100";
            elsif funct3 = "110" then     -- ori
                ALUControl <= "10";
                ALU_op     <= "0011";
            elsif funct3 = "010" then     -- slti
                ALUControl <= "01";
                ALU_op     <= "0110";
            elsif funct3 = "011" then     -- sltiu
                ALUControl <= "01";
                ALU_op     <= "1011";
            elsif funct3 = "001" then  -- slli
                ALUControl <= "11";
                ALU_op     <= "0111";
            elsif funct3 = "101" then     -- srli/srai
                ALUControl <= "11";
                if funct7 = "0100000" then
                    ALU_op <= "1001";     -- srai
                else
                    ALU_op <= "1000";     -- srli
                end if;
            end if;

        -- R type instructions
        elsif opcode = "0110011" then
            ALUSrc     <= '0';
            RegWrite   <= '1';
            ImmType    <= "000";

            if funct3 = "000" then        -- add/sub
                ALUControl <= "00";
                if funct7 = "0100000" then
                    ALU_op <= "0001";     -- sub
                else
                    ALU_op <= "0000";     -- add
                end if;
            elsif funct3 = "111" then     -- and
                ALUControl <= "10";
                ALU_op     <= "0010";
            elsif funct3 = "100" then     -- xor
                ALUControl <= "10";
                ALU_op     <= "0100";
            elsif funct3 = "110" then     -- or
                ALUControl <= "10";
                ALU_op     <= "0011";
            elsif funct3 = "010" then     -- slt
                ALUControl <= "01";
                ALU_op     <= "0110";
            elsif funct3 = "001" then     -- sll
                ALUControl <= "11";
                ALU_op     <= "0111";
            elsif funct3 = "101" then     -- srl/sra
                ALUControl <= "11";
                if funct7 = "0100000" then
                    ALU_op <= "0101";     -- sra
                else
                    ALU_op <= "1000";     -- srl
                end if;
            end if;

        -- lb, lh, lbu, lhu, lw 
        elsif opcode = "0000011" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ResultSrc  <= '1';           
            ImmType    <= "001";          
            ALUControl <= "00";
            ALU_op     <= "0000";
            MemRead    <= '1';
            
            case funct3 is
                when "000" =>  -- LB (sign-extend)
                    LdByte <= '1';
                    LdUnsigned <= '0';
                when "001" =>  -- LH (sign-extend)
                    LdHalf <= '1';
                    LdUnsigned <= '0';
                when "010" =>  -- LW
                    LdUnsigned <= '0';
                when "100" =>  -- LBU (zero-extend)
                    LdByte <= '1';
                    LdUnsigned <= '1';
                when "101" =>  -- LHU (zero-extend)
                    LdHalf <= '1';
                    LdUnsigned <= '1';
                when others =>
                    null;
            end case;

        -- sb, sh, sw 
        elsif opcode = "0100011" then
            ALUSrc     <= '1';
            MemWrite   <= '1';
            RegWrite   <= '0';
            ImmType    <= "010";         
            ALUControl <= "00";
            ALU_op     <= "0000";
            
            case funct3 is
                when "000" =>  -- SB
                    StByte <= '1';
                when "001" =>  -- SH
                    StHalf <= '1';
                when "010" =>  -- SW
                    null;
                when others =>
                    null;
            end case;

        -- bew, bne, blt, bge, bltu, bgeu
        elsif opcode = "1100011" then
            ALUSrc     <= '0';
            RegWrite   <= '0';
            ImmType    <= "011";          
            ALUControl <= "00";
            ALU_op     <= "0001";         

        -- lui
        elsif opcode = "0110111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "100";         -- U-type immediate
            ALUControl <= "00";
            ALU_op     <= "0000";

        -- auipc
        elsif opcode = "0010111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "100";         
            ALUControl <= "00";
            ALU_op     <= "0000";
            ASel        <= "01";

        -- jal
        elsif opcode = "1101111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "101";          
            ALUControl <= "00";

        -- jalr
        elsif opcode = "1100111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "001";          
            ALUControl <= "00";

        -- wfi
        elsif opcode = "1110011" then
            RegWrite   <= '0';
            ALU_op     <= "1111";
            Halt       <= '1';
        end if;
    end process;
end Behavioral;