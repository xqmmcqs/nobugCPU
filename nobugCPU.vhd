library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity nobugCPU is
    port(
    CLR, T3, C, Z, MF, PULSE: in std_logic;
    IR: in std_logic_vector(7 downto 4);
    SW, W: in std_logic_vector(3 downto 1);
    DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, LDZ, LDC, CIN, M, ABUS, SBUS, MBUS, SHORT, LONG: out std_logic;
    S, SEL: out std_logic_vector(3 downto 0);
    AAAA: out std_logic
    );
end nobugCPU;

architecture arch of nobugCPU is
    signal WRITE_REG, READ_REG, INS_FETCH, WRITE_MEM, READ_MEM, ST0: std_logic;
    signal ADD, SUB, AND_I, INC, LD, ST, JC, JZ, JMP, STP: std_logic;
    signal NOP, OUT_I, OR_I, CMP, MOV: std_logic;
    signal IRET, INT, INTEN, INTDI, EN_INT, ST1: std_logic;
begin
    WRITE_REG <= '1' when SW = "100" else '0';
    READ_REG <= '1' when SW = "011" else '0';
    INS_FETCH <= '1' when SW = "000" and ST1 = '0' else '0';
    READ_MEM <= '1' when SW = "010" else '0';
    WRITE_MEM <= '1' when SW = "001" else '0';

    ADD <= '1' when IR = "0001" and INS_FETCH = '1' and ST0 = '1' else '0';
    SUB <= '1' when IR = "0010" and INS_FETCH = '1' and ST0 = '1' else '0';
    AND_I <= '1' when IR = "0011" and INS_FETCH = '1' and ST0 = '1' else '0';
    INC <= '1' when IR = "0100" and INS_FETCH = '1' and ST0 = '1' else '0';
    LD <= '1' when IR = "0101" and INS_FETCH = '1' and ST0 = '1' else '0';
    ST <= '1' when IR = "0110" and INS_FETCH = '1' and ST0 = '1' else '0';
    JC <= '1' when IR = "0111" and INS_FETCH = '1' and ST0 = '1' else '0';
    JZ <= '1' when IR = "1000" and INS_FETCH = '1' and ST0 = '1' else '0';
    JMP <= '1' when IR = "1001" and INS_FETCH = '1' and ST0 = '1' else '0';
    STP <= '1' when IR = "1110" and INS_FETCH = '1' and ST0 = '1' else '0';

    NOP <= '1' when IR = "0000" and INS_FETCH = '1' and ST0 = '1' else '0';
    OUT_I <= '1' when IR = "1010" and INS_FETCH = '1' and ST0 = '1' else '0';
    OR_I <= '1' when IR = "1011" and INS_FETCH = '1' and ST0 = '1' else '0';
    CMP <= '1' when IR = "1100" and INS_FETCH = '1' and ST0 = '1' else '0';
    MOV <= '1' when IR = "1101" and INS_FETCH = '1' and ST0 = '1' else '0';

    IRET <= '1' when IR = "1111" and INS_FETCH = '1' and ST0 = '1' else '0';

    process(CLR, T3, W)
    begin
        if (CLR = '0') then
            ST0 <= '0';
        elsif (T3'event and T3 = '0') then
            if (ST0 = '0' and ((WRITE_REG = '1' and W(2) = '1') or (READ_MEM = '1' and W(1) = '1') or (WRITE_MEM = '1' and W(1) = '1') or (INS_FETCH = '1' and W(1) = '1'))) then
                ST0 <= '1';
            elsif (ST0 = '1' and (WRITE_REG = '1' and W(2) = '1')) then
                ST0 <= '0';
            end if;
        end if;
    end process;
    
    process(CLR, T3, W, INT)
	begin
        if (CLR = '0') then
            ST1 <= '0';
        elsif (T3'event and T3 = '0') then    
			if (ST1 = '0' and INT = '1' and (((NOP = '1' or ADD = '1' or SUB = '1' or AND_I = '1' or INC = '1' or JC = '1' or JZ = '1' or JMP = '1' or OUT_I = '1' or OR_I = '1' or CMP = '1' or MOV = '1' or STP = '1' or IRET = '1') and W(2) = '1') or ((ST = '1' or LD = '1') and W(3) = '1'))) then
                ST1 <= '1';
            elsif (ST1 = '1' and INT = '0' and W(2) = '1') then
				ST1 <= '0';
            end if;
        end if;
    end process;

    SBUS <= ((WRITE_REG or (READ_MEM and not ST0) or WRITE_MEM or (INS_FETCH and not ST0)) and W(1)) or (WRITE_REG and W(2)) or (ST1 and W(2));

    SEL(3) <= (WRITE_REG and (W(1) or W(2)) and ST0) or (READ_REG and W(2)) or (INS_FETCH and not ST0 and W(1)) or (INS_FETCH and W(1) and ST0 and EN_INT);
    SEL(2) <= (WRITE_REG and W(2)) or (INS_FETCH and not ST0 and W(1)) or (INS_FETCH and W(1) and ST0 and EN_INT);
    SEL(1) <= (WRITE_REG and ((W(1) and not ST0) or (W(2) and ST0))) or (READ_REG and W(2)) or (IRET and W(3));
    SEL(0) <= (WRITE_REG and W(1)) or (READ_REG and (W(1) or W(2))) or (IRET and W(3));

    SELCTL <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1)) or (INS_FETCH and not ST0 and W(1)) or (INS_FETCH and W(1) and ST0 and EN_INT) or (IRET and W(3));

    DRW <= (WRITE_REG and (W(1) or W(2))) or ((ADD or SUB or AND_I or INC or OR_I or MOV or (JMP and EN_INT)) and W(2)) or (LD and W(3)) or (INS_FETCH and not ST0 and W(1)) or (INS_FETCH and W(1) and ST0 and EN_INT);

    STOP <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1)) or (STP and W(2)) or (ST1 and W(1)) or (INS_FETCH and not ST0 and W(1)) or (IRET and W(2));

    LAR <= ((READ_MEM or WRITE_MEM) and W(1) and not ST0) or ((ST or LD) and W(2));

    SHORT <= ((READ_MEM or WRITE_MEM) and W(1)) or (INS_FETCH and not ST0 and W(1));

    MBUS <= (READ_MEM and W(1) and ST0) or (LD and W(3));

    ARINC <= (WRITE_MEM or READ_MEM) and W(1) and ST0;

    MEMW <= (WRITE_MEM and W(1) and ST0) or (ST and W(3));

    PCINC <= INS_FETCH and W(1) and ST0;
    LIR <= INS_FETCH and W(1) and ST0;

    CIN <= ADD and W(2);

    ABUS <= ((ADD or SUB or AND_I or INC or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I) and W(2)) or (INS_FETCH and W(1) and ST0 and EN_INT) or (IRET and W(3));

    LDZ <= (ADD or SUB or AND_I or INC or OR_I or CMP) and W(2);
    LDC <= (ADD or SUB or INC or CMP) and W(2);

    M <= ((AND_I or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I) and W(2)) or (IRET and W(3));

    S(3) <= ((ADD or AND_I or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I) and W(2)) or (IRET and W(3));
    --S(3) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and ADD) or (W(2) and AND_I) or (W(2) and LD);
    S(2) <= ((SUB or ST) and W(2)) or ((OR_I or CMP) and W(2));
    --S(2) <= (W(2) and (ST or JMP)) or (W(2) and SUB);
    S(1) <= ((SUB or AND_I or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I or CMP) and W(2)) or (IRET and W(3));
    --S(1) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and SUB) or (W(2) and AND_I) or (W(2) and LD);
    S(0) <= (ADD or AND_I or ST) and W(2);

    LPC <= (JMP and W(2)) or (INS_FETCH and not ST0 and W(1)) or (ST1 and W(2)) or (IRET and W(3));

    LONG <= (ST or LD or IRET) and W(2);

    PCADD <= ((C and JC) or (Z and JZ)) and W(2);

    process (CLR, MF, INTEN, INTDI, PULSE, EN_INT)
    begin
        if CLR = '0' then
            EN_INT <= '1';
        elsif MF'event and MF = '1' then
            EN_INT <= INTEN OR (EN_INT and not INTDI);
        end if;
    end process;
    
    process (CLR, EN_INT, PULSE)
	begin
		if CLR = '0' then
            INT <= '0';
        end if;
		if PULSE = '1' then
			INT <= EN_INT;
		end if;
		if EN_INT = '0' then
			INT <= '0';
		end if;
	end process;

    INTDI <= ST1 and W(1);

    INTEN <= IRET and W(1);
    
    AAAA <= IRET;

end architecture arch;
