// Standalone PDF export. The fixed HTML design coordinates are PDF points.
// Text uses the same embedded fonts, with shaped Thai glyph positions.
const rfqPdfFontSources=new Map();
function rfqPdfFontKey(family,weight,style){
  return `${family.replace(/["']/g,'').split(',')[0].trim()}|${Number(weight)||400}|${style||'normal'}`;
}
function rfqPdfReadFonts(){
  if(rfqPdfFontSources.size)return;
  for(const sheet of document.styleSheets){
    for(const rule of sheet.cssRules){
      if(rule.type!==CSSRule.FONT_FACE_RULE)continue;
      const match=rule.style.getPropertyValue('src').match(/data:font\/ttf;base64,([A-Za-z0-9+/=]+)/);
      if(!match)continue;
      const key=rfqPdfFontKey(rule.style.fontFamily,rule.style.fontWeight,rule.style.fontStyle);
      rfqPdfFontSources.set(key,Uint8Array.from(atob(match[1]),c=>c.charCodeAt(0)));
    }
  }
}
function rfqPdfMatrix(el,paper){
  let result=new DOMMatrix();
  for(let node=el;node&&node!==paper;node=node.parentElement){
    const style=getComputedStyle(node);
    const transform=style.transform==='none'?new DOMMatrix():new DOMMatrix(style.transform);
    const position=new DOMMatrix().translate(parseFloat(style.left)||0,parseFloat(style.top)||0);
    result=position.multiply(transform).multiply(result);
  }
  return result;
}
function rfqPdfColor(value){
  if(!value||value==='none'||value==='transparent')return undefined;
  if(/^#[0-9a-f]{3}$/i.test(value))value='#'+value.slice(1).split('').map(v=>v+v).join('');
  const match=value.match(/^#([0-9a-f]{6})$/i);
  if(match)return PDFLib.rgb(...[0,2,4].map(i=>parseInt(match[1].slice(i,i+2),16)/255));
  if(value==='#000'||value==='black')return PDFLib.rgb(0,0,0);
  if(value==='#fff'||value==='white')return PDFLib.rgb(1,1,1);
  const rgb=value.match(/^rgba?\((\d+)[, ]+(\d+)[, ]+(\d+)/);
  if(rgb)return PDFLib.rgb(...rgb.slice(1,4).map(v=>Number(v)/255));
  throw new Error('Unsupported PDF color: '+value);
}
function rfqPdfDrawSvg(page,svg,paper){
  const origin=rfqPdfMatrix(svg,paper),height=612;
  for(const shape of svg.children){
    if(getComputedStyle(shape).display==='none')continue;
    const num=name=>Number(shape.getAttribute(name)||0);
    const fill=rfqPdfColor(shape.getAttribute('fill'));
    const stroke=rfqPdfColor(shape.getAttribute('stroke'));
    const borderWidth=num('stroke-width');
    if(shape.tagName.toLowerCase()==='rect'){
      if(!fill&&!stroke)continue;
      page.drawRectangle({x:origin.e+num('x'),y:height-origin.f-num('y')-num('height'),width:num('width'),height:num('height'),color:fill,borderColor:stroke,borderWidth:stroke?borderWidth:0});
    }else if(shape.tagName.toLowerCase()==='line'){
      if(!stroke)continue;
      page.drawLine({start:{x:origin.e+num('x1'),y:height-origin.f-num('y1')},end:{x:origin.e+num('x2'),y:height-origin.f-num('y2')},color:stroke,thickness:borderWidth});
    }else if(shape.tagName.toLowerCase()==='path'){
      if(!fill&&!stroke)continue;
      page.drawSvgPath(shape.getAttribute('d'),{x:origin.e,y:height-origin.f,color:fill,borderColor:stroke,borderWidth:stroke?borderWidth:0,borderLineCap:PDFLib.LineCapStyle.Round});
    }else{
      throw new Error('Unsupported PDF vector: '+shape.tagName);
    }
  }
}
async function rfqPdfDrawText(page,el,paper,fonts,doc){
  const text=el.textContent;if(!text)return;
  const s=getComputedStyle(el),key=rfqPdfFontKey(s.fontFamily,s.fontWeight,s.fontStyle);
  let face=fonts.get(key);
  if(!face){
    const bytes=rfqPdfFontSources.get(key);
    if(!bytes)throw new Error('Missing embedded PDF font: '+key);
    const embedded=await doc.embedFont(bytes,{subset:true});
    face={embedded,shaper:fontkit.create(bytes),pageKeys:new Map()};fonts.set(key,face);
  }
  let fontKey=face.pageKeys.get(page);
  if(!fontKey){fontKey=page.node.newFontDictionary(face.embedded.name,face.embedded.ref);face.pageKeys.set(page,fontKey);}
  const size=parseFloat(s.fontSize),unit=size/face.shaper.unitsPerEm;
  const matrix=rfqPdfMatrix(el,paper);
  const color=rfqPdfColor(s.color),stroke=parseFloat(s.webkitTextStrokeWidth)||0;
  const {pushGraphicsState,popGraphicsState,beginText,endText,setFontAndSize,setTextMatrix,showText,PDFHexString,setFillingRgbColor,setStrokingRgbColor,setTextRenderingMode,setLineWidth}=PDFLib;
  const paddingLeft=parseFloat(s.paddingLeft)||0,paddingRight=parseFloat(s.paddingRight)||0;
  const width=parseFloat(s.width)||0;
  measureContext.font=`${s.fontStyle} ${s.fontWeight} ${s.fontSize} ${s.fontFamily}`;
  const lines=text.replace(/\r/g,'').split('\n');
  for(let lineIndex=0;lineIndex<lines.length;lineIndex++){
    const line=lines[lineIndex];if(!line)continue;
    const layout=face.shaper.layout(line);
    if(layout.glyphs.some(g=>g.id===0))throw new Error('มีอักขระที่ฟอนต์ PDF ไม่รองรับ');
    const encoded=face.embedded.encodeText(line).asBytes();
    if(encoded.length!==layout.glyphs.length*2)throw new Error('PDF font shaping mismatch');
    const natural=measureContext.measureText(line).width;
    const advance=layout.positions.reduce((n,p)=>n+p.xAdvance,0)*unit;
    const horizontal=advance?natural/advance:1;
    let left=paddingLeft;
    if(s.textAlign==='center')left+=(width-paddingLeft-paddingRight-natural)/2;
    if(s.textAlign==='right')left=width-paddingRight-natural;
    const by=baseline(el)+lineIndex*(parseFloat(s.lineHeight)||size);
    // ActualText preserves the original Thai spelling when copied or searched,
    // even when the font's shaping engine reorders or decomposes vowel glyphs.
    const actualText=PDFLib.PDFOperator.of('BDC',[PDFLib.PDFName.of('Span'),doc.context.obj({ActualText:PDFHexString.fromText(line)})]);
    const ops=[pushGraphicsState(),actualText,setFillingRgbColor(color.red,color.green,color.blue),setStrokingRgbColor(color.red,color.green,color.blue),setLineWidth(stroke),beginText(),setFontAndSize(fontKey,size),setTextRenderingMode(stroke?2:0)];
    let penX=0,penY=0;
    for(let i=0;i<layout.glyphs.length;i++){
      const p=layout.positions[i];
      const x=left+(penX+p.xOffset)*unit*horizontal,y=by-(penY+p.yOffset)*unit;
      const point=matrix.transformPoint({x,y});
      const glyphId=(encoded[2*i]<<8)|encoded[2*i+1];
      ops.push(setTextMatrix(matrix.a*horizontal,-matrix.b*horizontal,-matrix.c,matrix.d,point.x,612-point.y),showText(PDFHexString.of(glyphId.toString(16).padStart(4,'0'))));
      penX+=p.xAdvance;penY+=p.yAdvance;
    }
    ops.push(endText(),PDFLib.endMarkedContent(),popGraphicsState());page.pushOperators(...ops);
  }
}
async function rfqCreatePdf(name){
  if(document.fonts)await document.fonts.ready;
  calibrate();rfqPdfReadFonts();
  const doc=await PDFLib.PDFDocument.create();doc.registerFontkit(fontkit);
  doc.setTitle(name);doc.setCreator('RFQ HTML');doc.setProducer('RFQ standalone vector PDF');
  doc.catalog.getOrCreateViewerPreferences().setPrintScaling(PDFLib.PrintScaling.None);
  const fonts=new Map(),images=new Map();
  for(const paper of pages.querySelectorAll('.paper')){
    const page=doc.addPage([792,612]);
    rfqPdfDrawSvg(page,paper.querySelector('.form-lines'),paper);
    for(const logo of paper.querySelectorAll('.logo')){
      let image=images.get(logo.src);
      if(!image){image=await doc.embedPng(logo.src);images.set(logo.src,image);}
      const s=getComputedStyle(logo),m=rfqPdfMatrix(logo,paper),w=parseFloat(s.width),h=parseFloat(s.height);
      page.drawImage(image,{x:m.e,y:612-m.f-h,width:w,height:h});
    }
    for(const svg of paper.querySelectorAll('.check-box'))rfqPdfDrawSvg(page,svg,paper);
    for(const el of paper.querySelectorAll('.ink'))await rfqPdfDrawText(page,el,paper,fonts,doc);
    // Yield between pages so the busy message can paint for longer documents.
    await new Promise(resolve=>setTimeout(resolve,0));
  }
  return doc.save();
}
document.getElementById('save-pdf').addEventListener('click',async event=>{
  const button=event.currentTarget;
  if(button.disabled)return;
  const name=exportFileBase();button.disabled=true;button.setAttribute('aria-busy','true');
  fileSaveStatus.textContent='กำลังสร้าง PDF…';
  try{
    await new Promise(resolve=>setTimeout(resolve,0));
    const bytes=await rfqCreatePdf(name);
    const blob=new Blob([bytes],{type:'application/pdf'}),url=URL.createObjectURL(blob),a=document.createElement('a');
    a.href=url;a.download=name+'.pdf';document.body.append(a);a.click();a.remove();
    setTimeout(()=>URL.revokeObjectURL(url),60000);
    fileSaveStatus.textContent=`ดาวน์โหลดแล้ว: ${name}.pdf`;
  }catch(error){
    console.error('RFQ PDF export:',error);
    fileSaveStatus.textContent='สร้าง PDF ไม่สำเร็จ กรุณาลองใหม่ หรือใช้ปุ่มพิมพ์';
  }finally{
    button.disabled=false;button.removeAttribute('aria-busy');
  }
});
