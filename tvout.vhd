LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.ntsclib.all;

entity tvout is 
    port
    (
    sync_output : out std_logic;
    bw_output : out std_logic;
    main_clock : in std_logic
    );
end tvout;    

architecture behavioral of tvout is
    signal clock : std_logic; 
    signal alpha : std_logic;
    constant clockFrequency : real := 160000000.0;
begin
    PLL_INSTANCE: entity work.pll port map(main_clock, clock);
    output: entity work.ntsc 
                generic map(clockFrequency => clockFrequency) 
                port map(sync_output=>sync_output, bw_output=>bw_output, clock=>clock);
end behavioral;

