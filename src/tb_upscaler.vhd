--TBv3 working 15.43 10/12
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.package_imageArray.all;
use std.textio.all;
use std.env.finish;

entity tb_upscaler is
end tb_upscaler;

architecture testbench of tb_upscaler is

  --Char Type for file header
  type header_type  is array (0 to 53) of character;

  -- Signals for DUT
  constant x_size : natural := 22;
  constant y_size : natural := 22;
  constant upscale_ratio : natural := 2;
  signal clk    : std_logic;
  constant clk_period : time := 100 ps;
  signal reset  : std_logic;
  signal load   : std_logic; -- Input to load the next BMP
  signal done   : std_logic;  -- Done signal
  -- input and output image
  signal inputImageArray: image_process(0 to x_size-1, 0 to y_size-1);
  signal outputImageArray: image_process(0 to x_size*upscale_ratio-1, 0 to y_size*upscale_ratio-1);
  signal state  : std_logic_vector(1 downto 0);  -- Current state of
  signal upscaled  : std_logic;  -- upscaled
  signal ready  : std_logic; -- Ready to process
  signal sigHeader : header_type; --Variabel untuk menyimpan data header

begin
  upscaler_instance: entity work.upscaler
  generic map (
    x_size => x_size,
    y_size => y_size
  )
  port map (
    clk     => clk,
    reset   => reset,
    load    => load, -- Input to load the next BMP
    done    => done,  -- Done signal
    inputImageArray => inputImageArray,
    outputImageArray => outputImageArray,
    state   => state,  -- Current state of
    upscaled => upscaled,
		ready   => ready -- Ready to process
  );

  CLOCK: process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period / 2;
	end process CLOCK;

  readBMP : process
    type char_file is file of character; --Mendefinisikan tipe data yang akan dibaca. Karena file yang dibaca adalah file teks, maka tipe data yang digunakan adalah character
    file bmp_file : char_file open read_mode is "test.bmp"; --input file
    file out_file : char_file open write_mode is "out.bmp"; --output file
    variable image_width : integer; 
    variable image_height : integer;
    variable padding : integer; 
    variable char : character;
    variable i : integer := 0;
    variable j : integer := 0;
    variable resetSignal : std_logic := '0';
    variable header : header_type; 
  begin

    -- Reset the module:
		wait for clk_period*3;
    done <= '0';
    load <= '0';
    resetSignal := '1';
    reset <= resetSignal;
		wait for clk_period*3;
		resetSignal := '0';
    reset <= resetSignal;
		wait for clk_period*3;

    -- Read entire header
    while (i < 54) loop
      read(bmp_file, header(i));
      i := i+1;
    end loop;

    sigHeader <= header;

    -- Check ID field
    assert header(0) = 'B' and header(1) = 'M'
      report "First two bytes are not ""BM"". This is not a BMP file"
      severity failure;

    assert character'pos(header(10)) = 54 and
      character'pos(header(11)) = 0 and
      character'pos(header(12)) = 0 and
      character'pos(header(13)) = 0
      report "Pixel array offset in header is not 54 bytes"
      severity warning;

    assert character'pos(header(14)) = 40 and
      character'pos(header(15)) = 0 and
      character'pos(header(16)) = 0 and
      character'pos(header(17)) = 0
      report "DIB headers size is not 40 bytes, is this a Windows BMP?"
      severity warning;

    -- Check that the number of color planes is 1
    assert character'pos(header(26)) = 1 and
      character'pos(header(27)) = 0
      report "Color planes is not 1" severity warning;

    -- Check that the number of bits per pixel is 24
    assert character'pos(header(28)) = 24 and
      character'pos(header(29)) = 0
      report "Bits per pixel is not 24" severity warning;
sigHeader <= header;
    -- Read image width
    image_width := character'pos(header(18)) +
      character'pos(header(19)) * 2**8 +
      character'pos(header(20)) * 2**16 +
      character'pos(header(21)) * 2**24;

    -- Read image height
    image_height := character'pos(header(22)) +
      character'pos(header(23)) * 2**8 +
      character'pos(header(24)) * 2**16 +
      character'pos(header(25)) * 2**24;

    report "image_width: " & integer'image(image_width) &
      ", image_height: " & integer'image(image_height);

    -- Number of bytes needed to pad each row to 32 bits
    padding := (4 - x_size*3 mod 4) mod 4;
    
    -- Reset the module:
		reset <= '1';
		wait for clk_period;
		reset <= '0';
		wait for clk_period;

		-- READY:
		assert ready = '1' report "Module is not ready after reset!" severity failure;	
		wait for clk_period;
    -- STATE
		assert state = "00" report "State is incorrect!" severity error;	
    wait for clk_period;
    
    i := 0;
    j := 0;

    for i in 0 to x_size-1 loop
      for j in 0 to y_size-1 loop
          -- Read blue pixel
        read(bmp_file, char);
        inputImageArray(i,j).blue <=
          to_integer(to_unsigned(character'pos(char), 8));

        -- Read green pixel
        read(bmp_file, char);
        inputImageArray(i,j).green <=
          to_integer(to_unsigned(character'pos(char), 8));

        -- Read red pixel
        read(bmp_file, char);
        inputImageArray(i,j).red <=
          to_integer(to_unsigned(character'pos(char), 8));

        --wait for clk_period;
        
      end loop;

      -- Read and discard padding
      for i in 1 to padding loop
        read(bmp_file, char);
        report "Padding loop = " & integer'image(i);
      end loop;

      --wait for clk_period;

    end loop;

    load <= '1';
    wait for clk_period;
    load <= '0';
    wait for clk_period;

    wait until state = "10";
    wait for clk_period*2;
    -- STATE
		assert upscaled = '1' report "Image is not upscaled!" severity error;	
    wait for clk_period;

    i := 0;
    j := 0;
    report "WRITING FILE";
    -- Write header to output file
    for i in header_type'range loop
      write(out_file, header(i));
      report "header write loop = " & integer'image(i);
    end loop;
    
      i := 0;
      j := 0;
    --1000x1000
    for i in 0 to x_size-1 loop
      report "write loop = " & integer'image(i);
      for j in 0 to y_size-1 loop

        -- Write blue pixel
        write(out_file,
          character'val(outputImageArray(i,j).blue));

        -- Write green pixel
        write(out_file,
          character'val(outputImageArray(i,j).green));

        -- Write red pixel
        write(out_file,
          character'val(outputImageArray(i,j).red));

      end loop;

      -- Write padding
      for i in 1 to padding loop
        write(out_file, character'val(0));
      end loop;

    end loop;

    file_close(bmp_file);
    file_close(out_file);

    report "Simulation done";
  finish;
  end process;

end architecture;