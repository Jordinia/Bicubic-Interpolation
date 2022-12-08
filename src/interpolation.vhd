library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

use work.package_imageArray.all;

entity interpolation is
    generic(
        x               : natural := 100; 
        y               : natural := 100;
        upscale_ratio   : natural := 2
    );
    port (
        in_image    : in image_process(x-1 downto 0, y-1 downto 0);
        out_image   : out image_process(x*upscale_ratio-1 downto 0, x*upscale_ratio-1 downto 0);
        clk, reset  : in std_logic
    );
end entity interpolation;
    
architecture rtl of interpolation is
    
    -- Interpolation Kernel Function for Bicubic Interpolation 
    -- The interpolation kernel for bicubic is of the form:
    -- W(x) = (a+2)|x|^3-(a+3)|x|^2+1,          : for |x|<=1
    -- W(x) = a|x|^3 - 5a|x|^2 + 8a|x| - 4a     : for 1<|x|<=2
    -- W(x) = 0                                 : otherwise
    -- with a is coefficient that is usually set between -0.5 to 0.75. In this function, we set constant a = -0.5
    function kernel (position : real := 0.0) return real is
        variable coeff : real  := -0.5;
    begin
        if (position >= 0.0 AND position <= 1.0) then
           return (coeff+2.0)*(abs(position**3)) - (((coeff+3.0)*(abs(position**2))) + 1.0);
        elsif (position > 1.0 AND position <= 2.0) then
            return (coeff)*(abs(position**3)) - (5.0*coeff)*(abs(position**2))+ (8.0*coeff)*abs(position) - (4.0*coeff);
        else
            return 0.0;
        end if;
    end function;


    
    -- function that create 4x4 padding for input image
    function padding(in_image_buff: image_process(x-1 downto 0, y-1 downto 0)) return image_process is  
        variable i, j : natural;
        variable in_image_padded  : image_process(x+3 downto 0, y+3 downto 0);
    begin
        -- initial padded image (zeros array)
        for i in 0 to x+3 loop
            for j in 0 to y+3 loop
                in_image_padded(i,j).red    := 0;
                in_image_padded(i,j).green  := 0;
                in_image_padded(i,j).blue   := 0;
            end loop;
        end loop;

        --outimg[2:H+2, 2:W+2] = img
        for i in 0 to x loop
            for j in 0 to y loop
                in_image_padded(i+2, j+2) := in_image_buff(i, j);
            end loop;
        end loop;

        --zimg[2:H+2, 0:2, :C] = img[:, 0:1, :C]
        for i in 0 to x loop
            in_image_padded(i+2, 0) := in_image_buff(i, 0);
            in_image_padded(i+2, 1) := in_image_buff(i, 0);
            in_image_padded(i+2, 2) := in_image_buff(i, 1);
        end loop;

        --outimg(H+2 to H+4, W+2 to W+4, 1 to C) := img(H to H-1, W to W-1, 1 to C);
        for i in 0 to 1 loop
            for j in 0 to 1 loop
                in_image_padded(x+i+2, y+i+2) := in_image_buff(x,y);
            end loop;
        end loop;
        
        in_image_padded(x+2, y+4) := in_image_buff(x-1,y-1);
        in_image_padded(x+3, y+4) := in_image_buff(x-1,y-1);
        in_image_padded(x+4, y+4) := in_image_buff(x-1,y-1);
        

        --outimg(2 to H+2, 2 to W+2, 1 to C) := img(1 to H, 1 to W, 1 to C);
        for i in 0 to x loop
            for j in 0 to y loop
                in_image_padded(i+2, j+2) := in_image_buff(i, j);
            end loop;
        end loop;
        
        -- zimg[0:2, 2:W+2, :C] = img[0:1, :, :C]
        for j in 0 to y loop
            in_image_padded(0, j+2) := in_image_buff(0, j);
            in_image_padded(1, j+2) := in_image_buff(0, j);
            in_image_padded(2, j+2) := in_image_buff(1, j);
        end loop;

        -- zimg[0:2, 0:2, :C] = img[0, 0, :C]
        for i in 0 to 2 loop
            for j in 0 to 2 loop
                in_image_padded(i, j) := in_image_buff(0, 0);
            end loop;
        end loop;

        -- zimg[H+2:H+4, 0:2, :C] = img[H-1, 0, :C]
        for i in 0 to 2 loop
            for j in 0 to 2 loop
                in_image_padded(x+i, j) := in_image_buff(x-1, 0);
            end loop;
        end loop;
        -- zimg[H+2:H+4, W+2:W+4, :C] = img[H-1, W-1, :C]
        for i in 0 to 2 loop
            for j in 0 to 2 loop
                in_image_padded(x+i+2, y+j+2) := in_image_buff(x-1, y-1);
            end loop;
        end loop;
        -- zimg[0:2, W+2:W+4, :C] = img[0, W-1, :C]
        for i in 0 to 2 loop
            for j in 0 to 2 loop
                in_image_padded(i, y+j+2) := in_image_buff(0, y-1);
            end loop;
        end loop;

        return in_image_padded;
    end function;


    signal in_image_buff    : image_process(x-1 downto 0, y-1 downto 0);
    signal in_image_padded  : image_process(x+3 downto 0, y+3 downto 0);
    signal out_image_buff   : image_process(x*upscale_ratio-1 downto 0, y*upscale_ratio-1 downto 0);
    signal height, weight   : natural;
    signal i, j, k, l, m    : natural;
