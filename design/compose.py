from PIL import Image, ImageDraw, ImageFont
import os

ROOT = os.path.abspath('.')
ICON = os.path.join(ROOT, 'design', 'icon')
MOCK = os.path.join(ROOT, 'design', 'mockups')
FONT_B = r'C:\Windows\Fonts\segoeuib.ttf'
FONT_R = r'C:\Windows\Fonts\segoeui.ttf'
FONT_SB = r'C:\Windows\Fonts\seguisb.ttf'

os.makedirs(ICON, exist_ok=True)


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


icon = Image.open(os.path.join(ICON, 'icon-1024.png')).convert('RGB')
for size in (512, 192, 96, 48):
    icon.resize((size, size), Image.LANCZOS).save(os.path.join(ICON, f'icon-{size}.png'))

rounded(icon, 230).save(os.path.join(ICON, 'icon-rounded-1024.png'))
Image.new('RGB', (432, 432), '#000000').save(os.path.join(ICON, 'adaptive-background-432.png'))


def text(draw, xy, s, font, fill):
    draw.text(xy, s, font=font, fill=fill)


# ---------- icon preview ----------
W, H = 1400, 900
prev = Image.new('RGB', (W, H), '#0E0D12')
d = ImageDraw.Draw(prev)
# left dark panel
d.rounded_rectangle([40, 40, 680, 860], 32, fill='#141219')
big = rounded(icon, 230).resize((520, 520), Image.LANCZOS)
prev.paste(big, (100, 130), big)
text(d, (100, 690), "Основная иконка", ImageFont.truetype(FONT_B, 34), '#FFFFFF')
text(d, (100, 738), "1024 × 1024 · чёрный фон · градиент D", ImageFont.truetype(FONT_R, 22), '#9B94A5')

