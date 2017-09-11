LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

package fonts is
    function getFontBit(
        c: in integer range 0 to 127;
        x: in unsigned(3 downto 0);
        y: in unsigned(3 downto 0)
        ) return bit;
    type fontdata is array(32 to 127) of bit_vector(63 downto 0);
 constant font8x8 : fontdata := (
    x"0000000000000000",
    x"00180018183c3c18",
    x"0000000000003636",
    x"0036367f367f3636",
    x"000c1f301e033e0c",
    x"0063660c18336300",
    x"006e333b6e1c361c",
    x"0000000000030606",
    x"00180c0606060c18",
    x"00060c1818180c06",
    x"0000663cff3c6600",
    x"00000c0c3f0c0c00",
    x"060c0c0000000000",
    x"000000003f000000",
    x"000c0c0000000000",
    x"000103060c183060",
    x"003e676f7b73633e",
    x"003f0c0c0c0c0e0c",
    x"003f33061c30331e",
    x"001e33301c30331e",
    x"0078307f33363c38",
    x"001e3330301f033f",
    x"001e33331f03061c",
    x"000c0c0c1830333f",
    x"001e33331e33331e",
    x"000e18303e33331e",
    x"000c0c00000c0c00",
    x"060c0c00000c0c00",
    x"00180c0603060c18",
    x"00003f00003f0000",
    x"00060c1830180c06",
    x"000c000c1830331e",
    x"001e037b7b7b633e",
    x"0033333f33331e0c",
    x"003f66663e66663f",
    x"003c66030303663c",
    x"001f36666666361f",
    x"007f46161e16467f",
    x"000f06161e16467f",
    x"007c66730303663c",
    x"003333333f333333",
    x"001e0c0c0c0c0c1e",
    x"001e333330303078",
    x"006766361e366667",
    x"007f66460606060f",
    x"0063636b7f7f7763",
    x"006363737b6f6763",
    x"001c36636363361c",
    x"000f06063e66663f",
    x"00381e3b3333331e",
    x"006766363e66663f",
    x"001e33380e07331e",
    x"001e0c0c0c0c2d3f",
    x"003f333333333333",
    x"000c1e3333333333",
    x"0063777f6b636363",
    x"0063361c1c366363",
    x"001e0c0c1e333333",
    x"007f664c1831637f",
    x"001e06060606061e",
    x"00406030180c0603",
    x"001e18181818181e",
    x"0000000063361c08",
    x"ff00000000000000",
    x"0000000000180c0c",
    x"006e333e301e0000",
    x"003b66663e060607",
    x"001e3303331e0000",
    x"006e33333e303038",
    x"001e033f331e0000",
    x"000f06060f06361c",
    x"1f303e33336e0000",
    x"006766666e360607",
    x"001e0c0c0c0e000c",
    x"1e33333030300030",
    x"0067361e36660607",
    x"001e0c0c0c0c0c0e",
    x"00636b7f7f330000",
    x"00333333331f0000",
    x"001e3333331e0000",
    x"0f063e66663b0000",
    x"78303e33336e0000",
    x"000f06666e3b0000",
    x"001f301e033e0000",
    x"00182c0c0c3e0c08",
    x"006e333333330000",
    x"000c1e3333330000",
    x"00367f7f6b630000",
    x"0063361c36630000",
    x"1f303e3333330000",
    x"003f260c193f0000",
    x"00380c0c070c0c38",
    x"0018181800181818",
    x"00070c0c380c0c07",
    x"0000000000003b6e",
    x"0000000000000000" 
);
end fonts;

package body fonts is 
function getFontBit(
    c: in integer range 0 to 127;
    x: in unsigned(3 downto 0);
    y: in unsigned(3 downto 0)
    ) return bit is
    begin
    
    if c < font8x8'low then
        return '0';
    else
        return font8x8(c)(to_integer(y(3 downto 1)&x(3 downto 1)));
    end if;
end getFontBit;
end package body fonts;