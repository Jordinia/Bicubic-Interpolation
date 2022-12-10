# Final Project PSD A4 - Bicubic Interpolation Image Upscaling Hardware Accelerator on VHDL

## Background

Hardware Accelerator Image Upscaling is a hardware which can improve image quality by increasing the number of pixels (padding) in the image. Hardware Accelerator Image Upscaling is made to speed up the upscaling process without the need for a PC or laptop. This Hardware Accelerator is generally used in the process of improving the quality of CCTV or cameras with low resolution quality in order to get a higher quality.

Our project aims to recreate the functionality of the Hardware Accelerator Image Upscaling hardware using VHDL, a hardware description language used to design and simulate digital systems.

## How it works

When the user input the image, the image will first be turned into an array made out of the image's pixels rgb values. The hardware then will pass the array into the interpolation component. In the interpolation component, the rgb values of the image that is stored inside the array will then be upscaled through an algorithm called bicubic interpolation. The new rgb values will then be stored inside a new empty array that has been resized according to the scale of the upscaling. The new values inside of the array will then be outputted into an empty bmp file to show an upscaled version of the inputted image.

## How to use

Our design works by reading a BMP image file and then storing the value of each pixels into an array. The program then pass the array through the hardware and outputs the upscaled version of the inputted BMP image file.

## Testing

We tested our design by using a testbench file that reads a predetermined BMP image file that will be passed to the input. The design will be declared unsuccessful if the output BMP image file wasn't upscaled.

## Result
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/ScreenshotWave1.jpg?raw=true)
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/ScreenshotWave2.jpg?raw=true)

it took 2350 ps to upscale a 25x25 image into a 50x50

![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/ScreenshotWave3.jpg?raw=true)
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/ScreenshotWave4.jpg?raw=true)
