LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- line frequency 31468.5
-- 318 pixels per line
-- 10.00 MHz pixel frequency 
-- resolution: 238x223; pixel size 1:1.25
-- vertical: 33-255 visible
-- horizontal: 58-295 visible

entity tvout is
	port
	(
	sync_output : out std_logic;
	bw_output : out std_logic;
	main_clock : in std_logic
	);
end tvout;

architecture behavioral of tvout is
	constant pwmBits : natural := 5;
	constant pwmLevels : natural := 2**pwmBits;
	signal frameCount : unsigned(12 downto 0);
	signal frameCountN : unsigned(frameCount'length-1 downto 0);
	signal ntscLinecount : unsigned(8 downto 0);
	signal ntscLinecountN : unsigned(ntscLinecount'length-1 downto 0);
	signal ntscHPixelcount : unsigned(7+pwmBits downto 0);
	signal ntscHPixelcountN : unsigned(ntscHPixelcount'length-1 downto 0);
	signal ntscPixelcount : unsigned(8+pwmBits downto 0);
	signal ntscPixelcountN : unsigned(ntscPixelcount'length-1 downto 0);
	signal ntscSignal : std_logic;
	signal ntscLevel, ntscEq, ntscSe, ntscBl, ntscAc : std_logic;
	signal clock : std_logic; 
	constant clockFrequency : real := 160000000.0;
begin
	-- ************************************************************************
	--                          NTSC OUT
	-- ************************************************************************

	
	PLL_INSTANCE: entity work.pll port map(main_clock, clock);

	-- Derive all other signals from ntscLinecount, ntscPixelcount and ntscBitmap
	process (ntscLinecount, ntscPixelcount, ntscHPixelcount, frameCount)
	variable ntscPixelcountAdj : unsigned(ntscPixelcount'length-1 downto 0);
	begin
		 if (ntscHPixelcount = 159*pwmLevels) then
			ntscHPixelcountN <= to_unsigned(0,ntscHPixelcountN'length);
		 else
			ntscHPixelcountN <= ntscHPixelcount + 1;
		 end if;
		 if (ntscPixelcount = 318*pwmLevels) then
			ntscPixelcountN <= to_unsigned(0,ntscPixelcountN'length);
			if (ntscLinecount = 263) then
			  ntscLinecountN <= to_unsigned(0,ntscLinecountN'length);
			  frameCountN <= frameCount + 1;
			else
			  ntscLinecountN <= ntscLinecount + 1;
			  frameCountN <= frameCount;
			end if;
		 else
			frameCountN <= frameCount;
			ntscPixelCountN <= ntscPixelcount + 1;
			ntscLinecountN <= ntscLinecount;
		 end if;

	  -- ntscEq is the equalization pulse
	  if (ntscHPixelcount < 11*pwmLevels + pwmLevels/2) then 
		 ntscEq <= '0';
	  else
		 ntscEq <= '1';
	  end if;

	  -- ntscSe is the serration pulse
	  if (ntscHPixelcount < 136*pwmLevels + pwmLevels/2) then
		 ntscSe <= '0';
	  else
		 ntscSe <= '1';
	  end if;

	  -- ntscBl is the blanking pulse
	  if (ntscPixelcount < 23*pwmLevels + pwmLevels/2) then
		 ntscBl <= '0';
	  else
		 ntscBl <= '1';
	  end if;

	  -- ntscAc is high when raster is in active (i.e. displayed) part of scan
	  if ((21 < ntscLinecount) AND
			(54*pwmLevels+pwmLevels/2 < ntscPixelcount) AND
			(ntscPixelcount < 310*pwmLevels+pwmLevels/2)) then
		 ntscAc <= '1';
	  else
		 ntscAc <= '0';
	  end if;

	  -- logic to generate equalization, serration, and blanking pulses at start of every frame
	  if (ntscLinecount(8 downto 4) = 0) then
		 case ntscLinecount(3 downto 0) is
		 when X"0" =>
			  ntscSignal <= ntscEq;
		 when X"1" =>
			  ntscSignal <= ntscEq;
		 when X"2" =>
			  ntscSignal <= ntscEq;
		 when X"3" =>
			  ntscSignal <= ntscSe;
		 when X"4" =>
			  ntscSignal <= ntscSe;
		 when X"5" =>
			  ntscSignal <= ntscSe;
		 when X"6" =>
			  ntscSignal <= ntscEq;
		 when X"7" =>
			  ntscSignal <= ntscEq;
		 when X"8" =>
			  ntscSignal <= ntscEq;
		 when others =>
			  ntscSignal <= ntscBl;
		 end case;
	  else
		 ntscSignal <= ntscBl;
	  end if;

	  -- logic to generate ntsc level (i.e. the actual picture) during active part of frame
		 -- gray scale over rest of screen
		 ntscPixelcountAdj := ntscPixelcount + (resize(ntscLinecount,12) sll pwmBits) + (frameCount sll 1);
		 if (ntscPixelcountAdj((6+pwmBits) downto 7) >= ntscPixelcountAdj((pwmBits-1) downto 0)) then
			ntscLevel <= '1';
		 else
			ntscLevel <= '0';
		 end if;
	end process;

	process
	begin
	  wait until clock'event and clock = '1';
	  ntscHPixelcount <= ntscHPixelcountN;
	  frameCount <= frameCountN;
	  ntscPixelcount <= ntscPixelcountN;
	  ntscLinecount <= ntscLinecountN;
	  sync_output <= ntscSignal;             -- sync pulses
	  bw_output <= ntscAc AND ntscLevel;   -- black vs white
	end process;
end behavioral;