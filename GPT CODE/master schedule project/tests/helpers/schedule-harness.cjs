const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const dataPattern=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/;
function boot(html){
 const elements=new Map(),storage=new Map(),timers=new Map();let timer=0;
 for(const match of html.matchAll(/<([a-z][\w-]*)\b([^>]*\bid="([^"]+)"[^>]*)>/g)){
  let value=match[2].match(/\bvalue="([^"]*)"/)?.[1]||'';
  const element={id:match[3],textContent:'',innerHTML:'',checked:/\bchecked\b/.test(match[2]),hidden:/\bhidden\b/.test(match[2]),disabled:false,readOnly:false,open:false,style:{setProperty(){}},dataset:{},listeners:{},classList:{toggle(){},add(){},remove(){}},addEventListener(name,fn){(this.listeners[name]??=[]).push(fn)},setAttribute(name,v){this[name]=v},focus(){},click(){},closest(){return this.wrapper??=( {hidden:false} )},contains(){return false},querySelectorAll(){return []},showModal(){this.open=true},close(){this.open=false;for(const fn of this.listeners.close||[])fn()}};
  Object.defineProperty(element,'value',{get:()=>value,set:v=>value=v==null?'':String(v)});elements.set(element.id,element);
 }
 elements.get('schedule-data').textContent=html.match(dataPattern)[1];elements.get('status-filter').value='all';
 const context={console,structuredClone,Date,Intl,Math,JSON,Set,Map,Number,String,Array,Promise,Blob,URL,AbortController,TextEncoder,CSS:{escape:v=>String(v)},location:{protocol:'file:',hostname:'',port:''},setTimeout:(fn,ms)=>{timers.set(++timer,{fn,ms});return timer},clearTimeout:id=>timers.delete(id),localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)},window:{isSecureContext:true,addEventListener(){}},document:{getElementById:id=>{assert(elements.has(id),'Missing DOM element '+id);return elements.get(id)},querySelectorAll:()=>[],querySelector:()=>null,addEventListener(){},body:{dataset:{},classList:{toggle(){}}},documentElement:{outerHTML:html}}};
 context.DOMParser=class{parseFromString(s){let data=s.match(dataPattern)[1];return{getElementById:()=>({set textContent(v){data=v}}),set title(v){},documentElement:{get outerHTML(){return s.replace(dataPattern,()=>'<script id="schedule-data" type="application/json">'+data+'</script>')}}}}};
 vm.createContext(context);const script=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)][1][1];new vm.Script(script);vm.runInContext(script,context);return{context,elements,storage,run:code=>vm.runInContext(code,context)};
}
module.exports={boot,dataPattern};
