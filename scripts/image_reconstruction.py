import cv2
import numpy as np
import matplotlib.pyplot as plt

# 1. Read the Output File
try:
    with open('output_image.txt', 'r') as f:
        hex_data = f.read().splitlines()
except FileNotFoundError:
    print("Error: output_image.txt not found! Make sure you copied it from the xsim folder.")
    exit()
# 2. Convert Hex to Integers
pixel_values = []
for h in hex_data:
    if h.strip(): # Skip empty lines
        try:
            val = int(h, 16)
            pixel_values.append(val)
        except ValueError:
            pass # Skip garbage data if any
# 3. Reshape into Image
# Note: The output might be slightly smaller than 256x256 due to pipeline delay,
# but we can just take the first 256*254 pixels or reshape carefully.
# Let's try to reshape to the original size and fill missing with 0.
target_size = 256 * 256
if len(pixel_values) < target_size:
    print(f"Warning: Expected {target_size} pixels, got {len(pixel_values)}.")
    # Pad with zeros to match size
    pixel_values +=  * (target_size - len(pixel_values))
else:
    pixel_values = pixel_values[:target_size] # Trim excess
img_out = np.array(pixel_values, dtype=np.uint8).reshape((256, 256))
# 4. Display
plt.figure(figsize=(6,6))
plt.imshow(img_out, cmap='gray')
plt.title("FPGA Output (Sobel Edge Detection)")
plt.axis('off')
plt.show()

