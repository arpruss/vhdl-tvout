LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

-- resolution: 238x223; pixel size 1:1.25

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
    signal ntscHLinecount : unsigned(9 downto 0) := to_unsigned(0,10);
    signal ntscHPixelcount : unsigned(7+pwmBits downto 0) := to_unsigned(0,8+pwmBits);
    signal field : std_logic := '1';
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
    process (clock)
    variable ntscEq, ntscSe: std_logic;
    variable ntscLinecount : unsigned(9 downto 0);
    variable ntscPixelcount : unsigned(8+pwmBits downto 0);
    variable ntscPixelcountAdj : unsigned(ntscPixelcount'length-1 downto 0);
    variable visible : boolean;
    begin
        if rising_edge(clock) then
            if ntscHPixelcount = usToClock(63.5/2.0)-1 then
                ntscHPixelcount <= to_unsigned(0,ntscHPixelcount'length);
                if ntscHLinecount = 524 then
                    field <= not field; 
                    ntscHLinecount <= to_unsigned(0,ntscHlinecount'length);
                    if field = '0' then
                        frameCount <= frameCount + 1;
                    else
                        frameCount <= frameCount;
                    end if;
                else
                    field <= field;
                    ntscHLinecount <= ntscHLinecount + 1;
                    frameCount <= frameCount;
                end if;
            else
                field <= field;
                ntscHLinecount <= ntscHLinecount;
                ntscHPixelcount <= ntscHPixelcount + 1;
                frameCount <= frameCount;
            end if;
            
            if field = '1' and 18 <= ntscHLinecount then
                ntscLinecount := resize(ntscHLinecount - 18, ntscLinecount'length)(9 downto 1) & '0';
                visible := true;
                if ntscHLinecount(0) = '0' then
                    ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length);
                else
                    ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length) + usToClock(63.5/2.0);
                end if;
            elsif field = '0' and 19 <= ntscHLinecount then
                ntscLinecount := resize(ntscHLinecount - 19, ntscLinecount'length)(9 downto 1) & '1';
                visible := true;
                if ntscHLinecount(0) = '1' then
                    ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length);
                else
                    ntscPixelcount := resize(ntscHPixelcount, ntscPixelcount'length) + usToClock(63.5/2.0);
                end if;
            else
                visible := false;
                ntscLinecount := to_unsigned(0, ntscLinecount'length);
                ntscPixelcount := to_unsigned(0, ntscPixelcount'length);
            end if;

            if visible then
                if ntscPixelCount >= usToClock(63.5-1.5) then
                    sync_output <= '1';
                    bw_output <= '0';
                elsif ntscPixelCount < usToClock(4.7) then 
                    sync_output <= '0';
                    bw_output <= '0';
                elsif ntscPixelCount < usToClock(6.2+4.7) then
                    sync_output <= '1';
                    bw_output <= '0';
                elsif ntscHLinecount < 40 then
                    sync_output <= '1';
                    bw_output <= '0';
                else
                    sync_output <= '1';
                    -- active part of screen
                    ntscPixelcountAdj := ntscPixelcount + (resize(ntscLinecount,12) sll (pwmBits-1)) + (frameCount sll 1);
                    if ntscPixelcountAdj((6+pwmBits) downto 7) >= ntscPixelcountAdj((pwmBits-1) downto 0) then
                        bw_output <= '1';
                    else
                        bw_output <= '0';
                    end if;
                end if;
            else
                bw_output <= '0';
              -- ntscEq is the equalization pulse
                if ntscHPixelcount < usToClock(2.3) then --  usToClock(2.542)) then
                    ntscEq := '0';
                else
                    ntscEq := '1';
                end if;

              -- ntscSe is the serration pulse
                if ntscHPixelcount < usToClock(63.5/2.0-4.7) then -- usToClock(27.305)) then
                    ntscSe := '0';
                else
                    ntscSe := '1';
                end if;

                case ntscHLinecount(4 downto 1) is
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
