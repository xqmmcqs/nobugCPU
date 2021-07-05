library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity nobugCPU is
    port(
    CLR, T3, C, Z: in std_logic;
    IR: in std_logic_vector(7 downto 4);
    SW, W: in std_logic_vector(3 downto 1);
    DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, LDZ, LDC, CIN, M, ABUS, SBUS, MBUS, SHORT, LONG: out std_logic;
    S, SEL: out std_logic_vector(3 downto 0)
    );
end nobugCPU;

architecture arch of nobugCPU is
    signal WRITE_REG, READ_REG, INS_FETCH, WRITE_MEM, READ_MEM, ST0: std_logic;
    signal ADD, SUB, AND_I, INC, LD, ST, JC, JZ, JMP, STP: std_logic;
    signal NOP, OUT_I, OR_I, CMP, MOV: std_logic;
begin
    WRITE_REG <= '1' when SW = "100" else '0';
    READ_REG <= '1' when SW = "011" else '0';
    INS_FETCH <= '1' when SW = "000" else '0';
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

    process(CLR, T3, W)
    begin
        if (CLR = '0') then
            ST0 <= '0';
        elsif (T3'event and T3 = '0') then
            if (ST0 = '0' and ((WRITE_REG = '1' and W(2) = '1') or (READ_MEM = '1' and W(1) = '1') or (WRITE_MEM = '1' and W(1) = '1') or (INS_FETCH = '1' and W(2) = '1'))) then
                ST0 <= '1';
            end if;
        end if;
    end process;

    process(T3, W)
    begin
        if (T3'event and T3 = '1') then
            PCINC <= (INS_FETCH and not ST0 and W(2)) or ((NOP or ADD or SUB or AND_I or INC or (JC and not C) or (JZ and not Z) or OUT_I or OR_I or CMP or MOV) and W(1)) or ((LD or ST or (JC and C) or (JZ and Z) or JMP) and W(2));
            LIR <= (INS_FETCH and not ST0 and W(2)) or ((NOP or ADD or SUB or AND_I or INC or (JC and not C) or (JZ and not Z) or OUT_I or OR_I or CMP or MOV) and W(1)) or ((LD or ST or (JC and C) or (JZ and Z) or JMP) and W(2));
        end if;
    end process;

    SBUS <= ((WRITE_REG or (READ_MEM and not ST0) or WRITE_MEM or (INS_FETCH and not ST0)) and W(1)) or (WRITE_REG and W(2));

    SEL(3) <= (WRITE_REG and (W(1) or W(2)) and ST0) or (READ_REG and W(2));
    SEL(2) <= (WRITE_REG and W(2));
    SEL(1) <= (WRITE_REG and ((W(1) and not ST0) or (W(2) and ST0))) or (READ_REG and W(2));
    SEL(0) <= (WRITE_REG and W(1)) or (READ_REG and (W(1) or W(2)));

    SELCTL <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1));

    DRW <= (WRITE_REG and (W(1) or W(2))) or ((ADD or SUB or AND_I or INC or OR_I or MOV) and W(1)) or (LD and W(2));

    STOP <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1)) or (STP and W(1)) or (INS_FETCH and not ST0 and W(1));

    LAR <= ((READ_MEM or WRITE_MEM) and W(1) and not ST0) or ((ST or LD) and W(1));

    SHORT <= ((READ_MEM or WRITE_MEM) and W(1)) or ((NOP or ADD or SUB or AND_I or INC or (JC and not C) or (JZ and not Z) or OUT_I or OR_I or CMP or MOV) and W(1));

    MBUS <= (READ_MEM and W(1) and ST0) or (LD and W(2));

    ARINC <= (WRITE_MEM or READ_MEM) and W(1) and ST0;

    MEMW <= (WRITE_MEM and W(1) and ST0) or (ST and W(2));

    CIN <= ADD and W(1);

    ABUS <= ((ADD or SUB or AND_I or INC or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I) and W(1));

    LDZ <= (ADD or SUB or AND_I or INC or OR_I or CMP) and W(1);
    LDC <= (ADD or SUB or INC or CMP) and W(1);

    M <= ((AND_I or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I) and W(1));

    S(3) <= ((ADD or AND_I or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I) and W(1));
    --S(3) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and ADD) or (W(2) and AND_I) or (W(2) and LD);
    S(2) <= ((SUB or ST or JMP) and W(1)) or ((OR_I or CMP) and W(1));
    --S(2) <= (W(2) and (ST or JMP)) or (W(2) and SUB);
    S(1) <= ((SUB or AND_I or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I or CMP) and W(1));
    --S(1) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and SUB) or (W(2) and AND_I) or (W(2) and LD);
    S(0) <= (ADD or AND_I or ST or JMP) and W(1);

    LPC <= (JMP and W(1)) or (INS_FETCH and not ST0 and W(1));

    LONG <= '0';

    PCADD <= ((C and JC) or (Z and JZ)) and W(1);
end architecture arch;
