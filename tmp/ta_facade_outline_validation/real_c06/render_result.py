import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from analyze import ROOT, records, cached, parse, get, geometry

OUT = ROOT.parents[2]/'outputs'/'fo_c06_trial'
OUT.mkdir(parents=True,exist_ok=True)
W,H=1800,1100
im=Image.new('RGB',(W,H),'#17212b'); draw=ImageDraw.Draw(im)
font=lambda size:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',size)
draw.text((45,30),'FO trial | ESTIMATE_C06_REV02.dwg',font=font(36),fill='#f0f6fb')
draw.text((45,80),'Actual drawing geometry | AutoCAD 2026 | 03 Nov 2026',font=font(22),fill='#aabbca')
for x,c,t in [(45,'#b5c6d3','Panel geometry'),(360,'#e9c763','Code block: skipped'),(765,'#4ee4ec','New overall polyline')]:
    draw.line((x,140,x+45,140),fill=c,width=4)
    draw.text((x+60,125),t,font=font(23),fill='#e2eaf1')

def load_result(name):
    return [row[1] for row in map(parse,(ROOT/name).read_text(encoding='utf-8').splitlines())
            if row[0]=='ENTITY']

def panel(top,height,title,subtitle,source_handles,data_handles,result_name,box,area):
    draw.rounded_rectangle((30,top,W-30,top+height),radius=16,fill='#202d39',outline='#3c4c59',width=1)
    draw.text((55,top+20),title,font=font(28),fill='#ffffff')
    draw.text((55,top+59),subtitle,font=font(20),fill='#b8c7d4')
    xmin,ymin,xmax,ymax=box
    scale=min((W-150)/(xmax-xmin),(height-130)/(ymax-ymin))
    ox=(W-(xmax-xmin)*scale)/2
    oy=top+100+((height-125)-(ymax-ymin)*scale)/2
    xy=lambda p:(ox+(p[0]-xmin)*scale,oy+(ymax-p[1])*scale)
    result=load_result(result_name)
    outline=next(d for d in result if get(d,0)=='LWPOLYLINE')
    output_paths=geometry(outline)
    for points,c in output_paths:draw.polygon([xy(p) for p in points],fill='#1d4249')
    for r in records:
        h=r['handle']
        if h in source_handles or h in data_handles:
            for points,c in cached[h]:
                if len(points)>1:draw.line([xy(p) for p in points],fill='#e9c763' if h in data_handles else '#b5c6d3',width=1)
    for points,c in output_paths:draw.line([xy(p) for p in points],fill='#4ee4ec',width=4)
    info=next(d for d in result if get(d,0)=='INSERT')
    p=xy(get(info,10));draw.ellipse((p[0]-4,p[1]-4,p[0]+4,p[1]+4),fill='#ffda6b')
    label=f'INFO AREA = {area} m²'
    tx,ty=W-465,top+20
    draw.rounded_rectangle((tx-15,ty-5,W-55,ty+65),radius=10,fill='#314755')
    draw.text((tx,ty),label,font=font(25),fill='#ffdf85')
    draw.text((tx,ty+34),'Existing facade_1_INFO reused',font=font(17),fill='#cad5dd')

sources=['31FB9','31FB8','31FB6','31FB5','31FB4','31FB2','31FB1','31FB0','31FAE','31FAD','31FAC','31C33','31C32','31C31']
codes=['32284','32271','3225E','3224B','32238','32225','32212','321FF','321EC','321D9','321C6','321B3','321A0','3218D']
panel(185,330,'1. Panel strip with a stepped end','14 panel plines + 14 code blocks; panel area sum = 8.3549 m²',
      sources,codes,'trial-output.lspdata',[84650,-415500,94400,-413900],'9.14')
sources2=['2C232','2C231','2C227','2C225','2C224','2C222','2C221','2C217','2C216','2C215','2C214','2C213','2C212','2C211','2C207','2C1FD','2C1F3','2C1E9','2C1DF','2C1D5','2C1CB','2C1C1','2C1B7']
codes2=['2CBE5','2CBD2','2CBBF','2CBAC','2CB99','2CB86','2CB60','2CB4D','2CB27','2CB14','2CB01','2CAEE','2CADB','2CAC8','2CAB5','2CAA2','2CA8F','2CA7C','2CA69','2CA56','2CA43','2CA30']
panel(540,485,'2. Mixed blocks and plines','11 panel blocks + 11 panel plines + 1 line; 22 code blocks skipped',
      sources2,codes2,'mixed-output.lspdata',[58500,-259350,70200,-255950],'17.73')
draw.text((45,1055),'Preview from extracted CAD geometry. INFO values enlarged for readability. Overall area includes bridged gaps.',
          font=font(21),fill='#b8c7d4')
im.save(OUT/'FO_C06_trial.png')
print('PREVIEW',OUT/'FO_C06_trial.png')
