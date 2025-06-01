;update 20250601 2311
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
;Remove&Edit List Function Lee Mac
  (defun LM:RemoveNth (n l / i) 
    ;;  Arguments:                                              ;;
    ;;  n - index of item to remove (zero based)                ;;
    ;;  l - list from which item is to be removed               ;;
      (setq i -1)
      (vl-remove-if '(lambda (x) (= (setq i (1+ i)) n)) l)
  )
  (defun LM:str->lst ( str del / len lst pos )
    (setq len (1+ (strlen del)))
    (while (setq pos (vl-string-search del str))
        (setq lst (cons (substr str 1 pos) lst)
              str (substr str (+ pos len))
        )
    )
    (reverse (cons str lst))
  )
  (defun LM:lst->str ( lst del / str )
    (setq str (car lst))
    (foreach itm (cdr lst) (setq str (strcat str del itm)))
    str
  )
;
;Text_FUNC_
  (defun LM:StringSubst (new old str / inc len) 
    (setq len (strlen new)
          inc 0
    )
    (while (setq inc (vl-string-search old str inc)) 
      (setq str (vl-string-subst new old str inc)
            inc (+ inc len)
      )
    )
    str
  )
;
;Get_DOC_FUNC_
  ;Get_Data Document Ta Trai
    (defun LM:getdocumentobject ( dwg / app dbx dwl err vrs )
        (cond
            (   (not (setq dwg (findfile dwg))) nil)
            (   (cdr
                    (assoc (strcase dwg)
                        (vlax-for doc (vla-get-documents (setq app (vlax-get-acad-object)))
                            (setq dwl (cons (cons (strcase (vla-get-fullname doc)) doc) dwl))
                        )
                    )
                )
            )
            (   (progn
                    (setq dbx
                        (vl-catch-all-apply 'vla-getinterfaceobject
                            (list app
                                (if (< (setq vrs (atoi (getvar 'acadver))) 16)
                                    "objectdbx.axdbdocument"
                                    (strcat "objectdbx.axdbdocument." (itoa vrs))
                                )
                            )
                        )
                    )
                    (or (null dbx) (vl-catch-all-error-p dbx))
                )
                (prompt "\nUnable to interface with ObjectDBX.")
            )
            (   (vl-catch-all-error-p (setq err (vl-catch-all-apply 'vla-open (list dbx dwg))))
                (prompt (strcat "\n" (vl-catch-all-error-message err)))
            )
            (   dbx   )
        )
    )
    (defun getdrawinglayouts ( dwg / doc idx rtn )
      ;original_method_
        (if (setq doc (LM:getdocumentobject dwg))
            (progn
                (vlax-for lyt (vla-get-layouts doc)
                    (setq rtn (cons (vla-get-name lyt) rtn)
                          idx (cons (vla-get-taborder lyt) idx)
                    )
                )
                (vlax-release-object doc)
                (mapcar '(lambda ( n ) (nth n rtn)) (vl-sort-i idx '<))
            )
        )
      ;
    )
  ;
;
;Shell_FUNC
  ;Copy to clipboard FUNC
    (defun TA:copytext->clipboard (clipboard_text)
      ;sub FUNC สำหรับในคัดลอก text ให้อยู่ clipboard สำหรับ ctrl+v ในอนาคต
      ;มีฟังชั่นแบบนี้ด้วยหรอ ถามจริง
      (vlax-invoke
        (vlax-get
          (vlax-get (setq htmlfile (vlax-create-object "htmlfile")) 'ParentWindow)
          'ClipBoardData
        )
        'SetData
        "Text"
        clipboard_text ;input อะไรลงไป
      )
    )
  ;
  ;create_shortcut_FUNC
    (defun TA:create_shortcut_file (targetPath shortcutPath shortcutName )
      ;Note By Code_Developer
      ;As following argument name targetPath shortcutName shortcutPath_ must be Englist letter only 
      ;
      ; ;user_input for example process
        ; ; (setq targetPath    "C:\\xvba_modules-bb\\test.txt") ;argument example
        ; (setq targetPath  "C:\\TA\\TA_WORK\\000-AREA_PP29-AR-1305-A.pdf") ;argument example
        ; ; (setq shortcutPath    "C:\\xvba_modules-bb\\")       ;argument example
        ; (setq shortcutName "x1111test")                    ;argument example
        (setq shortcutPath_  (strcat shortcutPath shortcutName ".lnk"))
      ; ;
      ;get vla-object shell appication
        (setq shell (vlax-create-object "WScript.Shell"))
        (setq shortcut (vlax-invoke-method shell 'CreateShortcut shortcutPath_))
      ;
      ;put properties shortcut object
        (vlax-put-property shortcut 'TargetPath targetPath)
        (vlax-put-property shortcut 'WindowStyle 1)
        (vlax-put-property shortcut 'Description "My Shortcut Description")
      ;
      ;create shotcut to shortcutPath
        (vlax-invoke-method shortcut 'Save)
      ;clean object
        (vlax-release-object shortcut)
        (vlax-release-object shell)
      ;
      (princ "\nShortcut created successfully.")
      (princ)
    )
  ;
;



(defun c:find_xref_ ()
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
      (vl-prin1-to-string (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
      
      (if
        (and
          ; (= (sslength ss_pre_filter_set_xx_) 1)
          (= (wcmatch (strcase (vl-princ-to-string ss_pre_filter_set_xx_obj_)) "*IACADEXTERNALREFERENCE*") T)
        )
        (progn
          (setq External_ref_ename_ ss_pre_filter_set_xx_ename_ )
          (setq main_bol (LM:boundingbox (vlax-ename->vla-object External_ref_ename_)))
          (if (= (vla-get-name (vlax-ename->vla-object External_ref_ename_)) "BMTP_tbA1")
            (progn
              (vla-put-path (vlax-ename->vla-object External_ref_ename_) "..\\..\\EXRF PP-LINE\\BMTP_tbA1.dwg")
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (vla-Reload (vla-Item (vla-get-Blocks doc) "BMTP_tbA1"))
                            
            )
          )
        )
      )
      (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
    )
  ;
)
(defun c:RUN_plot ()
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
      (vl-prin1-to-string (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
      
      (if
        (and
          ; (= (sslength ss_pre_filter_set_xx_) 1)
          (= (wcmatch (strcase (vl-princ-to-string ss_pre_filter_set_xx_obj_)) "*IACADEXTERNALREFERENCE*") T)
        )
        (progn
          (setq External_ref_ename_ ss_pre_filter_set_xx_ename_ )
          (setq main_bol (LM:boundingbox (vlax-ename->vla-object External_ref_ename_)))
        )
      )
      (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
    )
  ;
  ;plot process
    (if (findfile (setq filename (strcat "" (getvar 'DWGPREFIX) (LM:StringSubst "" ".dwg" (getvar 'DWGNAME))  ".pdf"))) 
      (vl-file-delete filename)
    )
    (command "-plot" 
            "Yes" ;Detailed Plot Configuration?
            (getvar "ctab")
            "DWG To PDF.pc3" ;Printer Name
            "ISO_full_bleed_A3_(420.00_x_297.00_mm)" ;Paper Size
            ;paper_size ;Paper Size
            "m" ;Paper Units Millimeters
            "Landscape" ;Orientation
            "No" ;Plot Upside Down
            "window" ;Plot Area
            (nth 0 main_bol) ;vla-getboundingbox
            (nth 2 main_bol) ;vla-getboundingbox
            ;llpt				;Lower left corner of window
            ;urpt				;Upper right corner of window
            "Fit" ;Plot Scale	"Fit"
            "Center" ;Plot Offset
            "yes" ;Use Plot Style?
            "TA3 - FOR NORMIE.ctb" ;Plot Style Name
            "Yes" ;Plot Lineweights?
            "" ;Enter shade plot setting ["As displayed"/"Wireframe"/"Hidden"/"Visual styles"/"Rendered"]
            "N"
            "N"
            filename ; Name file and Location
            "Y"
            "Y"
        
    )
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
)
(defun c:RUNC_plot ()
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
      (vl-prin1-to-string (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
      
      (if
        (and
          ; (= (sslength ss_pre_filter_set_xx_) 1)
          (= (wcmatch (strcase (vl-princ-to-string ss_pre_filter_set_xx_obj_)) "*IACADEXTERNALREFERENCE*") T)
        )
        (progn
          (setq External_ref_ename_ ss_pre_filter_set_xx_ename_ )
          (setq main_bol (LM:boundingbox (vlax-ename->vla-object External_ref_ename_)))
        )
      )
      (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
    )
  ;
  ;plot process
    (if 
      (findfile 
        (setq filename (strcat "" 
                               (if (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                                (progn
                                  (strcat "C:\\TA WORK\\ไฟล์ข้อมูลแบบ แปลน , รูปด้าน , รูปตัด รถไฟฟ้่าสายสีม่วง สัญญา 5 21-06-67\\" (nth 3 (LM:str->lst (getvar "dwgprefix") "\\")) "\\" 
                                          (strcat 
                                            (substr (getvar 'dwgname) (+ (vl-string-search "PP" (getvar 'dwgname) 0 ) 1 ) 4 )
                                            " automation plottter"
                                          )
                                          "\\"
                                  )
                                )
                                (strcat "C:\\TA\\TA_WORK\\รถไฟฟ้า\\PPLINE ITD\\ไฟล์ข้อมูลแบบ แปลน , รูปด้าน , รูปตัด รถไฟฟ้่าสายสีม่วง สัญญา 5 21-06-67\\" (nth 5 (LM:str->lst (getvar "dwgprefix") "\\")) "\\" 
                                          (strcat 
                                            (substr (getvar 'dwgname) (+ (vl-string-search "PP" (getvar 'dwgname) 0 ) 1 ) 4 )
                                            " automation plottter"
                                          )
                                          "\\"
                                  )
                               )
                               (LM:StringSubst "" ".dwg" (getvar 'DWGNAME) )
                               ".pdf"
                       )
        )
      )
      (vl-file-delete filename)
    )
    (command "-plot" 
            "Yes" ;Detailed Plot Configuration?
            (getvar "ctab")
            "DWG To PDF.pc3" ;Printer Name
            "ISO_full_bleed_A3_(420.00_x_297.00_mm)" ;Paper Size
            ;paper_size ;Paper Size
            "m" ;Paper Units Millimeters
            "Landscape" ;Orientation
            "No" ;Plot Upside Down
            "window" ;Plot Area
            (nth 0 main_bol) ;vla-getboundingbox
            (nth 2 main_bol) ;vla-getboundingbox
            ;llpt				;Lower left corner of window
            ;urpt				;Upper right corner of window
            "Fit" ;Plot Scale	"Fit"
            "Center" ;Plot Offset
            "yes" ;Use Plot Style?
            "TA3 - FOR NORMIE.ctb" ;Plot Style Name
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

; ; automation_Process
;   (if (= (getvar "ctab") "Model") ;move model
;     (progn
;       (setvar "ctab" (nth 1 (getdrawinglayouts (getvar "dwgname"))))
;     )
;   )
;   (command "zoom" "a") 
;   (c:find_xref_)
;   (c:RUNc_plot)
;   (command "close" "n" )
; ;  

; ;ssss