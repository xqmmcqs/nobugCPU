-- --------------------------------------------------------------------
-- 							库引用
-- library 库名;
-- use 库名,库中程序包,程序包中的项;
-- --------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_signed.all;
-- --------------------------------------------------------------------



-- --------------------------------------------------------------------
--							实体声明
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
-- S 	               	选择ALU、
-- SEL    				选择R和MUX
-- --------------------------------------------------------------------
entity nobugCPU is
	port (
	CLR, 
	C, Z , 
	T3, QD: in std_logic; 
	IR: in std_logic_vector(7 downto 4);
	SW ,  W: in std_logic_vector(3 downto 1); 
	
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
--      					工程体
-- --------------------------------------------------------------------
--      结构体描述方式
-- 行为描述      behave      进程
-- --------------------------------------------------------------------
---- 结构体的声明
architecture behave of nobugCPU is
---- 中间信号的声明
	signal ST0, SST0 : std_logic;
begin
---- 结构体描述语句
	process (SW, IR,  W(1),  W(2),  W(3), T3 ,CLR, C, Z, ST0, SST0) 
	begin
		SELCTL <= '0';
		DRW <= '0';
		LPC <= '0';
		PCINC <= '0';
		PCADD <= '0';
		LIR <= '0';
		LAR <= '0';
		ARINC <= '0';
		LDZ <= '0';
		LDC <= '0';
		ABUS <= '0';
		SBUS <= '0';
		MBUS <= '0';
		CIN <= '0';
		M <= '0';
		MEMW <= '0';
		STOP <= '0';
		SHORT <= '0';
		LONG <= '0';
		SST0 <= '0';

		S <= "0000";
		SEL <= "0000";


		if (clr = '0') then
			ST0 <= '0';
		else
			if (T3'event and T3 = '0') and SST0 = '1' then
				ST0 <= '1';
			end if;

			case SW is
				-- WRITE_MEM
				when "001" =>
					SBUS <=  W(1);
					STOP <=  W(1);
					SHORT <=  W(1);
					SELCTL <=  W(1);
					SST0 <=  W(1);
					
					LAR <=  W(1) and (not ST0);
					ARINC <=  W(1) and ST0;
					MEMW <=  W(1) and ST0;
				-- READ_MEM
				when "010" =>
					STOP <=  W(1);
					SHORT <=  W(1);
					SELCTL <=  W(1);
					SST0 <=  W(1);
					
					SBUS <=  W(1) and (not ST0);
					LAR <=  W(1) and (not ST0);
					MBUS <=  W(1) and ST0;
					ARINC <=  W(1) and ST0;
				-- READ_REG
				when "011" =>
					SELCTL <=  W(1) or  W(2);
					STOP <=  W(1) or  W(2);
					
					SEL(0) <=  W(1) or  W(2);
					SEL(1) <=  W(2);
					SEL(2) <= '0';
					SEL(3) <=  W(2);
				-- WRITE_REG
				when "100" =>
					SELCTL <=  W(1) or  W(2);
					SBUS <=  W(1) or  W(2);
					STOP <=  W(1) or  W(2);
					SST0 <=  W(2);
					DRW <=  W(1) or  W(2);
					
					SEL(3) <= (ST0 and  W(1)) or (ST0 and  W(2));
					SEL(2) <=  W(2);
					SEL(1) <= ((not ST0) and  W(1)) or (ST0 and  W(2));
					SEL(0) <=  W(1);

				-- INS_FETCH
				when "000" =>
					if ST0 = '0' then
						LPC <=  W(1); -- 用户指定程序初始位置，为了可以置入PC的值
						SBUS <=  W(1);
						SST0 <=  W(1);
						SHORT <=  W(1);
						STOP <=  W(1);
						SELCTL <=  W(1);
					else -- ST0='1'
						LIR <=  W(1);
						PCINC <=  W(1);
						case IR is
							when "0001" => -- ADD
								S <=  W(2) & '0' & '0' &  W(2);
								CIN <=  W(2);
								ABUS <=  W(2);
								DRW <=  W(2);
								LDZ <=  W(2);
								LDC <=  W(2);
							when "0010" => -- SUB
								S <= '0' &  W(2) &  W(2) & '0';
								ABUS <=  W(2);
								DRW <=  W(2);
								LDZ <=  W(2);
								LDC <=  W(2);
							when "0011" => -- AND
								M <=  W(2);
								S <=  W(2) & '0' &  W(2) &  W(2);
								ABUS <=  W(2);
								DRW <=  W(2);
								LDZ <=  W(2);
							when "0100" => -- INC
								S <= '0' & '0' & '0' & '0';
								ABUS <=  W(2);
								DRW <=  W(2);
								LDZ <=  W(2);
								LDC <=  W(2);
							when "0101" => -- LD
								M <=  W(2);
								S <=  W(2) & '0' &  W(2) & '0' ;
								ABUS <=  W(2);
								LAR <=  W(2);
								LONG <=  W(2);
								
								DRW <=  W(3);
								MBUS <=  W(3);
							when "0110" => --ST
								-- W2 和 W3 的 S 不同
								M <=  W(2) or  W(3);
								S <= ( W(2) or  W(3)) &  W(2) & ( W(2) or  W(3)) &  W(2);
								ABUS <=  W(2) or  W(3);
								LAR <=  W(2);
								LONG <= W(2);
						  
								MEMW <= W(3);
							when "0111" => --JC
								PCADD <=  W(2) and C;
							when "1000" => --JZ
								PCADD <=  W(2) and Z;
							when "1001" => --JMP
								M <= W(2);
								S <=  W(2) &  W(2) &  W(2) &  W(2);
								ABUS <=  W(2);
								LPC <= W(2);
							when "1110" => --STP
								STOP <=  W(2);
-- -------------------------扩展功能-----------------------------------
							--输出
							when "1010" => -- out
								M <=  W(2);
								S <=  W(2) & '0' &  W(2) & '0';
								ABUS <=  W(2);
							--或 
							when "1011" => -- or
								M <=  W(2);
								S <=  W(2) &  W(2) &  W(2) & '0';
								ABUS <=  W(2);
								DRW <=  W(2);
								LDZ <=  W(2);
							--比较--
							when "1100" =>  -- cmp
								M <= '0';
								S <= '0' &  W(2) &  W(2) & '0'; 
								ABUS <=  W(2);
								DRW <=  W(2);
								LDZ <=  W(2);
							--移动-- 
							when "1101" => -- mov
								M <=  W(2);
								S <=  W(2) & '0' &  W(2) & '0'; 
								ABUS <=  W(2);
								DRW <=  W(2);
								LDZ <=  W(2);
							when others => null; -- IR
						end case; -- IR

					end if; -- ST0='1'

				when others => null;--SW="000"
			end case; -- SW

		end if; -- clr='1'

	end process;
end architecture behave;
-- --------------------------------------------------------------------


