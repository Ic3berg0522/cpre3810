--Michael Berg
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnit is
    port(
        opcode    : in  std_logic_vector(6 downto 0);
        funct3    : in  std_logic_vector(2 downto 0);
        funct7    : in  std_logic_vector(6 downto 0);
        ALUSrc    : out std_logic;
        ALUControl: out std_logic_vector(1 downto 0);
        ImmType   : out std_logic_vector(2 downto 0);
        ResultSrc : out std_logic;
        MemWrite  : out std_logic;
        RegWrite  : out std_logic;
	ALU_op : out std_logic_vector(3 downto 0)
    );
end ControlUnit;

architecture Behavioral of ControlUnit is

begin

    process(opcode, funct3, funct7)
    begin
        -- Default NOP
        ALUSrc     <= '0';
        ALUControl <= "00";
        ImmType    <= "000";
        ResultSrc  <= '0';
        MemWrite   <= '0';
        RegWrite   <= '0';
	ALU_op <= "0000";

        if opcode = "0010011" then 
            if funct3 = "000" then --addi
                ResultSrc  <= '0';
                ALUSrc     <= '1';
                ALUControl <= "00";
                ImmType    <= "000";
                MemWrite   <= '0';
                RegWrite   <= '1';	
		ALU_op <= "0000";

            elsif funct3 = "111" then --andi
                ResultSrc  <= '0';
                ALUSrc     <= '1';
                ALUControl <= "10";
                ImmType    <= "000";
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0010";

            elsif funct3 = "100" then --xori
                ResultSrc  <= '0';
                ALUSrc     <= '1';
                ALUControl <= "10";
                ImmType    <= "000";
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0100";

            elsif funct3 = "110" then --ori
                ResultSrc  <= '0';
                ALUSrc     <= '1';
                ALUControl <= "10";
                ImmType    <= "000";
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0011";

            elsif funct3 = "010" then --slti
                ResultSrc  <= '0';
                ALUSrc     <= '1';
                ALUControl <= "01";
                ImmType    <= "000";
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0110";

            elsif funct3 = "011" then --sltiu
                ResultSrc  <= '0';
                ALUSrc     <= '1';
                ALUControl <= "01";
                ImmType    <= "000";
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0110";

            elsif funct3 = "101" then --srli
                ALUSrc     <= '1';
                ALUControl <= "11";
                ImmType    <= "000";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0100";
		if funct7 = "0100000" then -- srai
			ALU_op <= "1001";
		end if;
            end if;

        elsif opcode = "0110011" then 
            if funct3 = "000" then --add
                ALUSrc     <= '0';
                ALUControl <= "00";
                ImmType    <= "111";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0010";
		if funct7 = "0100000" then -- sub
			ALU_op <= "0001";
		end if;
            elsif funct3 = "111" then --and
                ALUSrc     <= '0';
                ALUControl <= "10";
                ImmType    <= "111";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0010";

            elsif funct3 = "100" then --xor
                ALUSrc     <= '0';
                ALUControl <= "10";
                ImmType    <= "111";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0100";

            elsif funct3 = "110" then --or
                ALUSrc     <= '0';
                ALUControl <= "10";
                ImmType    <= "111";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0011";

            elsif funct3 = "010" then --slt
                ALUSrc     <= '0';
                ALUControl <= "01";
                ImmType    <= "111";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0010";

            elsif funct3 = "001" then --sll
                ALUSrc     <= '0';
                ALUControl <= "11";
                ImmType    <= "111";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0111";

            elsif funct3 = "101" then --srl
                ALUSrc     <= '0';
                ALUControl <= "11";
                ImmType    <= "111";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "1000";
		if funct7 = "0100000" then -- sra
			ALU_op <= "1001";
		end if;
            end if;
    
        elsif opcode = "0000011" then 
            if funct3 = "010" then --lw
                ALUSrc     <= '1';
                ALUControl <= "00";
                ImmType    <= "000";
                ResultSrc  <= '1';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0000";

            elsif funct3 = "000" then --lb
                ALUSrc     <= '1';
                ALUControl <= "00";
                ImmType    <= "000";
                ResultSrc  <= '1';
                MemWrite   <= '0';
                RegWrite   <= '1';		
		ALU_op <= "0000";
	
            elsif funct3 = "001" then --lh
                ALUSrc     <= '1';
                ALUControl <= "00";
                ImmType    <= "000";
                ResultSrc  <= '1';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0000";

            elsif funct3 = "100" then --lbu
                ALUSrc     <= '1';
                ALUControl <= "00";
                ImmType    <= "000";
                ResultSrc  <= '1';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0000";

            elsif funct3 = "101" then --lhu
                ALUSrc     <= '1';
                ALUControl <= "00";
                ImmType    <= "000";
                ResultSrc  <= '1';
                MemWrite   <= '0';
                RegWrite   <= '1';
		ALU_op <= "0000";
            end if;
            
        elsif opcode = "0100011" then --sw
            ALUSrc     <= '1';
            ALUControl <= "00";
            ImmType    <= "001";
            ResultSrc  <= '0';
            MemWrite   <= '1';
            RegWrite   <= '0';
	    ALU_op <= "0000";
            
        elsif opcode = "1101111" then --jal
            ALUSrc     <= '1';
            ALUControl <= "00";
            ImmType    <= "100";
            ResultSrc  <= '0';
            MemWrite   <= '0';
            RegWrite   <= '1';
	    
            
        elsif opcode = "1100111" then --jalr
            ALUSrc     <= '1';
            ALUControl <= "00";
            ImmType    <= "000";
            ResultSrc  <= '0';
            MemWrite   <= '0';
            RegWrite   <= '1';
            
        elsif opcode = "0010111" then --auipc
            ALUSrc     <= '1';
            ALUControl <= "00";
            ImmType    <= "011";
            ResultSrc  <= '0';
            MemWrite   <= '0';
            RegWrite   <= '1';
            
        elsif opcode = "1110011" then --wfi
            ALUSrc     <= '0';
            ALUControl <= "00";
            ImmType    <= "111";
            ResultSrc  <= '0';
            MemWrite   <= '0';
            RegWrite   <= '0';
            
        elsif opcode = "1100011" then 
            if funct3 = "000" then --beq
                ALUSrc     <= '0';
                ALUControl <= "00";
                ImmType    <= "010";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '0';
		ALU_op <= "0001";

            elsif funct3 = "001" then --bne
                ALUSrc     <= '0';
                ALUControl <= "00";
                ImmType    <= "010";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '0';
		ALU_op <= "0001";

            elsif funct3 = "100" then --blt
                ALUSrc     <= '0';
                ALUControl <= "00";
                ImmType    <= "010";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '0';
		ALU_op <= "0001";
		
            elsif funct3 = "101" then --bge
                ALUSrc     <= '0';
                ALUControl <= "00";
                ImmType    <= "010";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '0';
		ALU_op <= "0001";
		
            elsif funct3 = "110" then --bltu
                ALUSrc     <= '0';
                ALUControl <= "00";
                ImmType    <= "010";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '0';
		ALU_op <= "0001";

            elsif funct3 = "111" then --bgeu
                ALUSrc     <= '0';
                ALUControl <= "00";
                ImmType    <= "010";
                ResultSrc  <= '0';
                MemWrite   <= '0';
                RegWrite   <= '0';
		ALU_op <= "0001";
            end if;
        end if;

    end process;

end Behavioral;