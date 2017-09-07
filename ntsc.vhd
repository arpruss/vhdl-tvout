-- 
-- Original code copyright (c) 2003 James Bowman http://excamera.com/sphinx/fpga-ntsc.html
-- Heavy modifications copyright (c) 2017 Alexander Pruss https://github.com/arpruss/vhdl-tvout
-- MIT Licensed
--

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity ntsc is
    generic
    (
    clockFrequency : real := 208.33333333e6;
    pwmBits : natural := 4;
    screenWidth : natural := 640
    );    

    port
    (
    sync_output : out std_logic;
    bw_output : out std_logic;
    clock: in std_logic;
    x : out unsigned(9 downto 0);
    y : out unsigned(8 downto 0);
    req   : out std_logic := '0'; -- set to request a pixel
    pixel : in unsigned(pwmBits-1 downto 0)
    );
    function microsToTicks(us : real) return natural is
    begin
        return natural(floor(0.5+1.0e-6*us*clockFrequency));
    end microsToTicks;    
end ntsc;

architecture behavioral of ntsc is
    constant HALF_LINE : natural := microsToTicks(63.6/2.0);
    constant FULL_LINE : natural := HALF_LINE*2;
    constant lineBits : natural := natural(ceil(log2(real(FULL_LINE))));

    constant pwmLevels : natural := 2**pwmBits;
    signal halfLine : unsigned(9 downto 0) := to_unsigned(0,10);
    signal horizHCount : unsigned(lineBits-2 downto 0) := to_unsigned(0,lineBits-1); -- clock count within halfline
    signal horizCount : unsigned(lineBits-1 downto 0) := to_unsigned(0,lineBits); -- clock count within line
    signal field : std_logic := '1';
    
    constant DATA_LENGTH : natural := screenWidth*pwmLevels;
    constant DATA_HORIZ_START : natural := (microsToTicks((63.6-1.5+6.2+4.7)/2)-DATA_LENGTH/2)/pwmLevels*pwmLevels;
    constant DATA_HORIZ_END : natural := DATA_HORIZ_START + DATA_LENGTH;
    
begin 
    -- ************************************************************************
    --                          NTSC OUT
    -- ************************************************************************
    process (clock)
    variable ntscEq, ntscSe: std_logic;
    variable displayLine : unsigned(8 downto 0);
    variable dataRegion : boolean;

    begin
        if rising_edge(clock) then
            if horizHCount = HALF_LINE-1 then
                horizHCount <= to_unsigned(0,horizHCount'length);
                if halfLine = 524 then
                    field <= not field; 
                    halfLine <= to_unsigned(0,halfLine'length);
                else
                    halfLine <= halfLine + 1;
                end if;
            else
                horizHCount <= horizHCount + 1;
            end if;
            
            if horizCount = FULL_LINE-1 then
                horizCount <= to_unsigned(0,horizCount'length);
            else
                horizCount <= horizCount + 1;
            end if;
            
            -- for odd field, displayLine = (halfLine-40) rounded down to even
            -- for even field, displayLine = (halfLine-41) rounded up to odd
            -- displayLine is 9 bits long, which is calibrated so that it is above 479 when
            -- halfLine is less than 40 or 41.
            displayLine := resize(resize(halfLine,9) - (to_unsigned(20,8) & not field), 9)(8 downto 1) & not field;
            if (field = '1' and 18 <= halfLine) or 19 <= halfLine then
                if horizCount < microsToTicks(4.7) then 
                    sync_output <= '0';
                    bw_output <= '0';
                else
                    sync_output <= '1';
                    if horizCount >= DATA_HORIZ_END then
                        bw_output <= '0';
                    elsif displayLine >= 480 then
                        bw_output <= '0';
                    elsif horizCount < DATA_HORIZ_START then
                        bw_output <= '0';                
                        if horizCount = DATA_HORIZ_START-pwmLevels then
                            x <= to_unsigned(0, x'length);
                            y <= displayLine;
                        elsif horizCount = DATA_HORIZ_START-pwmLevels+pwmLevels/2 then
                            req <= '0';
                        elsif horizCount = DATA_HORIZ_START-pwmLevels+1 then
                            req <= '1';
                        end if;
                    else
                        if horizCount(pwmBits-1 downto 0) = 0 then                        
                            x <= resize(horizCount(horizCount'length-1 downto pwmBits)-(DATA_HORIZ_START / pwmLevels)+1, x'length);
                            y <= displayLine;
                        elsif horizCount(pwmBits-1 downto 0) = 1 and horizCount < DATA_HORIZ_END - pwmLevels then
                            req <= '1';
                        elsif horizCount(pwmBits-1 downto 0) = pwmLevels/2 then
                            req <= '0';
                        end if;
                        if pixel >= horizCount(pwmBits-1 downto 0) then
                            bw_output <= '1';
                        else
                            bw_output <= '0';
                        end if;
                    end if;
                end if;
            else
                bw_output <= '0';
              -- ntscEq is the equalization pulse
                if horizHCount < microsToTicks(2.3) then 
                    ntscEq := '0';
                else
                    ntscEq := '1';
                end if;

              -- ntscSe is the serration pulse
                if horizHCount < microsToTicks(63.6/2.0-4.7) then 
                    ntscSe := '0';
                else
                    ntscSe := '1';
                end if;

                if halfLine(4 downto 1) <= 2 then
                    sync_output <= ntscEq;
                elsif halfLine(4 downto 1) <= 5 then
                    sync_output <= ntscSe;
                elsif halfLine(4 downto 1) <= 9 then 
                    sync_output <= ntscEq;
                else
                    sync_output <= '1';
                end if;
            end if;
        end if;
    end process;
end behavioral;

