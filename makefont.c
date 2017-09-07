#include <stdio.h>
#include "font8x8_basic.h"

main() {
   int i;
   puts("package fonts is\n"
        " type fontdata is array(127 downto 32) of bit_vector(63 downto 0);\n"
        " constant font8x8 : fontdata := ("
        );
   for (i=32; i<128; i++) {
       printf("    x\"%02x%02x%02x%02x%02x%02x%02x%02x\"%c\n", 
            font8x8_basic[i][7],font8x8_basic[i][6],font8x8_basic[i][5],font8x8_basic[i][4],
            font8x8_basic[i][3],font8x8_basic[i][2],font8x8_basic[i][1],font8x8_basic[i][0],
            (i<127 ? ',' : ' '));
   }
   puts(");\n"
        "end fonts;");
}
