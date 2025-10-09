;Effective Block Name Funcition Lee Mac
  ;; Effective Block Name  -  Lee Mac
    ;; obj - [vla] VLA Block Reference object
  (defun LM:effectivename (obj) 
    (vlax-get-property obj 
                      (if (vlax-property-available-p obj 'effectivename) 
                        'effectivename
                        'name
                      )
    )
  )
  ;; Effective Block Name  -  Lee Mac
  ;; ent - [ent] Block Reference entity
  (defun LM:al-effectivename (ent / blk rep) 
    (if (wcmatch (setq blk (cdr (assoc 2 (entget ent)))) "`**") 
      (if 
        (and 
          (setq rep (cdadr 
                      (assoc -3 
                            (entget 
                              (cdr 
                                (assoc 330 
                                        (entget 
                                          (tblobjname "block" blk)
                                        )
                                )
                              )
                              '("AcDbBlockRepBTag")
                            )
                      )
                    )
          )
          (setq rep (handent (cdr (assoc 1005 rep))))
        )
        (setq blk (cdr (assoc 2 (entget rep))))
      )
    )
    blk
  )

;
;Bounding_Box_FUNC_
  ;; Selection Set Bounding Box  -  Lee Mac
  ;; Returns a list of the lower-left and upper-right WCS coordinates of a
  ;; rectangular frame bounding all objects in a supplied selection set.
  ;; sel - [sel] Selection set for which to return bounding box
    (defun LM:ssboundingbox ( sel / idx llp ls1 ls2 obj urp )
        (repeat (setq idx (sslength sel))
            (setq obj (vlax-ename->vla-object (ssname sel (setq idx (1- idx)))))
            (if (and (vlax-method-applicable-p obj 'getboundingbox)
                    (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-getboundingbox (list obj 'llp 'urp))))
                )
                (setq ls1 (cons (vlax-safearray->list llp) ls1)
                      ls2 (cons (vlax-safearray->list urp) ls2)
                )
            )
        )
        (if (and ls1 ls2)
            (mapcar '(lambda ( a b ) (apply 'mapcar (cons a b))) '(min max) (list ls1 ls2))
        )
    )
  ;; Selection Set Bounding Box  -  Lee Mac
  ;; Returns a list of the lower-left and upper-right WCS coordinates of a
  ;; rectangular frame bounding all objects in a supplied selection set.
  ;; sel - [sel] Selection set for which to return bounding box

    (defun LM:ssboundingbox ( sel / idx llp ls1 ls2 obj urp )
        (repeat (setq idx (sslength sel))
            (setq obj (vlax-ename->vla-object (ssname sel (setq idx (1- idx)))))
            (if (and (vlax-method-applicable-p obj 'getboundingbox)
                    (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-getboundingbox (list obj 'llp 'urp))))
                )
                (setq ls1 (mapcar 'min (vlax-safearray->list llp) (cond (ls1) ((vlax-safearray->list llp))))
                      ls2 (mapcar 'max (vlax-safearray->list urp) (cond (ls2) ((vlax-safearray->list urp))))
                )
            )
        )
        (if (and ls1 ls2) (list ls1 ls2))
    )
  ;
  ;; Bounding Box  -  Lee Mac
  ;; Returns the point list describing the rectangular frame bounding the supplied object.
  ;; obj - [vla] VLA-Object

    (defun LM:boundingbox ( obj / a b lst )
        (if
            (and
                (vlax-method-applicable-p obj 'getboundingbox)
                (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-getboundingbox (list obj 'a 'b))))
                (setq lst (mapcar 'vlax-safearray->list (list a b)))
            )
            (mapcar '(lambda ( a ) (mapcar '(lambda ( b ) ((eval b) lst)) a))
              '(
                    (caar   cadar)
                    (caadr  cadar)
                    (caadr cadadr)
                    (caar  cadadr)
                )
            )
        )
    )
