# Final Project PSD A4 - Bicubic Interpolation Image Upscaling Hardware Accelerator on VHDL

## Background

Image Upscaling Hardware Accelerator is a hardware device that improves the quality of an image by increasing the number of pixels in the image, also known as padding, while maintain or improving image quality. This hardware accelerator is designed to speed up image upscaling process without the need for a CPU, and uses a Bicubic Interpolation algorithm to further enhance the quality of the upscaled image. It can be used in image-intensive applications that require high-quality images, such as CCTV cameras or other low-resolution cameras.

Our project aims to recreate the functionality of an image upscaler using VHDL, a hardware description language used to design and simulate digital systems. This will allow us to create a digital system that can perform image upscaling quickly and accurately, without the need for computing power from existing CPU.

## How it works

When the user input the image, the image will first be turned into an array made out of the image's pixels rgb values. The hardware then will pass the array into the interpolation component. In the interpolation component, the rgb values of the image that is stored inside the array will then be upscaled through an algorithm called bicubic interpolation. The new rgb values will then be stored inside a new empty array that has been resized according to the scale of the upscaling. The new values inside of the array will then be outputted into an empty bmp file to show an upscaled version of the inputted image.

## How to use

Our design works by reading a BMP image file and then storing the value of each pixels into an array. The program then pass the array through the hardware and outputs the upscaled version of the inputted BMP image file.

## Finite State Machine

### Upscaler
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/FSM%20Upscaler.jpg?raw=true)

### Interpolation
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/FSM%20Interpolation.jpg?raw=true)

### Padding
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/FSM%20Padding.jpg?raw=true)

## Testing

We tested our design by using a testbench file that reads a predetermined BMP image file that will be passed to the input. The design will be declared unsuccessful if the output BMP image file wasn't upscaled.

## Result

### Wave
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/ScreenshotWave1.jpg?raw=true)
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/ScreenshotWave2.jpg?raw=true)

It took 2350 ps to upscale a 25x25 image into a 50x50

![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/ScreenshotWave3.jpg?raw=true)
![alt text](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/ScreenshotWave4.jpg?raw=true)

Full wave result is ![here](https://github.com/Jordinia/Bicubic-Interpolation/blob/main/Assets/UPSCALER.wlf)

### Upscaled Image
 
 - Failed Test 1, 22x22 into 44x44 cropped to 22x22

 ![alt text](https://raw.githubusercontent.com/Jordinia/Bicubic-Interpolation/main/Assets/test2.bmp) -> ![alt text](https://raw.githubusercontent.com/Jordinia/Bicubic-Interpolation/main/Assets/out1.bmp)
 
 - Test 2, 22x22 into 44x44 
 ![alt text](https://raw.githubusercontent.com/Jordinia/Bicubic-Interpolation/main/Assets/test2.bmp) -> ![alt text](https://raw.githubusercontent.com/Jordinia/Bicubic-Interpolation/main/Assets/out2.bmp)
