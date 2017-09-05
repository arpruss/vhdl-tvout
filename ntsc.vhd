LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

-- resolution: 238x223; pixel size 1:1.25

package ntsclib is
    function microsToClock(constant us, clockFrequency : real) return natural;
    function screenWidth(constant clockFrequency : real; constant pwmLevels : natural) return natural;
        
end ntsclib;

package body ntsclib is
    function microsToClock(constant us, clockFrequency : real) return natural is
    begin
        return natural(floor(0.5+1.0e-6*us*clockFrequency));
    end microsToClock;
    function screenWidth(constant clockFrequency : real; constant pwmLevels : natural) return natural is
    begin
        return microsToClock(63.5-1.5,clockFrequency)/pwmLevels*pwmLevels
            -(microsToClock(6.2+4.7,clockFrequency)+pwmLevels-1)/pwmLevels*pwmLevels;
    end;
end ntsclib;   

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;
use work.ntsclib.all;

entity ntsc is
    generic
    (
    clockFrequency : real := 160000000.0;
    pwmBits : natural := 5
    );    

    port
    (
    sync_output : out std_logic;
    bw_output : out std_logic;
    clock: in std_logic
    --x : out unsigned(9 downto 0);
    --y : out unsigned(8 downto 0);
    --req   : out std_logic; -- flips to request a pixel
    --pixel : in unsigned(pwmBits-1 downto 0)
    );
    function microsToClock(us : real) return natural is
    begin
        return work.ntsclib.microsToClock(us,clockFrequency);
    end microsToClock;    
end ntsc;

architecture behavioral of ntsc is
    constant pwmLevels : natural := 2**pwmBits;
    signal frameCount : unsigned(12 downto 0) := to_unsigned(0,13);
    signal halfLine : unsigned(9 downto 0) := to_unsigned(0,10);
    signal horizHCount : unsigned(7+pwmBits downto 0) := to_unsigned(0,8+pwmBits); -- clock count within halfline
    signal field : std_logic := '1';
    
    constant DATA_HORIZ_START : natural := (microsToClock(6.2+4.7)+pwmLevels-1)/pwmLevels*pwmLevels;
    constant DATA_HORIZ_END : natural := microsToClock(63.5-1.5)/pwmLevels*pwmLevels;
    
begin 
    -- ************************************************************************
    --                          NTSC OUT
    -- ************************************************************************

    
    process (clock)
    variable ntscEq, ntscSe: std_logic;
    variable displayLine : unsigned(9 downto 0);
    variable horizCount : unsigned(8+pwmBits downto 0);
    variable horizCountAdj : unsigned(horizCount'length-1 downto 0);
    variable dataLine : boolean;
    begin
        if rising_edge(clock) then
            if horizHCount = microsToClock(63.5/2.0)-1 then
                horizHCount <= to_unsigned(0,horizHCount'length);
                if halfLine = 524 then
                    field <= not field; 
                    halfLine <= to_unsigned(0,halfLine'length);
                    if field = '0' then
                        frameCount <= frameCount + 1;
                    end if;
                else
                    halfLine <= halfLine + 1;
                end if;
            else
                horizHCount <= horizHCount + 1;
            end if;
            
            if field = '1' and 18 <= halfLine then
                displayLine := resize(halfLine - 18, displayLine'length)(9 downto 1) & '0';
                dataLine := true;
                if halfLine(0) = '0' then
                    horizCount := resize(horizHCount, horizCount'length);
                else
                    horizCount := resize(horizHCount, horizCount'length) + microsToClock(63.5/2.0);
                end if;
            elsif field = '0' and 19 <= halfLine then
                displayLine := resize(halfLine - 19, displayLine'length)(9 downto 1) & '1';
                dataLine := true;
                if halfLine(0) = '1' then
                    horizCount := resize(horizHCount, horizCount'length);
                else
                    horizCount := resize(horizHCount, horizCount'length) + microsToClock(63.5/2.0);
                end if;
            else
                dataLine := false;
                displayLine := to_unsigned(0, displayLine'length);
                horizCount := to_unsigned(0, horizCount'length);
            end if;

            if dataLine then
                if horizCount >= DATA_HORIZ_END then
                    sync_output <= '1';
                    bw_output <= '0';
                elsif horizCount < microsToClock(4.7) then 
                    sync_output <= '0';
                    bw_output <= '0';
                elsif horizCount < DATA_HORIZ_START then
                    sync_output <= '1';
                    bw_output <= '0';
                elsif halfLine < 40 then
                    sync_output <= '1';
                    bw_output <= '0';
                else
                    sync_output <= '1';
                    -- active part of screen
                    horizCountAdj := horizCount + (resize(displayLine,12) sll (pwmBits-1)) + (frameCount sll 1);
                    if horizCountAdj((6+pwmBits) downto 7) >= horizCountAdj((pwmBits-1) downto 0) then
                        bw_output <= '1';
                    else
                        bw_output <= '0';
                    end if;
                end if;
            else
                bw_output <= '0';
              -- ntscEq is the equalization pulse
                if horizHCount < microsToClock(2.3) then --  microsToClock(2.542)) then
                    ntscEq := '0';
                else
                    ntscEq := '1';
                end if;

              -- ntscSe is the serration pulse
                if horizHCount < microsToClock(63.5/2.0-4.7) then -- microsToClock(27.305)) then
                    ntscSe := '0';
                else
                    ntscSe := '1';
                end if;

                case halfLine(4 downto 1) is
                when X"0" =>
                    sync_output <= ntscEq;
                when X"1" =>
                    sync_output <= ntscEq;
                when X"2" =>
                    sync_output <= ntscEq;
                when X"3" =>
                    sync_output <= ntscSe;
                when X"4" =>
                    sync_output <= ntscSe;
                when X"5" =>
                    sync_output <= ntscSe;
                when X"6" =>
                    sync_output <= ntscEq;
                when X"7" =>
                    sync_output <= ntscEq;
                when X"8" =>
                    sync_output <= ntscEq;
                when X"9" =>
                    sync_output <= ntscEq;
                when others =>
                    sync_output <= '1';
                end case;
            end if;
        end if;
    end process;
end behavioral;

