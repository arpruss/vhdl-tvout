--
-- Copyright (c) 2003 James Bowman
-- MIT License
--

...

signal ntscLinecount : std_logic_vector(8 downto 0);
signal ntscLinecountN : std_logic_vector(8 downto 0);
signal ntscHPixelcount : std_logic_vector(11 downto 0);
signal ntscHPixelcountN : std_logic_vector(11 downto 0);
signal ntscPixelcount : std_logic_vector(12 downto 0);
signal ntscPixelcountN : std_logic_vector(12 downto 0);
signal ntscSignal : std_logic;
signal ntscLevel, ntscEq, ntscSe, ntscBl, ntscAc : std_logic;
signal ntscBitmap : std_logic_vector(0 downto 0);

signal ntscAddr : std_logic_vector(8 downto 0);
signal ntscData : std_logic_vector(7 downto 0);

...

-- ************************************************************************
--                          NTSC OUT
-- ************************************************************************
bram0: RAMB4_S1_S8
      port map (ADDRA => ntscLineCount(4 downto 1) & ntscPixelcount(11 downto 4),
                ADDRB => ntscAddr,
                DIA => "0",
                DIB => ntscData,
                DOA => ntscBitmap, WEA => '0',
                WEB => '1',  CLKA => clock, CLKB => hostCLK,
                RSTA => hostReset, RSTB => hostReset, ENA => '1', ENB => '1');

-- Derive all other signals from ntscLinecount, ntscPixelcount and ntscBitmap
process (ntscLinecount, ntscPixelcount, ntscBitmap(0))
begin
  if (hostReset = '1') then
    ntscHPixelcountN <= "000000000000";
    ntscPixelcountN <= "0000000000000";
    ntscLinecountN <= "000000000";
  else
    if (ntscHPixelcount = "100111110000") then
      ntscHPixelcountN <= "000000000000";
    else
      ntscHPixelcountN <= ntscHPixelcount + 1;
    end if;
    if (ntscPixelcount = "1001111100000") then
      ntscPixelcountN <= "0000000000000";
      if (ntscLinecount = "100000111") then
        ntscLinecountN <= "000000000";
      else
        ntscLinecountN <= ntscLinecount + 1;
      end if;
    else
      ntscPixelCountN <= ntscPixelcount + 1;
      ntscLinecountN <= ntscLinecount;
    end if;
  end if;

  -- ntscEq is the equalization pulse
  if (ntscHPixelcount < "000010111000") then
    ntscEq <= '0';
  else
    ntscEq <= '1';
  end if;

  -- ntscSe is the serration pulse
  if (ntscHPixelcount < "100010001000") then
    ntscSe <= '0';
  else
    ntscSe <= '1';
  end if;

  -- ntscBl is the blanking pulse
  if (ntscPixelcount < "0000101111000") then
    ntscBl <= '0';
  else
    ntscBl <= '1';
  end if;

  -- ntscAc is high when raster is in active (i.e. displayed) part of scan
  if (("000010101" < ntscLinecount) AND
      ("0001101101000" < ntscPixelcount) AND
      (ntscPixelcount < "1001101101000")) then
    ntscAc <= '1';
  else
    ntscAc <= '0';
  end if;

  -- logic to generate equalization, serration, and blanking pulses at start of every frame
  if (ntscLinecount(8 downto 4) = "00000") then
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
  if (ntscLinecount = "0001000XX") then
    -- white bar across top of screen
    ntscLevel <= '1';
  elsif (ntscLinecount = "1XXXXXXXX") then
    -- black border at bottom of screen
    ntscLevel <= '0';
  elsif (ntscLinecount = "0111XXXXX") then
    -- bitmap in lower part of screen
    ntscLevel <= ntscBitmap(0);
  else
    -- gray scale over rest of screen
    if (ntscPixelcount(10 downto 7) >= (ntscPixelcount(3 downto 0))) then
      ntscLevel <= '1';
    else
      ntscLevel <= '0';
    end if;
  end if;

end process;

process
begin
  wait until clock'event and clock = '1';
  ntscHPixelcount <= ntscHPixelcountN;
  ntscPixelcount <= ntscPixelcountN;
  ntscLinecount <= ntscLinecountN;
  output_01 <= ntscSignal;             -- sync pulses
  output_02 <= ntscAc AND ntscLevel;   -- black vs white
end process;