;
(defun TA:preset_plotter_mode_3 ()
  ;set_var_plot
    ; (setq ss (car (entsel)))
    (setq adoc (vla-get-activedocument (vlax-get-acad-object)))
    (setq lyout (vla-get-activelayout adoc))
    (setq styleSheet "A3_Standard (MRT-AGATE) - purple line.ctb")
    (setq cfgName "AutoCAD PDF (High Quality Print).pc3")
    (vla-RefreshPlotDeviceInfo lyout)
    (vla-put-ConfigName lyout CfgName)
    (vla-put-PaperUnits lyout acMillimeters)
    (vla-put-plotrotation lyout ac0degrees)
    ; (vla-put-PlotType lyout acWindow)
    (vla-put-PlotType lyout acExtents)
    (vla-put-CanonicalMediaName lyout "ISO_full_bleed_A3_(420.00_x_297.00_MM)")
    (vla-put-PlotWithLineweights lyout :vlax-true)
    (vla-put-PlotWithPlotStyles lyout :vlax-true)
    (vla-put-StyleSheet lyout styleSheet)
    (vla-put-CenterPlot lyout :vlax-true)
    (vla-put-standardscale lyout acScaleToFit )
    (vla-put-plotrotation lyout ac90degrees)
    (vla-put-PaperUnits lyout acMillimeters)
  ;
)
(defun c:ChangeFont ( / styName newFont styObj)
  (setq styName "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-E2-P-OR00-TBKA1D$0$CVA-E2-P-OR00-TBKA1$0$A1-TITLE$0$ROMANT")     ; ← ใส่ชื่อ Style ที่ต้องการแก้
  (setq newFont "romant.shx")   ; ← ใส่ชื่อ Font ใหม่ เช่น arial.ttf, AngsanaUPC, Tahoma ฯลฯ

  (if (setq styObj (tblobjname "style" styName))
    (progn
      (entmod
        (subst (cons 3 newFont) (assoc 3 (entget styObj)) (entget styObj))
      )
      (princ (strcat "\nFont ของ Style \"" styName "\" ถูกเปลี่ยนเป็น \"" newFont "\" แล้ว."))
    )
    (princ (strcat "\nไม่พบ Style ชื่อ \"" styName "\""))
  )
  (princ)
)
(defun c:Plotter_CKST_CSD4plot ()
    ;return
      (command "ucs" "world")
    ;
    ;go_to_layout-process
      (if 
        (or 
          (= (getvar "ctab") "model")
          (/= (getvar "ctab") "layout1")
        )
        (progn 
          (setvar "ctab" "layout1")
          
        )
        (setvar "ctab" "layout1")
      )
    ;
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "x"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              (cons 410 (getvar "CTAB"))
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
          nil
        )
        (progn
          (setq ss_pre_filter_set_xx_ (ssget "X"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              (cons 410 (getvar "CTAB"))
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (setq External_ref_ename_ ())
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
        (if
          (and
            ; (= (sslength ss_pre_filter_set_xx_) 1)
            (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat "*" (strcase "Title Block_Under Ground_C1 v3") "*"))  T)
            
          )
          (progn
            (setq main_bol (LM:boundingbox ss_pre_filter_set_xx_obj_))
          )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  ;plot process
    (if 
      (findfile (setq filename (strcat "" (getvar 'DWGPREFIX) (LM:StringSubst "" ".dwg" (getvar 'DWGNAME))  ".pdf"))) 
      (vl-file-delete filename)
    )
  ;
  ;input_type_of_plot_
    (TA:preset_plotter_mode_3) 
  ;
    
  (command "-plot" 
          "Yes" ;Detailed Plot Configuration?
          (getvar "ctab")
          "DWG To PDF.pc3" ;Printer Name
          "ISO_full_bleed_A3_(420.00_x_297.00_mm)" ;Paper Size
          ;paper_size ;Paper Size
          "m" ;Paper Units Millimeters
          "Landscape" ;Orientation
          "No" ;Plot Upside Down
          "extents" ;Plot Area
          ; (nth 0 main_bol) ;vla-getboundingbox
          ; (nth 2 main_bol) ;vla-getboundingbox
          ;llpt				;Lower left corner of window
          ;urpt				;Upper right corner of window
          "Fit" ;Plot Scale	"Fit"
          "Center" ;Plot Offset
          "yes" ;Use Plot Style?
          "A3_Standard (MRT-AGATE) - purple line.ctb" ;Plot Style Name
          "Yes" ;Plot Lineweights?
          "" ;Enter shade plot setting ["As displayed"/"Wireframe"/"Hidden"/"Visual styles"/"Rendered"]
          "N"
          "N"
          filename ; Name file and Location
          "Y"
          "Y"
      
  )
    ;backup plot command process
      ; (command "-plot" 
      ;         "Yes" ;Detailed Plot Configuration?
      ;         (getvar "ctab")
      ;         "DWG To PDF.pc3" ;Printer Name
      ;         "ISO_full_bleed_A3_(420.00_x_297.00_mm)" ;Paper Size
      ;         ;paper_size ;Paper Size
      ;         "m" ;Paper Units Millimeters
      ;         "Landscape" ;Orientation
      ;         "No" ;Plot Upside Down
      ;         "Extents" ;Plot Area
      ;         ; (nth 0 main_bol) ;vla-getboundingbox
      ;         ; (nth 3 main_bol) ;vla-getboundingbox
      ;         ;llpt				;Lower left corner of window
      ;         ;urpt				;Upper right corner of window
      ;         "Fit" ;Plot Scale	"Fit"
      ;         "Center" ;Plot Offset
      ;         "yes" ;Use Plot Style?
      ;         "TA3 - FOR NORMIE.ctb" ;Plot Style Name
      ;         "Yes" ;Plot Lineweights?
      ;         "" ;Enter shade plot setting ["As displayed"/"Wireframe"/"Hidden"/"Visual styles"/"Rendered"]
      ;         "N"
      ;         "N"
      ;         filename ; Name file and Location
      ;         "Y"
      ;         "Y"
      ; )
    ;
  
    ;create shortcut process  (root from SUB_FUNC)
      ;kuy folder แม่งเสือกมีภาษาไทย หอยหลอดเอ้ย !!!!!!!
    ;
  ;
)
(defun c:updateheading ()
  (if  ;pre_select_ssget_or_post_select_ssget
    (=
      (setq ss_pre_filter_set_xx_ (ssget "x"
                                        (list
                                          (cons 0 "INSERT") ;type of object
                                          (cons 410 (getvar "CTAB"))
                                          ; (cons 8 "000 - GRID")   ;kind of layer
                                          ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                  )
      )
      nil
    )
    (progn
      (setq ss_pre_filter_set_xx_ (ssget "X"
                                        (list
                                          (cons 0 "INSERT") ;type of object
                                          (cons 410 (getvar "CTAB"))
                                          ; (cons 8 "000 - GRID")   ;kind of layer
                                          ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                  )
      )
    )
    (sslength ss_pre_filter_set_xx_)
  )
  (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - CKST_HEADING_VAL"))
  (if (/= ss_pre_filter_set_xx_ nil)
    (progn
      (setq heading_ename_ (ssname ss_pre_filter_set_xx_ 0))
      (setq heading_obj_ (vlax-ename->vla-object heading_ename_))
      (setq xx1 (strlen (LM:vl-getattributevalue heading_obj_ "heading-name" )))
      (setq lastword (substr (LM:vl-getattributevalue heading_obj_ "heading-name" ) xx1 2))
      (if (or
            (= lastword "1")
            (= lastword "2")
            (= lastword "3")
            (= lastword "4")
            (= lastword "5")
            (= lastword "6")
            (= lastword "7")
            (= lastword "8")
            (= lastword "9")
          )
        (progn
          (LM:vl-setattributevalue heading_obj_ "bubble_no_val" lastword )
        )
        (LM:vl-setattributevalue heading_obj_ "bubble_no_val" "1" )
      )
      
    )
  )
)
(defun c:updatetb31 ()
  (if  ;pre_select_ssget_or_post_select_ssget
    (=
      (setq ss_pre_filter_set_xx_ (ssget "x"
                                        (list
                                          (cons 0 "INSERT") ;type of object
                                          (cons 410 (getvar "CTAB"))
                                          ; (cons 8 "000 - GRID")   ;kind of layer
                                          ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                  )
      )
      nil
    )
    (progn
      (setq ss_pre_filter_set_xx_ (ssget "X"
                                        (list
                                          (cons 0 "INSERT") ;type of object
                                          (cons 410 (getvar "CTAB"))
                                          ; (cons 8 "000 - GRID")   ;kind of layer
                                          ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                  )
      )
    )
    (sslength ss_pre_filter_set_xx_)
  )
  (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "Title Block_Under Ground_C2 v3"))
  (if (/= ss_pre_filter_set_xx_ nil)
    (progn
      (setq titleblock_ename_ (ssname ss_pre_filter_set_xx_ 0))
      (setq titleblock_obj_ (vlax-ename->vla-object titleblock_ename_))
      (LM:vl-setattributevalue titleblock_obj_ "REV_DESC_01" "FIRST ISSUED" )
    )
  )
)
(defun c:ficou ()
  (if  ;pre_select_ssget_or_post_select_ssget
    (=
      (setq ss_pre_filter_set_xx_ (ssget "x"
                                        (list
                                          (cons 0 "INSERT") ;type of object
                                          (cons 410 (getvar "CTAB"))
                                          ; (cons 8 "000 - GRID")   ;kind of layer
                                          ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                  )
      )
      nil
    )
    (progn
      (setq ss_pre_filter_set_xx_ (ssget 
                                        (list
                                          (cons 0 "INSERT") ;type of object
                                          (cons 410 (getvar "CTAB"))
                                          ; (cons 8 "000 - GRID")   ;kind of layer
                                          ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                  )
      )
    )
    (sslength ss_pre_filter_set_xx_)
  )
  
  ;preloop_and_while
    (setq ss_pre_filter_set_xx_i 0)
    (setq new_ss (ssadd))
    (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
      (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
      (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
      (if (wcmatch (LM:effectivename ss_pre_filter_set_xx_obj_ ) "*Family - ___-*")
        (progn
          (setq new_ss (ssadd ss_pre_filter_set_xx_ename_ new_ss))
        )
      )
      (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
    )
  ;
  (command "erase"  new_ss "" )
)

; (c:updateheading)
; (c:ficou)
; (c:updatetb31)
; (c:ChangeFont)
; (c:Plotter_CKST_CSD4plot)
; (command "qsave")


; (command "close" "n" )
