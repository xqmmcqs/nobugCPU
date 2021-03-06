-- --------------------------------------------------------------------
-- 本文件名              	nobugCPU-nopipe
-- --------------------------------------------------------------------
-- 描述
-- 		第一个任务：必选题目
--		基础功能：
--			按照给定数据格式、指令系统和数据通路，根据所提供的器件要求，
-- 			自行设计一个基于硬布线控制器的顺序模型处理机。
--		附加功能：
-- 			在原指令基础上扩指至少三条。
-- 			允许用户在程序开始时指定PC指针的值。
-- --------------------------------------------------------------------
-- 版本日期	v1.0 	2021.7.3
-- --------------------------------------------------------------------



-- --------------------------------------------------------------------
--                          库引用
-- --------------------------------------------------------------------
-- library 库名;
-- use 库名,库中程序包,程序包中的项;
-- --------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- --------------------------------------------------------------------



-- --------------------------------------------------------------------
--                          实体声明
-- --------------------------------------------------------------------
----      输入in std_logic
-- CLR  #CLR
-- Z,C  状态寄存器
-- --------------------------------------------------------------------
----      输入in std_logic_vector
-- IR   指令高四位
-- SW   操作模式
-- W    三个节拍
-- --------------------------------------------------------------------
----      输出out std_logic 
-- SELCTL,              R0~3选择
-- DRW,                 R0~3控制
-- LPC, PCINC, PCADD,   PC 控制
-- LAR, ARINC,          AR 控制
-- STOP,                停机控制
-- LIR,                 IR 控制
-- LDZ, LDC,            状态控制
-- CIN, M,              运算控制
-- MEMW,                内存控制
-- ABUS, SBUS, MBUS,    总线控制
-- SHORT, LONG,         拍数控制
-- --------------------------------------------------------------------
----      输出out std_logic_vector 
-- S                    选择ALU、
-- SEL                  选择R和MUX
-- --------------------------------------------------------------------
entity nobugCPU is
	port(
	CLR, T3, C, Z: in std_logic;
	IR: in std_logic_vector(7 downto 4);
	SW, W: in std_logic_vector(3 downto 1);

	SELCTL, 
	DRW, 
	LPC, PCINC, PCADD, 
	LAR, ARINC, 
	LIR, 
	LDZ, LDC, 
	CIN, M, 
	MEMW, 
	ABUS, SBUS, MBUS, 
	STOP, 
	SHORT, LONG: out std_logic;
	S, SEL: out std_logic_vector(3 downto 0)
	);
end nobugCPU;
-- --------------------------------------------------------------------




-- --------------------------------------------------------------------
--                          工程体
-- --------------------------------------------------------------------
--      结构体描述方式
-- 数据流描述      dataflow      使用布尔代数式描述，以门信号赋值操作为主
-- --------------------------------------------------------------------
---- 结构体的声明
architecture arch of nobugCPU is
---- 中间信号的声明
	signal WRITE_REG, READ_REG, INS_FETCH, WRITE_MEM, READ_MEM, ST0: std_logic;
	signal ADD, SUB, AND_I, INC, LD, ST, JC, JZ, JMP, STP: std_logic;
	signal NOP, OUT_I, OR_I, CMP, MOV: std_logic;
begin
---- 结构体描述语句
-- 操作模式
	WRITE_REG <= '1' when SW = "100" else '0';
	READ_REG <= '1' when SW = "011" else '0';
	INS_FETCH <= '1' when SW = "000" else '0';
	READ_MEM <= '1' when SW = "010" else '0';
	WRITE_MEM <= '1' when SW = "001" else '0';

-- 操作码
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

-- ST0 状态
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

-- 控制信号合成
	SBUS <= ((WRITE_REG or (READ_MEM and not ST0) or WRITE_MEM or (INS_FETCH and not ST0)) and W(1)) or (WRITE_REG and W(2));

	SEL(3) <= (WRITE_REG and (W(1) or W(2)) and ST0) or (READ_REG and W(2));
	SEL(2) <= (WRITE_REG and W(2));
	SEL(1) <= (WRITE_REG and ((W(1) and not ST0) or (W(2) and ST0))) or (READ_REG and W(2));
	SEL(0) <= (WRITE_REG and W(1)) or (READ_REG and (W(1) or W(2)));

	SELCTL <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1));

	DRW <= (WRITE_REG and (W(1) or W(2))) or ((ADD or SUB or AND_I or INC or OR_I or MOV) and W(2)) or (LD and W(3));

	STOP <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1)) or (STP and W(2)) or (INS_FETCH and not ST0 and W(1));

	LAR <= ((READ_MEM or WRITE_MEM) and W(1) and not ST0) or ((ST or LD) and W(2));

	SHORT <= ((READ_MEM or WRITE_MEM) and W(1)) or (INS_FETCH and not ST0 and W(1));

	MBUS <= (READ_MEM and W(1) and ST0) or (LD and W(3));

	ARINC <= (WRITE_MEM or READ_MEM) and W(1) and ST0;

	MEMW <= (WRITE_MEM and W(1) and ST0) or (ST and W(3));

	PCINC <= INS_FETCH and W(1) and ST0;
	LIR <= INS_FETCH and W(1) and ST0;

	CIN <= ADD and W(2);

	ABUS <= ((ADD or SUB or AND_I or INC or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I) and W(2));

	LDZ <= (ADD or SUB or AND_I or INC or OR_I or CMP) and W(2);
	LDC <= (ADD or SUB or INC or CMP) and W(2);

	M <= ((AND_I or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I) and W(2));

	S(3) <= ((ADD or AND_I or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I) and W(2));
	--S(3) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and ADD) or (W(2) and AND_I) or (W(2) and LD);
	S(2) <= ((SUB or ST or JMP) and W(2)) or ((OR_I or CMP) and W(2));
	--S(2) <= (W(2) and (ST or JMP)) or (W(2) and SUB);
	S(1) <= ((SUB or AND_I or LD or ST or JMP) and W(2)) or (ST and W(3)) or ((OR_I or MOV or OUT_I or CMP) and W(2));
	--S(1) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and SUB) or (W(2) and AND_I) or (W(2) and LD);
	S(0) <= (ADD or AND_I or ST or JMP) and W(2);

	LPC <= (JMP and W(2)) or (INS_FETCH and not ST0 and W(1));

	LONG <= (ST or LD) and W(2);

	PCADD <= ((C and JC) or (Z and JZ)) and W(2);
end architecture arch;
-- --------------------------------------------------------------------

