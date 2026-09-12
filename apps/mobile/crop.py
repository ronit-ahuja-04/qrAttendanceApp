from PIL import Image
img = Image.open('assets/images/logo.png')
# Find bounding box or just crop top square
w, h = img.size
cropped = img.crop((0, 0, w, w))
cropped.save('assets/images/launcher_icon.png')
print("Cropped successfully to", cropped.size)
