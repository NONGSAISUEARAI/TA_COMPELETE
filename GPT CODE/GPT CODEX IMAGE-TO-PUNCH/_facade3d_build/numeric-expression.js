export function numericExpression(value){
 const source=String(value).trim().replace(/^=/,'').replaceAll('×','*').replaceAll('÷','/');
 if(!source||source.length>256)throw Error('กรอกตัวเลขหรือสูตร เช่น 3000/2');
 let index=0;
 const space=()=>{while(/\s/.test(source[index]??'')&&index<source.length)index++};
 const finite=n=>{if(!Number.isFinite(n))throw Error('ผลลัพธ์ต้องเป็นตัวเลขที่มีค่าจำกัด');return n};
 function atom(){space();const token=source[index];if(token==='+'||token==='-'){index++;return (token==='-'?-1:1)*atom()}if(token==='('){index++;const n=sum();space();if(source[index++]!==')')throw Error('วงเล็บไม่ครบ');return n}const match=source.slice(index).match(/^(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?/i);if(!match)throw Error('สูตรไม่ถูกต้อง · ใช้ + − * / และวงเล็บ');index+=match[0].length;return finite(Number(match[0]))}
 function product(){let n=atom();while(true){space();const op=source[index];if(op!=='*'&&op!=='/')return n;index++;const rhs=atom();if(op==='/'&&rhs===0)throw Error('หารด้วยศูนย์ไม่ได้');n=finite(op==='*'?n*rhs:n/rhs)}}
 function sum(){let n=product();while(true){space();const op=source[index];if(op!=='+'&&op!=='-')return n;index++;const rhs=product();n=finite(op==='+'?n+rhs:n-rhs)}}
 const result=sum();space();if(index!==source.length)throw Error('สูตรไม่ถูกต้อง · ใช้ + − * / และวงเล็บ');return Number(result.toPrecision(15));
}
