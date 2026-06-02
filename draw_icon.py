from PIL import Image, ImageDraw, ImageFont

size = 1024

# Transparent background for Android foreground
img_transparent = Image.new('RGBA', (size, size), (255, 255, 255, 0))
# White background for iOS and fallback
img_white = Image.new('RGBA', (size, size), (255, 255, 255, 255))

# Teal Card
teal_card = Image.new('RGBA', (520, 440), (0,0,0,0))
t_draw = ImageDraw.Draw(teal_card)
t_draw.rounded_rectangle([0, 0, 520, 440], radius=80, fill="#48D1B3")
teal_card = teal_card.rotate(-12, resample=Image.BICUBIC, expand=True)

# Blue Card
blue_card = Image.new('RGBA', (600, 480), (0,0,0,0))
b_draw = ImageDraw.Draw(blue_card)
b_draw.rounded_rectangle([0, 0, 600, 480], radius=80, fill="#5061F5")

try:
    font = ImageFont.truetype("arialbd.ttf", 136)
except:
    font = ImageFont.load_default()

b_draw.text((300, 240), "Hello", font=font, fill="white", anchor="mm")
blue_card = blue_card.rotate(10, resample=Image.BICUBIC, expand=True)

# Paste on transparent
img_transparent.paste(teal_card, (560 - teal_card.width//2, 600 - teal_card.height//2), teal_card)
img_transparent.paste(blue_card, (464 - blue_card.width//2, 420 - blue_card.height//2), blue_card)

# Paste on white
img_white.paste(teal_card, (560 - teal_card.width//2, 600 - teal_card.height//2), teal_card)
img_white.paste(blue_card, (464 - blue_card.width//2, 420 - blue_card.height//2), blue_card)

img_transparent.save("assets/images/icon.png")
img_white.save("assets/images/icon_ios.png")
