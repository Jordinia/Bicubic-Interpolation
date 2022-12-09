--VERSION 14.19 12/09
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

    -- shared VARIABLE inputImageArray : image;
    -- shared VARIABLE outputImageArray : image;
    
    -- function initialImageArray(
    --     signal x, y : natural;
    --     signal clk  : std_logic;
    --     signal inputImageArray : image_process
    -- ) return image_process;

    procedure initialImageArray(
        signal x, y : in natural;
        variable inputImageArray : inout image_process
    );

end package package_imageArray;

package body package_imageArray is

    -- function initialImageArray(
    --     signal x, y : natural;
    --     signal clk  : std_logic;
    --     signal inputImageArray : image_process
    -- ) return image_process is
    --     signal i : natural := 0;
    --     signal j : natural := 0;
    -- begin
    --     if rising_edge(clk) then
    --         i <= i + 1;
    --         if i = x then
    --             i <= 0;
    --             j <= j + 1;
    --             if j = y then
    --                 j <= 0;
    --             end if;
    --         end if;
    --         inputImageArray(i,j).RED <= 0;
    --         inputImageArray(i,j).GREEN <= 0;
    --         inputImageArray(i,j).BLUE <= 0;
    --       end if;
    -- end function initialImageArray;


    procedure initialImageArray(
        signal x, y : in natural;
        variable inputImageArray : inout image_process
    )  is
    begin
        for i in 0 to x loop
            for j in 0 to y loop
                inputImageArray(i,j).RED := 0;
                inputImageArray(i,j).GREEN := 0;
                inputImageArray(i,j).BLUE := 0;
            end loop;
        end loop;
    end procedure initialImageArray;
end package body package_imageArray;