begin
    in_image_buff <= in_image;

    process(clk) is
        type kernel_matrix is array (3 downto 0) of real;
        type real_array is array (natural range<>) of real;
        variable neig_x, neig_y         : real;
        variable x_matrix               : real_array(3 downto 0);
        variable y_matrix               : real_array(3 downto 0);
        variable k_matrix_x, k_matrix_y : kernel_matrix;
        variable neighbour_matrix       : image_process (3 downto 0, 3 downto 0);
        variable dot_product_buff       : rgb(3 downto 0);
        variable result_neighbour       : rgb;
        variable temp                   : rgb;
       
    begin
        if (rising_edge(clk)) then

            in_image_padded <= padding(in_image_buff);

            for i in 0 to x*upscale_ratio-1 loop
                for j in 0 to y*upscale_ratio-1 loop
                    neig_x := real(i)*(1.0/real(upscale_ratio)) + 2.0;
                    neig_y := real(j)*(1.0/real(upscale_ratio)) + 2.0;

                    x_matrix(0) := 1.0 + neig_x - round(neig_x);
                    x_matrix(1) := neig_x - round(neig_x);
                    x_matrix(2) := round(neig_x) + 1.0 - neig_x;
                    x_matrix(3) := round(neig_x) + 1.0 - neig_x;

                    y_matrix(0) := 1.0 + neig_y - round(neig_y);
                    y_matrix(1) := neig_y - round(neig_y);
                    y_matrix(2) := round(neig_y) + 1.0 - neig_y;
                    y_matrix(3) := round(neig_y) + 1.0 - neig_y;

                    for k in 0 to 3 loop
                        k_matrix_x(k) := kernel(x_matrix(k));
                        k_matrix_y(k) := kernel(y_matrix(k));
                    end loop;
                        
                    for k in 0 to 3 loop
                        for l in 0 to 3 loop
                            neighbour_matrix(k,l) := in_image_buff(integer(round(neig_x - x_matrix(k))), integer(round(neig_y - y_matrix(l))));
                        end loop;
                    end loop;
                    
                    --dot product k_matrix_x and neighbour_matrix, result in dot_product_buff
                    for k in 0 to 3  loop
                        temp.red    := 0;
                        temp.green  := 0;
                        temp.blue   := 0;
                        for l in 0 to 3 loop
                            for m in 0 to 3 loop
                                temp.red := temp.red + integer(round(k_matrix_x(k)*real(neighbour_matrix(l,m).red)));    
                                temp.green := temp.green + integer(round(k_matrix_x(k)*real(neighbour_matrix(l,m).green)));    
                                temp.blue := temp.blue + integer(round(k_matrix_x(k)*real(neighbour_matrix(l,m).blue)));       
                            end loop;
                        end loop;
                        dot_product_buff(k).red   := temp.red; 
                        dot_product_buff(k).green := temp.green; 
                        dot_product_buff(k).blue  := temp.blue; 
                    end loop; 
                    
                    --dot product k_matrix_y and dot_product_buff, result in result_neighbour
                    for k in 0 to 3  loop
                        for l in 0 to 1 loop
                            temp.red    := 0;
                            temp.green  := 0;
                            temp.blue   := 0;
                            for m in 0 to 3 loop
                                temp.red    := temp.red + integer(round(k_matrix_y(k)*real(dot_product_buff(l,m).red)));    
                                temp.green  := temp.green + integer(round(k_matrix_y(k)*real(dot_product_buff(l,m).green)));    
                                temp.blue   := temp.blue + integer(round(k_matrix_y(k)*real(dot_product_buff(l,m).blue)));       
                            end loop;
                        result_neighbour(k,l).red   := temp.red; 
                        result_neighbour(k,l).green := temp.green; 
                        result_neighbour(k,l).blue  := temp.blue; 
                        end loop;
                    end loop; 

                    out_image_buff(i,j).red  <= result_neighbour.red;
                    

                end loop;
            end loop;
       end if;
    end process;
    
    
    
end architecture rtl;