from pathlib import Path
import math
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).parent
helpers=(ROOT.parent/'real_c06'/'analyze.py').read_text(encoding='utf-8').split('rows = []')[0]
exec(compile(helpers,'inventory_helpers','exec'))
ROOT=Path(__file__).parent
rows=[parse(s) for s in (ROOT/'debug.lspdata').read_text().splitlines()]
def area(points):
    p0=points[0]
    ps=[(p[0]-p0[0],p[1]-p0[1]) for p in points]
    return sum(a[0]*b[1]-a[1]*b[0] for a,b in zip(ps,ps[1:]+ps[:1]))/2
for tag,data in rows:
    if tag=='GEOMETRY_IN':
        print(tag,len(data))
        for i,d in enumerate(data):
            ps=allget(d,10)
            print(i,get(d,5),len(ps),'AREA',area(ps),'MIN_EDGE',min(math.dist(a,b) for a,b in zip(ps,ps[1:]+ps[:1])))
            if abs(area(ps))<1:print('TINY',ps)
    elif tag=='GEOMETRY_OUT':print(tag,len(data),[(area([v[0] for v in loop]),len(loop)) for loop in data])
    elif tag=='UNCOVERED':print(tag,data[1])

inputs=next(d for tag,d in rows if tag=='INPUT')
loops=[d for tag,d in rows if tag=='GEOMETRY_OUT'][-1]
print('FINAL LOOPS',loops)
W,H=1800,650; im=Image.new('RGB',(W,H),'#202832'); draw=ImageDraw.Draw(im)
ps=[p for d in inputs for p in allget(d,10)]; xmin=min(p[0] for p in ps);xmax=max(p[0] for p in ps);ymin=min(p[1] for p in ps);ymax=max(p[1] for p in ps)
scale=(W-120)/(xmax-xmin)
xy=lambda p:(60+(p[0]-xmin)*scale,H/2+(ymax+ymin-2*p[1])*scale/2)
for d in inputs:
    ps=allget(d,10);draw.line([xy(p) for p in ps+[ps[0]]],fill='#87b994',width=2)
for loop in loops:
    ps=[v[0] for v in loop];draw.line([xy(p) for p in ps+[ps[0]]],fill='#39dce7',width=4)
for tag,data in rows:
    if tag=='UNCOVERED':draw.line([xy(p) for p in data[1][:2]],fill='#ff6474',width=7)
draw.text((30,30),'FO failure: source panels (green), computed outline (cyan), rejected edge (red)',font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',26),fill='#f1f5fa')
im.save(ROOT/'failure.png')
