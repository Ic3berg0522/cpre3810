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
        ImmType    : out std_logic_vector(2 downto 0);  -- 000=R,001=I,010=S,011=SB,100=U,101=UJ
        ResultSrc  : out std_logic;                    
        MemWrite   : out std_logic;
        RegWrite   : out std_logic;
        ALU_op     : out std_logic_vector(3 downto 0);    -- 0000=ADD,0001=SUB,0010=AND,0011=OR,0100=XOR,0110=SLT,0111=SLL,1000=SRL,1001=SRA,1011=SLTU
        Halt       : out std_logic   
        );
end ControlUnit;

architecture Behavioral of ControlUnit is
begin
    process(opcode, funct3, funct7)
    begin
        -- defaults
        ALUSrc     <= '0';
        ALUControl <= "00";
        ImmType    <= "000";  -- R
        ResultSrc  <= '0';
        MemWrite   <= '0';
        RegWrite   <= '0';
        ALU_op     <= "0000"; -- ADD
        Halt       <= '0';

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
                ALU_op     <= "0111";  -- SLLI
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
            ImmType    <= "000";          -- R

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

        -- sw 
        elsif opcode = "0100011" then
            ALUSrc     <= '1';
            MemWrite   <= '1';
            RegWrite   <= '0';
            ImmType    <= "010";         
            ALUControl <= "00";
            ALU_op     <= "0000";

        -- bew, bne, blt, bge, bltu, bgeu
        elsif opcode = "1100011" then
            ALUSrc     <= '0';
            RegWrite   <= '0';
            ImmType    <= "011";          
            ALUControl <= "00";
            ALU_op     <= "0001";         

        -- auipc
        elsif opcode = "0010111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "100";         
            ALUControl <= "00";
            ALU_op     <= "0000";

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
        elsif opcode = "0100100" then
            RegWrite   <= '0';
            ALU_op     <= "1111";
            Halt       <= '1';
        end if;
    end process;
end Behavioral;