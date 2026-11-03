from pathlib import Path
import re, json, math, collections
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).parent
TOKEN = re.compile(r'"(?:\\.|[^"\\])*"|\(|\)|[^\s()]+')
def parse(line):
    tokens = iter(TOKEN.findall(line))
    def read(token):
        if token == '(':
            out = []
            for part in tokens:
                if part == ')': return out
                out.append(read(part))
            raise ValueError('unclosed')
        if token.startswith('"'):
            return re.sub(r'\\(.)', lambda m: {'n':'\n','r':'\r','t':'\t'}.get(m[1],m[1]), token[1:-1])
        try: return float(token) if any(c in token.lower() for c in '.e') else int(token)
        except ValueError: return token
    return read(next(tokens))
def get(data, code, default=None):
    for pair in data:
        if pair[0] == code:
            return pair[2] if len(pair) == 3 and pair[1] == '.' else pair[1:]
    return default
def allget(data, code):
    return [p[2] if len(p)==3 and p[1]=='.' else p[1:] for p in data if p[0]==code]
rows = []
for line in (ROOT/'inventory.lspdata').read_text(encoding='utf-8',errors='replace').splitlines():
    try: rows.append(parse(line))
    except (ValueError,StopIteration): pass
entities, blocks, layers, attrs, variables = [], {}, {}, {}, {}
block = None
entity = None
for kind, data in rows:
    if kind == 'VAR': variables[data[0]] = data[1]
    elif kind == 'ENTITY':
        entity = data
        if get(data,410,'Model') == 'Model': entities.append(data)
    elif kind == 'ATTRIBUTE' and entity is not None:
        attrs.setdefault(get(entity,5),{})[get(data,2)] = get(data,1,'')
    elif kind == 'BLOCK':
        block = get(data,2); blocks[block] = {'data':data,'children':[]}
    elif kind == 'CHILD' and block: blocks[block]['children'].append(data)
    elif kind == 'LAYER': layers[get(data,2)] = data

def trans(p,m):
    a,b,c,d,x,y=m
    return (a*p[0]+b*p[1]+x,c*p[0]+d*p[1]+y)
def compose(m,n):
    a,b,c,d,x,y=m; e,f,g,h,u,v=n
    return (a*e+b*g,a*f+b*h,c*e+d*g,c*f+d*h,a*u+b*v+x,c*u+d*v+y)
def matrix(data):
    p=get(data,10,[0,0]); q=get(blocks[get(data,2)]['data'],10,[0,0])
    a=get(data,50,0); sx=get(data,41,1); sy=get(data,42,1)
    c,s=math.cos(a),math.sin(a)
    m=(c*sx,-s*sy,s*sx,c*sy,0,0)
    x,y=trans(q,m)
    return (*m[:4],p[0]-x,p[1]-y)
ACI={1:'#ff5d68',2:'#f1da63',3:'#42d87d',4:'#49dce8',5:'#7d9cff',6:'#ef8ddc',7:'#d6dce4',8:'#747f8e',9:'#a5acb8'}
def color(data,inherited):
    n=get(data,62,256)
    if n==0:return inherited
    if n==256:n=get(layers.get(get(data,8,'0'),[]),62,7)
    return ACI.get(abs(n),'#8d9cae')
def geometry(data,m=(1,0,0,1,0,0),inherited='#d6dce4',depth=0):
    if depth>25 or get(data,60,0)==1:return []
    kind=get(data,0); result=[]; col=color(data,inherited)
    if kind=='INSERT' and get(data,2) in blocks:
        n=compose(m,matrix(data))
        for child in blocks[get(data,2)]['children']:
            result.extend(geometry(child,n,col,depth+1))
    elif kind=='LINE':result.append(([trans(get(data,10),m),trans(get(data,11),m)],col))
    elif kind=='LWPOLYLINE':
        points=allget(data,10)
        if get(data,70,0)&1 and points:points=points+[points[0]]
        result.append(([trans(p,m) for p in points],col))
    elif kind in ('CIRCLE','ARC'):
        center=get(data,10); radius=get(data,40); a=get(data,50,0); b=get(data,51,2*math.pi)
        if b<=a:b+=2*math.pi
        points=[(center[0]+radius*math.cos(a+(b-a)*i/32),center[1]+radius*math.sin(a+(b-a)*i/32)) for i in range(33)]
        result.append(([trans(p,m) for p in points],col))
    return result
def bounds(paths):
    ps=[p for points,c in paths for p in points]
    return [min(p[0] for p in ps),min(p[1] for p in ps),max(p[0] for p in ps),max(p[1] for p in ps)] if ps else None
records=[]; cached={}
for data in entities:
    paths=geometry(data); cached[get(data,5)]=paths
    records.append({'handle':get(data,5),'type':get(data,0),'layer':get(data,8),'block':get(data,2),
        'point':get(data,10),'bounds':bounds(paths),'attributes':attrs.get(get(data,5),{})})
(ROOT/'inventory.json').write_text(json.dumps({'variables':variables,'entities':records,
    'blocks':[{'name':name,'types':dict(collections.Counter(get(d,0) for d in block['children']))} for name,block in blocks.items()]},ensure_ascii=False,indent=2),encoding='utf-8')
print('ENTITY COUNT',len(records),'BLOCK COUNT',len(blocks))
print('TYPES',dict(collections.Counter(r['type'] for r in records)))
print('LAYERS',collections.Counter(r['layer'] for r in records).most_common(15))
print('EXISTING FO',json.dumps([r for r in records if r['layer'].startswith('TA-FACADE')],ensure_ascii=False,indent=2))

def render(name,box,width=1800,height=900,selection=None):
    bg='#202832'; image=Image.new('RGB',(width,height),bg);draw=ImageDraw.Draw(image)
    xmin,ymin,xmax,ymax=box
    scale=min((width-100)/(xmax-xmin),(height-100)/(ymax-ymin))
    ox=(width-(xmax-xmin)*scale)/2; oy=(height-(ymax-ymin)*scale)/2
    def xy(p):return (ox+(p[0]-xmin)*scale,height-oy-(p[1]-ymin)*scale)
    for r in records:
        b=r['bounds']
        if not b or b[2]<xmin or b[0]>xmax or b[3]<ymin or b[1]>ymax:continue
        for points,c in cached[r['handle']]:
            if len(points)>1:
                if selection and r['handle'] in selection:c='#fa92e9'
                draw.line([xy(p) for p in points],fill=c,width=2 if r['layer'].startswith('TA-FACADE') else 1)
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
    draw.text((24,16),name,fill='#ffffff',font=font)
    image.save(ROOT/(name+'.png'))
render('drawing-overview',[-80000,-1900000,400000,140000],height=1800,width=1000)
render('existing-outline-row',[55000,-418000,98000,-411000])
render('existing-outline-row-2',[42000,-273000,73000,-264000])
render('rotated-panel-sample',[57000,-260000,69000,-254000])