# right light panel
d.rounded_rectangle([720, 40, 1360, 860], 32, fill='#F7F4F7')
text(d, (770, 100), "Размеры и адаптивная иконка", ImageFont.truetype(FONT_B, 30), '#18141D')
sizes = [192, 96, 48]
y = 190
for s in sizes:
    ic = rounded(icon, int(s * 0.225)).resize((s, s), Image.LANCZOS)
    prev.paste(ic, (790, y), ic)
    text(d, (790 + s + 24, y + s // 2 - 14), f"{s} × {s}", ImageFont.truetype(FONT_SB, 20), '#4A4453')
    y += s + 30
# adaptive foreground on a violet circle
circle = Image.new('RGBA', (260, 260), (0, 0, 0, 0))
cd = ImageDraw.Draw(circle)
cd.ellipse([0, 0, 259, 259], fill='#07070B', outline='#2A2433', width=2)
fg = Image.open(os.path.join(ICON, 'adaptive-foreground-432.png')).convert('RGBA').resize((200, 200), Image.LANCZOS)
circle.alpha_composite(fg, (30, 30))
prev.paste(circle, (1090, 200), circle)
text(d, (1090, 480), "Adaptive", ImageFont.truetype(FONT_SB, 18), '#4A4453')
text(d, (1060, 510), "foreground 432", ImageFont.truetype(FONT_R, 17), '#8D8697')

mono = Image.open(os.path.join(ICON, 'monochrome-432.png')).convert('RGBA').resize((110, 110), Image.LANCZOS)
dark_tile = Image.new('RGBA', (180, 180), (24, 20, 29, 255))
dark_tile.alpha_composite(mono, (35, 35))
prev.paste(dark_tile, (1090, 590), dark_tile)
text(d, (1090, 785), "Monochrome", ImageFont.truetype(FONT_SB, 18), '#4A4453')
prev.save(os.path.join(ICON, 'icon-preview.png'))
print('icon-preview.png')

# ---------- icon card for the board ----------
icon_hi = Image.open(os.path.join(ICON, 'icon-2048.png')).convert('RGB') if os.path.exists(os.path.join(ICON, 'icon-2048.png')) else icon
card = Image.new('RGB', (660, 1428), '#0E0D12')
cd = ImageDraw.Draw(card)
cd.rounded_rectangle([24, 24, 636, 1404], 30, fill='#141219', outline='#2A2433', width=2)
big_icon = rounded(icon_hi, 460).resize((460, 460), Image.LANCZOS)
card.paste(big_icon, (100, 150), big_icon)
text(cd, (60, 690), "Иконка", ImageFont.truetype(FONT_B, 40), '#FFFFFF')
text(cd, (60, 748), "D'arky", ImageFont.truetype(FONT_B, 32), '#C27BA0')
text(cd, (60, 798), "Жирная D · сине-фиолетовый градиент", ImageFont.truetype(FONT_R, 22), '#9B94A5')
text(cd, (60, 836), "Чёрный фон · 1024 / 2048 px", ImageFont.truetype(FONT_R, 20), '#6F6878')
for i, s in enumerate((96, 48)):
    ic = rounded(icon, int(s * 0.225)).resize((s, s), Image.LANCZOS)
    card.paste(ic, (60 + i * 150, 930), ic)
    text(cd, (60 + i * 150 + s + 16, 930 + s // 2 - 12), f"{s}", ImageFont.truetype(FONT_SB, 18), '#9B94A5')
card.save(os.path.join(MOCK, '13-icon-card.png'))
print('13-icon-card.png')

# ---------- design board ----------
shots = [
    ('01-auth.png', 'Вход', 'WebView клуба · телефон, пароль, восстановление'),
    ('02-home.png', 'Главная · светлая', 'Два абонемента · заморозка у «Профи»'),
    ('03-schedule.png', 'Расписание', 'Группы, «индив», аренда · FAB'),
    ('07-theme-menu.png', 'Меню', 'Тема оформления и «О приложении»'),
    ('08-theme-dialog.png', 'Тема оформления', '4 темы · применяются сразу'),
    ('09-home-dark.png', 'Главная · тёмная', 'Тема «Графит»'),
    ('10-home-pink.png', 'Главная · розовая', 'Брендовая тема · розовое расписание'),
    ('04-visits.png', 'Посещения', 'История по абонементам и разовым'),
    ('05-purchases.png', 'Покупки', 'Оплаты и пополнения по месяцам'),
    ('06-bookings.png', 'Записи', 'Свои занятия и отмена'),
    ('12-fab-spec.png', 'FAB: границы', '52 dp · drag + clamp в safe area'),
    ('13-icon-card.png', 'Иконка', 'D на чёрном · градиент · adaptive'),
]
SW, SH = 660, 1428
GX, GY = 110, 148
MX, MY = 160, 420
BW = MX * 2 + SW * 4 + GX * 3
BH = MY + (SH + GY) * 3 + 120
board = Image.new('RGB', (BW, BH), '#0E0D12')
bd = ImageDraw.Draw(board)
for yy in range(BH):
    t = yy / BH
    r = int(18 + 8 * (1 - t))
    g = int(15 + 5 * (1 - t))
    b = int(24 + 12 * (1 - t))
    bd.line([(0, yy), (BW, yy)], fill=(r, g, b))

tile = rounded(icon, 230).resize((176, 176), Image.LANCZOS)
board.paste(tile, (MX, 60), tile)
text(bd, (MX + 216, 52), "D'arky — эскизы интерфейса", ImageFont.truetype(FONT_B, 78), '#FFFFFF')
text(bd, (MX + 220, 148), "Android 15+ · Flutter · клиентский кабинет D'arky Dance · 19.11.2026", ImageFont.truetype(FONT_R, 38), '#9B94A5')
text(bd, (BW - MX - 520, 94), "дизайн-предложение · 2×", ImageFont.truetype(FONT_SB, 32), '#C27BA0')

for idx, (fn, title, sub) in enumerate(shots):
    col, row = idx % 4, idx // 4
    x = MX + col * (SW + GX)
    y = MY + row * (SH + GY)
    im = Image.open(os.path.join(MOCK, fn)).convert('RGB').resize((SW, SH), Image.LANCZOS)
    im = rounded(im, 30)
    board.paste(im, (x, y), im)
    bd.rounded_rectangle([x, y, x + SW - 1, y + SH - 1], 30, outline='#2A2433', width=2)
    text(bd, (x + 4, y + SH + 24), title, ImageFont.truetype(FONT_B, 38), '#F2EEF5')
    text(bd, (x + 4, y + SH + 74), sub, ImageFont.truetype(FONT_R, 24), '#8D8697')

# footer legend
ly = BH - 108
bd.ellipse([MX, ly + 13, MX + 20, ly + 33], fill='#C27BA0')
text(bd, (MX + 32, ly), "бренд", ImageFont.truetype(FONT_SB, 26), '#C9C2D2')
bd.ellipse([MX + 200, ly + 13, MX + 220, ly + 33], fill='#6C5CE7')
text(bd, (MX + 232, ly), "своё индивидуальное", ImageFont.truetype(FONT_SB, 26), '#C9C2D2')
bd.ellipse([MX + 560, ly + 13, MX + 580, ly + 33], fill='#C9C2D2')
text(bd, (MX + 592, ly), "чужое — только «индив» и зал", ImageFont.truetype(FONT_SB, 26), '#C9C2D2')
text(bd, (BW - MX - 760, ly), "полный экран — 11-home-full.png", ImageFont.truetype(FONT_R, 24), '#6F6878')
text(bd, (MX, BH - 62), "4 темы · расписание одним скроллом · FAB drag + clamp · оплата убрана · BFF не планируется", ImageFont.truetype(FONT_R, 24), '#6F6878')

board.save(os.path.join(ROOT, 'design', 'board.png'))
print('board.png', board.size)
