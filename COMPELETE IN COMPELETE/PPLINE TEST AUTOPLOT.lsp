;update 20250613 0220 ssdasasdsda
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
;Block Editor_FUNC
  (defun TA:vla-insertblock (blockName insertion_point scale rotation)
    (setq acadApp (vlax-get-acad-object))  ; เข้าถึง AutoCAD application
    (setq doc (vla-get-ActiveDocument acadApp))
    (if (= (getvar "ctab" ) "Model")
      (progn
        (setq ms (vla-get-ModelSpace doc))
      )
      (setq ms (vla-get-paperspace doc))
    )
      ; เข้าถึง Active Document
    
      ; เข้าถึง ModelSpace
    
    (setq block (vla-InsertBlock 
                  ms 
                  (vlax-3d-point insertion_point) 
                  blockName 
                  scale scale scale
                  rotation
                )
    )  ; แทรกบล็อก
  )
  (defun TA:set-block-explodable (block-name allow-exploding) 
    ;example_using
    ;;allow-exploding = :vlax-true or :vlax-false
    ; (set-block-explodable "A$C5b7816c3" :vlax-true)
    ; (set-block-explodable "A$C5b7816c3" :vlax-false)
    ;
    ;for testing code
    ; (setq block-name "001 - DYNAMIC LV" )
    ; (setq block-name "A$C405762cd" )
    ; (setq allow-exploding :vlax-false )
    ; (setq allow-exploding :vlax-true )
    ;
    (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
    (setq block-def (vla-Item (vla-get-Blocks doc) block-name))
    (vla-get-Explodable block-def)
    (if (/= block-def nil) 
      (progn 
        (vla-put-Explodable block-def allow-exploding)
      )
      (princ (strcat "\nBlock " block-name " not found."))
    )
  )
  (defun c:allow_explode_block_ALEX ()
    (setq blk_ename_ (car (entsel "specify Object")))
    (setq blk_obj_ (vlax-ename->vla-object blk_ename_))
    (setq ef_name (LM:effectivename blk_obj_))
    (TA:set-block-explodable ef_name :vlax-true)
  )
  (defun TA:set-block-blockscaling (block-name parameter)
    ;example_using
      ;;parameter = acAny or acUniform
      ; (set-block-explodable "A$C5b7816c3" acAny)
      ; (set-block-explodable "A$C5b7816c3" acUniform)
    ;
    (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
    (setq block-def (vla-Item (vla-get-Blocks doc) block-name))
    (if block-def
      (vla-put-blockscaling block-def parameter)
      (princ (strcat "\nBlock " block-name " not found."))
    )
  )
  (defun c:ADD_VISIBILITY_multi-mode_ADVSM_ ()
    (setq input_ins_ (getpoint ))
    (setq name_vis_ "view")
    (command "BPARAMETER" "v" "L" name_vis_ input_ins_ 1)
    (command "-Bvstate" "s" "VisibilityState0")
    ;preloop_and_while_ 
    (setq visibility_screw_mode_                    "1 = screw_mode") 
    (setq visibility_view_mode_                     "2 = front_top_side_cut_mode") 
    (setq visibility_number_mode_                   "3 = number_mode") 
    (setq visibility_AL.EXTR-U-Profile_mode_        "4 = AL.EXTR-U-Profile_mode")
    (setq visibility_copy_mode_                     "5 = copy visibility from another dynamic block")
    (setq visibility_copy_mode_                     "6 = Hex bolt ")
    (setq visibility_cutting_plan_mode_             "7 = Cutting Plan ")
    
    (setq visibility_mode_value_ (cond ((getint (strcat visibility_screw_mode_"\n"visibility_view_mode_"\n"visibility_number_mode_"\n"visibility_AL.EXTR-U-Profile_mode_"\n" visibility_copy_mode_"\n" visibility_cutting_plan_mode_ "\n" "<" (rtos (setq visibility_mode_value_ (cond (visibility_mode_value_) (1.0) ) ) ) "> : " ) ) ) (visibility_mode_value_) ) )
    ;Data_visibiity_list_normie_mode_
      (cond
        (;visibility_mode_case_1
          (and
              (= visibility_mode_value_ 1)
          )
          (progn
              (setq visibility_list_ (list
                                      "0_iso_view"
                                      "1_top_view"
                                      "2_side_head"
                                      "3_side_view_19mm."
                                      "4_side_view_25mm."
                                      "5_side_view_50mm."
                                      "6_side_view_75mm."
                                      "7_side_view_100mm."
                                    )
              )
              (princ "visibility_mode_case_1")
          )
        )
        (;visibility_mode_case_2
          (and
              (= visibility_mode_value_ 2) 
          )
          (progn
              (setq visibility_list_ (list
                                      "0_iso_view"
                                      "1_cut_view"
                                      "2_top_view"
                                      "3_front_view"
                                      "4_side_L_view"
                                      "4_side_R_view"
                                      "5_back_view"
                                      "6_bottom_view"
                                      "7_dynamic_length_view"
                                    )
              )
              (princ "visibility_mode_case_2")
          )
        )
        (;visibility_mode_case_3
          (and
              (= visibility_mode_value_ 3)
          )
          (progn
              (setq visibility_list_ (list
                                      "1_"
                                      "2_"
                                      "3_"
                                      "4_"
                                      "5_"
                                      "6_"
                                      "7_"
                                      "8_"
                                      "9_"
                                      "10_"
                                      "11_"
                                      "12_"
                                      "13_"
                                      "14_"
                                      "15_"
                                      "16_"
                                      "17_"
                                      "18_"
                                      "19_"
                                      "20_"
                                      "21_"
                                      "22_"
                                      "23_"
                                      "24_"
                                      "25_"
                                      "26_" 
                                    )
              )
              
              (princ "visibility_mode_case_3")
          )
        )
        (;visibility_mode_case_4
          (and
              (= visibility_mode_value_ 4)
          )
          (progn
              (setq visibility_list_ (list
                                      "1_cut_view_covering_profile"
                                      "2_top_view"
                                      "3_front_view"
                                      "4_side_L_view"
                                      "4_side_R_view"
                                      "5_back_view"
                                      "6_bottom_view"
                                      "7_dynamic_length_view"
                                    )
              )
              (princ "visibility_mode_case_4")
          )
        )
        (;visibility_mode_case_6
          (and
              (= visibility_mode_value_ 6)
          )
          (progn
              (setq visibility_list_ (list
                                      "top_view"
                                      "hex-nut"
                                      "x8mm."
                                      "x10mm."
                                      "x12mm."
                                      "x14mm."
                                      "x15mm."
                                      "x20mm."
                                      "x25mm."
                                      "x30mm."
                                      "x40mm."
                                      "x45mm."
                                      "x50mm."
                                      "x55mm."
                                      "x60mm."
                                      "x65mm."
                                      "x70mm."
                                      "x75mm."
                                      "x80mm."
                                      "x90mm."
                                      "x100mm."
                                    )
              )
              (princ "visibility_mode_case_6")
          )
        )
        (;visibility_mode_case_6
          (and
              (= visibility_mode_value_ 7)
          )
          (progn
              (setq visibility_list_ (list
                                      "NORMAL"
                                      "FOLDING_LINE"
                                      "CUTTING_LINE"
                                    )
              )
              (princ "visibility_mode_case_7")
          )
        )
      )
    ;
    ;visibility_copy_mode_[visibility_copy_mode_
      (if (and (/= visibility_mode_value_ 5) (numberp visibility_mode_value_))
        (progn
          (setq visibility_list_i 0)
          (while (< visibility_list_i (length visibility_list_))
            (setq visibility_list_SEQ (nth visibility_list_i visibility_list_))
            (command "-Bvstate" "n" visibility_list_SEQ "c" )
            (setq visibility_list_i (+ visibility_list_i 1))
          )
        )
        (if (and (= visibility_mode_value_ 5) (numberp visibility_mode_value_))
          (progn          
            (command "_bclose" "s")
            ;while_select_block_on_condition_
              (setq visibility_list_ nil)
              (while (= visibility_list_ nil)
                (setq vis_ename_ (car (entsel "specify Visibility Object")))
                (if 
                  (and ;conditional_rule_for_select_object_
                    (/= vis_ename_ nil)
                    (setq vis_obj_ (vlax-ename->vla-object vis_ename_))
                    (= (vla-get-objectname vis_obj_ ) "AcDbBlockReference")
                    (= (vla-get-isdynamicblock vis_obj_ ) :vlax-true)
                    (/= (LM:getdynpropallowedvalues vis_obj_ "view") nil)
                  )
                  (progn
                    (setq visibility_list_ (LM:removenth 0 (LM:getdynpropallowedvalues vis_obj_ "view")) )
                  )
                  (alert "Object invalid Please try again")
                )
              )
              (setq block_target_ename_ nil)
              (while (= block_target_ename_ nil)
                (setq block_target_ename_ (car (entsel "specify block_target_ename_ Object")))
                (if 
                  (and ;conditional_rule_for_select_object_
                    (/= block_target_ename_ nil)
                    (setq block_target_obj_ (vlax-ename->vla-object block_target_ename_))
                    (= (vla-get-objectname block_target_obj_ ) "AcDbBlockReference")
                  )
                  (progn
                    (setq block_target_obj_efname_ (LM:Effectivename block_target_obj_))
                    (command "_bedit" block_target_obj_efname_)
                    (setq visibility_list_i 0)
                    (while (< visibility_list_i (length visibility_list_))
                      (setq visibility_list_SEQ (nth visibility_list_i visibility_list_))
                      (command "-Bvstate" "n" visibility_list_SEQ "c" )
                      (setq visibility_list_i (+ visibility_list_i 1))
                    )
                  )
                  (alert "Object invalid Please try again")
                )
              )
            ;
          )
        )
      )
    ;  
    ; ;reture_visibility_to_defuat
      (command "-Bvstate" "s" "VisibilityState0"  )
      (command "BVHIDE" (ssget "x") "" "A" )
      (setvar "BVMODE" 1)
      (command "BVSHOW" (ssget "x") "" "C" )
    ;      
  )
  (defun c:dyanamic_rename_array_REAR ()
    (setq BPARAMETER_ename_ (car (entsel "specify Object")))
    (if (/= BPARAMETER_ename_ nil)
      (progn
        (setq BPARAMETER_obj_ (vlax-ename->vla-object BPARAMETER_ename_))
        (vlax-get-property BPARAMETER_obj_ "DistName" )
        (vlax-put-property BPARAMETER_obj_ "DistName" "array_width")
        (vlax-put-property BPARAMETER_obj_ "Grips" 1)
      )
      (setq BPARAMETER_ename_ nil)
    )
    
  )
  (defun c:dynamic_rewidth_array_1_rew1 ()
    ;user_input_
      (setq user_num_ (getreal "specify_num_for_array_width"))
    ;
    ;selection_set
      (setq ss_pre_filter_set_xx_ (ssget "x" 
                                        ; (list 
                                        ;   (cons 0 "INSERT") ;type of object
                                        ;   ; (cons 8 "000 - GRID")   ;kind of layer
                                        ;   ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                        ;   ; (cons 62 1)           ;kind of color call sign with color code index
                                        ; )
                                )
      )
      (sslength ss_pre_filter_set_xx_)
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)))
        ; (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        ; (TA:dump_obj_ ss_pre_filter_set_xx_ename_)
        
        ;ColumnOffset process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockArrayActionEntity")
              (= (strcase (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ActionType" )) "ARRAY")
              (= (strcase (setq ss_pre_filter_set_xx_name_ (vla-get-name (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)))) "ARRAY_MAIN")
            )
            (progn
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ColumnOffset" user_num_ )
            )
          )
        ;
        ;array_width process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockLinearParameterEntity")  
              (= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistName" ) "array_width")        
            )
            (progn
              (setq basepoint_edit_ (list 
                                      (* (/ user_num_ 2) -1)
                                      (cadr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "BasePoint" )))) 
                                      (caddr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "BasePoint" )))) 
                                    )
              )
              (setq endpoint_edit_ (list 
                                      (* (/ user_num_ 2) 1)
                                      (cadr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "endpoint" )))) 
                                      (caddr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "endpoint" )))) 
                                    )
              )
              
              
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "BasePoint" (vlax-3d-point basepoint_edit_) )
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "EndPoint" (vlax-3d-point endpoint_edit_) )
              
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ValueSetIncrement" user_num_ )
              
              (setq Parameter_name_ (vla-get-name (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)  ))
            )
          )
        ;
        ;array_grip_process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockLinearGripEntity")  
              (= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ParameterName" ) Parameter_name_)        
            )
            (progn
              
              (setq position_edit_ (list 
                                      (* (/ user_num_ 2) 1)
                                      (cadr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Position" )))) 
                                      (caddr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Position" )))) 
                                    )
              )
              
              
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Position" (vlax-3d-point position_edit_) )
              
            )
          )
        ;
        
        
        
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  )
  (defun c:dynamic_rewidth_array_2_rew2_ ()
    ;user_input_
      (setq user_num_ (getreal "specify_num_for_array_width"))
    ;
    ;selection_set
      (setq ss_pre_filter_set_xx_ (ssget "x" 
                                        ; (list 
                                        ;   (cons 0 "INSERT") ;type of object
                                        ;   ; (cons 8 "000 - GRID")   ;kind of layer
                                        ;   ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                        ;   ; (cons 62 1)           ;kind of color call sign with color code index
                                        ; )
                                )
      )
      (sslength ss_pre_filter_set_xx_)
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)))
        ; (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        ; (TA:dump_obj_ ss_pre_filter_set_xx_ename_)
        
        ;ColumnOffset process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockArrayActionEntity")
              (= (strcase (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ActionType" )) "ARRAY")
              (= (strcase (setq ss_pre_filter_set_xx_name_ (vla-get-name (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)))) "ARRAY_MAIN")
            )
            (progn
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ColumnOffset" user_num_ )
            )
          )
        ;
        ;array_width process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockLinearParameterEntity")  
              (= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistName" ) "array_width")        
            )
            (progn
              (setq basepoint_edit_ (list 
                                      0 ;(* (/ user_num_ 2) -1)
                                      (cadr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "BasePoint" )))) 
                                      (caddr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "BasePoint" )))) 
                                    )
              )
              (setq endpoint_edit_ (list 
                                      (* user_num_ 1)
                                      (cadr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "endpoint" )))) 
                                      (caddr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "endpoint" )))) 
                                    )
              )
              
              
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "BasePoint" (vlax-3d-point basepoint_edit_) )
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "EndPoint" (vlax-3d-point endpoint_edit_) )
              
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ValueSetIncrement" user_num_ )
              
              (setq Parameter_name_ (vla-get-name (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)  ))
            )
          )
        ;
        ;array_grip_process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockLinearGripEntity")  
              (= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "ParameterName" ) Parameter_name_)        
            )
            (progn
              
              (setq position_edit_ (list 
                                      0 ;(* user_num_ 1) ;incase if i need arrow at the endpoint by TA:Trairat
                                      (cadr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Position" )))) 
                                      (caddr (vlax-safearray->list (vlax-variant-value (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Position" )))) 
                                    )
              )
              
              
              (vlax-put-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Position" (vlax-3d-point position_edit_) )
              
            )
          )
        ;
        
        
        
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  )
  (defun c:dynamic_ARsaveas_array_()
    ;user_input_
      ; (setq user_num_ (getreal "specify_num_for_array_width"))
    ;
    ;selection_set
      (setq ss_pre_filter_set_xx_ (ssget "x"
                                        ; (list 
                                        ;   (cons 0 "INSERT") ;type of object
                                        ;   ; (cons 8 "000 - GRID")   ;kind of layer
                                        ;   ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                        ;   ; (cons 62 1)           ;kind of color call sign with color code index
                                        ; )
                                )
      )
      (sslength ss_pre_filter_set_xx_)
    ;
    (setq ss_pre_filter_set_xx_ (ssget)) ;test
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)))
        ; (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        ; (TA:dump_obj_ ss_pre_filter_set_xx_ename_)
        ;
        ;array_width process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockLinearParameterEntity")  
              (= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistName" ) "array_width")        
              (/= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistanceDesc" ) "")        
            )
            (progn
              ;saveas new block name process
                (setq name_block_ (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistanceDesc" ))
                (setq check_2 (vl-string-search "@" name_block_  1))
                (setq check_22 (substr name_block_ (+ check_2 1) 8))
                (setq check_222 (vl-string-search "mm." check_22  1))
                (setq check_2222 (substr check_22 1 check_222))

                (setq check_1 nil )
                (setq new_efname_ "ZOO" )
                (setq get_array_distance (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Distance" ))
                (setq i 1)
                (while
                  (and
                    (/= (type check_1) 'INT)
                    
                    
                    ; (< i (strlen name_block_ ))
                  )
                  (if (/= (vl-string-search "@" name_block_  1) "m")
                    (progn
                      (setq new_efname_ (strcat (substr name_block_ 1 i)))
                      (setq check_1 (vl-string-search "@" new_efname_  1))
                      
                      
                      ; (setq new_efname_1 (strcat (substr name_block_ 26 1)))
                    )
                  )
                  (setq i (+ i 1))
                )
                (setq new_efname_val (strcat (substr new_efname_  (strlen new_efname_) 5 ) (rtos get_array_distance 2 0)))
                (setq new_name_block_ (LM:StringSubst 
                                        new_efname_val 
                                        check_2222 
                                        name_block_ 
                                      )
                )
              
                (command "bsaveas" new_name_block_ )
                (command "_bclose" )
              ;
              ;insertion_block_process_
                (setq new_block_name new_name_block_  )
                (TA:set-block-blockscaling new_block_name acUniform)
                (setq getpoint_ (getpoint))
                (command "insert" new_block_name  getpoint_ 1 0 )
              ;
              
            )
          )
        ;
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  )
  (defun c:dynamic_ARsaveas_array_and_insert_arsins()
    ;user_input_
      ; (setq user_num_ (getreal "specify_num_for_array_width"))
    ;
    ;selection_set
      (setq ss_pre_filter_set_xx_ (ssget "x"
                                        ; (list 
                                        ;   (cons 0 "INSERT") ;type of object
                                        ;   ; (cons 8 "000 - GRID")   ;kind of layer
                                        ;   ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                        ;   ; (cons 62 1)           ;kind of color call sign with color code index
                                        ; )
                                )
      )
      (sslength ss_pre_filter_set_xx_)
    ;
    (setq ss_pre_filter_set_xx_ (ssget)) ;test
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)))
        ; (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        ; (TA:dump_obj_ ss_pre_filter_set_xx_ename_)
        ;
        ;array_width process
          (if 
            (and
              (= (setq ss_pre_filter_set_xx_hon_objname_ (vla-get-objectname (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))) "AcDbBlockLinearParameterEntity")  
              (= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistName" ) "array_width")        
              (/= (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistanceDesc" ) "")        
            )
            (progn
              ;saveas new block name process
                (setq name_block_ (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "DistanceDesc" ))
                (setq check_2 (vl-string-search "@" name_block_  1))
                (setq check_22 (substr name_block_ (+ check_2 1) 8))
                (setq check_222 (vl-string-search "mm." check_22  1))
                (setq check_2222 (substr check_22 1 check_222))

                (setq check_1 nil )
                (setq new_efname_ "ZOO" )
                (setq get_array_distance (vlax-get-property (vlax-ename->vla-object ss_pre_filter_set_xx_ename_) "Distance" ))
                (setq i 1)
                (while
                  (and
                    (/= (type check_1) 'INT)
                    
                    
                    ; (< i (strlen name_block_ ))
                  )
                  (if (/= (vl-string-search "@" name_block_  1) "m")
                    (progn
                      (setq new_efname_ (strcat (substr name_block_ 1 i)))
                      (setq check_1 (vl-string-search "@" new_efname_  1))
                      
                      
                      ; (setq new_efname_1 (strcat (substr name_block_ 26 1)))
                    )
                  )
                  (setq i (+ i 1))
                )
                (setq new_efname_val (strcat (substr new_efname_  (strlen new_efname_) 5 ) (rtos get_array_distance 2 0)))
                (setq new_name_block_ (LM:StringSubst 
                                        new_efname_val 
                                        check_2222 
                                        name_block_ 
                                      )
                )
              
                (command "bsaveas" new_name_block_ )
                (command "_bclose" )
              ;
              ;insertion_block_process_
                (setq new_block_name new_name_block_  )
                (TA:set-block-blockscaling new_block_name acUniform)
                (setq replace_ename_ (car (entsel "specify Object")))
                (setq replace_obj_ (vlax-ename->vla-object replace_ename_))
                (if (= (vla-get-objectname replace_obj_) "AcDbBlockReference")
                  (progn
                    (setq replace_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint replace_obj_))))
                    (setq replace_obj_dynlist_ (LM:getdynprops replace_obj_))
                    (setq replace_obj_rotation_ (rad-to-deg (vla-get-rotation replace_obj_)) )
                  )
                )
                (command "insert" new_block_name  replace_obj_ins_ 0.001 replace_obj_rotation_ )
                (setq newblk_dyn_ename_ (entlast))
                (setq  newblk_dyn_obj_ (vlax-ename->vla-object  newblk_dyn_ename_))
                ;preloop_and_while
                  (setq replace_obj_dynlist_i 0)
                  (while (< replace_obj_dynlist_i (length replace_obj_dynlist_))
                    (setq replace_obj_dynlist_val_1 (car (nth  replace_obj_dynlist_i replace_obj_dynlist_)))
                    (setq replace_obj_dynlist_val_2 (cdr (nth  replace_obj_dynlist_i replace_obj_dynlist_)))
                    (if (and
                          (= (wcmatch replace_obj_dynlist_val_1 "Origin") nil)
                        )
                      (progn
                        (LM:setdynpropvalue newblk_dyn_obj_ replace_obj_dynlist_val_1 replace_obj_dynlist_val_2 )
                      )
                    )
                    
                    (setq replace_obj_dynlist_i (+ replace_obj_dynlist_i 1))
                  )
                ;
                (vla-delete replace_obj_)

              ;
              
            )
          )
        ;
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  )
  (defun c:BasePoint_to_BasePoint_[B2B] ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
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
                                          ; (cons 8 "000 - GRID")   ;kind of layer
                                          ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
    ;
    
    ;fillter_main_point_name_object_
    (setq main_point_ename_ERR_CHECK ;Detect the variable's result in case of a function error
      (vl-catch-all-apply 
        (function 
          (lambda () 
            (setq main_point_ename_ "No Selection BLock object")
            (while (= main_point_ename_ "No Selection BLock object")
              ;user_input_data
                (setq main_point_ename_ (car (entsel "specify Base Point Block Object")))
              ;
              ;fillter_object_type_
                (if 
                  (and
                    (if (/= main_point_ename_ nil) (progn (setq main_point_obj_ (vlax-ename->vla-object main_point_ename_)) ))
                      (= (vla-get-objectname main_point_obj_) "AcDbBlockReference")
                    )
                  (progn
                    (setq main_point_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint main_point_obj_))))
                  )
                  (setq main_point_ename_ nil)
                )
                (if
                  (or
                    (= main_point_ename_ nil)
                    (/= (vla-get-objectname main_point_obj_) "AcDbBlockReference")
                    
                  )
                  (progn
                    (= main_point_ename_ nil)
                    (alert "No selection Block object")
                  )
                )
              ;
            )
          )
        )
      )
    )
    (if (vl-catch-all-error-p main_point_ename_ERR_CHECK)
      (progn
        (setq detect_error_main_point_ename_ ;Detect the variable's result in case of a function error
          (wcmatch
            (strcase
              (vl-catch-all-error-message
                main_point_ename_detect_error
              )
            )
            "FUNCTION*,*ERROR*"
          )
        )
      )
      (setq detect_error_main_point_ename_ nil)
    )
    
    ;
    ;user_input_insertionpoint_for_move
      (setq user_input_ins_point_ERR_CHECK nil)
      (setq main_point_ename_ nil)
      (while 
        (and 
          (= main_point_ename_ nil)
          (= user_input_ins_point_ERR_CHECK nil)
        )
        (setq user_input_ins_point_ERR_CHECK ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq user_input_ins_point_ (getpoint "specify getpoint for new insertionpoint"))
              )
            )
          )
        )
        (cond
          (;blank_case_1
            (and
              (= user_input_ins_point_ERR_CHECK nil)
              (= user_input_ins_point_ nil)
            )
            (progn
              (setq main_point_ename_ nil)
              (setq user_input_ins_point_ERR_CHECK nil)
              (alert "Please selection insertionpoint for move")
              (princ "blank_case_1")
            )
          )
          (;blank_case_2
            (and
              (vl-catch-all-error-p user_input_ins_point_ERR_CHECK)
              (= user_input_ins_point_ nil)
            )
            (progn
              (setq main_point_ename_ nil)
              (setq user_input_ins_point_ERR_CHECK nil)
              (alert "Please selection insertionpoint for move")
              (princ "blank_case_2")
            )
          )
          (;have_Inspt
            (and 
              (= (numberp (car user_input_ins_point_)) T)
              (= (numberp (cadr user_input_ins_point_)) T)
            )
            (progn
              (setq main_point_ename_ "no block object")
              (princ "have_Inspt")
            )
          )
        )
        
      )
      (if 
        (and
          (= user_input_ins_point_ nil)
          (vl-catch-all-error-p user_input_ins_point_ERR_CHECK )
        )
        (progn
          (setq detect_error_user_input_ins_point_ ;Detect the variable's result in case of a function error
            (wcmatch
              (strcase
                (vl-catch-all-error-message
                  user_input_ins_point_ERR_CHECK
                )
              )
              "FUNCTION*,*ERROR*,*NIL*"
            )
          )
        )
      )
    ;
    ;main_idea_code
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (setvar "osmode" 0)
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          ;main_idea
            ;getins_data
            (setq ss_pre_filter_set_xx_hon_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
            (setq ss_pre_filter_set_xx_hon_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_hon_obj_))))
            ;
            ;put_move_data
            (cond
              (;user_input_ins_case_1
                (and
                    (= (numberp (car user_input_ins_point_)) T)
                    (= (numberp (cadr user_input_ins_point_)) T)
                )
                (progn
                  (vla-move ss_pre_filter_set_xx_hon_obj_ 
                            (vlax-3d-point ss_pre_filter_set_xx_hon_obj_ins_)
                            (vlax-3d-point user_input_ins_point_)
                  )
                  (princ "useinput_ins_case_1")
                )
              )
              (;Block_ins_case_2
                (and 
                  (= user_input_ins_point_ nil)
                  (= detect_error_user_input_ins_point_ T)
                )
                (progn  ;move to ins main block
                        (vla-move ss_pre_filter_set_xx_hon_obj_ 
                                  (vlax-3d-point ss_pre_filter_set_xx_hon_obj_ins_)
                                  (vlax-3d-point main_point_obj_ins_)
                        )
                        (setq user_input_ins_point_ nil)
                        (princ "useinput_ins_case_2")
                )
              )
            )
            
              
            ;
          ;
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
        (setvar "osmode" 1215)
      ;
    ;
  )
  (defun c:Replace_block_object_Reblock ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
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
    ;specify_object_for_filter_by_EFname_
      (setq Filter_target_ename_ (car (entsel "specify TA:EF_Filter_ss_set_ Object")))
      (setq Filter_target_obj_ (vlax-ename->vla-object Filter_target_ename_))
      (setq Filter_target_obj_EFname_ (LM:effectivename Filter_target_obj_))
      (setq ss_post_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ Filter_target_obj_EFname_))
    ;
    ;insert_target_object_process_
      (setq insert_target_ename_ (car (entsel "specify insert_target_ename_  Object")))
      (setq insert_target_obj_ (vlax-ename->vla-object insert_target_ename_))
      (setq insert_target_obj_EFname_ (LM:effectivename insert_target_obj_))
    ;
    ;preloop_and_while
      (setq ss_post_filter_set_xx_i 0)
      (setq ss_newset_ (ssadd))
      ; (sslength ss_newset)
      (while (< ss_post_filter_set_xx_i (sslength ss_post_filter_set_xx_))
        (setq ss_post_filter_set_xx_ename_ (ssname ss_post_filter_set_xx_ ss_post_filter_set_xx_i))
          (setq ss_post_filter_set_xx_hon_obj_ (vlax-ename->vla-object ss_post_filter_set_xx_ename_))
            (setq ss_post_filter_set_xx_hon_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_post_filter_set_xx_hon_obj_))))
            (setq ss_post_filter_set_xx_hon_obj_ro_ (vla-get-rotation ss_post_filter_set_xx_hon_obj_))
            (setvar "osmode" 0)
            (TA:vla-insertblock insert_target_obj_EFname_ ss_post_filter_set_xx_hon_obj_ins_ 1 ss_post_filter_set_xx_hon_obj_ro_ )
            (vla-delete ss_post_filter_set_xx_hon_obj_ )
            (setq new_obj_ (entlast ))
            (setq ss_newset_ (ssadd new_obj_ ss_newset_))
        
        (setq ss_post_filter_set_xx_i (+ ss_post_filter_set_xx_i 1))
      )
    ;

    ;preloop_and_while
      ;while_select_block_on_condition_
        ;first_cond_for_while_loop_input
          (setq getRO_ ;Detect the variable's result in case of a function error
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (setq getRO_RO_ (cond ( (getint (strcat "\nspecify get rotation\n<" (rtos (setq getRO_RO_ (cond (getRO_RO_) (1.0) ) ) ) "> : " ) ) ) (getRO_RO_) ) )
                )
              )
            )
          )
          (while ;start_while-loop_
            (and
              (numberp getRO_)
            )
            (setq ss_newset_i 0)
            (while (< ss_newset_i (sslength ss_newset_))
              (setq ss_newset_ename_ (ssname ss_newset_ ss_newset_i))
              (setq ss_newset_obj_ (vlax-ename->vla-object ss_newset_ename_))
              
              (vla-put-rotation ss_newset_obj_ (deg-to-rad getRO_))
              (setq ss_newset_i (+ ss_newset_i 1))

            )
            ;final_cond_for_while_loop_input_ (ESC for exit while-loop_)
              (setq getRO_ ;Detect the variable's result in case of a function error
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (setq getRO_RO_ (cond ( (getint (strcat "\nspecify get rotation\n<" (rtos (setq getRO_RO_ (cond (getRO_RO_) (1.0) ) ) ) "> : " ) ) ) (getRO_RO_) ) )
                    )
                  )
                )
              )
            ;
          )
        ;
      ;
    ;
    ;return_osmode_mode
      (setvar "osmode" 1279)
    ;
  )
  (defun TA:Assembly_block_ (blk_obj_ )
    ; (setq blk_ename_ (car (entsel "specify Object")))
    ; (setq blk_obj_ (vlax-ename->vla-object blk_ename_))
    (setq blk_list_ ())
    (if (= (vla-get-objectname blk_obj_) "AcDbBlockReference")
      (progn
        (setq blkname (cdr (assoc 2 (entget (vlax-vla-object->ename blk_obj_)))))
        (setq bdef (tblobjname "BLOCK" blkname))
        (if (= (vl-prin1-to-string (type bdef)) "ENAME")
          (progn
            (setq nested (entnext bdef))
            
            (while 
              (and nested 
                  (/= (cdr (assoc 0 (entget nested))) "ENDBLK")
              )
              (if (= (cdr (assoc 0 (entget nested))) "INSERT")
                (progn 


                  (setq nested_obj_ (vlax-ename->vla-object nested))
                  
                  (if (= (vla-get-visible nested_obj_) :vlax-true)
                    (progn
                      (princ (strcat "\n  └─ Nested block: " (LM:effectivename nested_obj_)) )
                      (setq blk_list_ (cons (LM:effectivename nested_obj_) blk_list_))
                    )
                  )
                  
                )
              )
              (setq nested (entnext nested))
            )
          )
        )
      )
    )
    (TA:Count_item_in_list_ blk_list_ )
    
  
  
  )
  (defun TA:Assembly_vla-obj-block_ (blk_obj_ )
    ; (setq blk_ename_ (car (entsel "specify Object")))
    ; (setq blk_obj_ (vlax-ename->vla-object blk_ename_))
    (setq blk_list_ ())
    (if (= (vla-get-objectname blk_obj_) "AcDbBlockReference")
      (progn
        (setq blkname (cdr (assoc 2 (entget (vlax-vla-object->ename blk_obj_)))))
        (setq bdef (tblobjname "BLOCK" blkname))
        (if (= (vl-prin1-to-string (type bdef)) "ENAME")
          (progn
            (setq nested (entnext bdef))
            
            (while 
              (and nested 
                  (/= (cdr (assoc 0 (entget nested))) "ENDBLK")
              )
              (if (= (cdr (assoc 0 (entget nested))) "INSERT")
                (progn 


                  (setq nested_obj_ (vlax-ename->vla-object nested))
                  
                  (if (= (vla-get-visible nested_obj_) :vlax-true)
                    (progn
                      (princ (strcat "\n  └─ Nested block: " (LM:effectivename nested_obj_)) )
                      (setq blk_list_ (cons nested_obj_ blk_list_))
                    )
                  )
                  
                )
              )
              (setq nested (entnext nested))
            )
          )
        )
      )
    )
    (TA:Count_item_in_list_ blk_list_ )
    
  
  
  )
  (defun TA:Assembly_ename_ (blk_obj_ )
    ; (setq blk_ename_ (car (entsel "specify Object")))
    ; (setq blk_obj_ (vlax-ename->vla-object blk_ename_))
    (setq blk_list_ ())
    (if (= (vla-get-objectname blk_obj_) "AcDbBlockReference")
      (progn
        (setq blkname (cdr (assoc 2 (entget (vlax-vla-object->ename blk_obj_)))))
        (setq bdef (tblobjname "BLOCK" blkname))
        (if (= (vl-prin1-to-string (type bdef)) "ENAME")
          (progn
            (setq nested (entnext bdef))
            
            (while 
              (and nested 
                  (/= (cdr (assoc 0 (entget nested))) "ENDBLK")
              )
              (if (= (cdr (assoc 0 (entget nested))) "INSERT")
                (progn 


                  (setq nested_obj_ (vlax-ename->vla-object nested))
                  
                  (if (= (vla-get-visible nested_obj_) :vlax-true)
                    (progn
                      (princ (strcat "\n  └─ Nested block: " (LM:effectivename nested_obj_)) )
                      (setq blk_list_ (cons nested blk_list_))
                    )
                  )
                  
                )
              )
              (setq nested (entnext nested))
            )
          )
        )
      )
    )
    (TA:Count_item_in_list_ blk_list_ )
    
  
  
  )
  (defun TA:Assembly_des-name-block_ (blk_obj_ )
    ; (setq blk_ename_ (car (entsel "specify Object")))
    ; (setq blk_obj_ (vlax-ename->vla-object blk_ename_))
    ; (setq blk_obj_ target_block_obj_)
    (setq blk_list_ ())
    (if (= (vla-get-objectname blk_obj_) "AcDbBlockReference")
      (progn
        (setq blk_ename_ (vlax-vla-object->ename blk_obj_) )
        (setq blkname (cdr (assoc 2 (entget blk_ename_))))
        (setq bdef (tblobjname "BLOCK" blkname))
        (if (= (vl-prin1-to-string (type bdef)) "ENAME")
          (progn
            (setq nested (entnext bdef))
            
            (while 
              (and nested 
                  (/= (cdr (assoc 0 (entget nested))) "ENDBLK")
              )
              (if (= (cdr (assoc 0 (entget nested))) "INSERT")
                (progn 


                  (setq nested_obj_ (vlax-ename->vla-object nested))
                  (setq block-editor_des-name (vla-get-comments (vla-Item (vla-get-Blocks (vla-get-ActiveDocument (vlax-get-acad-object))) (LM:effectivename nested_obj_))))
                  (if 
                    (and 
                      (= (vla-get-visible nested_obj_) :vlax-true)
                      (/= (LM:getvisibilityparametername nested_obj_) nil)
                      (LM:getdynpropvalue nested_obj_ (LM:getvisibilityparametername nested_obj_))
                    )
                    (progn
                      (princ (strcat "\n  └─ Nested block: " (LM:effectivename nested_obj_)) )
                      (setq blk_list_ (cons
                                        (strcat 
                                          (if (or (= block-editor_des-name nil) (= block-editor_des-name "")) (progn (LM:effectivename nested_obj_)) block-editor_des-name)
                                          (substr (LM:getdynpropvalue nested_obj_ (LM:getvisibilityparametername nested_obj_ ) ) 2 20 )
                                        ) 
                                        blk_list_
                                      )
                      )
                    
                    )
                  )
                  
                )
              )
              (setq nested (entnext nested))
            )
          )
        )
      )
    )
    (TA:Count_item_in_list_ blk_list_ )
  )
  (defun TA:Foreach_Assembly_des-name-block_ (blk_ename_)
    ;preloop_and_while
      (setq sub-block_ ())
      (setq sub-block_ename_ ())
      (setq blkname (cdr (assoc 2 (entget blk_ename_))))
      (setq bdef (tblobjname "BLOCK" blkname))
      (setq nested (entnext bdef))
      (while (/= nested nil )
        (if 
          (and 
            (= (vla-get-objectname (vlax-ename->vla-object nested)) "AcDbBlockReference")
            (= (vla-get-visible (vlax-ename->vla-object nested)) :vlax-true)
            (= (vla-get-isdynamicblock (vlax-ename->vla-object nested)) :vlax-true)
            (/= (LM:getdynpropvalue (vlax-ename->vla-object nested) (LM:getvisibilityparametername (vlax-ename->vla-object nested))) "")
          )
          (progn
            (setq sub-block_ (cons (LM:effectivename (vlax-ename->vla-object nested)) sub-block_))
            (setq sub-block_ename_(cons nested sub-block_ename_))
            ; (length sub-block_)
            ; (length sub-block_ename_)
          )
        )
        (setq nested (entnext nested))
      )
    ;
    (setq blk_list_ ())
    (foreach x sub-block_ename_
      (setq x_obj_ (vlax-ename->vla-object x))
      (princ (strcat "\n  └─ Nested block: " (LM:effectivename x_obj_)) )
      (setq block-editor_des-name (vla-get-comments (vla-Item (vla-get-Blocks (vla-get-ActiveDocument (vlax-get-acad-object))) (LM:effectivename x_obj_))))
      (setq blk_list_ (cons 
                        (strcat 
                          (if (or (= block-editor_des-name nil) (= block-editor_des-name "") ) (progn (LM:effectivename x_obj_)) block-editor_des-name )
                          (substr (LM:getdynpropvalue x_obj_ (LM:getvisibilityparametername x_obj_) ) 2 20 )
                        )
                        blk_list_
                      )
      )
    )
    (TA:Count_item_in_list_ blk_list_ )
  )
  (defun c:DynBlk_make_thread-bolt_mktbolt ()
    (setq visibility_list_              
      (list 
        "top_view"
        "top_view_x8mm."
        "top_view_x10mm."
        "top_view_x12mm."
        "top_view_x14mm."
        "top_view_x15mm."
        "top_view_x20mm."
        "top_view_x25mm."
        "top_view_x30mm."
        "top_view_x35mm."
        "top_view_x40mm."
        "top_view_x45mm."
        "top_view_x50mm."
        "top_view_x55mm."
        "top_view_x60mm."
        "top_view_x65mm."
        "top_view_x70mm."
        "hex-nut" 
        "x8mm." 
        "x10mm."
        "x12mm." 
        "x14mm." 
        "x15mm." 
        "x20mm." 
        "x25mm." 
        "x30mm." 
        "x40mm." 
        "x45mm." 
        "x50mm." 
        "x55mm." 
        "x60mm." 
        "x65mm." 
        "x70mm." 
        "x75mm." 
        "x80mm." 
        "x90mm." 
        "x100mm." 
      )
    )
    ;preloop_and_while
      (setq visibility_list_i 0)
      (while (< visibility_list_i (length visibility_list_))
        (setq visibility_list_ename_ (nth  visibility_list_i visibility_list_))
        (if (wcmatch visibility_list_ename_ "*mm.*")
          (progn
            (command "bvstate" "s" visibility_list_ename_ )
            (command "insert" "000 - PROTOTYPE-DYNAMIC_THREAD_BOLT" (list 0 0 0) 1 270 )
            ;get_new_entlast ename
              (setq new_blk_ename_ (entlast))
              (setq new_blk_obj_ (vlax-ename->vla-object new_blk_ename_))
            ;
            ;dyn_object_
              (LM:setdynpropvalue new_blk_obj_ "thread_dia."  5)
              (LM:setdynpropvalue new_blk_obj_ "array_width" (LM:StringSubst "" "mm." (LM:StringSubst "" "x" visibility_list_ename_ )) )
            ;
          )
        )
        (setq visibility_list_i (+ visibility_list_i 1))
      )
    ;
    
    
  )
  (defun c:MKblk () 
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq sstarget_ (ssget "i"
                                            (list
                                              ; (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
          nil
        )
        (progn
          (setq sstarget_ (ssget
                                            (list
                                              ; (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength sstarget_)
      )
    (setvar "osmode" 1215)
    ; (setq pttarget_ (getpoint "specify point for basepoint"))
    (setq ssssasas (TA:ss_vla-getboundingbox sstarget_))
    (setq pttarget_ (car ssssasas))
    (command "point" pttarget_)
    (setq pttarget_torr (list 
                      (+ (car (car ssssasas)) 0) ;ไม่เผื่อก็ ใส่ 0 ปกติใส่ 2.5 เผื่อใบตัด
                      (+ (cadr (car ssssasas)) 0) ;ไม่เผื่อก็ ใส่ 0 ปกติใส่ 2.5 เผื่อใบตัด
                      
                    )
    )
    
    (setvar "osmode" 1215)
    (setq namefile_ (getvar "dwgname"))
    (setq name_ename_ (car (entsel "specify EF name")))
    (setq name_obj_ (vlax-ename->vla-object name_ename_))
    (setq nameblk (LM:StringSubst 
                    ""
                    ","
                    (LM:StringSubst 
                      ""
                      ".dwg"
                      (strcat 
                        namefile_
                        "_"
                        ""
                        (LM:StringSubst "-" "/" (vla-get-textstring name_obj_))
                        ; (rtos (fix (* (car (TA:get_vertex_len_ (ssname sstarget_ 0))) 1000 ) ) 2 0 )
                        ; "mm."
                      )
                    )
                  )
    )
    (if 
      (or 
        (wcmatch
          (vl-princ-to-string
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-Item (vla-get-Blocks doc) nameblk)
                )
              )
            )
          )
          "*error*,*IAcadBlock*"
        )
      )
      (progn
        (if 
          (and
            (wcmatch
              (vl-princ-to-string
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (vla-delete (vla-Item (vla-get-Blocks doc) nameblk) )
      )
    )
                )
              )
              "*error*,*IAcadBlock*"
            )
          )
          (progn
            (command "_block" nameblk pttarget_torr sstarget_ "" )
            (TA:vla-insertblock nameblk pttarget_torr 1 0 )
          )
        )
      )
    )
    ; ;new_blk_entlast object
    ;   (setq sss_ename (entlast))
    ;   (setq sss_obj (vlax-ename->vla-object sss_ename))
    ;   (command "_copybase" pttarget_ sss_ename ""    )
    ; ;
  )
  (defun c:MKTblk () 
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq sstarget_ (ssget "i"
                                            (list
                                              ; (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
          nil
        )
        (progn
          (setq sstarget_ (ssget
                                            (list
                                              ; (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength sstarget_)
      )
    ;
    (setvar "osmode" 1215)
    (setq pttarget_torr (getpoint "specify point for basepoint"))
    ; (setq ssssasas (TA:ss_vla-getboundingbox sstarget_))
    ; (setq pttarget_ (car ssssasas))
    ; (setq pttarget_torr (list 
    ;                   (+ (car (car ssssasas)) 0) ;ไม่เผื่อก็ ใส่ 0 ปกติใส่ 2.5 เผื่อใบตัด
    ;                   (+ (cadr (car ssssasas)) 0) ;ไม่เผื่อก็ ใส่ 0 ปกติใส่ 2.5 เผื่อใบตัด
                      
    ;                 )
    ; )
    
    (setvar "osmode" 1215)
    (setq namefile_ (getvar "dwgname"))
    (setq nameblk (LM:StringSubst 
                    ""
                    ","
                    (LM:StringSubst 
                      ""
                      ".dwg"
                      (strcat 
                        namefile_
                        "_"
                        ""
                        (LM:StringSubst "-" "." (rtos (getvar "cdate") 2 6))
                        ; (rtos (fix (* (car (TA:get_vertex_len_ (ssname sstarget_ 0))) 1000 ) ) 2 0 )
                        ; "mm."
                        (getstring "input_subfix")
                      )
                    )
                  )
    )
    (if 
      (or 
        (wcmatch
          (vl-princ-to-string
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-Item (vla-get-Blocks doc) nameblk)
                )
              )
            )
          )
          "*error*,*IAcadBlock*"
        )
      )
      (progn
        (if 
          (and
            (wcmatch
              (vl-princ-to-string
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (vla-delete (vla-Item (vla-get-Blocks doc) nameblk) )
      )
    )
                )
              )
              "*error*,*IAcadBlock*"
            )
          )
          (progn
            (command "_block" nameblk pttarget_torr sstarget_ "" )
            (TA:vla-insertblock nameblk pttarget_torr 1 0 )
          )
        )
      )
    )
    ; ;new_blk_entlast object
    ;   (setq sss_ename (entlast))
    ;   (setq sss_obj (vlax-ename->vla-object sss_ename))
    ;   (command "_copybase" pttarget_ sss_ename ""    )
    ; ;
  )
  (defun c:MKBREAL () 
    (setvar "osmode" 0)
    (setq sstarget_ (ssadd))
    (setq namefile_ (getvar "dwgname"))
    (setq nameblk_ename_ (car (entsel "specify Object")))
    (setq sstarget_ (ssadd nameblk_ename_ sstarget_))
    (setq nameblk_obj_ (vlax-ename->vla-object nameblk_ename_))
    (setq nameblk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint nameblk_obj_))))
    (setq nameblk (vla-get-textstring nameblk_obj_))
    
    (if 
      (or 
        (wcmatch
          (vl-princ-to-string
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-Item (vla-get-Blocks doc) nameblk)
                )
              )
            )
          )
          "*error*,*IAcadBlock*"
        )
      )
      (progn
        (if 
          (and
            (wcmatch
              (vl-princ-to-string
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (vla-delete (vla-Item (vla-get-Blocks doc) nameblk))
                    )
                  )
                )
              )
              "*error*,*IAcadBlock*"
            )
          )
          (progn
            (command "_block" nameblk nameblk_obj_ins_ sstarget_ "" )
            (TA:vla-insertblock nameblk nameblk_obj_ins_ 1 0 )
          )
        )
      )
    )
    (setvar "osmode" 1215)
    ; ;new_blk_entlast object
    ;   (setq sss_ename (entlast))
    ;   (setq sss_obj (vlax-ename->vla-object sss_ename))
    ;   (command "_copybase" pttarget_ sss_ename ""    )
    ; ;
  )
  (defun c:MKPartBLK_MKP2 () 
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq sstarget_ (ssget "i"
                                            (list
                                              ; (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
          nil
        )
        (progn
          (setq sstarget_ (ssget
                                            (list
                                              ; (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength sstarget_)
      )
    (setvar "osmode" 1215)
    (setq pttarget_ (getpoint "specify point for basepoint"))
    ; (setq ssssasas (TA:ss_vla-getboundingbox sstarget_))
    ; (setq pttarget_ (car ssssasas))
    ; (command "point" pttarget_)
    (setq pttarget_torr (list 
                      (+ (car pttarget_) 0)
                      (+ (cadr pttarget_) 0)
                      
                    )
    )
    
    (setvar "osmode" 1215)
    (setq namefile_ (getvar "dwgname"))
    (setq name_ename_ (car (entsel "specify EF name")))
    (setq name_obj_ (vlax-ename->vla-object name_ename_))
    (setq nameblk (LM:StringSubst 
                    ""
                    ","
                    (LM:StringSubst 
                      ""
                      ".dwg"
                      (strcat 
                        namefile_
                        "_"
                        ""
                        (LM:StringSubst "-" "/" (vla-get-textstring name_obj_))
                        "_Blanksize-PL"
                        ; (rtos (fix (* (car (TA:get_vertex_len_ (ssname sstarget_ 0))) 1000 ) ) 2 0 )
                        ; "mm."
                      )
                    )
                  )
    )
    (if 
      (or 
        (wcmatch
          (vl-princ-to-string
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-Item (vla-get-Blocks doc) nameblk)
                )
              )
            )
          )
          "*error*,*IAcadBlock*"
        )
      )
      (progn
        (if 
          (and
            (wcmatch
              (vl-princ-to-string
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (vla-delete (vla-Item (vla-get-Blocks doc) nameblk) )
                    )
                  )
                )
              )
              "*error*,*IAcadBlock*"
            )
          )
          (progn
            (command "_block" nameblk pttarget_torr sstarget_ "" )
            (TA:vla-insertblock nameblk pttarget_torr 1 0 )
          )
        )
      )
    )
    ; ;new_blk_entlast object
    ;   (setq sss_ename (entlast))
    ;   (setq sss_obj (vlax-ename->vla-object sss_ename))
    ;   (command "_copybase" pttarget_ sss_ename ""    )
    ; ;
  )
  (if (= 1 2) ;vvvvvv
    (progn
      (setq ss_ename_ (car (entsel "specify Object")))
      (setq ss_obj_ (vlax-ename->vla-object ss_ename_))
      (TA:Assembly_des-name-block_ ss_obj_)
      
    )
  )
  (defun c:make_cutting_plan_addATT ()
    
    (command "-attdef" "L" "" "FULL_SIZE_NO." "" "----" "S" "TA" "J" "MC" 0 0 0)
    ;new_blk_entlast object
      (setq att_ename (entlast))
      (setq att_obj_ (vlax-ename->vla-object att_ename))
      (vla-put-alignment att_obj_  12)
      (vla-put-textalignmentpoint att_obj_ (vlax-3d-point 0.02 0.02 0))
      (vla-put-height att_obj_ 0.1)
      (vla-put-lockposition  att_obj_ -1)

    ;
    (command "-attdef" "L" "" "ON_PANEL_SIZE_NO." "" "----" "S" "TA" "J" "BL" att_xyz-ins 0  )
    ;new_blk_entlast object
      (setq att_ename (entlast))
      (setq att_obj_ (vlax-ename->vla-object att_ename))
      (vla-put-alignment att_obj_  12)
      (vla-put-textalignmentpoint att_obj_ (vlax-3d-point 0.02 0.2 0))
      (vla-put-height att_obj_ 0.1)
      (vla-put-lockposition  att_obj_ -1)

    ;
    (command "-attdef" "L" "" "QTY." "" "----" "S" "TA" "J" "BL" att_xyz-ins 0  )
    ;new_blk_entlast object
      (setq att_ename (entlast))
      (setq att_obj_ (vlax-ename->vla-object att_ename))
      (vla-put-alignment att_obj_  12)
      (vla-put-textalignmentpoint att_obj_ (vlax-3d-point 0.4 0.4 0))
      (vla-put-height att_obj_ 0.1)
      (vla-put-lockposition  att_obj_ -1)

    ;

  )
  (defun c:make_cutting_plan_dyndip ()
    (setq pt (getpoint "inputpoint"))
    (setvar "osmode" 0)
    (TA:vla-insertblock "000 - DYNAMIC SYMBOL DIRECTION PAINT" pt 50 0 )
    (setvar "osmode" 1215)
    ; ;new_blk_entlast object
    ;   (TA:vla-insertblock "000 - DYNAMIC SYMBOL DIRECTION PAINT" pt 1 0 )
    ;   (setq sym_ename (entlast))
    ;   (setq sym_obj (vlax-ename->vla-object sym_ename))
    ;   (setq pt2 (polar pt (deg-to-rad 90) 2))
    ; ;

    ;new_blk_entlast object
      (command "_bparameter" "R" pt 4 "0" "" 1)
      
      (command "_bparameter" "L" pt pt2 pt2 1)
      (command "BACTIONTOOL"  "R"    )
      (command "BACTIONTOOL"  "T"    )          
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
      (defun TA:GetClipboardText ( / htmlfile clipObj result)
        (setq htmlfile (vlax-create-object "htmlfile"))
        (setq clipObj  (vlax-get (vlax-get htmlfile 'ParentWindow) 'ClipBoardData))
        (setq result   (vlax-invoke clipObj 'GetData "Text"))
        (vlax-release-object htmlfile)
        result
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

(defun TA:ChangeFont ( / styName newFont styObj)    
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
(defun c:loadlisp ()
  (cond
    ((and 
          (= (getenv "COMPUTERNAME") "NONGSAISUEARAI")
          (= (getenv "USERNAME") "popul")
        )
      (progn
        (setq Er-msg_ (vl-catch-all-apply (function (lambda () (load "C:/TA compelete github/TA_COMPELETE/COMPELETE NEXT 2025/Z73-Tranference_Autocad-Excel_data.lsp") ) ) ) )
        (setq Er-msg_1 (vl-catch-all-apply (function (lambda () (load "C:/TA compelete github/TA_COMPELETE/COMPELETE NEXT 2025/REWORK DIM/z62x_REWORK_DIMENSION_REV02.lsp") ) ) ) )
        (setq Er-msg_1 (vl-catch-all-apply (function (lambda () (load "C:/TA compelete github/TA_COMPELETE/COMPELETE IN COMPELETE/SFB_FINDING_SPECFILY_NAME_BLOCK.lsp") ) ) ) )
        (setq Er-msg_1 (vl-catch-all-apply (function (lambda () (load "C:/TA compelete github/TA_COMPELETE/000 - automation_cad.lsp") ) ) ) )
      )
    )
    ((and 
       (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI")
       (= (getenv "USERNAME") "Admin")
     )
      (progn
        (setq Er-msg_ (vl-catch-all-apply (function (lambda () (load "C:/Users/Admin/Documents/GitHub/TA_COMPELETE/COMPELETE NEXT 2025/Z73-Tranference_Autocad-Excel_data.lsp") ) ) ) )
        (setq Er-msg_1 (vl-catch-all-apply (function (lambda () (load "C:/Users/Admin/Documents/GitHub/TA_COMPELETE/COMPELETE NEXT 2025/REWORK DIM/z62x_REWORK_DIMENSION_REV02.lsp") ) ) ) )
        (setq Er-msg_1 (vl-catch-all-apply (function (lambda () (load "C:/Users/Admin/Documents/GitHub/TA_COMPELETE/COMPELETE IN COMPELETE/SFB_FINDING_SPECFILY_NAME_BLOCK.lsp") ) ) ) )
      )
    )
  )
)
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
  (defun c:Plotter_CKST_CSD-R-PLOT ()
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
            "extents" ;Plot Area
            ; (nth 0 main_bol) ;vla-getboundingbox
            ; (nth 2 main_bol) ;vla-getboundingbox
            ;llpt				;Lower left corner of window
            ;urpt				;Upper right corner of window
            "Fit" ;Plot Scale	"Fit"
            "Center" ;Plot Offset
            "yes" ;Use Plot Style?
            "A3_Standard (MRT-AGATE) - purple line - for CSD.ctb" ;Plot Style Name
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
  (defun c:Plotter_CKST_CSD3plot ()
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
            (or
              ; (= (sslength ss_pre_filter_set_xx_) 1)
              (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat "*" (strcase "Title Block_Under Ground_C1 v3") "*"))  T)
              (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat "*" (strcase "Title Block_Under Ground_C2 v3") "*"))  T)
              
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
  (defun c:Auto_page_AU1PAGE (  )
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
    ;detect and delete ex mtext 
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_mtext_detect_ (ssget "x"
                                              (list
                                                (cons 0 "mtext") ;type of object
                                                (cons 410 (getvar "CTAB"))
                                                (cons 8 "G-ANNO-TTLB,G-ANNO-SCHD")   ;kind of layer
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
                                                (cons 8 "G-ANNO-TTLB,G-ANNO-SCHD")   ;kind of layer
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
                (= (wcmatch ss_mtext_detect_obj_textstring "*PP20*,*-2025*,*-2024*,C,B,A,*-25*,*-24*,*CRD UPDATED*,*FIRST SUBMISSION CRD*,SRB,AJT,LCC,PSE,OYT,CRD,PPP" ) T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*STATION*,*.rvt*,*Autodesk*" ) T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*PP20 :*") T )
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
            (command "_block" "000 - TA AUTO PAGE" circle_obj_inscen_ circle_ename "" )
            (setvar "BLOCKREDEFINEMODE" 1)
            (command "-INSERTCONTENT" 
                      (cond 
                        ((and 
                          (= (getenv "COMPUTERNAME") "NONGSAISUEARAI")
                          (= (getenv "USERNAME") "popul")
                        )
                        (progn 
                          "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\PP19\\CAD\\C-1-PP19-AR-4130-01-B.dwg"
                        )
                        )
                        ((and 
                          (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI")
                          (= (getenv "USERNAME") "Admin")
                        )
                        (progn 
                          "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\PP17\\CAD\\C-1-PP17-AR-4180-01-B.dwg")
                        )
                      )
                    "000 - TA AUTO PAGE" 
                    circle_obj_inscen_ 1 1 0 "" "" "" "" 
            )
            (setvar "BLOCKREDEFINEMODE" 1)
            (command "erase" "L" "")
          ;

        )
      )
    ;
    ;insert - process
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
      (if (wcmatch (vl-princ-to-string (vl-catch-all-apply (function (lambda () (vla-Item (vla-get-Blocks doc) "000 - TA AUTO PAGE")) ) ) ) "*IAcadBlock*" )
        (progn
          ;get-file-name_data_mode_
            ;pre-settting
              (setq filter_string_list_ (list "*C-2-Pp*"))
              (setq current_filepath (getvar "dwgprefix"))
              (setq current_filename (getvar "dwgname"))
              (setq current_file_folder_list_ (vl-directory-files current_filepath "*.dwg"))
              (setq list_data_ current_file_folder_list_)
              (setq new_list_data_ ())
            ;
              (setq true_list_data_ (vl-sort (reverse (TA:wcmatch_list (list "*C-2-PP*") current_file_folder_list_ T)) '<))
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
              (vla-put-color sss_obj_ 2)
              (LM:vl-setattributevalue sss_obj_ "DATE_VAL" (strcat 
                                                            (substr (rtos (getvar "cdate" ) 2 0) 7 2)
                                                            "-"
                                                            (substr (rtos (getvar "cdate" ) 2 0) 5 2)
                                                            "-"
                                                            (substr (rtos (getvar "cdate" ) 2 0) 1 4)
                                                          )
              )
              (LM:vl-setattributevalue sss_obj_ "STATUS_VAL" "W" )
              (LM:vl-setattributevalue 
                sss_obj_
                "SHEET_VAL"
                (LM:StringSubst 
                  ""
                  "1-A"
                  (LM:StringSubst 
                    ""
                    "-B"
                    (LM:StringSubst 
                      ""
                      "C-"
                      (LM:StringSubst 
                        ""
                        ".dwg"
                        current_filename
                      )
                    )
                  )
                )
              )
              (LM:vl-setattributevalue sss_obj_ "REVISION_VAL" "A" )
              (LM:vl-setattributevalue sss_obj_ "SHEET_NO_VAL" (strcat 
                                                              (rtos (if (= true_list_data_index_val_ 0 ) (progn 1 ) (+ true_list_data_index_val_ 1 ) )  2 0)
                                                              "/"
                                                              (rtos true_list_data_length_ 2 0)
                                                            ) 
              )
              (LM:vl-setattributevalue sss_obj_ "REVISION_VAL_IS_1" "A" )
              (LM:vl-setattributevalue sss_obj_ "DATE_VAL_IS_1" (strcat 
                                                                  (substr (rtos (getvar "cdate") 2 0 ) 7 2 )
                                                                  "-"
                                                                  (substr (rtos (getvar "cdate") 2 0 ) 5 2 )
                                                                  "-"
                                                                  (substr (rtos (getvar "cdate") 2 0 ) 1 4 )
                                                                ) 
              )
              (LM:vl-setattributevalue sss_obj_ "REVISION_TEXT_VAL_IS_1" "FIRST SUBMISSION" )
              (if (= (wcmatch current_filename "*-AR-41*") T)
                (progn
                  (LM:setdynpropvalue sss_obj_ "view" "1_")
                )
              )
              (if (= (wcmatch current_filename "*-AR-42*") T)
                (progn
                  (LM:setdynpropvalue sss_obj_ "view" "2_")
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
    (command "pasteclip" (setq ss (list 468.5 59 0)) )
    (command "zoom" "e")
    (command "qsave" )
  )
  (defun c:update_up1auto_ ()
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
    ;detect and delete ex mtext 
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_mtext_detect_ (ssget "x"
                                              (list
                                                (cons 0 "mtext") ;type of object
                                                (cons 410 (getvar "CTAB"))
                                                (cons 8 "G-ANNO-TTLB,G-ANNO-SCHD,G-ANNO-REVC-IDEN")   ;kind of layer
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
                                                (cons 8 "G-ANNO-TTLB,G-ANNO-SCHD,G-ANNO-REVC-IDEN")   ;kind of layer
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
                (= (wcmatch ss_mtext_detect_obj_textstring "*PP20*,*-2025*,*-2024*,C,B,A,*-25*,*-24*,*CRD UPDATED*,*FIRST SUBMISSION CRD*,SRB,AJT,LCC,PSE,OYT,CRD,PPP" ) T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*STATION*,*.rvt*,*Autodesk*" ) T )
                (/= (wcmatch ss_mtext_detect_obj_textstring "*PP20 :*") T )
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
    (setq circle_obj_inscen_ (list 0.5000000 -1.0000000 0))
    (command "-INSERTCONTENT" 
            (cond 
              ((and 
                (= (getenv "COMPUTERNAME") "NONGSAISUEARAI")
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\PP19\\CAD\\C-1-PP19-AR-4130-01-B.dwg"
              )
              )
              ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI")
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\PP17\\CAD\\C-1-PP17-AR-4180-01-B.dwg")
              )
            )
          "000 - TA AUTO PAGE" 
          circle_obj_inscen_ 1 0 0 "" "" "" "" 
    )
    (command "erase" "L" "")
     
    ;insert - process
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
      (if (wcmatch (vl-princ-to-string (vl-catch-all-apply (function (lambda () (vla-Item (vla-get-Blocks doc) "000 - TA AUTO PAGE")) ) ) ) "*IAcadBlock*" )
        (progn
          ;get-file-name_data_mode_
            ;pre-settting
              (setq filter_string_list_ (list "*C-2-Pp*"))
              (setq current_filepath (getvar "dwgprefix"))
              (setq current_filename (getvar "dwgname"))
              (setq current_file_folder_list_ (vl-directory-files current_filepath "*.dwg"))
              (setq list_data_ current_file_folder_list_)
              (setq new_list_data_ ())
            ;
              (setq true_list_data_ (vl-sort (reverse (TA:wcmatch_list (list "*C-2-PP*") current_file_folder_list_ T)) '<))
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
                (if
                  (and
                    ; (= (sslength ss_pre_filter_set_xx_) 1)
                    (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat 
                                                                                          "*" (strcase "M_Revision Tag - M_Revision Ta") "*" 
                                                                                          "*" (strcase "DPA_AN_Revision T") "*" 
                                                                                        )
                       )  
                       T
                    )
                    
                  )
                  (progn
                    (vla-delete ss_pre_filter_set_xx_obj_)
                  )
                )
                (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
              )
            ; 
          ;
          ;insert block process
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
              (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - TA AUTO PAGE"))
            ;
            ;new_blk_entlast object

              (setq sss_ename (ssname ss_pre_filter_set_xx_ 0))
              (command "attsync" "n" "000 - TA AUTO PAGE")
              (setq sss_obj_ (vlax-ename->vla-object sss_ename))
              (setq sss_obj_ (vlax-ename->vla-object sss_ename))
              (vla-put-color sss_obj_ 2)
              (LM:vl-setattributevalue sss_obj_ "DATE_VAL" (strcat 
                                                            (substr (rtos (getvar "cdate" ) 2 0) 7 2)
                                                            "-"
                                                            (substr (rtos (getvar "cdate" ) 2 0) 5 2)
                                                            "-"
                                                            (substr (rtos (getvar "cdate" ) 2 0) 1 4)
                                                          )
              )
              (LM:vl-setattributevalue sss_obj_ "STATUS_VAL" "W" )
              (LM:vl-setattributevalue 
                sss_obj_
                "SHEET_VAL"
                (LM:StringSubst 
                  ""
                  "1-A"
                  (LM:StringSubst 
                    ""
                    "-B"
                    (LM:StringSubst 
                      ""
                      "C-"
                      (LM:StringSubst 
                        ""
                        ".dwg"
                        current_filename
                      )
                    )
                  )
                )
              )
              (LM:vl-setattributevalue sss_obj_ "REVISION_VAL" "A" )
              (LM:vl-setattributevalue sss_obj_ "SHEET_NO_VAL" (strcat 
                                                              (rtos (if (= true_list_data_index_val_ 0 ) (progn 1 ) (+ true_list_data_index_val_ 1 ) )  2 0)
                                                              "/"
                                                              (rtos true_list_data_length_ 2 0)
                                                            ) 
              )
              (LM:vl-setattributevalue sss_obj_ "REVISION_VAL_IS_1" "A" )
              (LM:vl-setattributevalue sss_obj_ "DATE_VAL_IS_1" (strcat 
                                                                  (substr (rtos (getvar "cdate") 2 0 ) 7 2 )
                                                                  "-"
                                                                  (substr (rtos (getvar "cdate") 2 0 ) 5 2 )
                                                                  "-"
                                                                  (substr (rtos (getvar "cdate") 2 0 ) 1 4 )
                                                                ) 
              )
              (LM:vl-setattributevalue sss_obj_ "REVISION_TEXT_VAL_IS_1" "FIRST SUBMISSION" )
              (if (= (wcmatch current_filename "*-AR-41*") T)
                (progn
                  (LM:setdynpropvalue sss_obj_ "view" "1_")
                )
              )
              (if (= (wcmatch current_filename "*-AR-42*,*-AR-43*") T)
                (progn
                  (LM:setdynpropvalue sss_obj_ "view" "2_")
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
    
    (command "pasteclip" (setq ss (list 468.5 59 0)) )
    
    
    (setq Er-msg_ 
      (vl-catch-all-apply 
        (function 
          (lambda () 
            (if (= (setq detectloop (getstring "enter to save files")) "" ) (progn  (command "zoom" "E") (command "qsave") (command "close")) )
          )
        )
      )
    )
  )
  (defun c:ADDFLLOGO ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_mtext_ (ssget "x"
                                            (list
                                              (cons 0 "MTEXT") ;type of object
                                              (cons 8 "G-ANNO-TEXT")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              (cons 62 7)           ;kind of color call sign with color code index
                                                         ;kind of color call sign with color code index
                                              (cons 410 "model")
                                            )
                                      )
          )
          nil
        )
        (progn
          (setq ss_pre_mtext_ (ssget 
                                (list 
                                  (cons 0 "MTEXT") ;type of object
                                  (cons 8 "G-ANNO-TEXT") ;kind of layer
                                  ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                  (cons 62 7) ;kind of color call sign with color code index
                                  (cons 410 "model")
                                )
                              )
          )
        )
      )
    ;
    ;preloop_and_while
      (setq ss_pre_mtext_i 0)
      (setq ss_post_mtext_ (ssadd))
      (while (< ss_pre_mtext_i (sslength ss_pre_mtext_))
        (setq ss_pre_mtext_ename_ (ssname ss_pre_mtext_ ss_pre_mtext_i))
        (setq ss_pre_mtext_obj_ (vlax-ename->vla-object  ss_pre_mtext_ename_))
        (if (or 
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "\LNOTES :" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "1  ALL DIMENSIONS IN MILLIMETRES UNLESS NOTED OTHERWISE" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "2  LEVELS ARE INDICATED IN METRES RELATIVE TO A DATUM 100M BELOW MEAN SEA LEVEL (MSL)" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "3  DRAWING TO SCALE WHEN PLOTTED AT A1" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "4  DO NOT SCALE FROM DRAWIN" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "5  ARCHITECTURAL DRAWINGS TO BE READ IN CONJUNCTION WITH STRUCTURAL DRAWINGS" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "E & M DRAWINGS" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "6  FOR STRUCTURAL SETTING OUT DIMENSIONS REFER STRUCTURAL DRAWINGS" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "7  FOR DRAINAGE DETAILS REFER DRAINAGE DRAWINGS" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "8  DIMENSIONS SHOWN IN GENERAL ARRANGEMENT" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "9  DIMENSIONS SHOWN FROM DIAPHRAGM" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "INDICATED. DIMENSIONS SHOWN" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "STRUCTURAL TOLERAN" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "10 FOR ROOM FINISHES REFER ARCHITECTURAL PARTICULAR SPECIFICATIONS" "*")) T )
              (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "11 BLOCKWORK" "*")) T )
            )
          (progn
            (vla-put-backgroundfill ss_pre_mtext_obj_ :vlax-false)
            (setq ss_post_mtext_ (ssadd ss_pre_mtext_ename_ ss_post_mtext_ ))
            (if (= (wcmatch (vla-get-textstring ss_pre_mtext_obj_) (strcat "*" "\LNOTES :" "*")) T )
              (progn
                (vlax-dump-object ss_pre_mtext_obj_)
              )
            )
          )
        )
        (setq ss_pre_mtext_i (+ ss_pre_mtext_i 1))
      )
    ;
    (command "pselect"  ss_post_mtext_ "" )
  )
  (defun c:PPLINE_CKST_REWORK-TTB_ ()
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
    ;
    ;get ex data_
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (setq External_ref_ename_ ())
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (if
            (and
              ; (= (sslength ss_pre_filter_set_xx_) 1)
              (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat "*" (strcase "000 - TA AUTO") "*"))  T)
            )
            (progn
              (setq ss_pre_filter_set_xx_ename_auto_ ss_pre_filter_set_xx_ename_ )
              (setq SHEET_VAL (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "SHEET_VAL"))
              (setq SHEET_NO_VAL (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "SHEET_NO_VAL"))
              (setq REVISION_VAL (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "REVISION_VAL"))
              (setq STATUS_VAL (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "STATUS_VAL"))
              (setq DATE_VAL (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "DATE_VAL"))
              (setq DATE_VAL_IS_1 (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "DATE_VAL_IS_1"))
              (setq REVISION_VAL_IS_1 (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "REVISION_VAL_IS_1"))
              (setq REVISION_TEXT_VAL_IS_1 (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "REVISION_TEXT_VAL_IS_1"))
              
            )
          )
          (if
            (and
              ; (= (sslength ss_pre_filter_set_xx_) 1)
              (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcat "*" (strcase "ACM_Titleblock_MRTA") "*"))  T)
            )
            (progn
              (setq ss_pre_filter_set_xx_ename_TTB_ ss_pre_filter_set_xx_ename_ )
            )
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    ;
    ;get mtext title block
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "x"
                                              (list 
                                                (cons 0 "mtext") ;type of object
                                                (cons 7 "Arial_7,Arial_8,Arial_9,Arial_10")   ;kind of layer
                                                (cons 8 "G-ANNO-TTLB")   ;kind of layer
                                                (cons 410 (getvar "CTAB"))
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
                                                (cons 0 "mtext") ;type of object
                                                (cons 7 "Arial_7,Arial_8,Arial_9,Arial_10")   ;kind of layer
                                                (cons 8 "G-ANNO-TTLB")   ;kind of layer
                                                (cons 410 (getvar "CTAB"))
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
        (setq ss_pre_filter_set_xx_obj_ins_list_ ())
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_)) 
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
          (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
          (setq ss_pre_filter_set_xx_obj_textstr_ (vla-get-textstring ss_pre_filter_set_xx_obj_  ))
          (if (or
                (= (= ss_pre_filter_set_xx_obj_textstr_ "1") T)
                (= (= ss_pre_filter_set_xx_obj_textstr_ "2") T)
                (= (wcmatch ss_pre_filter_set_xx_obj_textstr_ "*PP*,*STATION*,*ENLARGEED*,*REFLECTED*,*PLAN*,*SHEET*") T)
              )
            (progn
              
          (setq ss_pre_filter_set_xx_obj_ins_list_ 
            (cons 
              (list 
                ss_pre_filter_set_xx_obj_textstr_
                ss_pre_filter_set_xx_obj_ins_
              )
              ss_pre_filter_set_xx_obj_ins_list_
            )
          )
          )
          
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
        ;TA:stanndard_lambda_sorting
          (setq ss_pre_filter_set_xx_obj_ins_list_sorted_ (vl-sort ss_pre_filter_set_xx_obj_ins_list_  ;bigest open indent list
                                                    (function 
                                                      (lambda (a b) 
                                                        (> (nth 1 (cadr a)) (nth 1 (cadr b)))
                                                      )
                                                    )
                                ) ;bigest close indent list
          )
          (setq contact_no (car (nth 0 ss_pre_filter_set_xx_obj_ins_list_sorted_)))
          (setq title_1 (car (nth 1 ss_pre_filter_set_xx_obj_ins_list_sorted_)))
          (setq title_2 (car (nth 2 ss_pre_filter_set_xx_obj_ins_list_sorted_)))
          (setq title_3 (car (nth 3 ss_pre_filter_set_xx_obj_ins_list_sorted_)))
        ;
      ;
      
    ;
    ;creating block process
      (if (= 
            (wcmatch (vl-princ-to-string (vl-catch-all-apply (function (lambda () 
                                                                         (vla-Item 
                                                                           (vla-get-Blocks 
                                                                             (setq doc ( vla-get-ActiveDocument ( vlax-get-acad-object ) ) )
                                                                           ) 
                                                                           "Title Block_Under Ground_C1 v3"
                                                                         )
                                                                       ) 
                                                             ) 
                                         ) 
                     ) "*IAcadBlock*" 
            )
            nil
          )
        (progn
          (setvar "osmode" 0)
          (command "circle" (list 0 0 0) 10 "" ) 
          ;new_blk_entlast object
            (setq circle_ename (entlast))
            (setq circle_obj (vlax-ename->vla-object circle_ename))
            (setq circle_obj_inscen_ (vlax-safearray->list (vlax-variant-value (vla-get-center circle_obj ))))
            (command "_block" "Title Block_Under Ground_C1 v3" circle_obj_inscen_ circle_ename "" )
            ; (TA:vla-insertblock "Title Block_Under Ground_C1 v3" circle_obj_inscen_ 1 0 )
            (TA:set-block-blockscaling "Title Block_Under Ground_C1 v3" acUniform )
            (setvar "BLOCKREDEFINEMODE" 1)
            (command "-INSERTCONTENT" 
                  (cond 
                    ((and 
                        (= (getenv "COMPUTERNAME") 
                          "NONGSAISUEARAI"
                        )
                        (= (getenv "USERNAME") "popul")
                      )
                      (progn 
                        "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
                      )
                    )
                    ((and 
                        (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                        (= (getenv "USERNAME") "Admin")
                      )
                      (progn 
                        "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
                      )
                    )
                  )
                  "Title Block_Under Ground_C1 v3"
                  circle_obj_inscen_
                  1
                  0
                  "" "" "" "" "" 
                  "" "" "" "" "" 
                  "" "" "" "" "" 
                  "" "" "" "" "" 
                  "" "" "" "" "" 
                  "" "" "" "" "" 
                  "" "" "" "" "" 
                  "" "" "" "" "" 
                  "" "" "" "" "" 
            )
            

          ;
        )
        (TA:vla-insertblock "Title Block_Under Ground_C1 v3" (list 0 0 0) 1 0 )
      )
    ;
    ;new_blk_entlast object
      (setq new_WD-TTB_ename (entlast))
      (setq new_WD-TTB_obj_ (vlax-ename->vla-object new_WD-TTB_ename))
      (LM:setdynpropvalue new_WD-TTB_obj_ "paper size" "A1" )
      (LM:vl-setattributevalue new_WD-TTB_obj_ "contact_working_val" 
        (cond
          ( (= contact_no "1")
          (progn
            "CONTRACT 1 : UNDERGROUND CIVIL WORKS"
          )
          )
          ( (= contact_no "2")
            (progn
              "CONTRACT 2 : UNDERGROUND CIVIL WORKS"
            )
          )
        )
      )
      (LM:vl-setattributevalue new_WD-TTB_obj_ "title_1_val"  (if (= title_1 nil) (progn "" ) title_1 ))
      (LM:vl-setattributevalue new_WD-TTB_obj_ "title_2_val"  (if (= title_2 nil) (progn "" ) title_2))
      (LM:vl-setattributevalue new_WD-TTB_obj_ "title_3_val"  (if (= title_3 nil) (progn "" ) title_3))
      (LM:vl-setattributevalue new_WD-TTB_obj_ "status_val"  "w")
      (LM:vl-setattributevalue 
        new_WD-TTB_obj_
        "drawing_no_val"
        (LM:StringSubst 
          ""
          "1-A"
          (LM:StringSubst 
            ""
            "-B"
            (LM:StringSubst 
              ""
              "C-"
              (LM:StringSubst 
                ""
                ".dwg"
                (getvar "dwgname")
              )
            )
          )
        )
      )
      (LM:vl-setattributevalue 
        new_WD-TTB_obj_
        "designed_by_date_val"
        (strcat (substr (rtos (getvar "cdate") 2 0) 7 2) 
                "-"
                (substr (rtos (getvar "cdate") 2 0) 5 2)
                "-"
                (substr (rtos (getvar "cdate") 2 0) 1 4)
        )
      )
      
      (LM:vl-setattributevalue new_WD-TTB_obj_ "rev_no_val" "A" )
      (LM:vl-setattributevalue new_WD-TTB_obj_ "sheet_no_val" "-" )
      (LM:vl-setattributevalue new_WD-TTB_obj_ "scale_for_a1_val" "A1 = 1:500" )
      (LM:vl-setattributevalue new_WD-TTB_obj_ "dwg_scale_val" "A3 = 1:1000" )
      (LM:vl-setattributevalue new_WD-TTB_obj_ "units_val" "mm." )
    ;
    ;get mtext title block for del
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "x"
                                              (list 
                                                (cons 0 "mtext") ;type of object
                                                ; (cons 7 "Arial_7,Arial_8")   ;kind of layer
                                                (cons 8 "G-ANNO-TTLB")   ;kind of layer
                                                (cons 410 (getvar "CTAB"))
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
                                                (cons 0 "mtext") ;type of object
                                                ; (cons 7 "Arial_7,Arial_8")   ;kind of layer
                                                (cons 8 "G-ANNO-TTLB")   ;kind of layer
                                                (cons 410 (getvar "CTAB"))
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
        (command "pselect"  ss_pre_filter_set_xx_ "" )
      ;
      ;enter for delete mtext 
        (if (and 
              (= (setq detectloop (getstring "enter to delete Object")) "")
            )
          (progn
            (command "erase"  ss_pre_filter_set_xx_ "")
            (command "erase"  ss_pre_filter_set_xx_ename_auto_ "")
            (command "erase"  ss_pre_filter_set_xx_ename_ttb_ "")
          )
        )
      ;
    ;
    (command "pasteclip" (setq ss (list 0 0 0)) )
    (setvar "osmode" 1215)
  )
  (defun c:PPLINE_CKST_REWORK-TTB11_ ()
    (defun TA:ChangeFont ( / styName newFont styObj)
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
    ;update process
      ; (TA:set-block-explodable "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD" :vlax-true)
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "Title Block_Under Ground_C1 v3"
          (list 900 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD"
          (list 850 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
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
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "Title Block_Under Ground_C1 v3"))
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (if (= (LM:effectivename ss_pre_filter_set_xx_obj_ ) "Title Block_Under Ground_C1 v3")
          (progn
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_DATE_val" "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "STATUS_val" "W")
            
            (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_1_val" )

            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" (strcat 
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" )
                                                                              " "
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" )
                                                                            )
            )
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" "" )

            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "STATUS_val" "W")
            ; (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DRAWING_NO_val")
            
            (setq REV-LV "01")
            (setq REV (strcat "REV_" REV-LV))
            (setq REV_DATE_ (strcat "REV_DATE_" REV-LV))
            (setq REV_DESC_ (strcat "REV_DESC_" REV-LV))
            (setq DWG (strcat "DWG" REV-LV))
            (setq CHK (strcat "CHK" REV-LV))
            (setq APP (strcat "APP" REV-LV))
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV        "A")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DATE_  "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DESC_  "FIRST SUBMISSION")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ DWG        "TA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ CHK        "KEN")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ APP        "MK")
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_val"     "SA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "CHECKED_BY_val"      "UY")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "APRVD_BY_val"        "PP")
          )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    (TA:ChangeFont)
    
    (command "qsave")
    (command "pselect"  ss_pre_filter_set_xx_ "" )
  )
  (defun c:PPLINE_CKST_REWORK-TTB12_ ()
    (defun TA:ChangeFont ( / styName newFont styObj)
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
    ;update process
      ; (TA:set-block-explodable "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD" :vlax-true)
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "Title Block_Under Ground_C1 v3"
          (list 900 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD"
          (list 850 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
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
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "Title Block_Under Ground_C1 v3"))
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (if (= (LM:effectivename ss_pre_filter_set_xx_obj_ ) "Title Block_Under Ground_C1 v3")
          (progn
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_DATE_val" "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "STATUS_val" "W")
            
            (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_1_val" )

            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" (strcat 
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" )
                                                                              " "
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" )
                                                                            )
            )
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" "" )

            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "SCALE_FOR_A1_VAL" "A1 = 1:100")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "dwg_scale_val" "A3 = 1:200")
            ; (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DRAWING_NO_val")
            
            
            
            (setq REV-LV "01")
            (setq REV (strcat "REV_" REV-LV))
            (setq REV_DATE_ (strcat "REV_DATE_" REV-LV))
            (setq REV_DESC_ (strcat "REV_DESC_" REV-LV))
            (setq DWG (strcat "DWG" REV-LV))
            (setq CHK (strcat "CHK" REV-LV))
            (setq APP (strcat "APP" REV-LV))
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV        "A")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DATE_  "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DESC_  "FIRST SUBMISSION")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ DWG        "TA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ CHK        "KEN")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ APP        "MK")
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_val"     "SA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "CHECKED_BY_val"      "UY")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "APRVD_BY_val"        "PP")
          )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    (TA:ChangeFont)
    
    (command "qsave")
    (command "pselect"  ss_pre_filter_set_xx_ "" )
  )
  (defun c:PPLINE_CKST_REWORK-TTB21_ ()
    (defun TA:ChangeFont ( / styName newFont styObj)
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
    ; (command "rename" "B" "Title Block_Under Ground_C1 v3" "Title Block_Under Ground_C2 v3")
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
    ;update process
      ; (TA:set-block-explodable "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD" :vlax-true)
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "Title Block_Under Ground_C2 v3"
          (list 900 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD"
          (list 850 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
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
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "Title Block_Under Ground_C2 v3"))
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (if (= (LM:effectivename ss_pre_filter_set_xx_obj_ ) "Title Block_Under Ground_C2 v3")
          (progn
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_DATE_val" "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "STATUS_val" "W")
            
            (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_1_val" )

            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" (strcat 
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" )
                                                                              " "
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" )
                                                                            )
            )
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" "" )

            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "SCALE_FOR_A1_VAL" "A1 = 1:500")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "dwg_scale_val" "A3 = 1:1000")
            ; (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DRAWING_NO_val")
            
            
            
            (setq REV-LV "01")
            (setq REV (strcat "REV_" REV-LV))
            (setq REV_DATE_ (strcat "REV_DATE_" REV-LV))
            (setq REV_DESC_ (strcat "REV_DESC_" REV-LV))
            (setq DWG (strcat "DWG" REV-LV))
            (setq CHK (strcat "CHK" REV-LV))
            (setq APP (strcat "APP" REV-LV))
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV        "A")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DATE_  "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DESC_  "FIRST SUBMISSION")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ DWG        "TA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ CHK        "KEN")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ APP        "MK")
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_val"     "SA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "CHECKED_BY_val"      "BL")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "APRVD_BY_val"        "PT")
          )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    (TA:ChangeFont)
    
    (command "qsave")
    (command "pselect"  ss_pre_filter_set_xx_ "" )
  )
  (defun c:PPLINE_CKST_REWORK-TTB22_ ()
    (defun TA:ChangeFont ( / styName newFont styObj)
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
    (command "rename" "B" "Title Block_Under Ground_C1 v3" "Title Block_Under Ground_C2 v3")
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
    ;update process
      ; (TA:set-block-explodable "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD" :vlax-true)
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "Title Block_Under Ground_C2 v3"
          (list 900 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
      (command "-INSERTCONTENT" 
          (cond 
            ((and 
                (= (getenv "COMPUTERNAME") 
                  "NONGSAISUEARAI"
                )
                (= (getenv "USERNAME") "popul")
              )
              (progn 
                "C:\\TA FAMELINE old data\\TA\\TA_WORK\\MASS TRANSIT\\TA_PPLINE CKST\\TA_PPLINE CKST_combine_CSD-ceiling-plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
            ((and 
                (= (getenv "COMPUTERNAME") "DESKTOP-FSRT7SI" )
                (= (getenv "USERNAME") "Admin")
              )
              (progn 
                "C:\\TA WORK\\PPLINE CKST\\20250701_new_merge_C1-C2_Finishes-Reflected Ceiling Plan\\C1-C2_Finishes-Reflected Ceiling Plan\\TA-FL-CKST-TTB_.dwg"
              )
            )
          )
          "CVA-C2-P-PP00-TBKA1 (WD)$0$CVA-C2-P-OR00-TBKA1-WD"
          (list 850 0 0)
          1
          1
          0
      )
      (command "erase" "L" "" )
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
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "Title Block_Under Ground_C2 v3"))
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (if (= (LM:effectivename ss_pre_filter_set_xx_obj_ ) "Title Block_Under Ground_C2 v3")
          (progn
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_DATE_val" "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "STATUS_val" "W")
            
            (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_1_val" )

            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" (strcat 
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_2_val" )
                                                                              " "
                                                                              (LM:vl-getattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" )
                                                                            )
            )
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "title_3_val" "" )

            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "SCALE_FOR_A1_VAL" "A1 = 1:100")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "dwg_scale_val" "A3 = 1:200")
            ; (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DRAWING_NO_val")
            
            
            
            (setq REV-LV "01")
            (setq REV (strcat "REV_" REV-LV))
            (setq REV_DATE_ (strcat "REV_DATE_" REV-LV))
            (setq REV_DESC_ (strcat "REV_DESC_" REV-LV))
            (setq DWG (strcat "DWG" REV-LV))
            (setq CHK (strcat "CHK" REV-LV))
            (setq APP (strcat "APP" REV-LV))
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV        "A")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DATE_  "03-10-2025")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ REV_DESC_  "FIRST SUBMISSION")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ DWG        "TA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ CHK        "KEN")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ APP        "MK")
            
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "DESIGNED_BY_val"     "SA")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "CHECKED_BY_val"      "BL")
            (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ "APRVD_BY_val"        "PT")
          )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    (TA:ChangeFont)
    
    (command "qsave")
    (command "pselect"  ss_pre_filter_set_xx_ "" )
  )
  (defun c:PPLINE_CKST_MATHEADING ()
    (setq ttb_ename_ (car (entsel "specify ref for heading Object")))
    (setq ttb_obj_ (vlax-ename->vla-object ttb_ename_))
    (setq heading_text_
     (strcat 
        (LM:vl-getattributevalue ttb_obj_ "title_2_val")
        " "
        (LM:vl-getattributevalue ttb_obj_ "title_3_val")
      )
    )
    (setq target_ename_ (car (entsel "specify Object")))
    (setq target_obj_ (vlax-ename->vla-object target_ename_))
    (LM:setdynpropvalue target_obj_ "distance1" 1)
    (LM:vl-setattributevalue target_obj_ "heading-name" heading_text_)
    (setq ss_pre_filter_set_xx_obj_getboundingbox (vla-getboundingbox target_obj_ 'min_ 'max_)) 
    (setq ss_pre_filter_set_xx_min_ (vlax-safearray->list min_)) 
    (setq ss_pre_filter_set_xx_max_ (vlax-safearray->list max_)) 
    
    (LM:setdynpropvalue target_obj_ "distance1" (fix (+ (- (car ss_pre_filter_set_xx_max_) (car ss_pre_filter_set_xx_min_) ) 1)))
  )
  (defun c:PPLINE_CKST_MAT1 ()
    
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "x"
                                            (list
                                              (cons 0 "INSERT") ;type of object
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
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "Title Block_Under Ground_C1 v3"))
    ;
    (setq ttb_ename_ (ssname ss_pre_filter_set_xx_ 0))
    (setq ttb_obj_ (vlax-ename->vla-object ttb_ename_))
    (setq heading_text_
     (strcat 
        (LM:vl-getattributevalue ttb_obj_ "title_2_val")
        " "
        (LM:vl-getattributevalue ttb_obj_ "title_3_val")
      )
    )
    (command "pasteclip" (setq ss (list 0 0 0)) )
    (setq target_ename_ (entlast))
    ; (setq target_ename_ (car (entsel "specify Object")))
    (setq target_obj_ (vlax-ename->vla-object target_ename_))
    (LM:vl-setattributevalue target_obj_ "heading-name" heading_text_)
    (setq ss_pre_filter_set_xx_obj_getboundingbox (vla-getboundingbox target_obj_ 'min_ 'max_)) 
    (setq ss_pre_filter_set_xx_min_ (vlax-safearray->list min_)) 
    (setq ss_pre_filter_set_xx_max_ (vlax-safearray->list max_)) 
    (LM:setdynpropvalue target_obj_ "distance1" (fix (+ (- (car ss_pre_filter_set_xx_max_) (car ss_pre_filter_set_xx_min_) ) 1)))
  )
  ; (c:loadlisp)
  ; (c:update_up1auto_)
;


(TA:ChangeFont)
; ; ; automation_Process
;   (if (= (getvar "ctab") "Model") ;move model
;     (progn
;       (setvar "ctab" (nth 1 (getdrawinglayouts (getvar "dwgname"))))
;     )
;   )
; ;   ; (c:CKdim)
;   ; (c:Plotter_CKST_CSD-R-PLOT) ; csd file1
;   (c:Plotter_CKST_CSD3plot) ; newest plotter
;   ; (c:Plotter_CKST_CSDPLOT)
;   ; (c:PPLINE_CKST_REWORK-TTB2_)
;   (command "zoom" "a") 
; ; ;   ; (c:find_xref_)
; ;   ; (c:RUNPPEL_plot)
;   (command "close" "n" )
;  

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
