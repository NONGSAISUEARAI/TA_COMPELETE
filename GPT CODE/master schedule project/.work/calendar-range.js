// View settings only: selecting a calendar window never changes task dates.
let calendarRange=null;
function calendarWindow(autoMin,autoMax){
 const min=calendarRange?dateNumber(calendarRange.start):autoMin,max=calendarRange?dateNumber(calendarRange.end):autoMax;
 const weekday=new Date(min).getUTCDay(),start=min-((weekday+6)%7)*DAY;
 const numberOfWeeks=Math.max(calendarRange?1:4,Math.ceil((max-start+DAY)/(7*DAY)));
 return {min,max,start,numberOfWeeks,totalDays:numberOfWeeks*7};
}
function refreshCalendarRange(min,max,start,totalDays){
 $('calendar-from').value=calendarRange?.start||dateISO(min);$('calendar-to').value=calendarRange?.end||dateISO(max);
 const last=start+(totalDays-1)*DAY;
 $('calendar-range-note').classList.remove('is-error');$('calendar-range-note').textContent=(calendarRange?'ช่วงที่เลือก':'แสดงตามข้อมูลทั้งหมด')+' · ปฏิทิน '+dayFormat(dateISO(start),true)+' – '+dayFormat(dateISO(last),true)+' · จัดสัปดาห์จันทร์–อาทิตย์';
}
function applyCalendarRange(){
 const first=$('calendar-from').value,last=$('calendar-to').value;
 let error='';
 if(!first||!last||!validRecordDate(first)||!validRecordDate(last))error='กรุณาเลือกวันเริ่มและวันสิ้นสุดให้ครบ';
 else if(last<first)error='วันสิ้นสุดต้องไม่อยู่ก่อนวันเริ่ม';
 else if(dateNumber(last)-dateNumber(first)>DAY*366*10)error='เลือกช่วงวันที่ได้ไม่เกิน 10 ปี';
 if(error){$('calendar-range-note').classList.add('is-error');$('calendar-range-note').textContent=error;return false}
 calendarRange={start:first,end:last};render();return true;
}
function resetCalendarRange(){calendarRange=null;render()}
$('calendar-apply').onclick=applyCalendarRange;
$('calendar-auto').onclick=resetCalendarRange;
for(const id of ['calendar-from','calendar-to'])$(id).addEventListener('keydown',event=>{if(event.key==='Enter'){event.preventDefault();applyCalendarRange()}});
