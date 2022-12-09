--bicubic interpolation
--version: 18.41 12/09
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

--comment code below if you run in Quartus prime lite/standard version.
--use IEEE.fixed_pkg.all;

--uncomment code below if you run in Quartus prime lite/standard version.
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

use work.package_imageArray.all;

entity interpolation is
    generic(
        x               : natural := 4; 
        y               : natural := 4;
        upscale_ratio   : natural := 2
    );
    port (
        in_image    : in image_process(0 to x-1,0 to y-1);
        out_image   : out image_process(0 to x*upscale_ratio-1, 0 to y*upscale_ratio-1);
        clk, start  : in std_logic
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


    component padding is
        generic(
        x               : natural; 
        y               : natural;
        upscale_ratio   : natural
        );
    port (
        clk             : in std_logic;
        in_image        : in image_process(0 to x-1, 0 to y-1);
        image_padded    : out image_process(0 to x+3, 0 to y+3);
        done_padding    : out std_logic;
        enable_padding  : in std_logic
        );
    end component;
    
    type state_type is (IDLE,PAD_STATE, PROCESSING, DONE);
    signal state            : state_type;
    signal in_image_buff    : image_process(0 to x-1,0 to y-1);
    signal in_image_padded  : image_process(0 to x+3, 0 to y+3);
    signal out_image_buff   : image_process(0 to x*upscale_ratio-1, 0 to y*upscale_ratio-1);
    signal height, weight   : natural;
    signal i, j, k, l, m    : natural := 0;
    signal done_padding     : std_logic;
    signal enable_padding   : std_logic := '0';
begin
         
    in_image_buff <= in_image;

    pad4x4 :padding generic map (
        x => x, y => y, upscale_ratio => upscale_ratio
    ) port map (
        clk => clk,
        in_image => in_image,
        image_padded => in_image_padded,
        done_padding => done_padding,
        enable_padding => enable_padding

    );

    process (clk) is
        type kernel_matrix is array (0 to 3) of sfixed(7 downto -7);
        type sfixed_array is array (natural range<>) of sfixed(7 downto -7);
        type rgb_array is array (natural range<>) of rgb;
        variable neig_x, neig_y         : sfixed(7 downto -7) := (others => '0');
        variable x_matrix               : sfixed_array(0 to 3);
        variable y_matrix               : sfixed_array(0 to 3);
        variable k_matrix_x, k_matrix_y : kernel_matrix;
        variable neighbour_matrix       : image_process (0 to 3, 0 to 3) := (others => (others => (others => 0)));
        variable dot_product_buff       : rgb_array(0 to 3);
        variable result_neighbour       : rgb;
        variable temp                   : rgb;
		variable temp_sfixed_red        : sfixed(7 downto -7) := (others => '0');
		variable temp_sfixed_green		: sfixed(7 downto -7) := (others => '0');
		variable temp_sfixed_blue		: sfixed(7 downto -7) := (others => '0');
       
    begin 
        if start = '0' then
            state <= IDLE;
        elsif (rising_edge(clk)) then
            
            case state is
                when IDLE => 
                    if start = '1' then
                        state <= PAD_STATE;
                    end if;

                when PAD_STATE =>
                    enable_padding <= '1';
                    if done_padding <= '1' then
                        enable_padding <= '0';
                        state <= PROCESSING;
                    end if;

                when PROCESSING =>
                    for i in 0 to x*upscale_ratio-1 loop
                        for j in 0 to y*upscale_ratio-1 loop
                            neig_x := to_sfixed(real(i)*(1.0/real(upscale_ratio)) + 2.0, neig_x);
                            neig_y := to_sfixed(real(j)*(1.0/real(upscale_ratio)) + 2.0, neig_y);

                            x_matrix(0) := to_sfixed(1.0 + to_real(neig_x) - round(to_real(neig_x)) , x_matrix(0));
                            x_matrix(1) := to_sfixed(to_real(neig_x) - round(to_real(neig_x))       , x_matrix(1));
                            x_matrix(2) := to_sfixed(round(to_real(neig_x)) + 1.0 - to_real(neig_x) , x_matrix(2));
                            x_matrix(3) := to_sfixed(round(to_real(neig_x)) + 1.0 - to_real(neig_x) , x_matrix(3));
                                
                            y_matrix(0) := to_sfixed(1.0 + to_real(neig_y) - round(to_real(neig_y)) , y_matrix(0));
                            y_matrix(1) := to_sfixed(to_real(neig_y) - round(to_real(neig_y))       , y_matrix(1));
                            y_matrix(2) := to_sfixed(round(to_real(neig_y)) + 1.0 -to_real(neig_y)  , y_matrix(2));
                            y_matrix(3) := to_sfixed(round(to_real(neig_y)) + 1.0 - to_real(neig_y) , y_matrix(3));

                            for k in 0 to 3 loop
                                k_matrix_x(k) := to_sfixed(kernel(to_real(x_matrix(k))), k_matrix_x(k));
                                k_matrix_y(k) := to_sfixed(kernel(to_real(y_matrix(k))), k_matrix_y(k));
                                --wait until (rising_edge(clk));
                            end loop;

                        
                            for k in 0 to 3 loop
                                for l in 0 to 3 loop
                                    neighbour_matrix(k,l) := in_image_padded(integer(round(to_real(neig_x) - to_real(x_matrix(k)))), integer(round(to_real(neig_y) - to_real(y_matrix(l)))));
                                    --wait until (rising_edge(clk));
                                end loop;
                                --wait until (rising_edge(clk));
                            end loop;
                        
                            --dot product k_matrix_x and neighbour_matrix, result in dot_product_buff
                            for k in 0 to 3  loop
                                temp.red    := 0;
                                temp.green  := 0;
                                temp.blue   := 0;
                                for l in 0 to 3 loop
                                    for m in 0 to 3 loop
                                        temp_sfixed_red     := to_sfixed((neighbour_matrix(l,m).red), temp_sfixed_red);
                                        temp_sfixed_green   := to_sfixed((neighbour_matrix(l,m).green), temp_sfixed_green);
                                        temp_sfixed_blue    := to_sfixed((neighbour_matrix(l,m).blue), temp_sfixed_blue);
                                        

                                        temp.red    := temp.red + integer((to_real(k_matrix_x(k))*to_real(temp_sfixed_red)));    
                                        temp.green  := temp.green + integer((to_real(k_matrix_x(k))*to_real(temp_sfixed_green)));    
                                        temp.blue   := temp.blue + integer((to_real(k_matrix_x(k))*to_real(temp_sfixed_blue)));    
                                        --wait until (rising_edge(clk));   
                                    end loop;
                                    --wait until (rising_edge(clk));
                                end loop;
                                dot_product_buff(k).red   := temp.red; 
                                dot_product_buff(k).green := temp.green; 
                                dot_product_buff(k).blue  := temp.blue; 
                                --wait until (rising_edge(clk));
                            end loop; 
                            
                            --dot product k_matrix_y and dot_product_buff, result in result_neighbour
                            for k in 0 to 3  loop
                                for l in 0 to 1 loop
                                    temp.red    := 0;
                                    temp.green  := 0;
                                    temp.blue   := 0;
                                    for m in 0 to 3 loop
                                        temp_sfixed_red     := to_sfixed((dot_product_buff(m).red), temp_sfixed_red);
                                        temp_sfixed_green   := to_sfixed((dot_product_buff(m).green), temp_sfixed_green);
                                        temp_sfixed_blue    := to_sfixed((dot_product_buff(m).blue), temp_sfixed_blue);
                                            
                                        temp.red    := temp.red + integer((to_real(k_matrix_y(k))*to_real(temp_sfixed_red)));    
                                        temp.green  := temp.green + integer((to_real(k_matrix_y(k))*to_real(temp_sfixed_green)));    
                                        temp.blue   := temp.blue + integer((to_real(k_matrix_y(k))*to_real(temp_sfixed_blue))); 
                                        --wait until (rising_edge(clk));      
                                    end loop;
                                result_neighbour.red   := temp.red; 
                                result_neighbour.green := temp.green; 
                                result_neighbour.blue  := temp.blue; 
                                --wait until (rising_edge(clk));
                                end loop;
                                --wait until (rising_edge(clk));
                            end loop;
                        
                            out_image_buff(i,j).red     <= result_neighbour.red;
                            out_image_buff(i,j).green   <= result_neighbour.blue;
                            out_image_buff(i,j).blue    <= result_neighbour.blue;

                                --wait until (rising_edge(clk));
                        end loop;
                        --wait until (rising_edge(clk));
                    end loop;
                    state <= DONE;

                when DONE =>
                    out_image <=  out_image_buff;
                    state <= IDLE;
            end case; 
        end if;
    end process;
end architecture rtl;