--padding
--version: 13.23 12/10
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.package_imageArray.all;

entity padding is
    generic(
        x               : natural := 1000; 
        y               : natural := 1000;
        upscale_ratio   : natural := 2
    );
    port (
        clk            : in std_logic;
        in_image        : in image_process(0 to x-1, 0 to y-1);
        image_padded    : out image_process(0 to x+3, 0 to y+3);
        done_padding    : inout std_logic := '0';
        enable_padding  : in std_logic
    );
end entity padding;

architecture rtl of padding is
    type state_type is (IDLE, ZEROS, PAD_2x2, PAD_8POINT, DONE);
    signal state : state_type;
    signal image_padded_buff  : image_process(0 to x+3, 0 to y+3);
    signal ready : std_logic;

begin
    
    process (clk)
        variable i, j : natural := 0;
    begin
        
        if rising_edge(clk) then
            ready <= enable_padding;
            case state is
                when IDLE =>
                done_padding <= '0';
                    if ready = '1' then
                        state <= ZEROS;
                        ready <= '0';
                        
                    end if;    
                when ZEROS =>
                    for i in 0 to x+3 loop
                        for j in 0 to y+3 loop
                            image_padded_buff(i,j).red    <= 0;
                            image_padded_buff(i,j).green  <= 0;
                            image_padded_buff(i,j).blue   <= 0;
                        end loop;
                    end loop;
                    state <= PAD_2x2;   
                when PAD_2x2 =>
                    --outimg[2:H+2, 2:W+2] = img
                    for i in 0 to x-1 loop
                        for j in 0 to y-1 loop
                            image_padded_buff(i+2, j+2) <= in_image(i, j);
                        end loop;
                    end loop;

                    --zimg[2:H+2, 0:2, :C] = img[:, 0:1, :C]
                    for i in 0 to x-1 loop
                        image_padded_buff(i+2, 0) <= in_image(i, 0);
                        image_padded_buff(i+2, 1) <= in_image(i, 0);
                        image_padded_buff(i+2, 2) <= in_image(i, 1);
                    end loop;

                    for i in 0 to 1 loop
                        for j in 0 to 1 loop
                            image_padded_buff(x-1+i+2, y-1+i+2) <= in_image(x-1,y-1);
                        end loop;
                    end loop;
                    
                    image_padded_buff(x-1+2, y-1+4) <= in_image(x-1,y-1);
                    image_padded_buff(x-1+3, y-1+4) <= in_image(x-1,y-1);
                    image_padded_buff(x-1+4, y-1+4) <= in_image(x-1,y-1);
                    
            
                    --outimg(2 to H+2, 2 to W+2, 1 to C) <= img(1 to H, 1 to W, 1 to C);
                    for i in 0 to x-1 loop
                        for j in 0 to y-1 loop
                            image_padded_buff(i+2, j+2) <= in_image(i, j);
                        end loop;
                    end loop;
                    
                    -- zimg[0:2, 2:W+2, :C] = img[0:1, :, :C]
                    for j in 0 to y-1 loop
                        image_padded_buff(0, j+2) <= in_image(0, j);
                        image_padded_buff(1, j+2) <= in_image(0, j);
                        image_padded_buff(2, j+2) <= in_image(1, j);
                    end loop;
                    state <= PAD_8POINT;

                when PAD_8POINT =>
                    -- zimg[0:2, 0:2, :C] = img[0, 0, :C]
                    for i in 0 to 2 loop
                        for j in 0 to 2 loop
                            image_padded_buff(i, j) <= in_image(0, 0);
                        end loop;
                    end loop;
            
                    -- zimg[H+2:H+4, 0:2, :C] = img[H-1, 0, :C]
                    for i in 0 to 2 loop
                        for j in 0 to 2 loop
                            image_padded_buff(x-1+i, j) <= in_image(x-1, 0);
                        end loop;
                    end loop;
                    -- zimg[H+2:H+4, W+2:W+4, :C] = img[H-1, W-1, :C]
                    for i in 0 to 2 loop
                        for j in 0 to 2 loop
                            image_padded_buff(x-1+i+2, y-1+j+2) <= in_image(x-1, y-1);
                        end loop;
                    end loop;
                    -- zimg[0:2, W+2:W+4, :C] = img[0, W-1, :C]
                    for i in 0 to 2 loop
                        for j in 0 to 2 loop
                            image_padded_buff(i, y-1+j+2) <= in_image(0, y-1);
                        end loop;
                    end loop;
                    state <= DONE;
                    done_padding <= '1';
                    image_padded <= image_padded_buff;
                when DONE =>
                    --done_padding <= '1';
                    state <= IDLE;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture;