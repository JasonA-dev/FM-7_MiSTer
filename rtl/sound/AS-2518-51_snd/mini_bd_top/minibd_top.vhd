library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity minibd_top is
port(
		clk_50	: in std_logic;
		reset_l	: in std_logic;
		ps2_clk	: inout std_logic;
		ps2_dat	: inout std_logic;
		audio_o	: out	std_logic
		);
end minibd_top;

architecture rtl of minibd_top is
-- Sound board signals
signal reset_h		:  std_logic;
signal cpu_clk		:	std_logic;
signal clkdiv		:	std_logic_vector(5 downto 0);
signal clk_14		:	std_logic;
signal snd_ctl		: 	std_logic_vector(7 downto 0);

-- PS/2 interface signals
signal codeReady	: std_logic;
signal scanCode	: std_logic_vector(9 downto 0);
signal send 		: std_logic;
signal Command 	: std_logic_vector(7 downto 0);
signal PS2Busy		: std_logic;
signal PS2Error	: std_logic;
signal dataByte	: std_logic_vector(7 downto 0);
signal dataReady	: std_logic;
begin
reset_h <= (not reset_l);

-- Main audio board code
Core: entity work.AS_2518_51
port map(
	dac_clk => clk_50,
	cpu_clk => cpu_clk,
	reset_l => reset_l,
	addr_i => snd_ctl(5 downto 0),
	snd_int_i => not scancode(8),
	test_sw_l => '1',
	audio_o => audio_o
	);

	

	
-- PLL takes 50MHz clock on mini board and puts out 14.28MHz	
PLL: entity work.williams_snd_pll
port map(
	areset => reset_h,
	inclk0 => clk_50,
	c0 => clk_14
	);

	-- PS/2 keyboard controller
keyboard: entity work.PS2Controller
port map(
		Reset     => reset_h,
		Clock     => clk_50,
		PS2Clock  => ps2_clk,
		PS2Data   => ps2_dat,
		Send      => send,
		Command   => command,
		PS2Busy   => ps2Busy,
		PS2Error  => ps2Error,
		DataReady => dataReady,
		DataByte  => dataByte
		);

-- PS/2 scancode decoder	
decoder: entity work.KeyboardMapper
port map(
		Clock     => clk_50,
		Reset     => reset_h,
		PS2Busy   => ps2Busy,
		PS2Error  => ps2Error,
		DataReady => dataReady,
		DataByte  => dataByte,
		Send      => send,
		Command   => command,
		CodeReady => codeReady,
		ScanCode  => scanCode
		);

-- Connect PS2 scancodes to sound control inputs
inputreg: process
begin
	wait until rising_edge(clk_50);
		if scanCode(8) = '0' then
			snd_ctl(5 downto 0) <= not scanCode(5 downto 0);
		else
			snd_ctl(5 downto 0) <= "111111";
		end if;
end process;

snd_ctl(7 downto 6) <= "11";

-- Clock divider, takes 14.28MHz PLL output and divides it by 4, pretty close to 3.58 MHz
clock_div: process(clk_14)
begin
	if rising_edge(clk_14) then	
		clkdiv <= clkdiv + 1;
		cpu_clk <= clkdiv(3);
	end if;
end process;

end rtl;
