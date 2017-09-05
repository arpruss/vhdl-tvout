LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

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
    signal frameCount : unsigned(12 downto 0) := to_unsigned(0,13);
    signal frameCountN : unsigned(frameCount'length-1 downto 0) := to_unsigned(0,frameCount'length);
    signal ntscHLinecount : unsigned(9 downto 0) := to_unsigned(0,10);
    signal ntscHLinecountN : unsigned(ntscHLinecount'length-1 downto 0) := to_unsigned(0,ntscHLinecount'length);
    signal ntscHPixelcount : unsigned(7+pwmBits downto 0) := to_unsigned(0,8+pwmBits);
    signal ntscHPixelcountN : unsigned(ntscHPixelcount'length-1 downto 0) := to_unsigned(0,ntscHPixelcount'length);
    signal field : std_logic := '0';
    signal fieldN : std_logic := '0';
    signal ntscSignal, ntscLevel : std_logic;
    signal clock : std_logic; 
    constant clockFrequency : real := 160000000.0;

function usToClock(us : real) return natural is
begin
    return natural(floor(0.5+1.0e-6*us*clockFrequency));
end usToClock;    
    
begin 
    -- ************************************************************************
    --                          NTSC OUT
    -- ************************************************************************

    
    PLL_INSTANCE: entity work.pll port map(main_clock, clock);

    -- Derive all other signals from ntscLinecount, ntscPixelcount and ntscBitmap
    process (ntscHLinecount, ntscHPixelcount, frameCount, field)
    variable ntscEq, ntscSe: std_logic;
    variable ntscLinecount : unsigned(9 downto 0);
    variable ntscPixelcount : unsigned(8+pwmBits downto 0);
    variable ntscPixelcountAdj : unsigned(ntscPixelcount'length-1 downto 0);
    variable visible : boolean;
    begin
        if ntscHPixelcount = usToClock(63.5/2.0) then
            ntscHPixelcountN <= to_unsigned(0,ntscHPixelcountN'length);
            if ntscHLinecount = 524 then -- hmm, should be 525, but doesn't work with that?!! TODO
                fieldN <= not field; 
                ntscHLinecountN <= to_unsigned(0,ntscHlinecountN'length);
                if field = '1' then
                    frameCountN <= frameCount + 1;
                else
                    frameCountN <= frameCount;
                end if;
            else
                fieldN <= field;
                ntscHLinecountN <= ntscHLinecount + 1;
                frameCountN <= frameCount;
            end if;
        else
            fieldN <= field;
            ntscHLinecountN <= ntscHLinecount;
            ntscHPixelcountN <= ntscHPixelcount + 1;
            frameCountN <= frameCount;
        end if;
        
        if field = '0' and 18 <= ntscHLinecount then
            ntscLinecount := resize(ntscHLinecount - 18, ntscLinecount'length)(9 downto 1) & '0';
            visible := true;
            if ntscHLinecount(0) = '0' then
                ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length);
            else
                ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length) + usToClock(63.5/2.0) + 1;
            end if;

        elsif field = '1' and 19 <= ntscHLinecount then
            ntscLinecount := resize(ntscHLinecount - 19, ntscLinecount'length)(9 downto 1) & '1';
            visible := true;
            if ntscHLinecount(0) = '1' then
                ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length);
            else
                ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length) + usToClock(63.5/2.0) + 1;
            end if;
        else
            visible := false;
            ntscLinecount := to_unsigned(0, ntscLinecount'length);
            ntscPixelcount := to_unsigned(0, ntscPixelcount'length);
        end if;

        if visible then
            if ntscPixelCount < usToClock(1.5) then
                ntscSignal <= '1';
                ntscLevel <= '0';
            elsif ntscPixelCount < usToClock(1.5+4.7) then 
                ntscSignal <= '0';
                ntscLevel <= '0';
            elsif ntscPixelCount < usToClock(1.5+4.7+4.7) then
                ntscSignal <= '1';
                ntscLevel <= '0';
            elsif ntscLinecount < 20 then
                ntscSignal <= '1';
                ntscLevel <= '0';
            else
                ntscSignal <= '1';
                -- active part of screen
                ntscPixelcountAdj := ntscPixelcount + (resize(ntscLinecount,12) sll (pwmBits-1)) + (frameCount sll 1);
                if (ntscPixelcountAdj((6+pwmBits) downto 7) >= ntscPixelcountAdj((pwmBits-1) downto 0)) then
                    ntscLevel <= '1';
                else
                    ntscLevel <= '0';
                end if;
            end if;
        else
            ntscLevel <= '0';
          -- ntscEq is the equalization pulse
            if (ntscHPixelcount < usToClock(2.542)) then
                ntscEq := '0';
            else
                ntscEq := '1';
            end if;

          -- ntscSe is the serration pulse
            if (ntscHPixelcount < usToClock(27.305)) then
                ntscSe := '0';
            else
                ntscSe := '1';
            end if;

            case ntscHLinecount(4 downto 1) is
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
            when X"9" =>
                ntscSignal <= ntscEq;
            when others =>
                ntscSignal <= '1';
            end case;
        end if;
    end process;

    process
    begin
        wait until clock'event and clock = '1';
        ntscHPixelcount <= ntscHPixelcountN;
        frameCount <= frameCountN;
        ntscHLinecount <= ntscHLinecountN;
        field <= fieldN;
        sync_output <= ntscSignal;             -- sync pulses
        bw_output <= ntscLevel;   -- black vs white
    end process;
end behavioral;