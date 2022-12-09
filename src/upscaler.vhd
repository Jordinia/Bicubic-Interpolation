-- UPSCALER V2 w.o interpolation
--VERSION 01.30 10/12
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- use the package
use work.package_imageArray.all;

entity upscaler is
  generic (
      x_size : natural := 1000;
      y_size : natural := 1000
  );
  port(
		clk    : in std_logic;
		reset  : inout std_logic;
    load   : in std_logic; -- Input to load the next BMP
    done   : in std_logic; -- Done signal

    -- input and output image
    inputImageArray: in image_process(0 to x_size-1, 0 to y_size-1);
    outputImageArray: out image_process(0 to x_size-1, 0 to y_size-1);
    -- outputImageArray: out image_process(0 to (x_size*2)-1, 0 to (y_size*2)-1);

    -- state condition
    state  : out std_logic_vector(1 downto 0);  -- Current state
    upscaled : out std_logic;
		ready  : out std_logic -- Ready to process


	);
        
end entity upscaler;

-- architecture declaration, providing the implementation for the FSM
architecture rtl of upscaler is
  -- type for the FSM states
  type fsm_states is (IDLE, ACTIVE, FINISHED);

  -- signal for the current state of the FSM
  signal cur_state : fsm_states;
  signal x_size2 : natural := x_size;
  signal y_size2 : natural := x_size;
  signal tempImageArray: image_process(0 to x_size-1, 0 to y_size-1);
begin
  -- always block for the FSM
  upscaler: process(clk, reset)
  begin
    if (reset = '1') then
      -- reset the FSM to the IDLE state
      for i in 0 to x_size-1 loop
        for j in 0 to y_size-1 loop
            tempImageArray(i, j).RED <= 0;
            tempImageArray(i, j).GREEN <= 0;
            tempImageArray(i, j).BLUE <= 0;
        end loop;
      end loop;
      outputImageArray <= tempImageArray;
      ready <= '1';
      upscaled <= '0';
      state <= "00";
      cur_state <= IDLE;
      reset <= '0';
    elsif (rising_edge(clk)) then
      -- update the FSM state based on the current state and the inputs
      case cur_state is
        when IDLE =>
          state <= "00";
          for i in 0 to x_size-1 loop
            for j in 0 to y_size-1 loop
                tempImageArray(i, j).RED <= 0;
                tempImageArray(i, j).GREEN <= 0;
                tempImageArray(i, j).BLUE <= 0;
            end loop;
          end loop;
          outputImageArray <= tempImageArray;
          if (load = '1') then
            tempImageArray <= inputImageArray;
            state <= "01";
            cur_state <= ACTIVE;
          end if;
        when ACTIVE =>
          state <= "10";
          outputImageArray <= tempImageArray;
          cur_state <= FINISHED;
        when FINISHED =>
          ready <= '0';
          upscaled <= '1';
          if (done = '1') then
            reset <= '1';
          end if;
      end case;
    end if;
  end process;
end architecture rtl;