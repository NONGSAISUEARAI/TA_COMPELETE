from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).parent
helpers=(ROOT.parent/'real_c06'/'analyze.py').read_text(encoding='utf-8').split('rows = []')[0]
exec(compile(helpers,'inventory_helpers','exec'))
ROOT=Path(__file__).parent
OUT=ROOT.parents[2]/'outputs'/'fo_test_debug'
debug=[parse(s) for s in (ROOT/'debug.lspdata').read_text().splitlines()]
inputs=next(d for tag,d in debug if tag=='INPUT')
old=[d for tag,d in debug if tag=='GEOMETRY_OUT'][-1]
fixed=[parse(s) for s in (OUT/'fixed-geometry.lspdata').read_text().splitlines()]
new=next(d for tag,d in fixed if tag=='ENTITY' and get(d,0)=='LWPOLYLINE')
W,H=1800,850; im=Image.new('RGB',(W,H),'#17212b');draw=ImageDraw.Draw(im)
font=lambda s:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',s)
draw.text((40,25),'FO error reproduced and fixed | test.dwg',font=font(35),fill='#f1f5fa')
draw.text((40,75),'Same 14 closed panel polylines | cyan: computed outline | grey: source geometry',font=font(22),fill='#b4c4d3')
ps=[p for d in inputs for p in allget(d,10)];xmin=min(p[0] for p in ps);xmax=max(p[0] for p in ps);ymin=min(p[1] for p in ps);ymax=max(p[1] for p in ps)
def panel(top,title,subtitle,loops,bad=False):
    draw.rounded_rectangle((25,top,W-25,top+330),radius=16,fill='#22303b',outline='#3e5261')
    draw.text((50,top+15),title,font=font(28),fill='#ff99a5' if bad else '#90ecd7')
    draw.text((50,top+55),subtitle,font=font(20),fill='#c6d3df')
    scale=(W-150)/(xmax-xmin)
    xy=lambda p:(75+(p[0]-xmin)*scale,top+100+(ymax-p[1])*scale)
    for d in inputs:
        points=allget(d,10);draw.line([xy(p) for p in points+[points[0]]],fill='#a4b6c4',width=1)
    for points in loops:draw.line([xy(p) for p in points+[points[0]]],fill='#43e0e9',width=4)
    if bad:
        for tag,data in debug:
            if tag=='UNCOVERED':draw.line([xy(p) for p in data[1][:2]],fill='#ff6a7a',width=7)
panel(125,'v1.6: FO stops with an error','A neighboring panel group was incorrectly treated as an inner loop; red edge is left outside.',[[v[0] for v in loop] for loop in old],True)
panel(480,'v1.7: one closed outline + one INFO block','AREA = 9.19 m² | lower-left step retained | source entities unchanged',[allget(new,10)])
draw.text((40,823),'Preview drawn from native AutoCAD geometry and diagnostic data; original DWG was preserved.',font=font(18),fill='#aebfcd')
im.save(OUT/'FO_before_after.png')
