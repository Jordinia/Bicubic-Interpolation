--VERSION 01.30 10/12
-- Bicubic interpolation memory package
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


package package_imageArray is
    -- Type for storing RGB value of each pixel:
	subTYPE COLOR IS INTEGER range 0 to 255;
    TYPE RGB IS RECORD
        RED     : COLOR;
        GREEN   : COLOR;
        BLUE    : COLOR;
    END RECORD;

    -- Type for storing image pixel containing RGB:
    type image_process is array (natural range<>, natural range<>) of RGB;

end package package_imageArray;