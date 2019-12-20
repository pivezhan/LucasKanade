LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
ENTITY TB_STD_FIFO IS
END TB_STD_FIFO;
 
ARCHITECTURE behavior OF TB_STD_FIFO IS 
	
	-- Component Declaration for the Unit Under Test (UUT)
	component STD_FIFO
		port (
			CLK		: in std_logic;
			RST		: in std_logic;
			DataIn	: in std_logic_vector(7 downto 0);
			WriteEn	: in std_logic;
			ReadEn	: in std_logic;
			DataOut	: out std_logic_vector(7 downto 0);
			Full	: out std_logic;
			Empty	: out std_logic
		);
	end component;
	
	--Inputs
	signal CLK		: std_logic := '0';
	signal RST		: std_logic := '0';
	signal DataIn	: std_logic_vector(7 downto 0) := (others => '0');
	signal ReadEn	: std_logic := '0';
	signal WriteEn	: std_logic := '0';
	
	--Outputs
	signal DataOut	: std_logic_vector(7 downto 0);
	signal Empty	: std_logic;
	signal Full		: std_logic;
	
	-- Clock period definitions
	constant CLK_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: STD_FIFO
		PORT MAP (
			CLK		=> CLK,
			RST		=> RST,
			DataIn	=> DataIn,
			WriteEn	=> WriteEn,
			ReadEn	=> ReadEn,
			DataOut	=> DataOut,
			Full	=> Full,
			Empty	=> Empty
		);
	
	-- Clock process definitions
	CLK_process :process
	begin
	CLK <= '0';
	wait for CLK_period/2;
	CLK <= '1';
	wait for CLK_period/2;
	end process;
	
	-- Reset process
	rst_proc : process
	begin
	RST <= '1';
	wait for 20 ns;
	RST <= '0';
	wait for 100 ns;
	end process;
	
	-- Test case one
	T1: process
	begin
	wait for 20 ns;
	WriteEn<='1';
	DataIn<="00000010";
	wait for 20 ns;
	ReadEn<='1';
	end process;
END;
