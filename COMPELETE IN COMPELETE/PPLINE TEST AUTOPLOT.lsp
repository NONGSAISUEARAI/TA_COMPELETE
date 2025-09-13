;update 20250613 0220 ssdasasdsda
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
;Filter Selection Set by Effectivename Ta Trai  
  ;Note By Code_Developer
  ;
  ;Fully command must have sub-functions with names starting with TA: or LM:
  ;
  ;
  (defun TA:EF_Filter_ss_set_ (ss_pre_filter_set_  effectivename) ;กรอง block object ด้วย LM:effectivename
    (setq ss_post_filter_set_ (ssadd))
    ; (setq effectivename "12a")
    ;preloop_and_while
      (setq ss_pre_filter_set_i 0)
      (while 
        ;get_data
          (setq ss_pre_filter_set_ename (ssname  ss_pre_filter_set_ ss_pre_filter_set_i) )
          (setq ss_pre_filter_set_obj (vlax-ename->vla-object ss_pre_filter_set_ename))
          (setq ss_pre_filter_set_obj_efname_ (LM:effectivename ss_pre_filter_set_obj))
        ;
        ;filter_data
          (if (= ss_pre_filter_set_obj_efname_ effectivename)
            (progn
            (ssadd ss_pre_filter_set_ename ss_post_filter_set_)
            )
            (princ (strcat "\nfilter_selection_set_and_sorting is processing " (rtos (* ss_pre_filter_set_i (/ 100 (float (sslength ss_pre_filter_set_)))) 2 0) "%\n"))
          )
        ;
        (setq ss_pre_filter_set_i (+ ss_pre_filter_set_i 1))
      )
    ;
    (sslength ss_post_filter_set_)
    (princ ss_post_filter_set_)
    (setq ss_post_filter_set_ ss_post_filter_set_)
  )
  (defun TA:EF_Filter_ss_set_v2_ (ss_pre_filter_set_  effectivename_list) ;กรอง block object ด้วย LM:effectivename 
    (setq ss_post_filter_set_ (ssadd))
    ; (setq effectivename "12a")
    ;preloop_and_while
      (setq ss_pre_filter_set_i 0)
      (while 
        ;get_data
          (setq ss_pre_filter_set_ename (ssname  ss_pre_filter_set_ ss_pre_filter_set_i) )
          (setq ss_pre_filter_set_obj (vlax-ename->vla-object ss_pre_filter_set_ename))
          (setq ss_pre_filter_set_obj_efname_ (LM:effectivename ss_pre_filter_set_obj))
        ;
        ;filter_data
          (if (= (TA:FIND_DUPLICATE_LIST ss_pre_filter_set_obj_efname_ effectivename_list) "Y")
            (progn
            (ssadd ss_pre_filter_set_ename ss_post_filter_set_)
            )
            (princ (strcat "\nfilter_selection_set_and_sorting is processing " (rtos (* ss_pre_filter_set_i (/ 100 (float (sslength ss_pre_filter_set_)))) 2 0) "%\n"))
          )
        ;
        (setq ss_pre_filter_set_i (+ ss_pre_filter_set_i 1))
      )
    ;
    (sslength ss_post_filter_set_)
    (princ ss_post_filter_set_)
    (setq ss_post_filter_set_ ss_post_filter_set_)
  )
  
  (defun TA:Prop_Filter_ss_set_ (Selection_list_ nameprop_ propval_)
    (setq temp_ssget_ (ssadd))
    (setq Selection_list_i 0)
    (while (< Selection_list_i (sslength Selection_list_))
      (setq Selection_list_ename_ (ssname Selection_list_ Selection_list_i))
      (setq Selection_list_obj_ (vlax-ename->vla-object Selection_list_ename_))
        (if
          (= (vlax-get-property Selection_list_obj_ nameprop_) propval_ )
          (progn
            (setq temp_ssget_ (ssadd Selection_list_ename_ temp_ssget_))
          )
          (princ "\n")
        )
      (setq Selection_list_i (+ Selection_list_i 1))
    )
    (sslength temp_ssget_)
    (setq temp_ssget_ temp_ssget_)
  )
  (defun TA:member (str_name_ member_list_)
      (setq member_list_i 0)
      (setq found nil)
      (while (and
              (< member_list_i (length member_list_))
              (/= found T)
            )
        (setq member_list_val (nth member_list_i member_list_))
        (if (= str_name_ member_list_val)
          (progn
            (setq found T)  
          )
            (setq found nil)
        )
        (setq member_list_i (+ member_list_i 1))
      )
      (setq result found)
  )
  (defun TA:member_position (str_name_ pos member_list_)
      (setq member_list_i 0)
      (setq result_found_val ())
      (setq found nil)
      (while (and
              (< member_list_i (length member_list_))
              ; (/= found T)
            )
        (setq member_list_val (nth member_list_i member_list_))
        (if (= str_name_ (nth pos member_list_val))
          (progn
            ; (setq found T)
            (setq result_found_val (cons member_list_val result_found_val))          
          )
            (setq found nil)
        )
        (setq member_list_i (+ member_list_i 1))
      )
      (setq result result_found_val)
  )
  (defun remove_member_list_ (num_ point_list_)
    (setq new_list_ ())
    ; (setq num_ 2)
    (setq point_list_i 0)
    (while (< point_list_i (length point_list_))
      
      (setq point_list_set_ (nth point_list_i point_list_))
      (setq point_list_set_remove (vl-remove (nth num_ point_list_set_) point_list_set_))
      (setq new_list_ (cons point_list_set_remove new_list_))
      (setq point_list_i (+ point_list_i 1))
      
    )
    (setq result_ (reverse new_list_))
  )
  (defun remove_single_list_ (num_ point_list_)
    (setq new_list_ ())
      (setq point_list_set_ point_list_)
      (setq point_list_set_remove (vl-remove (nth num_ point_list_set_) point_list_set_))

    (setq result_ point_list_set_remove)
  )
  (defun TA:remove_val_list_ (val_list_ target_list_)
    ;example
      ; (setq target_list_ (list 1 2 3 4 5 6 7 8 9 nil))
      ; (setq target_list_ (list "ปรับปรุงอาตาร_DERMA_HEALTH_คลอ" "ง9_DB_STUDIO" ""))
      ; (setq val_list_ nil) 
      ; (TA:remove_val_list_ 8 target_list_)
    ;
    ;preloop_and_while
      (setq target_list_i 0)
      (while (< target_list_i (length target_list_))
        (setq target_list_ename_ (nth  target_list_i target_list_))
        (if (or (= target_list_ename_ nil) (= target_list_ename_ "") )
          (progn
            (setq target_list_ (vl-remove (nth target_list_i target_list_) target_list_))
          )
        )
        (setq target_list_i (+ target_list_i 1))
      )
      (setq target_list_ target_list_)
    ; 
  )
  (defun TA:FIND_DUPLICATE_LIST (target_val_ target_list_)
    ;example_code
      ; (setq target_val_ 69)
      ; (setq target_list_ (list 2 5 69 4 26 9 5 23 6 9 52  6))
    ;
    ;preloop_and_while
      (setq target_list_i 0)
      (setq check_list_val "N")
      (while (and (< target_list_i (length target_list_)) (= check_list_val "N"))
        (setq target_list_ename_ (nth  target_list_i target_list_))
          (if (= target_val_ target_list_ename_ )
            (progn
              (setq check_list_val "Y")
            )
            (setq check_list_val "N")
          )
        (setq target_list_i (+ target_list_i 1))
      )
    ;
    ;summary_checking_list_
      (if (= target_list_i (length target_list_))
        (progn
          (princ (strcat "do not found duplicate targetlist \n" ))
        )
        (princ (strcat "target_val_ has been duplicate in " (rtos target_list_i 2 0) "\n" ))
      )
      (setq check_list_val check_list_val)
    ;
  )
  (defun TA:Count_item_in_list_ (c_list_ )
    ;
      (setq result_ ())
      (while (/= c_list_ nil)
        (length c_list_)
        (setq c_list_val_ (car c_list_))
        (setq count_i (- 
                  (length c_list_)
                  (length (setq c_list_ (vl-remove c_list_val_ c_list_)))
                )
        )
        (setq result_ (cons (cons c_list_val_ count_i ) result_))
        
      )
    ;
  )
  (defun LM:CountItems (l / c l r x) 
    (while l 
      (setq x (car l))
      (setq c (length l))
      (setq l (vl-remove x (cdr l)))
      (setq r (cons (cons x (- c (length l))) r))
    )
    (reverse r)
  )
  (defun TA:find-all-indexes (val lst / idx result)
    (setq idx 0)
    (setq result '())
    (while lst
      (if (equal (car lst) val)
        (setq result (cons idx result))
      )
      (setq idx (1+ idx))
      (setq lst (cdr lst))
    )
    (reverse result)
  )
  (defun TA:wcmatch_list (filter_string_list_ list_data_ strcase_val)
    ;Note By Code_Developer
    ;This command is designed to work exclusively with a list name & array.
    ;The pripicle of the codework will read list name & array then filter target value that filter_string parameter indicate.
    ;Fully command must have sub-functions with names starting with TA: or LM:
    ;
    ;Example how argument work
      ; (setq filter_string_list_ (list 
      ;                             "*text_that _you_need*"
      ;                             "50"
      ;                             "45" 50 48 69
      ;                             "*re*"
      ;                             "*ai*"
      ;                           )
      ; )
      ; (setq list_data_ (list "50" "45" "A" "TRE" "TEXT" "ikwai na sonteen isud e heer" 48 55 69 50))
      ; (setq strcase_val nil)
    ;
    ;1st condition
    (cond
      ((= strcase_val nil)
        (progn
          (setq filter_string_list_ (mapcar 
                                      '(lambda (x) 
                                          (if 
                                            (and (= (type x) 'str) 
                                                (/= (atof x) 'real)
                                            ) 
                                            (progn 
                                              (strcase x T)
                                            ) 
                                            ""
                                          ;  (if (testexpr)
                                          ;   (progn
                                          ;     (thenexpr)
                                          ;   )
                                          ;  )
                                          )
                                        )
                                      filter_string_list_
                                    )
          )
          (setq list_data_ (mapcar 
                                      '(lambda (x) 
                                          (if 
                                            (and 
                                              (= (type x) 'str)
                                              (/= (atof x) 'real)
                                            ) 
                                            (progn 
                                              
                                              (strcase x T)
                                            ) 
                                            ""
                                          ;  (if (testexpr)
                                          ;   (progn
                                          ;     (thenexpr)
                                          ;   )
                                          ;  )
                                          )
                                        )
                                      list_data_
                                    )
          )
        )
      )
      ; ((= strcase_val T)
      ;   (progn
      ;     (setq filter_string_list_ (mapcar 
      ;                                 '(lambda (x) 
      ;                                    (if 
      ;                                      (and (= (type x) 'str) 
      ;                                           (/= (atof x) 'real)
      ;                                      ) 
      ;                                      (progn 
      ;                                        (strcase x T)
      ;                                      ) 
      ;                                      ""
      ;                                     ;  (if (testexpr)
      ;                                     ;   (progn
      ;                                     ;     (thenexpr)
      ;                                     ;   )
      ;                                     ;  )
      ;                                    )
      ;                                  )
      ;                                 filter_string_list_
      ;                               )
      ;     )
      ;     (setq list_data_ (mapcar 
      ;                                 '(lambda (x) 
      ;                                    (if 
      ;                                      (and  
      ;                                           (/= (atof x) 'real)
      ;                                      ) 
      ;                                      (progn 
      ;                                        (strcase x T)
      ;                                      ) 
      ;                                      ""
      ;                                     ;  (if (testexpr)
      ;                                     ;   (progn
      ;                                     ;     (thenexpr)
      ;                                     ;   )
      ;                                     ;  )
      ;                                    )
      ;                                  )
      ;                                 list_data_
      ;                               )
      ;     )
      ;   )
      ; )
    )
      (setq filter_result_ (vl-remove-if-not 
                            '(lambda (x) 
                                (apply 'or 
                                        (mapcar 
                                          '(lambda (p) (wcmatch x p))
                                          filter_string_list_
                                        )
                                )
                              )
                            list_data_
                          )
      )
      (setq filter_result_ (reverse filter_result_))
    ;
  )
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
  (defun TA:preset_plotter_mode_1 ()
    ;set_var_plot
      ; (setq ss (car (entsel)))
      (setq adoc (vla-get-activedocument (vlax-get-acad-object)))
      (setq lyout (vla-get-activelayout adoc))
      (setq styleSheet "TA3.ctb")
      (setq cfgName "AutoCAD PDF (High Quality Print).pc3")
      (vla-RefreshPlotDeviceInfo lyout)
      (vla-put-ConfigName lyout CfgName)
      
      (vla-put-PaperUnits lyout acMillimeters)
      (vla-put-plotrotation lyout ac0degrees)
      ; (vla-put-PlotType lyout acWindow)
      (vla-put-PlotType lyout acExtents)
      (vla-put-CanonicalMediaName lyout "ISO_full_bleed_A4_(210.00_x_297.00_MM)")
      ; (vla-put-CanonicalMediaName lyout "ISO_full_bleed_A3_(420.00_x_297.00_mm)")
      (vla-put-PlotWithLineweights lyout :vlax-true)
      (vla-put-PlotWithPlotStyles lyout :vlax-true)
      (vla-put-StyleSheet lyout styleSheet)
      (vla-put-CenterPlot lyout :vlax-true)
      (vla-put-standardscale lyout acScaleToFit )
      (vla-put-plotrotation lyout ac90degrees)
    
    
      (vla-put-PaperUnits lyout acMillimeters)
    ;
  )
  (defun TA:preset_plotter_mode_2 ()
    ;set_var_plot
      ; (setq ss (car (entsel)))
      (setq adoc (vla-get-activedocument (vlax-get-acad-object)))
      (setq lyout (vla-get-activelayout adoc))
      (setq styleSheet "monochrome.ctb")
      (setq cfgName "AutoCAD PDF (High Quality Print).pc3")
      (vla-RefreshPlotDeviceInfo lyout)
      (vla-put-ConfigName lyout CfgName)
      (vla-put-PaperUnits lyout acMillimeters)
      (vla-put-plotrotation lyout ac0degrees)
      ; (vla-put-PlotType lyout acWindow)
      (vla-put-PlotType lyout acExtents)
      (vla-put-CanonicalMediaName lyout "ISO_full_bleed_A4_(210.00_x_297.00_MM)")
      ; (vla-put-CanonicalMediaName lyout "ISO_full_bleed_A3_(420.00_x_297.00_mm)")
      (vla-put-PlotWithLineweights lyout :vlax-true)
      (vla-put-PlotWithPlotStyles lyout :vlax-true)
      (vla-put-StyleSheet lyout styleSheet)
      (vla-put-CenterPlot lyout :vlax-true)
      (vla-put-standardscale lyout acScaleToFit )
      (vla-put-plotrotation lyout ac90degrees)
    
    
      (vla-put-PaperUnits lyout acMillimeters)
    ;
  )
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
  (defun TA:preset_plotter_mode_4 ()
    ;set_var_plot
      ; (setq ss (car (entsel)))
      (setq adoc (vla-get-activedocument (vlax-get-acad-object)))
      (setq lyout (vla-get-activelayout adoc))
      (setq styleSheet "FAMELINE-CKST-Generic.ctb")
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

;PPLINE-ITD
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
                                  (strcat "C:\\TA\\TA_WORK\\รถไฟฟ้า\\PPLINE ITD\\ไฟล์ข้อมูลแบบ แปลน , รูปด้าน , รูปตัด รถไฟฟ้่าสายสีม่วง สัญญา 5 21-06-67\\" (nth 6 (LM:str->lst (getvar "dwgprefix") "\\")) "\\" 
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
  (defun c:RUNPPEL_plot ()
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
      (setq filename (strcat 
                      "C:\\TA WORK\\ไฟล์ข้อมูลแบบ แปลน , รูปด้าน , รูปตัด รถไฟฟ้่าสายสีม่วง สัญญา 5 21-06-67\\PP27 DAO KHANONG STATION\\PP27 automation plottter\\"
                      (LM:StringSubst "" ".dwg" (getvar 'DWGNAME) )
                        ".pdf"
                    )
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
;



;PPLINE-CKST
  (defun c:Plotter_CKST_CSDPLOT ()
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
              (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat "*" (strcase "ACM_Titleblock_MRTA") "*"))  T)
              
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
            "window" ;Plot Area
            (nth 0 main_bol) ;vla-getboundingbox
            (nth 2 main_bol) ;vla-getboundingbox
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
  (defun c:Plotter_CKST_GEN-PLOT ()
      ;return
        (command "ucs" "world")
      ;
    ;plot process
      (if 
        (findfile (setq filename (strcat "" (getvar 'DWGPREFIX) (LM:StringSubst "" ".dwg" (getvar 'DWGNAME))  ".pdf"))) 
        (vl-file-delete filename)
      )
    ;
    ;input_type_of_plot_
      (TA:preset_plotter_mode_4) 
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
            "Extents" ;Plot Area
            ; (nth 0 main_bol) ;vla-getboundingbox
            ; (nth 2 main_bol) ;vla-getboundingbox
            ;llpt				;Lower left corner of window
            ;urpt				;Upper right corner of window
            "Fit" ;Plot Scale	"Fit"
            "Center" ;Plot Offset
            "yes" ;Use Plot Style?
            "FAMELINE-CKST-Generic.ctb" ;Plot Style Name
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
  (defun c:Auto_page_AUPAGE (  )
    ;detect and delete ex mtext 
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_mtext_detect_ (ssget "x"
                                              (list
                                                (cons 0 "mtext") ;type of object
                                                (cons 410 (getvar "CTAB"))
                                                (cons 8 "G-ANNO-TTLB")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                (cons 62 256)           ;kind of color call sign with color code index
                                              )
                                        )
            )   
            nil
          )
          (progn 
            (setq ss_mtext_detect_ (ssget
                                              (list
                                                (cons 0 "mtext") ;type of object
                                                (cons 410 (getvar "CTAB"))
                                                (cons 8 "G-ANNO-TTLB")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                (cons 62 256)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
        )
      ;
      ;preloop_and_while
        (setq ss_mtext_detect_i 0)
        (setq ss_mtext_detect_temp  (ssadd))
        (while (< ss_mtext_detect_i (sslength ss_mtext_detect_))
          (setq ss_mtext_detect_ename_ (ssname ss_mtext_detect_ ss_mtext_detect_i))
          (setq ss_mtext_detect_obj_ (vlax-ename->vla-object  ss_mtext_detect_ename_))
          (setq ss_mtext_detect_obj_textstring (vla-get-textstring ss_mtext_detect_obj_))
          (if (and
                (= (wcmatch ss_mtext_detect_obj_textstring "*PP19*,*-2025*,*-2024*,C,B" ) T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*STATION*,*.rvt*,*Autodesk*" ) T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*PP19 :*") T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*.rvt*" ) T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*Autodesk*") T )
                ; (= (wcmatch ss_mtext_detect_obj_textstring "*-2025*" ) T )
                ; (= (wcmatch ss_mtext_detect_obj_textstring "*-2024*" ) T )
                ; (= (wcmatch ss_mtext_detect_obj_textstring "C" ) T )
                ; (= (wcmatch ss_mtext_detect_obj_textstring "B" ) T )
              )
            (progn
              (setq ss_mtext_detect_temp (ssadd ss_mtext_detect_ename_ ss_mtext_detect_temp  ))
              (command "pselect"  ss_mtext_detect_temp "" )
            )
          )
          (setq ss_mtext_detect_i (+ ss_mtext_detect_i 1))
        )
      ;
      ;enter for delete mtext 
        (if (and 
              (/= (sslength ss_mtext_detect_temp) 0)
              (= (setq detectloop (getstring "enter to change length Object")) "")
            )
          (progn
            (command "erase"  ss_mtext_detect_temp "")
          )
        )
      ;
    ;
    ;creating block process
      (if (= 
            (wcmatch (vl-princ-to-string (vl-catch-all-apply (function (lambda () (vla-Item (vla-get-Blocks doc) "000 - TA AUTO PAGE")) ) ) ) "*IAcadBlock*" )
            nil
          )
        (progn
          (command "circle" (list 0 0 0) 10 "" ) 
          ;new_blk_entlast object
            (setq circle_ename (entlast))
            (setq circle_obj (vlax-ename->vla-object circle_ename))
            (setq circle_obj_inscen_ (vlax-safearray->list (vlax-variant-value (vla-get-center circle_obj ))))
            (command "erase" "L" "")
            (command "_block" "000 - TA AUTO PAGE" circle_obj_inscen_ circle_ename "" )
            (TA:vla-insertblock "000 - TA AUTO PAGE" circle_obj_inscen_ 1 0 )
            (setvar "BLOCKREDEFINEMODE" 1)
            (command "-INSERTCONTENT" 
                    "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\PP19\\CAD\\C-1-PP19-AR-4130-01-B.dwg"
                    "000 - TA AUTO PAGE" 
                    circle_obj_inscen_ 1 1 0 "" "" "" "" )
            (setvar "BLOCKREDEFINEMODE" 1)
            (command "erase" "L" "")
          ;
        )
      )
    ;
    ;insert - process
      (if (wcmatch 
          (vl-princ-to-string (vl-catch-all-apply (function (lambda () (vla-Item (vla-get-Blocks doc) "000 - TA AUTO PAGE") ) ) ) ) "*IAcadBlock*" 
        )
        (progn
          ;get-file-name_data_mode_
            ;pre-settting
              (setq filter_string_list_ (list "*C-1-Pp*"))
              (setq current_filepath (getvar "dwgprefix"))
              (setq current_filename (getvar "dwgname"))
              (setq current_file_folder_list_ (vl-directory-files current_filepath "*.dwg"))
              (setq list_data_ current_file_folder_list_)
              (setq new_list_data_ ())
            ;
              (setq true_list_data_ (reverse (TA:wcmatch_list (list "*C-1-PP*") current_file_folder_list_ T)))
              (setq true_list_data_index_val_ (car (TA:find-all-indexes current_filename true_list_data_)))
              (setq true_list_data_length_ (length true_list_data_ ))
            ;
          ;
          ;return
          ;find tittle block
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
                    (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat "*" (strcase "ACM_Titleblock_MRTA") "*"))  T)
                    
                  )
                  (progn
                    (setq main_bol (LM:boundingbox ss_pre_filter_set_xx_obj_))
                  )
                )
                (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
              )
            ; 
          ;
          ;insert block process
            (TA:vla-insertblock 
              "000 - TA AUTO PAGE"
              (car main_bol)
              1
              0
            )
            ;new_blk_entlast object
              (setq sss_ename (entlast))
              (setq sss_obj_ (vlax-ename->vla-object sss_ename))
              (LM:vl-setattributevalue sss_obj_ "DATE_VAL" (strcat 
                                                            (substr (rtos (getvar "cdate" ) 2 0) 7 2)
                                                            "-"
                                                            (substr (rtos (getvar "cdate" ) 2 0) 5 2)
                                                            "-"
                                                            (substr (rtos (getvar "cdate" ) 2 0) 1 4)
                                                          )
              )
              (LM:vl-setattributevalue sss_obj_ "STATUS_VAL" "C" )
              (LM:vl-setattributevalue sss_obj_ "SHEET_VAL" (LM:StringSubst
                                                              ""
                                                              "C-"
                                                              (LM:StringSubst "" ".dwg" current_filename ) 
                                                            ) 
              )
              (LM:vl-setattributevalue sss_obj_ "REVISION_VAL" "W" )
              (LM:vl-setattributevalue sss_obj_ "SHEET_NO_VAL" (strcat 
                                                              (rtos (+ true_list_data_index_val_ 1)  2 0)
                                                              "/"
                                                              (rtos (+ true_list_data_length_ 1) 2 0)
                                                            ) 
              )
            ;
          ;
          (wcmatch 
            (vl-princ-to-string 
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-Item (vla-get-Blocks doc) "000 - TA AUTO PAGE")
                  )
                )
              )
            )
            "*error*,*IAcadBlock*"
          )
        )
        (alert "plase insert block name \"000 - TA AUTO PAGE\" ")
      )
    ;
  )
;



; ; ; automation_Process
;   (if (= (getvar "ctab") "Model") ;move model
;     (progn
;       (setvar "ctab" (nth 1 (getdrawinglayouts (getvar "dwgname"))))
;     )
;   )
;   ; (c:CKdim)
;   (c:Plotter_CKST_CSDPLOT)
;   (command "zoom" "a") 
; ;   ; (c:find_xref_)
; ;   ; (c:RUNPPEL_plot)
;   (command "close" "n" )
; ; ;  

; automation_Process
  ; (if (= (getvar "ctab") "Model") ;move model
  ;   (progn
  ;     (setvar "ctab" (nth 1 (getdrawinglayouts (getvar "dwgname"))))
  ;   )
  ; )
  ; (c:CKdim)
  ; (c:Plotter_CKST_GEN-PLOT)
  ; (command "zoom" "a") 
  ; (command "close" "n" )
;  
(setq filter_result_ (vl-remove-if-not 
                              '(lambda (x) 
                                  (apply 'or 
                                         (mapcar 
                                           '(lambda (p) (wcmatch x p))
                                           '("A" "B" )
                                         )
                                  )
                                )
                              '( "A" "a" "B" "b" "c")
                            )
        )