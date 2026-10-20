import test from 'node:test';
import assert from 'node:assert/strict';
import {numericExpression} from '../numeric-expression.js';
test('Numeric formulas respect precedence, parentheses, unary signs and decimals',()=>{
 for(const [formula,value]of [['3000/2',1500],['1200-900',300],['(900+300)*2',2400],['2+3*4',14],['-1200/2',-600],['=.1+.2',.3],['2e3/4',500],['600 × 2 ÷ 3',400],['.5 * (10 - -2)',6]])assert.equal(numericExpression(formula),value);
});
test('Invalid formulas and nonfinite results cannot execute or change a value',()=>{
 for(const formula of ['', '1/0','0/0','3000/','(2+3','3abc','Math.random()','globalThis.x=1','2**3','1e999','2;alert(1)','2'.repeat(257)])assert.throws(()=>numericExpression(formula));
});
