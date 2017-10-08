LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--library work;
--use work.fonts.all;

entity tvout is 
    port
    (
    sync_output : out std_logic;
    bw_output : out std_logic;
    main_clock : in std_logic;
    button : in std_logic
    );
attribute altera_chip_pin_lc : string;
attribute altera_chip_pin_lc of button : signal is "@144";   
attribute altera_chip_pin_lc of bw_output : signal is "@96";   
attribute altera_chip_pin_lc of sync_output : signal is "@119";   
attribute altera_attribute : string;
attribute altera_attribute of button : signal is "-name WEAK_PULL_UP_RESISTOR ON";
end tvout;   

architecture behavioral of tvout is
    constant pwmBits : natural := 4;
    constant screenWidth : natural := 640;
    constant clockFrequency : real := 208.33333333e6;
    signal clock : std_logic; 
    signal req: std_logic;
    signal x : unsigned(9 downto 0);
    signal y : unsigned(8 downto 0);
    signal pixel: unsigned(pwmBits-1 downto 0) ;
    signal posX : signed(10 downto 0) := to_signed(screenWidth/2,11);
    signal vX : signed(1 downto 0) := to_signed(1,2);
    signal posY : signed(9 downto 0) := to_signed(240,10);
    signal vY : signed(1 downto 0) := to_signed(1,2);
    signal ch : integer range 0 to 127;
    

begin
    PLL_INSTANCE: entity work.pll port map(main_clock, clock);
    output: entity work.ntsc 
                generic map(clockFrequency => clockFrequency, pwmBits=>pwmBits, screenWidth=>screenWidth) 
                port map(sync_output=>sync_output, bw_output=>bw_output, clock=>clock, pixel=>pixel, 
                    req=>req, x=>x, y=>y, new_frame=>open);

    process(req)

    variable xs : signed(10 downto 0);
    variable ys : signed(9 downto 0);
    variable dist2 : signed(xs'length+ys'length downto 0);
    variable distScaled : unsigned(xs'length+ys'length-11 downto 0);
    begin
        if rising_edge(req) then
            if x=screenWidth-1 and y=479 then
                --note that (screenWidth-1,479) will be invisible on a typical TV, so if we miss
                --the timing on it, no harm done; we basically have all the vertical blanking
                --time available for setting up the next frame.
                if posX >= screenWidth-1 then
                    vX <= to_signed(-1, vX'length);
                elsif posX <= 0 then
                    vX <= to_signed(1, vX'length);
                end if;
                if posY >= 479 then
                    vY <= to_signed(-1, vY'length);
                elsif posY <= 0 then
                    vY <= to_signed(1, vY'length);
                end if;
                if button = '0' then
                    posX <= posX + vX+vX+vX+vX;
                    posY <= posY + vY+vY+vY+vY;
                else
                    posX <= posX + vX;
                    posY <= posY + vY;
                end if;
--            elsif 200 <= x and x < 216 and 200 <= y and y < 216 then
--                if getFontBit(66, resize(x-to_unsigned(200,x'length),4), 
--                                                 resize(y-to_unsigned(200,y'length),4))='1' then
--                    pixel <= to_unsigned(255, pixel'length);
--                else
--                    pixel <= to_unsigned(0, pixel'length);
--                end if;
            else
                xs := signed(resize(x,11))-posX;
                ys := signed(resize(y,10))-posY;
                distScaled := resize(unsigned(xs*xs+ys*ys) srl 11,distScaled'length);
                if button = '0' and (
                    resize(signed(x)-integer(screenWidth/2),10) = resize(signed(y)-integer(240),10) or 
                    resize(signed(x)-integer(screenWidth/2),10) = resize(integer(240)-signed(y),10) ) then
                    pixel <= to_unsigned(255,pwmBits);
                else
                    if distScaled < 2**pwmBits then
                        pixel <= 2**pwmBits-1-resize(distScaled,pwmBits);
                    else
                        pixel <= to_unsigned(0,pwmBits);
                    end if;
                end if;
            end if;
         end if;
    end process;
end behavioral;

