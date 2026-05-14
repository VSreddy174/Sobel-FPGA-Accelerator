import cv2
import numpy as np

# 1. Load and Resize Image
img = cv2.imread('your_image.jpg', cv2.IMREAD_GRAYSCALE)
img_resized = cv2.resize(img, (256, 256))

# 2. Save to input_image.txt (Hex format, one pixel per line)
with open('input_image.txt', 'w') as f:
    for row in range(256):
        for col in range(256):
            pixel = img_resized[row, col]
            f.write(f"{pixel:02x}\n") # Write as hex (e.g., FF, A5, 00)

print("input_image.txt generated!")

