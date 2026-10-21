// Cap the whole U/V gizmo in screen pixels. As the model is magnified, reduce
// the pixel budget too, so the helper becomes less intrusive at close zoom.
export function originHelperWorldSize(nominalSize,worldPerPixel){
 const unit=Math.max(1e-12,worldPerPixel),projected=nominalSize*.85/unit;
 const pixels=Math.max(14,48*Math.sqrt(48/Math.max(48,projected)));
 return Math.min(nominalSize,pixels*unit/.85);
}
