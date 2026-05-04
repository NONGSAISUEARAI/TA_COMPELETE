;update 20250818 0504pm
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
  ;Attribute Function Lee Mac
    ;; Get Attribute Value  -  Lee Mac
    ;; Returns the value held by the specified tag within the supplied block, if present.
    ;; blk - [vla] VLA Block Reference Object
    ;; tag - [str] Attribute TagString
    ;; Returns: [str] Attribute value, else nil if tag is not found.
    (defun LM:vl-getattributevalue (blk tag) 
      (setq tag (strcase tag))
      (vl-some 
        '(lambda (att) 
          (if (= tag (strcase (vla-get-tagstring att))) (vla-get-textstring att))
        )
        (vlax-invoke blk 'getattributes)
      )
    )
    ;; Set Attribute Value  -  Lee Mac
    ;; Sets the value of the first attribute with the given tag found within the block, if present.
    ;; blk - [vla] VLA Block Reference Object
    ;; tag - [str] Attribute TagString
    ;; val - [str] Attribute Value
    ;; Returns: [str] Attribute value if successful, else nil.
    (defun LM:vl-setattributevalue (blk tag val) 
      (setq tag (strcase tag))
      (vl-some 
        '(lambda (att) 
          (if (= tag (strcase (vla-get-tagstring att))) 
            (progn (vla-put-textstring att val) val)
          )
        )
        (vlax-invoke blk 'getattributes)
      )
    )
    ;; Get Attribute Values  -  Lee Mac
    ;; Returns an association list of attributes present in the supplied block.
    ;; blk - [vla] VLA Block Reference Object
    ;; Returns: [lst] Association list of ((<tag> . <value>) ... )
    (defun LM:vl-getattributevalues (blk) 
      (mapcar '(lambda (att) (cons (vla-get-tagstring att) (vla-get-textstring att))) 
              (vlax-invoke blk 'getattributes)
      )
    )
    (defun LM:vl-getattributevalue-tag-TA-Modifies (blk) 
      (mapcar '(lambda (att) (vla-get-tagstring att)) 
              (vlax-invoke blk 'getattributes)
      )
    )
    (defun LM:vl-getattributevalue-val-TA-Modifies (blk) 
      (mapcar '(lambda (att) (vla-get-textstring att)) 
              (vlax-invoke blk 'getattributes)
      )
    )
    ;; Set Attribute Values  -  Lee Mac
    ;; Sets attributes with tags found in the association list to their associated values.
    ;; blk - [vla] VLA Block Reference Object
    ;; lst - [lst] Association list of ((<tag> . <value>) ... )
    ;; Returns: nil
    (defun LM:vl-setattributevalues (blk lst / itm) 
      (foreach att (vlax-invoke blk 'getattributes) 
        (if (setq itm (assoc (vla-get-tagstring att) lst)) 
          (vla-put-textstring att (cdr itm))
        )
      )
    )
  ;
  ;Dynamic Funcion Lee Mac
    ;; Get Dynamic Block Property Value  -  Lee Mac
      ;; Returns the value of a Dynamic Block property (if present)
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; prp - [str] Dynamic Block property name (case-insensitive)

      (defun LM:getdynpropvalue ( blk prp )
          (setq prp (strcase prp))
          (vl-some '(lambda ( x ) (if (= prp (strcase (vla-get-propertyname x))) (vlax-get x 'value)))
              (vlax-invoke blk 'getdynamicblockproperties)
          )
      )
    ;; Set Dynamic Block Property Value  -  Lee Mac
      ;; Modifies the value of a Dynamic Block property (if present)
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; prp - [str] Dynamic Block property name (case-insensitive)
      ;; val - [any] New value for property
      ;; Returns: [any] New value if successful, else nil

      (defun LM:setdynpropvalue ( blk prp val )
          (setq prp (strcase prp))
          (vl-some
            '(lambda ( x )
                  (if (= prp (strcase (vla-get-propertyname x)))
                      (progn
                          (vla-put-value x (vlax-make-variant val (vlax-variant-type (vla-get-value x))))
                          (cond (val) (t))
                      )
                  )
              )
              (vlax-invoke blk 'getdynamicblockproperties)
          )
      )
    ;; Get Dynamic Block Properties  -  Lee Mac
      ;; Returns an association list of Dynamic Block properties & values.
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; Returns: [lst] Association list of ((<prop> . <value>) ... )

      (defun LM:getdynprops ( blk )
          (mapcar '(lambda ( x ) (cons (vla-get-propertyname x) (vlax-get x 'value)))
              (vlax-invoke blk 'getdynamicblockproperties)
          )
      )
      (defun LM:getdynprops_nonvalue ( blk )
          (mapcar '(lambda ( x ) (vla-get-propertyname x))
              (vlax-invoke blk 'getdynamicblockproperties)
          )
      )
    ;; Set Dynamic Block Properties  -  Lee Mac
      ;; Modifies values of Dynamic Block properties using a supplied association list.
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; lst - [lst] Association list of ((<Property> . <Value>) ... )
      ;; Returns: nil

      (defun LM:setdynprops ( blk lst / itm )
          (setq lst (mapcar '(lambda ( x ) (cons (strcase (car x)) (cdr x))) lst))
          (foreach x (vlax-invoke blk 'getdynamicblockproperties)
              (if (setq itm (assoc (strcase (vla-get-propertyname x)) lst))
                  (vla-put-value x (vlax-make-variant (cdr itm) (vlax-variant-type (vla-get-value x))))
              )
          )
      )
    ;; Get Dynamic Block Property Allowed Values  -  Lee Mac
      ;; Returns the allowed values for a specific Dynamic Block property.
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; prp - [str] Dynamic Block property name (case-insensitive)
      ;; Returns: [lst] List of allowed values for property, else nil if no restrictions

      (defun LM:getdynpropallowedvalues ( blk prp )
          (setq prp (strcase prp))
          (vl-some '(lambda ( x ) (if (= prp (strcase (vla-get-propertyname x))) (vlax-get x 'allowedvalues)))
              (vlax-invoke blk 'getdynamicblockproperties)
          )
      )
    ;; Toggle Dynamic Block Flip State  -  Lee Mac
      ;; Toggles the Flip parameter if present in a supplied Dynamic Block.
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; Return: [int] New Flip Parameter value

      (defun LM:toggleflipstate ( blk )
          (vl-some
            '(lambda ( prp / rtn )
                  (if (equal '(0 1) (vlax-get prp 'allowedvalues))
                      (progn
                          (vla-put-value prp (vlax-make-variant (setq rtn (- 1 (vlax-get prp 'value))) vlax-vbinteger))
                          rtn
                      )
                  )
              )
              (vlax-invoke blk 'getdynamicblockproperties)
          )
      )
    ;; Get Visibility Parameter Name  -  Lee Mac
      ;; Returns the name of the Visibility Parameter of a Dynamic Block (if present)
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; Returns: [str] Name of Visibility Parameter, else nil

      (defun LM:getvisibilityparametername ( blk / vis )  
          (if
              (and
                  (vlax-property-available-p blk 'effectivename)
                  (setq blk
                      (vla-item
                          (vla-get-blocks (vla-get-document blk))
                          (vla-get-effectivename blk)
                      )
                  )
                  (= :vlax-true (vla-get-isdynamicblock blk))
                  (= :vlax-true (vla-get-hasextensiondictionary blk))
                  (setq vis
                      (vl-some
                        '(lambda ( pair )
                              (if
                                  (and
                                      (= 360 (car pair))
                                      (= "BLOCKVISIBILITYPARAMETER" (cdr (assoc 0 (entget (cdr pair)))))
                                  )
                                  (cdr pair)
                              )
                          )
                          (dictsearch
                              (vlax-vla-object->ename (vla-getextensiondictionary blk))
                              "ACAD_ENHANCEDBLOCK"
                          )
                      )
                  )
              )
              (cdr (assoc 301 (entget vis)))
          )
      )
    ;; Get Dynamic Block Visibility State  -  Lee Mac
      ;; Returns the value of the Visibility Parameter of a Dynamic Block (if present)
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; Returns: [str] Value of Visibility Parameter, else nil

      (defun LM:getvisibilitystate ( blk / vis )
          (if (setq vis (LM:getvisibilityparametername blk))
              (LM:getdynpropvalue blk vis)
          )
      )
    ;; Set Dynamic Block Visibility State  -  Lee Mac
      ;; Sets the Visibility Parameter of a Dynamic Block (if present) to a specific value (if allowed)
      ;; blk - [vla] VLA Dynamic Block Reference object
      ;; val - [str] Visibility State Parameter value
      ;; Returns: [str] New value of Visibility Parameter, else nil

      (defun LM:SetVisibilityState ( blk val / vis )
          (if
              (and
                  (setq vis (LM:getvisibilityparametername blk))
                  (member (strcase val) (mapcar 'strcase (LM:getdynpropallowedvalues blk vis)))
              )
              (LM:setdynpropvalue blk vis val)
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
  ;Method Selection Set Ta Trai
    (defun TA:standard_func_selection_set_cond_case_1 () ;วิธีเก็บข้อมูล selection set แบบเดียวกับ pickfirst variable
      ;selection_set
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx (ssget "I" 
                                              (list 
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
            nil
          )
          (progn 
            (setq ss_pre_filter_set_xx (ssget 
                                          (list 
                                            (cons 0 "INSERT") ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx)
        )
      ;
    )
    (defun TA:standard_func_entsel_case_1 () ;วิธีเก็บข้อมูลแบบตัวแปรเดี่ยวตามเงื่อนไข (condition rule) จนกว่าจะถูกต้อง
      ;user_input get_effectivename 
        (setq get_effectivename_ nil)
        (setq get_effectivename_obj_val_ nil)
        ;preloop_and_while_
            (while (not get_effectivename_)
              (princ (setq get_effectivename_ (car (entsel "\nPlease Specify Attribute Block\n"))))
              (if (and ;condition rule
                    (/= get_effectivename_ nil)
                    (= (vla-get-hasattributes (vlax-ename->vla-object get_effectivename_)) :vlax-true)
                    ; (/= (vla-get-isdynamicblock (vlax-ename->vla-object get_effectivename_)) :vlax-true)
                  )
                (progn ;add data
                  ; (alert "\nplease select block object")
                  ; (setq get_effectivename_ nil)
                  ; (setq get_effectivename_obj_val_ nil)
                  (setq get_effectivename_obj_val_ (LM:Effectivename (vlax-ename->vla-object get_effectivename_)))
                  ;add more
                )
                (setq get_effectivename_ nil)
              )
            )
        ;
      ;
      ;user_input_get_block_(not loop)
        ;block_data_for insertion
          (setq blk_ename_ (car (entsel "specify_block_")))
          (setq blk_ename_obj_ (vlax-ename->vla-object blk_ename_))
          (if (= (setq type_obj_ (vla-get-objectname (vlax-ename->vla-object blk_ename_))) "AcDbBlockReference") ;For Check objectname
            (progn
              (setq blk_ename_obj_inspt_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint blk_ename_obj_))))
              (setq blk_ename_obj_efname_ (LM:effectivename blk_ename_obj_ ))
            )
            (alert "Object is not block.")
          )
        ;
      ;
      ;get_data_dynamic_block_object
        (if (= 1 1) 
          (progn
            ;user_input_get_block_(not loop)
              ;block_data_for insertion
                (if (/= (setq blk_ename_ (car (entsel "specify_block_"))) nil)
                  (progn
                    (setq blk_ename_obj_ (vlax-ename->vla-object blk_ename_))
                  )
                  (alert "Object is blank.")
                )         
                (if (and
                      (= (setq type_obj_ (vla-get-objectname (vlax-ename->vla-object blk_ename_))) "AcDbBlockReference");For Check objectname
                      (= (vla-get-isdynamicblock blk_ename_obj_) :vlax-true );For Check objectname is dynamicblock
                    ) 
                  (progn
                    (setq blk_ename_obj_inspt_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint blk_ename_obj_))))
                    (setq blk_ename_obj_efname_ (LM:effectivename blk_ename_obj_ ))
                  )
                  (alert "Object is not block.")
                )
              ;
            ;
          )
        )
      ;
    )
  ;
  ;Sorting Coordinate Function Ta Trai
    (defun CO:sort_by_X (list_)  ;เรียงชุดข้อมูลตามแนวแกน
      (setq sortedLst (vl-sort list_ (function (lambda (a b) (< (car (cadr a)) (car (cadr b)))))))
    )
    (defun CO:sort_by_y (list_)  ;เรียงชุดข้อมูลตามแนวแกน
      (setq sortedLst (vl-sort list_ (function (lambda (a b) (< (cadr (cadr a)) (cadr (cadr b)))))))
    )
    (defun CO:sort_by_val_ (val_ list_ )  ;เรียงชุดข้อมูลตามแนวแกน
      (if (< val_ (length (car list_)))
        (progn
          (setq sortedLst (vl-sort list_ (function (lambda (a b) (< (nth val_ a) (nth val_ b))))))
        )
        (setq error_ "The number of val is less than list")
      )
    )
    (defun TA:standard_list_croodinate_sorting (ss_post_filter_set_ sequence ) ;เรียง object ตามแนวแกน ใน selection set
      ; ;selection_set
        ;   (if  ;pre_select_ssget_or_post_select_ssget
        ;     (= 
        ;       (setq ss_pre_filter_set_xx (ssget "I" 
        ;                                         (list 
        ;                                           (cons 0 "INSERT") ;type of object
        ;                                           ; (cons 8 "*GRID*")   ;kind of layer
        ;                                           ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
        ;                                           ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                         )
        ;                                   )
        ;       )
        ;       nil
        ;     )
        ;     (progn 
        ;       (setq ss_pre_filter_set_xx (ssget 
        ;                                     (list 
        ;                                       (cons 0 "INSERT") ;type of object
        ;                                       ; (cons 8 "*GRID*")   ;kind of layer
        ;                                       ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
        ;                                       ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                     )
        ;                                   )
        ;       )
        ;     )
        ;     (sslength ss_pre_filter_set_xx)
        ;   )
      ; ;
      ; ;user_input
        ;   (setq effectivename_val (LM:effectivename (vlax-ename->vla-object (car (entsel )))))
      ; ;
      ; ;filter_via_sub_func
        ;   (setq ss_post_filter_set_ (TA:Filter_ss_set_ ss_pre_filter_set_xx  effectivename_val))
      ; ;
      ;preloop_and_while get_ename_and_add_ins_pt
        (setq sum_data_ ())
        (setq ss_post_filter_set_i 0)
        (while  (< ss_post_filter_set_i (sslength ss_post_filter_set_))
          ;get_data
            (setq ss_post_filter_set_ename (ssname ss_post_filter_set_ ss_post_filter_set_i))
            (setq ss_post_filter_set_obj (vlax-ename->vla-object ss_post_filter_set_ename))
          ;
          ;sum_data_via_data
            (setq sum_data (TA:ename+vla-get-insertionpoint ss_post_filter_set_obj))
            (setq sum_data_ (cons sum_data sum_data_))
          ;
          (setq ss_post_filter_set_i (+ ss_post_filter_set_i 1))
        )
      ;
      ;sub_user_input_
        (cond
          ((= sequence "X") ;correct case
            (progn
              (princ "XXX")
              (setq sort_x (CO:sort_by_X sum_data_))
            )
          )
          ((= sequence "Y") ;correct case
            (progn
              (princ "YYY")
              (setq sort_y (CO:sort_by_Y sum_data_))
            )
          )
          ((and ;incorrect case
              (/= sequence "X")
              (/= sequence "Y")
            )
            (progn
              (princ "error_sorting_ename please specify argument X or Y")
              ; (setq sort_y (sort_by_y sum_data_))
            )
          )
        )
      ;
    )
    (defun TA:standard_list_croodinate+ename (ss_post_filter_set_  ) ;เรียง object ตามแนวแกน ใน selection set  
      ; ;selection_set
        ;   (if  ;pre_select_ssget_or_post_select_ssget
        ;     (= 
        ;       (setq ss_pre_filter_set_xx (ssget "I" 
        ;                                         (list 
        ;                                           (cons 0 "INSERT") ;type of object
        ;                                           ; (cons 8 "*GRID*")   ;kind of layer
        ;                                           ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
        ;                                           ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                         )
        ;                                   )
        ;       )
        ;       nil
        ;     )
        ;     (progn 
        ;       (setq ss_pre_filter_set_xx (ssget 
        ;                                     (list 
        ;                                       (cons 0 "INSERT") ;type of object
        ;                                       ; (cons 8 "*GRID*")   ;kind of layer
        ;                                       ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
        ;                                       ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                     )
        ;                                   )
        ;       )
        ;     )
        ;     (sslength ss_pre_filter_set_xx)
        ;   )
      ; ;
      ; ;user_input
        ;   (setq effectivename_val (LM:effectivename (vlax-ename->vla-object (car (entsel )))))
      ; ;
      ; ;filter_via_sub_func
        ;   (setq ss_post_filter_set_ (TA:Filter_ss_set_ ss_pre_filter_set_xx  effectivename_val))
      ; ;
      ;preloop_and_while get_ename_and_add_ins_pt
        (setq sum_data_ ())
        (setq ss_post_filter_set_i 0)
        (while  (< ss_post_filter_set_i (sslength ss_post_filter_set_))
          ;get_data
            (setq ss_post_filter_set_ename (ssname ss_post_filter_set_ ss_post_filter_set_i))
            (setq ss_post_filter_set_obj (vlax-ename->vla-object ss_post_filter_set_ename))
          ;
          ;sum_data_via_data
            (setq sum_data (TA:vla-get-insertionpoint+ename ss_post_filter_set_obj))
            (setq sum_data_ (cons sum_data sum_data_))
          ;
          (setq ss_post_filter_set_i (+ ss_post_filter_set_i 1))
        )
        (setq sum_data_ sum_data_)
        ;
      ;
    )
    (defun TA:corrd_sorting_group (all_vlains_ Toerrance_num_value)
      ;Note By Code_Developer
      ;principle of codework is designed for finding coordinate in list and create main row 
      ;The main row will be used as fundamental for sorting each column in coordinate list 
      ;Fully command must have sub-functions with names starting with TA: or LM:
      ;
      ;argument list
      ;all_vlains_        =  all coordinate in list 
      ;                       (standard form for all_vlains argument must be 
      ;                        (
      ;                         (x y z)entity_name
      ;                         (x y z)entity_name
      ;                         (x y z)entity_name
      ;                        )
      ;TA:Toerrance_num_  = is argument from Sub FUNC name "TA:Toerrance_num_"
      ;                     that specify and decide coordinate by calculate spacing 
      ;                     coodinate to coodinate is same column or not in row/col
      ;
      ;main idea of codework
      ;first step is always keep lowest insertion coordinate point in variable name "test_vlains_ename_1st"
      ;second step by setting "test_vlains_ename_1st" as main corrdinate that let other coordinates pass
      ;into the loop for checking whether they are in the same row/column,via using SUB_FUNC name TA:Toerrance_num_
      ;
      ;
      ;creating main rows process
        ;preloop_and_while creating main row in list 
          (setq test_vlains_ename_1st (nth 0 all_vlains_))
          (setq all_vlains_i 0)
          (setq main_row ())
          (setq main_row (cons test_vlains_ename_1st main_row))
          (while (< all_vlains_i (length all_vlains_))
            (setq all_vlains_ename_subrow_ (nth  all_vlains_i all_vlains_))
            (if 
              (and 
                (/= test_vlains_ename_1st all_vlains_ename_subrow_)
                (TA:Toerrance_num_ 
                  (car (car test_vlains_ename_1st))
                  (car (car all_vlains_ename_subrow_))
                  Toerrance_num_value
                )
              )
              (progn 
                (setq main_row (cons all_vlains_ename_subrow_ main_row))
                (length main_row)
              )
            )
            (setq all_vlains_i (+ all_vlains_i 1))
          )
        ;
        ;TA:stanndard_lambda_sorting_Y-axis
          (setq main_row_sorted_Y_ (vl-sort main_row ;bigest open indent list
                                                    (function 
                                                      (lambda (a b) 
                                                        (> (nth 1 (car a)) (nth 1 (car b)))
                                                      )
                                                    )
                                ) ;bigest close indent list
          )
        ;
      ;
      ;creating sub rows process
        ;preloop_and_while main row loop first loop
          (setq main+sub_row_ ())
          (setq main_row_sorted_Y_i 0)
          (while (< main_row_sorted_Y_i (length main_row_sorted_Y_))
            (setq main_row_sorted_Y_main_set_ (nth  main_row_sorted_Y_i main_row_sorted_Y_))
              ;preloop_and_while main row loop second loop
                (setq all_vlains_i 0)
                (setq sub_row_ ())
                (while (< all_vlains_i (length all_vlains_))
                  (setq all_vlains_subrow_ (nth  all_vlains_i all_vlains_))
                    (if 
                      (and 
                        (/= test_vlains_ename_1st all_vlains_ename_subrow_)
                        (TA:Toerrance_num_ 
                          (cadr (car all_vlains_subrow_))
                          (cadr (car main_row_sorted_Y_main_set_))
                          10 ;do not use argument from TA:corrd_sorting_group
                        )
                      )
                      (progn 
                        (setq sub_row_ (cons all_vlains_subrow_ sub_row_ ))
                        (length sub_row_)
                        ;TA:stanndard_lambda_sorting
                        (setq sub_row_ (vl-sort sub_row_  ;bigest open indent list
                                                                  (function 
                                                                    (lambda (a b) 
                                                                      (< (nth 0 (car a)) (nth 0 (car b)))
                                                                    )
                                                                  )
                                              ) ;bigest close indent list
                        )
                        
                        ;
                      )
                    )
                  (setq all_vlains_i (+ all_vlains_i 1))
                )
              ;
            (setq main+sub_row_ (cons sub_row_ main+sub_row_))
            ; (format-data main+sub_row_)
            (length main+sub_row_)
            (setq main_row_sorted_Y_i (+ main_row_sorted_Y_i 1))
          )
        ;
        ;TA:stanndard_lambda_sorting
          ;88 211 342 405 463 คือกลุ่มตัวเลขที่ต้องการจะใช้เรียงในกลุ่ม ;main
          ;จากที่กล่าวมา ถ้าต้องเรียงกลุ่ม ;main จะทำการดึงตัวแปรกลุ่ม ;main 
          ;เพื่อตั้งต้นก่อน จะได้ผลลัพธ์แบบนี้
          ; (setq main 
          ;   (list ;main
          ;     (list(list 138.044 88.6521 0.0) "<Entity name: 23abbecab20>") 
          ;     (list(list 288.589 90.6521 0.0) "<Entity name: 23abbecabb0>")
          ;     (list(list 392.914 92.6521 0.0) "<Entity name: 23abbecabe0>")
          ;   )
          ; )
          ;ซึ่ง main ในที่นี้ คือตัวแทน a b ใน lambda โดยเป็น main คือ list ย่อยของ main+sub_row_
          ;วิธีตรวจสอบำตอบง่ายๆ คือ ให้ ตั้งการดึงข้อมูลย่อยจาก main
          ;สมมุติว่าใช้ (cadr (nth 0 (nth 0 main))) แล้วได้ตัวเลขในกลุ่มดังกล่าว [88 211 342 405 463]
          ;แสดงว่าถูกต้อง
          ; (setq main+sub_row_ 
          ;   (list
          ;     (list ;main
          ;       (list(list 138.044 88.6521 0.0) "<Entity name: 23abbecab20>") 
          ;       (list(list 288.589 90.6521 0.0) "<Entity name: 23abbecabb0>")
          ;       (list(list 392.914 92.6521 0.0) "<Entity name: 23abbecabe0>")
          ;     ) 
          ;     (list ;main
          ;       (list(list 147.328 211.264 0.0) "<Entity name: 23abbecab50>") 
          ;       (list(list 288.589 210.776 0.0) "<Entity name: 23abbecabc0>")
          ;       (list(list 392.914 212.776 0.0) "<Entity name: 23abbecabf0>")
          ;     )
          ;     (list ;main
          ;       (list(list 100.205 342.1 0.0) "<Entity name: 23abbecab80>") 
          ;       (list(list 288.589 344.1 0.0) "<Entity name: 23abbecabd0>")
          ;       (list(list 392.914 346.1 0.0) "<Entity name: 23abbecac00>")
          ;     )
          ;     (list ;main
          ;       (list(list 119.914 405.524 0.0) "<Entity name: 23abbecaed0>") 
          ;       (list(list 251.971 407.524 0.0) "<Entity name: 23abbecaee0>")
          ;       (list(list 356.296 409.524 0.0) "<Entity name: 23abbecaef0>")
          ;     )
          ;     (list ;main
          ;       (list(list 156.532 463.701 0.0) "<Entity name: 23abbecaf60>") 
          ;       (list(list 288.589 465.701 0.0) "<Entity name: 23abbecaf70>")
          ;       (list(list 392.914 467.701 0.0) "<Entity name: 23abbec7800>")
          ;     )
          ;   )
          ; )
          (setq main+sub_row_sorted_ (vl-sort main+sub_row_  ;bigest open indent list
                                              (function 
                                                (lambda (a b) 
                                                  (>
                                                    (cadr (nth 0 (nth 0 a)))
                                                    (cadr (nth 0 (nth 0 b)))
                                                    
                                                  )
                                                )
                                              )
                                    ) ;bigest close indent list
          )
          ; (format-data main+sub_row_)
          (setq main+sub_row_sorted_ main+sub_row_sorted_)
        ;
        
      ;
      ;
    )
    (defun TA:custom-sort (user_custom_sort_ target_custom_sort_ )
      ;Note By Code_Developer
      ;This command is designed to work exclusively with a list array 
      ;principle of codework is designed for sorting by user custom, Then user can create custom in array list-form
      ;
      ;example argument
        ; (setq user_custom_sort_ '("Cherry" "Banana" "Apple" "Mango"))
        ; (setq target_custom_sort_  '("Cherry" "Banana" "Cherry" "Banana" "Cherry" "Banana" "Apple" "Mango" "Apple" "Mango" "Apple" "Mango"))
      ;
      ;
      ;preloop_and_while
        (setq new_sort_ ())
        (setq user_custom_sort_i 0)
        (while (< user_custom_sort_i (length user_custom_sort_))
          (setq user_custom_sort_tag_ (nth  user_custom_sort_i user_custom_sort_))
          
          ;preloop_and_while
            (setq target_custom_sort_i 0)
            (while (< target_custom_sort_i (length target_custom_sort_))
              (setq target_custom_sort_val_ (nth  target_custom_sort_i target_custom_sort_))
              
              (if (= target_custom_sort_val_ user_custom_sort_tag_ )
                (progn
                  (setq new_sort_ (cons target_custom_sort_val_ new_sort_))
                )
              )
              (setq target_custom_sort_i (+ target_custom_sort_i 1))
            )
          ;
      
          (setq user_custom_sort_i (+ user_custom_sort_i 1))
        )
      ;
      (setq new_sort_ new_sort_)
    )
  ;
  ;get_Intersect_func
    (defun LM:intersections (ob1 ob2 mod / lst rtn) 
      (if 
        (and (vlax-method-applicable-p ob1 'intersectwith) 
            (vlax-method-applicable-p ob2 'intersectwith)
            (setq lst (vlax-invoke ob1 'intersectwith ob2 mod))
        )
        (repeat (/ (length lst) 3) 
          (setq rtn (cons (list (car lst) (cadr lst) (caddr lst)) rtn)
                lst (cdddr lst)
          )
        )
      )
      (remove_member_list_ 2 (reverse rtn))
      
    )
    (defun LM:intersections+0 (ob1 ob2 mod / lst rtn) 
      (if 
        (and (vlax-method-applicable-p ob1 'intersectwith) 
            (vlax-method-applicable-p ob2 'intersectwith)
            (setq lst (vlax-invoke ob1 'intersectwith ob2 mod))
        )
        (repeat (/ (length lst) 3) 
          (setq rtn (cons (list (car lst) (cadr lst) (caddr lst)) rtn)
                lst (cdddr lst)
          )
        )
      )
      ; (remove_member_list_ 2 (reverse rtn))
      (reverse rtn)
      
    )
    (defun LM:intersections_crood_position (ob1 ob2 coord_ mod  / lst rtn) 
      (if 
        (and (vlax-method-applicable-p ob1 'intersectwith) 
            (vlax-method-applicable-p ob2 'intersectwith)
            (setq lst (vlax-invoke ob1 'intersectwith ob2 mod))
        )
        (repeat (/ (length lst) 3) 
          (setq rtn (cons (list (car lst) (cadr lst) (caddr lst)) rtn)
                lst (cdddr lst)
          )
        )
      )
      (cond ;soectify corrdinate position
        ((= coord_ "xyz")
        (progn 
          (reverse rtn)
        )
        )
        ((= coord_ "xy")
        (progn 
          (remove_member_list_ 2 (reverse rtn))
        )
        )
        ((or
          (/= coord_ "xy")
          (/= coord_ "xyz")
          (= coord_ nil)
        )
        (progn 
          (princ "\n:::::::::::::::: ERROR ::::::::::::::::::::::")
          (princ "\n:::::Please Specify Coordinate Position::::::\n")
          (princ ":::::::::::::: X Y    = 2 coord :::::::::::::\n")
          (princ ":::::::::::::: X Y Z  = 3 coord :::::::::::::\n")
        )
        )
      )
    )
    (defun LM:intersectionsinset ( sel / id1 id2 ob1 ob2 rtn )
      (repeat (setq id1 (sslength sel))
          (setq ob1 (vlax-ename->vla-object (ssname sel (setq id1 (1- id1)))))
          (repeat (setq id2 id1)
              (setq ob2 (vlax-ename->vla-object (ssname sel (setq id2 (1- id2))))
                    rtn (cons (LM:intersections ob1 ob2 acextendnone) rtn)
              )
          )
      )
      (apply 'append (reverse rtn))
    )
    
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
        ;example argument 
      
        ;
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
    (defun TA:get-value_in-list_ (index lst)
      (nth index lst)
    )
  ;
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
    (defun c:select_layout_number_LayNum_ ()
      (setq input_layout_number (cond ( (getint (strcat "\nspecify get color \n<" (rtos (setq input_layout_number (cond (input_layout_number) (1.0) ) ) ) "> : " ) ) ) (input_layout_number) ) )
      (setq layout_list_ (getdrawinglayouts (getvar "dwgname")))
      (setvar "ctab" (nth (fix input_layout_number) layout_list_ ) )
    )
    (defun c:go-to-model_2model ()
      (setvar "ctab" "Model")
    )
    (defun c:select_layout_number_2LayoutClose_2LAC ()
      (setq layout_list_ (getdrawinglayouts (getvar "dwgname")))
      (setvar "ctab" (nth 1 layout_list_ ) )
      (command "zoom" "extent" )
      (command "qsave")
      (command "close")
    )    
    (defun c:select_layout_number_2Layout_2LAA ()
      (setq layout_list_ (getdrawinglayouts (getvar "dwgname")))
      (setvar "ctab" (nth 1 layout_list_ ) )
      (command "zoom" "extent" )
      (command "qsave")
    )   
    (defun c:gethandle ()
      (setq get_ename_ (car (entsel "specify Object")))
      (setq get_obj_ (vlax-ename->vla-object get_ename_))
      (princ (vla-get-handle get_obj_))
    )

  ;
  ;Get_Data Function Ta Trai
    (defun TA:get_name_block_in_drawing (mode)
      ;user_input_
        (setq mode "mode")
      ;
      ;get_obj_file_
        (setq multi_blocks_obj (vla-get-blocks (vla-get-ActiveDocument (vlax-get-acad-object))))
        (setq block_list_ ())
      ;
      ;method_for_get_name_block_in_drawing
        ;method_1_get_name_
          (vlax-for block_ multi_blocks_obj 
            (setq block_list_ (append block_list_ (list (vla-get-name block_))))
          )
        ;
        ; ;method_2_get_name_
        ;   (setq block_i 0)
        ;   (while (< block_i (vla-get-count multi_blocks_obj))
        ;     (setq block_ (vla-item multi_blocks_obj block_i))
        ;     (setq block_list_ (append block_list_ (list (vla-get-name block_))))
        ;     (setq block_i (1+ block_i))
        ;   )
        ; ;
      ;
      ;sorting_name_block
        (setq sorted_block_list_ (acad_strlsort block_list_))
      ;
      ;preloop_and_while filtter_
        (setq sorted_block_list_i 0)
        (setq filter_sorted_block_ ())

        (while (< sorted_block_list_i (length sorted_block_list_))
          (setq filter_sorted_block_effectivename_ (nth sorted_block_list_i sorted_block_list_))
          
          (if (/= (substr filter_sorted_block_effectivename_ 1 1) "*") ; ตรวจสอบว่าชื่อเริ่มต้นด้วย *
            (progn
              (setq filter_sorted_block_ (cons filter_sorted_block_effectivename_ filter_sorted_block_))
            )
          )
          (setq sorted_block_list_i (+ sorted_block_list_i 1))
        )
      ;

      
      (setq filter_sorted_block_total (length filter_sorted_block_))
      (princ "\n                  |=====================|")
      (princ "\n                  | TOTAL BLOCK IN FILE |")
      (princ (strcat "\n                  |     = " (itoa filter_sorted_block_total) " block     |"))
      (princ "\n                  |          set        |")
      (princ "\n                  |---------------------|\n")
      (setq filter_sorted_block_ filter_sorted_block_)

    )
    (defun TA:get_name_layer_in_drawing ()
      (setq layers_list_ ())
      (setq layers_obj (vla-get-layers (vla-get-ActiveDocument (vlax-get-acad-object))))
      ;method_1_get_layers_name
        (vlax-for lay layers_obj
          (setq layers_list (append layers_list (list (vla-get-Name lay))))
        )
      ;
      ;method_2_get_layers_name
        (setq layers_i 0)
        (while (< layers_i (vla-get-count layers_obj))
          (setq layers_ (vla-item layers_obj layers_i))
          (setq layers_list_ (append layers_list_ (list (vla-get-name layers_))))
          (setq layers_i (1+ layers_i))
        )
      ;
      ;summary_layer_data
        (setq layers_list_total (length layers_list_))
        (princ "\n                  |=====================|")
        (princ "\n                  | TOTAL LAYERS IN FILE |")
        (princ (strcat "\n                  |     = " (itoa layers_list_total) " layer     |"))
        (princ "\n                  |          set        |")
        (princ "\n                  |---------------------|")
        (setq layers_list_ layers_list_)
      ;
    )
    (defun TA:ename+vla-get-insertionpoint (obj) ;ประกอบ entity_name กับ insertion_poiint ให้เป็น list (BLOCK ONLY)
      (if (= (vla-get-objectname obj) "AcDbBlockReference")
        (progn
          ;get_data
            (setq ename_ (vlax-vla-object->ename obj)) 
            
            (setq _inspt (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint obj))))
          ;
          ;sum_data_to_list
            (setq sum_list (list 
                            ename_
                            _inspt
                            ;add more
                          )
            )
          ;
        )
        (setq error "OBJECT IS NOT BLOCK")
      )
    )
    (defun TA:vla-get-insertionpoint+ename (obj) ;ประกอบ entity_name กับ insertion_poiint ให้เป็น list (BLOCK ONLY)
      (if (= (vla-get-objectname obj) "AcDbBlockReference")
        (progn
          ;get_data
            (setq ename_ (vlax-vla-object->ename obj)) 
            
            (setq _inspt (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint obj))))
          ;
          ;sum_data_to_list
            (setq sum_list (list 
                            _inspt
                            ename_
                            ;add more
                          )
            )
          ;
        )
        (setq error "OBJECT IS NOT BLOCK")
      )
    )
    (defun TA:move_axis_insertionpoint (blk_obj_ axis_set_ axis_val_) ;ใช้ move axis_set_ ทีละแกน = "x" "y" "z" 
      (if (= (vla-get-objectname blk_obj_) "AcDbBlockReference")
        (progn
          (setq blk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint blk_obj_))))
          (cond
            (;aixs_case_1
              (and 
                (= (strcase axis_set_) "X")
                (= (numberp axis_val_) T)
              )
              (progn
                (vla-put-insertionpoint blk_obj_ 
                                        (vlax-3d-point (list
                                                          (+ (car blk_obj_ins_) axis_val_)
                                                          (+ (cadr blk_obj_ins_) 0)
                                                          (+ (caddr blk_obj_ins_) 0)
                                                        )
                                        )
                )
                (princ "aixs_case_1")
              )
            )
            (;aixs_case_2
              (and
                  (= (strcase axis_set_ ) "Y")
                  (= (numberp axis_val_) T)
              )
              (progn
                (vla-put-insertionpoint blk_obj_ 
                                        (vlax-3d-point (list
                                                          (+ (car blk_obj_ins_) 0)
                                                          (+ (cadr blk_obj_ins_) axis_val_)
                                                          (+ (caddr blk_obj_ins_) 0)
                                                        )
                                        )
                )
                (princ "aixs_case_2")
              )
            )
            (;aixs_case_3
              (and 
                (= (strcase axis_set_) "Z")
                (= (numberp axis_val_) T)
              )
              (progn
                (vla-put-insertionpoint blk_obj_ 
                                        (vlax-3d-point (list
                                                          (+ (car blk_obj_ins_) 0)
                                                          (+ (cadr blk_obj_ins_) 0)
                                                          (+ (caddr blk_obj_ins_) axis_val_)
                                                        )
                                        )
                )
                (princ "aixs_case_3")
              )
            )
          )
          
        )
      )
    )
    (defun TA:ename+vla-getboundingbox (obj) ;ประกอบ entity_name กับ vla-getboundingbox ให้เป็น list (LINE OR POLYLINE ONLY)
      ; (setq obj (vla-get-objectname (vlax-ename->vla-object (car (entsel))))) ;For Check objectname
      (if (or
            (= (vla-get-objectname obj) "AcDbLine")
            (= (vla-get-objectname obj) "AcDbPolyline")
            (= (vla-get-objectname obj) "AcDbBlockReference") 
            (= (vla-get-objectname obj) "AcDbArc") 
          )
        (progn
          ;get_data
            (setq ename_ (vlax-vla-object->ename obj)) 
            
            (setq _inspt (vla-getboundingbox obj 'min_ 'max_))
            (setq min_ (vlax-safearray->list min_))
            (setq max_ (vlax-safearray->list max_))
          ;
          ;sum_data_to_list
            (setq sum_list (list 
                            ename_
                            min_
                            max_
                            ;add more
                          )
            )
          ;
        )
        (setq error "OBJECT IS NOT LINE/POLYLINE")
      )
    )
    (defun TA:ss_vla-getboundingbox (sss_)
      ; (setq sss_ (ssget))
      (cond
        (;type_case_1
            (and
              (= (type sss_) 'PICKSET)
            )
            (progn
              ;preloop_and_while
                (setq sss_i 0)
                (setq sss_obj_getboundingbox_list_ nil)
                (while (< sss_i (sslength sss_))
                  (setq sss_ename_ (ssname sss_ sss_i))
                  (setq sss_obj_ (vlax-ename->vla-object sss_ename_))
                  (setq sss_obj_getboundingbox (vla-getboundingbox sss_obj_ 'min_ 'max_)) 
                  (setq sss_min_ (vlax-safearray->list min_)) 
                  (setq sss_max_ (vlax-safearray->list max_))
                  (setq sss_obj_getboundingbox_list_ (cons (list sss_min_ sss_max_) sss_obj_getboundingbox_list_))      
                  (setq sss_i (+ sss_i 1))
                )
                ;TA:stanndard_lambda_sorting
                  (setq low_xy_ (list 
                                  (setq low_x (car 
                                                (car 
                                                  (car 
                                                    (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                            (function 
                                                              (lambda (a b) 
                                                                (< (nth 0 (car a)) 
                                                                    (nth 0 (car b))
                                                                )
                                                              )
                                                            )
                                                    )
                                                  )
                                                )
                                              ) ;bigest close indent list
                                  )
                                  (setq low_y (cadr 
                                                (car 
                                                  (car 
                                                    (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                            (function 
                                                              (lambda (a b) 
                                                                (< (nth 1 (car a)) 
                                                                    (nth 1 (car b))
                                                                )
                                                              )
                                                            )
                                                    )
                                                  )
                                                )
                                              ) ;bigest close indent list
                                  )
                                )
                  )
                  (setq high_xy_ (list 
                                  (setq high_x (car 
                                                  (cadr 
                                                    (car 
                                                      (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                              (function 
                                                                (lambda (a b) 
                                                                  (> (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                  )
                                                                )
                                                              )
                                                      )
                                                    )
                                                  )
                                                ) ;bigest close indent list
                                  )
                                  (setq high_y (cadr 
                                                  (cadr 
                                                    (car 
                                                      (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                              (function 
                                                                (lambda (a b) 
                                                                  (> (nth 1 (cadr a)) 
                                                                      (nth 1 (cadr b))
                                                                  )
                                                                )
                                                              )
                                                      )
                                                    )
                                                  )
                                                ) ;bigest close indent list
                                  )
                                )
                  )
                ;
                (list low_xy_ high_xy_  )
                
              ;
              ; (princ "type_case_1")
            )
        )
        (;type_case_2
          (and
            (= (type sss_) 'LIST)
          )
          (progn
            (progn
              ;preloop_and_while
                (setq sss_i 0)
                (setq sss_obj_getboundingbox_list_ nil)
                (while (< sss_i (length sss_))
                  (setq sss_ename_ (nth sss_i sss_ ))
                  (setq sss_obj_ (vlax-ename->vla-object sss_ename_))
                  (setq sss_obj_getboundingbox (vla-getboundingbox sss_obj_ 'min_ 'max_)) 
                  (setq sss_min_ (vlax-safearray->list min_)) 
                  (setq sss_max_ (vlax-safearray->list max_))
                  (setq sss_obj_getboundingbox_list_ (cons (list sss_min_ sss_max_) sss_obj_getboundingbox_list_))      
                  (setq sss_i (+ sss_i 1))
                )
                ;TA:stanndard_lambda_sorting
                  (setq low_xy_ (list 
                                  (setq low_x (car 
                                                (car 
                                                  (car 
                                                    (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                            (function 
                                                              (lambda (a b) 
                                                                (< (nth 0 (car a)) 
                                                                    (nth 0 (car b))
                                                                )
                                                              )
                                                            )
                                                    )
                                                  )
                                                )
                                              ) ;bigest close indent list
                                  )
                                  (setq low_y (cadr 
                                                (car 
                                                  (car 
                                                    (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                            (function 
                                                              (lambda (a b) 
                                                                (< (nth 0 (cadr a)) 
                                                                    (nth 0 (cadr b))
                                                                )
                                                              )
                                                            )
                                                    )
                                                  )
                                                )
                                              ) ;bigest close indent list
                                  )
                                )
                  )
                  (setq high_xy_ (list 
                                  (setq high_x (car 
                                                  (cadr 
                                                    (car 
                                                      (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                              (function 
                                                                (lambda (a b) 
                                                                  (> (nth 0 (car a)) 
                                                                      (nth 0 (car b))
                                                                  )
                                                                )
                                                              )
                                                      )
                                                    )
                                                  )
                                                ) ;bigest close indent list
                                  )
                                  (setq high_y (cadr 
                                                  (cadr 
                                                    (car 
                                                      (vl-sort sss_obj_getboundingbox_list_  ;bigest open indent list
                                                              (function 
                                                                (lambda (a b) 
                                                                  (> (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                  )
                                                                )
                                                              )
                                                      )
                                                    )
                                                  )
                                                ) ;bigest close indent list
                                  )
                                )
                  )
                ;
                (list low_xy_ high_xy_  )
              ;
              ; (princ "type_case_1")
            ) 
          )
        )
      ) 
    )
    (defun TA:Get_Pline_vertext_angle_case1 (ename_) 
      ; (setq ename_ new_rec)
      (setq s_ (cadr (TA:Get_Pline_vertext_ins_point_ ename_)))
      (setq d1 (angtos (angle (nth 1 s_) (nth 2 s_))))
      (setq s_i 0)
      (setq s_ii 1)
      (setq end_val_ nil)
      (setq sum_ ())
      (while (< s_i (length s_))
          (setq pt_1 (nth s_i s_))
          (setq pt_3 (nth s_i s_))
          (if (= s_ii (length s_)) 
            (progn 
              (setq end_val_ "end")
              (setq pt_3 (nth (- s_i 1) s_))
            )
            (setq pt_2 (nth s_ii s_))
          )
          (setq angle_pt (atof (angtos (angle pt_1 pt_2))))
          (if (= end_val_ "end") 
            (progn
              (setq angle_pt (atof (angtos (angle pt_3 pt_1))))
              (setq sum (append  (list pt_1) (list angle_pt s_ii) ))
            )
            (setq sum (append  (list pt_1) (list angle_pt s_ii)))
          )
          
          (setq sum_ (cons sum sum_))
          (setq s_i (+ s_i 1))
          (setq s_ii (+ s_ii 1))
      )
      (setq result_ (reverse sum_))
    )
    (defun TA:Get_Pline_vertext_angle_case2 (ename_) 
      (setq s_ (cadr (TA:Get_Pline_vertext_ins_point_ ename_)))
      (setq d1 (angtos (angle (nth 1 s_) (nth 2 s_))))
      (setq s_i 0)
      (setq s_ii 1)
      (setq end_val_ nil)
      (setq sum_ ())
      (while (< s_i (length s_))
          (setq pt_1 (nth s_i s_))
          (if (= s_ii (length s_)) 
            (progn 
              (setq end_val_ "end")
            )
            (setq pt_2 (nth s_ii s_))
          )
          (setq angle_pt (atof (angtos (angle pt_1 pt_2))))
          (if (= end_val_ "end") 
            (progn 
              (setq sum (append  (list pt_1) (list end_val_ s_ii) ))
            )
            (setq sum (append  (list pt_1) (list angle_pt s_ii)))
          )
          
          (setq sum_ (cons sum sum_))
          (setq s_i (+ s_i 1))
          (setq s_ii (+ s_ii 1))
      )
      (setq result_ (reverse sum_))
    )
    (defun TA:Get_Pline_vertext_ins_point_ (ename_) ;must be (car (entsel))
      (setq Get_Pline_ (entget ename_))
      (setq Get_Pline_vtx_pt (vl-remove-if-not '(lambda (x) (= 10 (car x))) Get_Pline_))
      (setq Get_Pline_vtx_pt_ (mapcar 'cdr Get_Pline_vtx_pt))
      (setq ename+Get_Pline_vtx_pt_ (list
                                      ename_
                                      Get_Pline_vtx_pt_
                                    )
      
      )
    )
    (defun TA:get_vertex_len_ (ename_)
      ; (setq ref_line (car (entsel)))
      (setq ss (vlax-ename->vla-object ename_))
      (setq vertex_total (length (cadr (TA:Get_Pline_vertext_ins_point_ ename_))))
      (setq sum_ ())

      (setq vertex_i 0)
      (setq vertex_ii 1)

      (while (< vertex_i vertex_total)
        (cond
          (;_case_1
            (and
                (/= vertex_i (- vertex_total 1))
            )
            (progn
              ;get_data_len
                (setq len_i (vlax-curve-getDistatParam ss vertex_i) )
                (setq len_ii (vlax-curve-getDistatParam ss vertex_ii))
                ;
                ;sum
                  (setq sum (list (- len_ii len_i)))
                  (setq sum_ (append sum sum_ ))
                ;
              (princ "_case_1\n")
            )
          )
          (;_case_2
            (and
              (= vertex_i (- vertex_total 1))    
            )
            (progn
              ;ไม่มี
              (princ "_case_2\n")
            )
          )

        )
        
        
        (setq vertex_i (+ vertex_i 1))
        (setq vertex_ii (+ vertex_ii 1))
      )
      ;summary_reverse
        (setq sum_len (reverse sum_))
      ;
    )
    (defun TA:midpoint (ins_start_ ins_end_) ;คำนวณ midpoint จากระยะหัว-ท้าย ของเส้น
      ; (setq ins_start_ (list ins_start_x1 ins_start_y1))
      ; (setq ins_end_ (list ins_end_x1 ins_end_y1))
      (setq ins_mid_ (list 
                  (/ (+ (car ins_start_) (car ins_end_)) 2.0)
                  (/ (+ (cadr ins_start_) (cadr ins_end_)) 2.0)
                )
      )
    )
    (defun LM:PolyCentroid (e / l) 
      (foreach x (setq e (entget e)) (if (= 10 (car x)) (setq l (cons (cdr x) l))))
      ((lambda (a) 
        (if (not (equal 0.0 a 1e-8)) 
          (trans 
            (mapcar '/ 
                    (apply 'mapcar 
                          (cons '+ 
                                (mapcar 
                                  (function 
                                    (lambda (a b) 
                                      ((lambda (m) 
                                          (mapcar 
                                            (function (lambda (c d) (* (+ c d) m)))
                                            a
                                            b
                                          )
                                        ) 
                                        (- (* (car a) (cadr b)) (* (car b) (cadr a)))
                                      )
                                    )
                                  )
                                  l
                                  (cons (last l) l)
                                )
                          )
                    )
                    (list a a)
            )
            (cdr (assoc 210 e))
            0
          )
        )
      ) 
      (* 3.0 
          (apply '+ 
                (mapcar 
                  (function 
                    (lambda (a b) (- (* (car a) (cadr b)) (* (car b) (cadr a))))
                  )
                  l
                  (cons (last l) l)
                )
          )
      )
      )
    )
    (defun TA:find_center (main_border_) -
      (setq main_border_obj_ (vlax-ename->vla-object main_border_))
      (setq obj (vla-get-objectname main_border_obj_)) ;For Check objectname
      (if (= obj "AcDbPolyline") 
        (progn 
          (setq main_border_obj_boline_ (TA:ename+vla-getboundingbox main_border_obj_))
          (setq min_crood (cadr main_border_obj_boline_))
          (setq max_crood (caddr main_border_obj_boline_))
          (setq Mx (/ (+ (car min_crood) (car max_crood)) 2))
          (setq My (/ (+ (cadr min_crood) (cadr max_crood)) 2))
          (setq Mz (/ (+ (caddr min_crood) (caddr max_crood)) 2))
          (setq center_point_ (list Mx My Mz))
        )
        (alert "TA:find_center : Object is not PolyLine")
      )
    )
    (defun TA:Find_boundary_line_ (main_border_)
      ;for testing code
        ; (setq main_border_ (car (entsel)))
      ;
      ;get_data_
        (setq main_border_obj_ (vlax-ename->vla-object main_border_))
        (setq obj (vla-get-objectname main_border_obj_)) ;For Check objectname
        (if (or (= obj "AcDbPolyline") (= obj "AcDbBlockReference") (= obj "AcDbArc")) 
          (progn 
            (setq main_border_obj_boline_ (TA:ename+vla-getboundingbox main_border_obj_))
            (setq min_crood (cadr main_border_obj_boline_))
            (setq max_crood (caddr main_border_obj_boline_))
            ; (setq Mx (/ (+ (car min_crood) (car max_crood)) 2))
            ; (setq My (/ (+ (cadr min_crood) (cadr max_crood)) 2))
            ; (setq Mz (/ (+ (caddr min_crood) (caddr max_crood)) 2))
            ; (setq center_point_ (list Mx My Mz))
            (setq obj_boline_ (list 
                                (cadr main_border_obj_boline_ )
                                (caddr main_border_obj_boline_ )
                              )
            )
          )
          (alert "TA:find_center : Object is not PolyLine")
        )
      ;
    )
  ;
  ;convert_value_
    (defun deg-to-rad (angle)
      (* angle (/ pi 180.0))
    )
    (defun rad-to-deg (rad)
      (/ (* rad 180) pi) 
    )
    (defun TA:ModifyRotation (Ex_rotation New_rotation)
      ;Note By Code_Developer
      ;The principle of this code is designed to modify the angle value, allowing for both increments and decrements based on a reference number.
      ;The reference number used must be a value representing degrees, ranging from 1 to 360.
      ;The number added or subtracted from the angle is calculated based on the number of degrees rotated, considering 1 full rotation as 360 degrees.
      ;
      (cond 
        ( ;normal_rotation_case_1
          (and 
            (>= New_rotation 0)
            (<= New_rotation 360)
          )
          (progn
            (princ "rotation_case_1\n")
            (setq new_rotaion_val_ (+ Ex_rotation New_rotation))
            (if (<= new_rotaion_val_ 360)
              (progn
                (setq new_rotaion_val_ (+ Ex_rotation New_rotation))
              )
              (setq new_rotaion_val_ (- (+ Ex_rotation New_rotation) 360))
            )
            
            
          )
        )
        (;multi_time_rotation_case_2
          (and 
            (> New_rotation 360)
          )
          (progn 
            (princ "rotation_case_2\n")
            (setq round_time_ (atoi (rtos (/ New_rotation 360) 2 0)))
            (setq round_time_val (* round_time_ 360))
            (setq new_rotaion_val_ (- New_rotation round_time_val))
            (if (> (+ Ex_rotation new_rotaion_val_ ) 360)
            (progn
              (setq new_rotaion_val_ans_ (-  (+ Ex_rotation new_rotaion_val_ ) 360 ))
            )
              (setq new_rotaion_val_ans_ (+ Ex_rotation new_rotaion_val_ ))
            )
            
          )
        )
        (;rotation_case_3
          (and 
            (<= New_rotation 0) 
          )
          (progn 
            (princ "rotation_case_3\n")
            (setq round_time_ (atoi (rtos (/ New_rotation 360) 2 0)))
            (setq round_time_val (* round_time_ 360))
            (setq new_rotaion_val_ (- New_rotation round_time_val))
            (setq Ex_rotation_val_ (+ Ex_rotation new_rotaion_val_))
            (if (< Ex_rotation_val_ 0)
              (progn
                (setq new_rotaion_val_ans_ (+ 360 Ex_rotation_val_))
              )
              (setq new_rotaion_val_ans_ Ex_rotation_val_ )
            )
            
          )
        )
        
      )
    )
    (defun LM:round ( n )
      (fix (+ n (if (minusp n) -0.5 0.5)))
    )
    (defun LM:roundup (n m) 
      ((lambda (r) (cond ((equal 0.0 r 1e-8) n) ((< n 0) (- n r)) ((+ n (- m r))))) 
        (rem n m)
      )
    )
    (defun relocate_ins_ (data_list_ x_sym x_num_ y_sym y_num_ )
      (if (= (length data_list_) 2)
        (progn
          (setq data_list_ (list 
                            (x_sym (car data_list_) x_num_)
                            (y_sym (cadr data_list_) y_num_)
                          )
          )
        )
      )
    )
    (defun TA:Toerrance_num_ (target_num_ main_num_ tor_num_)
      (if
        (and 
          (< target_num_ (+ main_num_ tor_num_))
          (> target_num_ (- main_num_ tor_num_))
        )
        (progn
          T
        )
      )
    )
    (defun c:Selection-set_reverse_ssreverse ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "LINE") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "LINE") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (if (> (rad-to-deg (vla-get-angle ss_pre_filter_set_xx_obj_)) 90)
            (progn
              (command "reverse" ss_pre_filter_set_xx_ename_ "" )
            )
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
    (defun c:temp_reset_angle_RSANGE_ ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "line") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "line") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          
          (setq ss_pre_filter_set_xx_obj_start_end_pt_ (list
                                          (setq ss_pre_filter_set_xx_obj_startpt_ (vlax-safearray->list
                                                                     (vlax-variant-value ( vla-get-startpoint ss_pre_filter_set_xx_obj_ ))
                                                                   )
                                          )
                                          (setq ss_pre_filter_set_xx_obj_endpt_ (vlax-safearray->list
                                                                    (vlax-variant-value ( vla-get-endpoint ss_pre_filter_set_xx_obj_ ))
                                                                 )
                                          )
                                        )
          )
          (vla-put-endpoint ss_pre_filter_set_xx_obj_
            (vlax-3d-point  
              (car ss_pre_filter_set_xx_obj_endpt_)
              (cadr ss_pre_filter_set_xx_obj_startpt_)
              0
            )
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
  ;
  ;format_FUNC
    (defun format-all-workbook-list (data)
      (progn
        ;; เริ่มต้นเปิดต้น list
        (princ "(")
        (princ (car data)) ; พิมพ์ตัวเลขหลัก
        (princ "\n") ; เว้นบรรทัดเพื่อจัด layout

        ;; ใช้ foreach เพื่อวนลูป book
        (foreach book (cdr data)
          (progn
            (princ "  (")
            (princ (car book)) ; พิมพ์ index ของ book
            (princ " ")
            (princ (cadr book)) ; พิมพ์ชื่อของ book
            (princ " ")
            (princ (caddr book)) ; พิมพ์ object ของ book
            (princ "\n    (\n") ; เว้นบรรทัดสำหรับ sheet list

            ;; วนลูปภายใน sheet list
            (foreach sheet (cadddr book)
              (progn
                (princ "      (")
                (princ (car sheet)) ; พิมพ์ index ของ sheet
                (princ " ")
                (princ (cadr sheet)) ; พิมพ์ชื่อของ sheet
                (princ " ")
                (princ (caddr sheet)) ; พิมพ์ object ของ sheet
                (princ ")\n"))) ; ปิด sheet list
            (princ "    )\n  )\n"))) ; ปิด book และจัด layout
        (princ ")\n")
      )
    )
    (defun format-all-worksheet-list (lst)
      (progn
        ;; พิมพ์ header ของ list
        (princ "(")
        (princ (car lst)) ; พิมพ์ element ตัวแรก
        (princ " ")
        (princ (cadr lst)) ; พิมพ์ element ตัวที่สอง
        (princ " ")
        (princ (caddr lst)) ; พิมพ์ element ตัวที่สาม
        (princ "\n (\n")

        ;; ใช้ foreach สำหรับวนลูป element ย่อย
        (foreach sublist (cadddr lst) ; ส่วนที่เป็น sublist
          (progn
            (princ "  (")
            (princ (car sublist))  ; พิมพ์ element ย่อยตัวแรก
            (princ " ")
            (princ (cadr sublist)) ; พิมพ์ element ย่อยตัวที่สอง
            (princ " ")
            (princ (caddr sublist)) ; พิมพ์ element ย่อยตัวที่สาม
            (princ ")\n")))
        
        ;; ปิดท้าย list
        (princ " )\n)")
      )
    )
    (defun format-data (data)
      (progn
        ;; เริ่มต้นเปิดต้น list
        (princ "(")
        (princ (car data)) ; พิมพ์ตัวเลขหลัก
        (princ "\n") ; เว้นบรรทัดเพื่อจัด layout

        ;; ใช้ foreach เพื่อวนลูป book
        (foreach book (cdr data)
          (progn
            (princ "  (")
            (princ (car book)) ; พิมพ์ index ของ book
            (princ " ")
            (princ (cadr book)) ; พิมพ์ชื่อของ book
            (princ " ")
            (princ (caddr book)) ; พิมพ์ object ของ book
            (princ "\n    (\n") ; เว้นบรรทัดสำหรับ sheet list

            ;; วนลูปภายใน sheet list
            (foreach sheet (cadddr book)
              (progn
                (princ "      (")
                (princ (car sheet)) ; พิมพ์ index ของ sheet
                (princ " ")
                (princ (cadr sheet)) ; พิมพ์ชื่อของ sheet
                (princ " ")
                (princ (caddr sheet)) ; พิมพ์ object ของ sheet
                (princ ")\n"))) ; ปิด sheet list
            (princ "    )\n  )\n"))) ; ปิด book และจัด layout
        (princ ")\n")
      )
    )
  ;
  ;text_convert_
    (defun LM:StringSubst ( new old str / inc len )
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
  ;CLEANER_FUNC Ta Trai
    (defun TA:get_name_block_in_drawing_to_list ()
      ;get_obj_file_
        (setq multi_blocks_obj (vla-get-blocks (vla-get-ActiveDocument (vlax-get-acad-object))))
        (setq block_list_ ())
      ;
      ;method_for_get_name_block_in_drawing
        ;method_1_get_name_
          (vlax-for block_ multi_blocks_obj 
            (setq block_list_ (append block_list_ (list (vla-get-name block_))))
          )
        ;
        ; ;method_2_get_name_
        ;   (setq block_i 0)
        ;   (while (< block_i (vla-get-count multi_blocks_obj))
        ;     (setq block_ (vla-item multi_blocks_obj block_i))
        ;     (setq block_list_ (append block_list_ (list (vla-get-name block_))))
        ;     (setq block_i (1+ block_i))
        ;   )
        ; ;
      ;
      ;sorting_name_block
        (setq sorted_block_list_ (acad_strlsort block_list_))
      ;
      ;preloop_and_while filtter_
        (setq sorted_block_list_i 0)
        (setq filter_sorted_block_ ())

        (while (< sorted_block_list_i (length sorted_block_list_))
          (setq filter_sorted_block_effectivename_ (nth sorted_block_list_i sorted_block_list_))
          
          (if (/= (substr filter_sorted_block_effectivename_ 1 1) "*") ; ตรวจสอบว่าชื่อเริ่มต้นด้วย *
            (progn
              (setq filter_sorted_block_ (cons filter_sorted_block_effectivename_ filter_sorted_block_))
            )
          )
          (setq sorted_block_list_i (+ sorted_block_list_i 1))
        )
      ;
      ;summary_total_block
        (setq filter_sorted_block_total (length filter_sorted_block_))
        (princ "\n                  |=====================|")
        (princ "\n                  | TOTAL BLOCK IN FILE |")
        (princ (strcat "\n                  |     = " (itoa filter_sorted_block_total) " block         |"))
        (princ "\n                  |          set        |")
        (princ "\n                  |---------------------|")
        (setq filter_sorted_block_ (acad_strlsort filter_sorted_block_))
      ;
    )
    (defun TA:RE_COLOR_ALL_NORMAL_OBJECT_CHANGE_ (c-main-color)
      (setq all_obj_in_block (ssget "x" 
                                    (list 
                                      ; (cons 0 "insert")       ;type of object
                                      ; (cons 8 "*GRID*")   ;kind of layer
                                      ; (cons 2 "SSSS")       ;kind of nameblock
                                      ; (cons 62 1)           ;kind of color call sign with color code index
                                    )
                              )
      )
      (command "chprop" all_obj_in_block "" "c" c-main-color "")
    )
    (defun TA:RE_COLOR_ALL_DIM+LEADER_OBJ (dim-main-color)
      ;dim_obj_mode
        ; (setq ss (vlax-get-property (vlax-ename->vla-object (car (entsel))) 'objectname)) ;logic for testing
        ; (setq ss (vlax-dump-object (vlax-ename->vla-object (car (entsel))) 'objectname))  ;logic for testing
        ;user_input_ selection_dim_object
          (setq all_dim_out_block (ssget "x" 
                                          (list 
                                            (cons 0 "dimension")       ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "SSSS")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                  )
          )
        ;
        ; (command "pselect" all_dim_out_block "")
        (if (/= all_dim_out_block nil)
          (progn
            (setq all_dim_out_block_total (sslength all_dim_out_block))
            (setq all_dim_out_block_iii 0)
            (while
              (< all_dim_out_block_iii all_dim_out_block_total)
              (setq all_dim_out_block_ename (ssname all_dim_out_block all_dim_out_block_iii))
              (setq all_dim_out_block_obj (vlax-ename->vla-object all_dim_out_block_ename))
              ; (vlax-dump-object all_dim_out_block_obj)
                (cond 
                  ((and 
                      (= (vlax-get-property all_dim_out_block_obj 'objectname) 
                          "AcDbAlignedDimension"
                      )
                    )
                    (progn 
                      (vla-put-textcolor all_dim_out_block_obj dim-main-color)
                      (vla-put-dimensionlinecolor all_dim_out_block_obj dim-main-color)
                      (vla-put-extensionlinecolor all_dim_out_block_obj dim-main-color)
                    )
                    (princ "\n")
                  )
                  ((and 
                      (= (vlax-get-property all_dim_out_block_obj 'objectname) 
                          "AcDb2LineAngularDimension"
                      )
                    )
                    (progn 
                      (vla-put-textcolor all_dim_out_block_obj dim-main-color)
                      (vla-put-dimensionlinecolor all_dim_out_block_obj dim-main-color)
                      (vla-put-extensionlinecolor all_dim_out_block_obj dim-main-color)
                    )
                  )
                  ((and 
                      (= (vlax-get-property all_dim_out_block_obj 'objectname) 
                          "AcDbRotatedDimension"
                      )
                    )
                    (progn 
                      (vla-put-textcolor all_dim_out_block_obj dim-main-color)
                      (vla-put-dimensionlinecolor all_dim_out_block_obj dim-main-color)
                      (vla-put-extensionlinecolor all_dim_out_block_obj dim-main-color)
                    )
                  )
                  ((and 
                      (= (vlax-get-property all_dim_out_block_obj 'objectname) 
                          "AcDbArcDimension"
                      )
                    )
                    (progn 
                      (vla-put-textcolor all_dim_out_block_obj dim-main-color)
                      (vla-put-dimensionlinecolor all_dim_out_block_obj dim-main-color)
                      (vla-put-extensionlinecolor all_dim_out_block_obj dim-main-color)
                    )
                  )
                  ((and 
                      (= (vlax-get-property all_dim_out_block_obj 'objectname) 
                          "AcDbDiametricDimension" 
                      )
                    )
                    (progn 
                      (vla-put-textcolor all_dim_out_block_obj dim-main-color)
                      (vla-put-dimensionlinecolor all_dim_out_block_obj dim-main-color)
                    )
                  )
                  ((and 
                      (= (vlax-get-property all_dim_out_block_obj 'objectname) 
                          "AcDbOrdinateDimension" 
                      )
                    )
                    (progn 
                      (vla-put-textcolor all_dim_out_block_obj dim-main-color)
                      (vla-put-ExtensionLineColor  all_dim_out_block_obj dim-main-color)
                    )
                  )
                  ((and 
                      (= (vlax-get-property all_dim_out_block_obj 'objectname) 
                          "AcDbRadialDimension" 
                      )
                    )
                    (progn 
                      (vla-put-textcolor all_dim_out_block_obj dim-main-color)
                      (vla-put-dimensionlinecolor all_dim_out_block_obj dim-main-color)
                    )
                  )
                )
              ; (vla-put-textcolor all_dim_out_block_obj dim-main-color)
              ; (vla-put-dimensionlinecolor all_dim_out_block_obj dim-main-color)
              ; ; (vla-put-extensionlinecolor all_dim_out_block_obj dim-main-color)
              (setq all_dim_out_block_iii (+ all_dim_out_block_iii 1))
            )
          )
          (princ "\n")
        )
      ;
      ;leader_obj_mode
        ;user_input_ selection_leader_object    
          (setq all_leader_out_block (ssget "x" 
                                        (list 
                                          (cons 0 "leader")       ;type of object
                                          ; (cons 8 "*GRID*")   ;kind of layer
                                          ; (cons 2 "SSSS")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                )
          )
        ;
          (if (/= all_leader_out_block nil)
            (progn
              (setq all_leader_out_block_total (sslength all_leader_out_block))
              (setq all_leader_out_block_iii 0)
              (while
                (< all_leader_out_block_iii all_leader_out_block_total)
                (setq all_leader_out_block_ename (ssname all_leader_out_block all_leader_out_block_iii))
                (setq all_leader_out_block_obj (vlax-ename->vla-object all_leader_out_block_ename))
                (vla-put-dimensionlinecolor all_leader_out_block_obj dim-main-color)
                (setq all_leader_out_block_iii (+ all_leader_out_block_iii 1))
              )
            )
            (princ "\n")
          )
      ;
    )
  ;
  ;delete_func_
    (defun TA:delete_block_ (selection_set_ efname_val_1 efname_val_2 efname_val_3)
      ;for testing_data_
        ; (setq selection_set_ (ssget ))
        ; (setq efname_val_ "special_block2460499.7018" )
      ;
      ;get_data_
        
      ;
      ;prelooop_and_while
        (setq selection_set_i 0)
        (while  (< selection_set_i (sslength selection_set_))
          (setq selection_set_ename_ (ssname selection_set_ selection_set_i))
          (setq selection_set_ename_obj (vlax-ename->vla-object selection_set_ename_))
          
            ;delete_block_process
              (if
                (and 
                  (/= (LM:effectivename selection_set_ename_obj) efname_val_1)
                  (/= (LM:effectivename selection_set_ename_obj) efname_val_2)
                  (/= (LM:effectivename selection_set_ename_obj) efname_val_3)
                )
                (progn
                  (vla-delete selection_set_ename_obj)
                )
                (princ "/nnext")
              )
            ;
          
          (setq selection_set_i (+ selection_set_i 1))
        )
      ;

    )
  ;
  ;CREATE_OBJECT_FUNC
    ;text
      (defun create-text-vla (pt textString height rotation / acadDoc textObj) 
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq textObj (vla-addtext modelSpace textString pt height))
        (vla-put-Height textObj height)
        (vla-put-Rotation textObj rotation)
        textObj
      )
    ;
    ;add+pline_data
      (defun TA:vla-AddLightWeightPolyline_(point_list_)
          ;; This example creates a lightweight polyline in model space.
          (setq acadObj (vlax-get-acad-object))
          (setq doc (vla-get-ActiveDocument acadObj))
          
          ;; Define the intersection points
          

          ;; Convert 3D points to a flat 2D list
          (setq points (apply 'append (mapcar '(lambda (pt) (list (car pt) (cadr pt))) point_list_)))

          ;; Convert to safe array
          (setq pointArray (vlax-make-safearray vlax-vbDouble (cons 0 (- (length points) 1))))
          (vlax-safearray-fill pointArray points)
              
          ;; Create a lightweight Polyline object in model space
          (setq modelSpace (vla-get-ModelSpace doc))
          (setq plineObj (vla-AddLightWeightPolyline modelSpace pointArray))
          (vla-ZoomAll acadObj)
      )
      (defun create-pline (coords)
        (if (= (length coords) 0)
            nil
          (progn
            ; สร้างพอลีไนจากค่าพิกัด
            (command "pline" (car coords) )
            
            ; วนลูปผ่านพิกัดทั้งหมดและเชื่อมต่อเส้นต่อเนื่อง
            (foreach coord (cdr coords)
              (command coord )
            )
          )
        )
        (command "")
      )
      (defun create-plines (coords close_loop_)
        (if (= (length coords) 0)
            nil
          (progn
            ; สร้างพอลีไนจากค่าพิกัด
            (command "pline" (car coords) )
            
            ; วนลูปผ่านพิกัดทั้งหมดและเชื่อมต่อเส้นต่อเนื่อง
            (foreach coord (cdr coords)
              (command coord )
            )
          )
        )
        (command "")
        (cond
          ( (= close_loop_ "close") 
            (progn 
              (setq new_line_data_ (vlax-ename->vla-object (entlast)))
              (vla-put-closed new_line_data_ :vlax-true)
            )
          )
          ((= close_loop_ "open") 
            (progn 
              (setq new_line_data_ (vlax-ename->vla-object (entlast)))
              (vla-put-closed new_line_data_ :vlax-false)
            )
          )
        )
      )
      (defun TA:vla-addvertex_ (pline_obj_ vertex_num_ point_list_)
        (setq point_list_new (remove_single_list_ 2 point_list_))
        (setq newVertex (vlax-make-safearray vlax-vbDouble '(0 . 1)))
        (vlax-safearray-fill newVertex point_list_new)
        (vla-addvertex pline_obj_ vertex_num_ newVertex)
      )
      (defun TA:add_vertex_point_pline_via_breakpt_ (ename_cut_edge_ ename_intersection_obj_)
        
        ;get_data_main_cut_and_main_intersection_
          (setq bb_obj_ (vlax-ename->vla-object ename_cut_edge_))     
          (setq ss_obj_ (vlax-ename->vla-object ename_intersection_obj_))     
          (setq intersec_ (LM:intersections+0 
                            bb_obj_
                            ss_obj_
                            acextendnone
                          )
          )
          (setq vertex_list_ (TA:Get_Pline_vertext_angle_case1 
                                ename_intersection_obj_
                              )
          )
          (setq intersec_i 0)
        ;
        ;preloop_and_while adding_vertex_point_
          (setq ename_list_ ())
          (setq ssadd_list_ (ssadd))
          (while   (< intersec_i (length intersec_))
            (setq intersec_val_ (nth intersec_i intersec_))
            (command "breakatpoint" ename_intersection_obj_ intersec_val_ "")
            (setq new_E_ (entlast))
            ; (command "pselect" new_E_)
            ; (command "pselect" ss)
            (setq ename_list_ (cons new_E_ ename_list_))
            (setq ssadd_list_ (ssadd new_E_ ssadd_list_))
            (setq ssadd_list_ (ssadd ename_intersection_obj_ ssadd_list_))
            (sslength ssadd_list_)
            (command "_.pedit" "_m" ssadd_list_ "" "_j" "" "")
            (setq ename_intersection_obj_ (entlast))
            (setq intersec_i (+ intersec_i 1))
            
          )
        ;
      )
      (defun TA:add_vertex_point_pline_via_breakpt_1 (ename_cut_edge_ ename_intersection_obj_)
        
            
            ;get_data_main_cut_and_main_intersection_
              (setq bb_obj_ (vlax-ename->vla-object ename_cut_edge_))     
              (setq ss_obj_ (vlax-ename->vla-object ename_intersection_obj_))     
              (setq intersec_ (LM:intersections+0 
                                bb_obj_
                                ss_obj_
                                acextendnone
                              )
              )
              (command "pedit" ename_intersection_obj_ "" "c" "" )
              (setq vertex_list_ (TA:Get_line_ins_point_ 
                                    ename_intersection_obj_
                                  )
              )
              (setq intersec_i 0)
            ;
            ;preloop_and_while adding_vertex_point_
              (setq ename_list_ ())   
              (setq ssadd_list_ (ssadd))
              (while   (< intersec_i (length intersec_))
                (setq intersec_val_ (nth intersec_i intersec_))
                (command "breakatpoint" ename_intersection_obj_ intersec_val_ "")
                
                (setq new_E_ (entlast))
                ; (command "pselect" new_E_)
                ; (command "pselect" ss)
                (setq ename_list_ (cons new_E_ ename_list_))
                (setq ssadd_list_ (ssadd new_E_ ssadd_list_))
                (setq ssadd_list_ (ssadd ename_intersection_obj_ ssadd_list_))
                (sslength ssadd_list_)
                (command "_.pedit" "_m" ssadd_list_ "y" "" "_j" "" "")
                (command "_.pedit" "_m" ssadd_list_ "" "y" )
                (setq ename_intersection_obj_ (entlast))
                (setq intersec_i (+ intersec_i 1))
                
              )
            ;
      )
    ;
    ;add_circle
      (defun TA:vla-addarc_ (center_ rad_ point_list_ )
        ; point_list_ must be two coord set in list
        ; do not vlax-3d_point w/ agument
        ;sub_func_
          (defun CO:sort_by_val_ (val_ list_ )  ;เรียงชุดข้อมูลตามแนวแกน
            (if (< val_ (length (car list_)))
              (progn
                (setq sortedLst (vl-sort list_ (function (lambda (a b) (< (nth val_ a) (nth val_ b))))))
              )
              (setq error_ "The number of val is less than list")
            )
          )
        ;
        ;basic_get_data_
          (setq acadObj (vlax-get-acad-object))
          (setq doc (vla-get-ActiveDocument acadObj))
          (setq modelSpace (vla-get-ModelSpace doc))
        ;
        ;advance_get_data
          ; (setq point_list_ (reverse (append (CO:sort_by_val_ 1 point_list_) (list (car point_list_)))))
          (setq point_list_ (append (CO:sort_by_val_ 1 point_list_) (list (car point_list_))))
        ;
        ;preloop_and_while sorting arc_line
          (setq angle_list_ ())
          (setq point_list_i 0)
          (setq point_list_ii 1)
          (while (< point_list_i (- (length point_list_) 1))
            (setq point_list_set_1 (nth point_list_i point_list_))
            (setq angle_ (atof (angtos (angle center_ point_list_set_1))))
            (setq sum (list
                        point_list_set_1
                        angle_
                      )
            )
            (setq angle_list_ (cons sum angle_list_))
            (setq point_list_i (+ point_list_i 1))
            (setq point_list_ii (+ point_list_ii 1))
          )
        ;
        (setq point_list_ (append (CO:sort_by_val_ 1 angle_list_) (list (car (CO:sort_by_val_ 1 angle_list_) ))) )
        (setq point_list_i 0)
        (setq point_list_ii 1)
        (while (< point_list_i (- (length point_list_) 1))
          (setq point_list_set_1 (car (nth point_list_i point_list_)))
          (setq point_list_set_2 (car (nth point_list_ii point_list_)))
          (setq start_ang_ (angle center_ point_list_set_1))
          (setq end_ang_ (angle center_ point_list_set_2))
          ; (setq rad_ (distance center_ point_list_set_1))
          
          (vla-addarc modelSpace (vlax-3d-point center_) rad_  start_ang_ end_ang_)
          (setq point_list_i (+ point_list_i 1))
          (setq point_list_ii (+ point_list_ii 1))
        )
        
      )
      (defun TA:vla-addarc_half_ (center_ rad_ point_list_ )
        ; point_list_ must be two coord set in list
        ; do not vlax-3d_point w/ agument
        ;sub_func_
          (defun CO:sort_by_val_ (val_ list_ )  ;เรียงชุดข้อมูลตามแนวแกน
            (if (< val_ (length (car list_)))
              (progn
                (setq sortedLst (vl-sort list_ (function (lambda (a b) (< (nth val_ a) (nth val_ b))))))
              )
              (setq error_ "The number of val is less than list")
            )
          )
        ;
        ;basic_get_data_
          (setq acadObj (vlax-get-acad-object))
          (setq doc (vla-get-ActiveDocument acadObj))
          (setq modelSpace (vla-get-ModelSpace doc))
        ;
        ;advance_get_data
          ; (setq point_list_ (reverse (append (CO:sort_by_val_ 1 point_list_) (list (car point_list_)))))
          (setq point_list_ (append (CO:sort_by_val_ 1 point_list_) (list (car point_list_))))
        ;
        ;preloop_and_while sorting arc_line
          (setq angle_list_ ())
          (setq point_list_i 0)
          (setq point_list_ii 1)
          (while (< point_list_i (- (length point_list_) 1))
            (setq point_list_set_1 (nth point_list_i point_list_))
            (setq angle_ (atof (angtos (angle center_ point_list_set_1))))
            (setq sum (list
                        point_list_set_1
                        angle_
                      )
            )
            (setq angle_list_ (cons sum angle_list_))
            (setq point_list_i (+ point_list_i 1))
            (setq point_list_ii (+ point_list_ii 1))
          )
        ;
        (setq point_list_ (append (CO:sort_by_val_ 1 angle_list_) (list (car (CO:sort_by_val_ 1 angle_list_) ))) )
        (setq point_list_i 0)
        (setq point_list_ii 1)
        (while (< point_list_i (- (length point_list_) 2))
          (setq point_list_set_1 (car (nth point_list_i point_list_)))
          (setq point_list_set_2 (car (nth point_list_ii point_list_)))
          (setq start_ang_ (angle center_ point_list_set_1))
          (setq end_ang_ (angle center_ point_list_set_2))
          ; (setq rad_ (distance center_ point_list_set_1))
          
          (vla-addarc modelSpace (vlax-3d-point center_) rad_  start_ang_ end_ang_)
          (setq point_list_i (+ point_list_i 1))
          (setq point_list_ii (+ point_list_ii 1))
        )
        
      )
      (defun TA:add_full_circle_ (center_pt radius)
        ;default adding VLA
          (setq acadObj (vlax-get-acad-object))
          (setq doc (vla-get-ActiveDocument acadObj))
          (setq modelSpace (vla-get-ModelSpace doc))
        ;
        ;vla-addcircle method
          (vla-addcircle modelSpace  
                        (vlax-3d-point center_pt) 
                        radius
          )
          (entlast)
        ;
      )
    ;
    ;add-point
      (defun vla-addpoint_ (point) 
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (vla-addpoint modelSpace (vlax-3d-point point))
      )
    ;
    ;get_line
      (defun TA:Get_line_ins_point_ (ename_)
        
        ; (setq ename_ (car (entsel)))
        (setq ename_obj_ (vlax-ename->vla-object ename_))
        (setq ename_obj_str_pt_ (vlax-safearray->list (vlax-variant-value (vla-get-startpoint ename_obj_))))
        (setq ename_obj_end_pt_ (vlax-safearray->list (vlax-variant-value (vla-get-endpoint ename_obj_))))
        (setq sum_ (list
                    ename_obj_str_pt_
                    ename_obj_end_pt_
                  )
        )
      )
      
    ;
    ;offset
      (defun TA:Offset_line (ename num_ )
        ; (setq 1-PL_en_ (car (entsel)))
        (setq 1-PL_en_obj (vlax-ename->vla-object ename))
        (vla-Offset 1-PL_en_obj num_)
      )
      (defun TA:Offset_Pline_multi_vertex_ (ename num_ mode)
        ; ;for_testing_mode
        ;   (setq ename (car (entsel)))
        ;   (setq num_ 0.01)
        ;   (setq mode "min")
        ; ;
        ;test_vla-get-objectname_process
          (if (= (vla-get-objectname (vlax-ename->vla-object ename)) "AcDbPolyline")
            (progn
              (setq Get_Pline_ (entget ename))
              (setq Get_Pline_vtx_pt (vl-remove-if-not '(lambda (x) (= 10 (car x))) Get_Pline_))
              (setq Get_Pline_vtx_pt_ (mapcar 'cdr Get_Pline_vtx_pt))
            )
          )
        ;
        ;test_length_vertex_process
          (if 
            (and
              (= (vla-get-objectname (vlax-ename->vla-object ename)) "AcDbPolyline")
              (> (length Get_Pline_vtx_pt_) 2)
            )
            (progn
              (setq num_plus_ (* num_ 1))
              (setq num_minus_ (* num_ -1))
              (setq 1-PL_en_obj (vlax-ename->vla-object ename))
            )
            (princ "s")
          )
        ;
        ;plus mode process
          (if 
            (and
              (= (vla-get-objectname (vlax-ename->vla-object ename)) "AcDbPolyline")
              (> (length Get_Pline_vtx_pt_) 2)
            )
            (progn
              (setq result_num_plus_ ())
              (vla-Offset 1-PL_en_obj num_plus_)
              (setq num_plus_obj_ (entlast))
              (setq num_plus_area_ (vla-get-area (vlax-ename->vla-object num_plus_obj_)))
              (setq result_num_plus_ (cons num_plus_area_ result_num_plus_))
              (setq result_num_plus_ (cons num_plus_obj_ result_num_plus_))
            )
            (princ "s")
          )
        ;
        ;minus mode process
          (if 
            (and
              (= (vla-get-objectname (vlax-ename->vla-object ename)) "AcDbPolyline")
              (> (length Get_Pline_vtx_pt_) 2)
            )
            (progn
              (setq result_num_minus_ ())
              (vla-Offset 1-PL_en_obj num_minus_)
              (setq num_minus_obj_ (entlast))
              (setq num_minus_area_ (vla-get-area (vlax-ename->vla-object num_minus_obj_)))
              (setq result_num_minus_ (cons num_minus_area_ result_num_minus_))
              (setq result_num_minus_ (cons num_minus_obj_ result_num_minus_))
            )
            (princ "s")
          )
        ;
        ;result_data
          (setq resul_overall_ (append (list result_num_minus_) (list result_num_plus_)))
        ;
        (cond 
          ((and
            (= mode "max")
          )
          (progn
            (setq max_data_ (CO:sort_by_val_ 1 resul_overall_  ))
            (vla-delete (vlax-ename->vla-object (car (nth 0 max_data_))))
            (setq new_data_ (car (nth 1 max_data_)))
          )
          )
          ((= mode "min")
          (progn
            (setq min_data_ (reverse (CO:sort_by_val_ 1 resul_overall_  )))
            (vla-delete (vlax-ename->vla-object (car (nth 0 min_data_))))
            (setq new_data_ (car (nth 1 min_data_)))
            
          )
          )
          
        )
      )
    ;
  ;
  ;Block Editor_FUNC
    (defun TA:vla-insertblock (blockName insertion_point scale rotation)
      (setq acadApp (vlax-get-acad-object))  ; เข้าถึง AutoCAD application
      (setq doc (vla-get-ActiveDocument acadApp))
      (if (and 
            ; (= (getvar "ctab" ) "Model")
            (>= (getvar "cvport") 2)
          )
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
                                          ;   ; (cons 8 "*GRID*")   ;kind of layer
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
                                          ;   ; (cons 8 "*GRID*")   ;kind of layer
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
                                          ;   ; (cons 8 "*GRID*")   ;kind of layer
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
                                          ;   ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                            ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
              (TA:vla-insertblock 
                nameblk 
                (if (= (getvar "worlducs") 0)(progn (trans pttarget_torr 1 0)) pttarget_torr ) 
                1 
                0 
              )
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
    (defun c:MKPartBLK_MKP2 () 
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq sstarget_ (ssget "i"
                                              (list
                                                ; (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
      
      (setvar "osmode" 1215)ผ
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
                          "_CSD-PLAN"
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
  ;dynamic_block_FUNC
    ;dynamic_Alminium_sheet_FUNC
      (defun c:dynamic_update_U-Carrier_[UCupdate] ()
        
        ;user_input get_effectivename 
          (setq get_effectivename_ nil)
          ; (setq get_effectivename_lasted nil)
          (setq get_effectivename_obj_val_ nil)
        ;
        ;preloop_and_while_
          (while (not get_effectivename_)
            (princ (setq get_effectivename_ (car (entsel "\nPlease Specify Attribute Block\n"))))   
            (if (/= get_effectivename_ nil)
              (progn
                (setq get_effectivename_lasted get_effectivename_)
              )
            )          
                      
            (if 
              (and ;condition rule
                
                (setq B (= (setq type_obj_ (vla-get-objectname (vlax-ename->vla-object (if (= get_effectivename_ nil) (progn get_effectivename_lasted ) get_effectivename_ )))) 
                          "AcDbBlockReference"
                        )
                )
                ; (= (substr (LM:Effectivename (vlax-ename->vla-object get_effectivename_)) 1 72) "000 - DYNAMIC_ARRAY_ASSCESSORIES_FAMELINE_AL._U45-CARRIER_BRACKET_FITTING")
                (setq C 
                        (= 
                          (wcmatch
                          (LM:Effectivename (vlax-ename->vla-object (if (= get_effectivename_ nil) (progn get_effectivename_lasted ) get_effectivename_ ))) 
                          "*000 - DYNAMIC_ARRAY_ASSCESSORIES_FAMELINE_AL._U45-CARRIER_BRACKET_FITTING*"
                          )
                        )
                )
                ; (= (vla-get-hasattributes (vlax-ename->vla-object get_effectivename_)) :vlax-true)
                (setq D (= (vla-get-isdynamicblock (vlax-ename->vla-object (if (= get_effectivename_ nil) (progn get_effectivename_lasted ) get_effectivename_ )))
                          :vlax-true
                        )
                )
              )
              (progn ;add data
                ; (alert "\nplease select block object")
                ; (setq get_effectivename_ nil)
                ; (setq get_effectivename_obj_val_ nil)
                ;get_dynamic_data
                  (setq get_effectivename_ get_effectivename_lasted)
                  (setq get_effectivename_obj_val_ (LM:Effectivename (vlax-ename->vla-object get_effectivename_)))
                  (setq array_width (LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "array_width" ))
                  (setq total_u-profile_depth (LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "total_u-profile_depth" ))
                  (setq u-profile_width_set (LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "u-profile_width_set" ))
                  
                  ; (setq louver_angle_ (LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "louver_angle" )) ;ปิดชั่วคราวเปลี่ยนเป็น user input 
                  (setq louver_angle_deg (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq louver_angle_deg (cond (louver_angle_deg) (1.2) ) ) ) "> : " ) ) ) (louver_angle_deg) ) ) ;
                  (setq louver_angle_ (deg-to-rad louver_angle_deg) )

                  ; (setq louver_width_(LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "louver_width" )) ;ปิดชั่วคราวเปลี่ยนเป็น user input 
                  (setq louver_width_ (cond ( (getreal (strcat "\nspecify louver_width_<" (rtos (setq louver_width_ (cond (louver_width_) (10) ) ) ) "> : " ) ) ) (louver_width_) ) )
                  (setq u-profile_width_set (LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "u-profile_width_set"  ))
                  (setq louver_depth_start_angle_ (deg-to-rad 90))
                  (setq louver_depth_end_angle_ (deg-to-rad (- 180 (+ 90 (rad-to-deg louver_angle_)  ))))
                
                  (setq position_1Y (LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "Position1 Y" ))
                ;
                ;reset_block_process_
                  (command "resetblock" get_effectivename_ "" )
                  (setq u-profile_width_set (LM:getdynpropvalue (vlax-ename->vla-object get_effectivename_) "array_width" ))
                  
                ;
                ;trigonmetry_cal
                  ;find_ louver_depth_ formula
                    ;
                      (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "louver_depth" 
                        (if (>= louver_angle_deg 90)
                          (progn
                            louver_width_
                          )
                          (/
                            (* 
                              (sin louver_angle_)
                              louver_width_
                            ) 
                            (sin louver_depth_end_angle_)
                          )
                        )
                      )
                    ;
                  ;
                  ;find_ base_trigon_ formula
                    ;
                      (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "base_trigon" 
                        (if (>= louver_angle_deg 90)
                          (progn
                            louver_width_
                          )
                          (/
                            (* 
                              (sin louver_depth_start_angle_)
                              louver_width_
                            ) 
                            (sin louver_depth_end_angle_)
                          )
                        )
                      )
                    ;
                  ;

                ;
                ;louver_depth_90deg
                  ;
                    (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "louver_depth_90deg" 
                      (if (>= louver_angle_deg 90)
                        (progn
                          (setq louver_depth (cond ( (getreal (strcat "\nspecify louver_depth<" (rtos (setq louver_depth (cond (louver_depth) (1.2) ) ) ) "> : " ) ) ) (louver_depth) ) )
                        )
                        0
                      )
                    )
                  ;
                ;
                ;return_input_data_to_parameter_
                  (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "louver_angle" louver_angle_)
                  
                  ; (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "position1 X" 0)
                  ; (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "position1 Y" position_1Y)
                  
                  (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "louver_width" 
                    (if (>= louver_angle_deg 90)
                      (progn
                        louver_depth
                      )
                      louver_width_
                    )
                  )
                  
                  (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "u-profile_width_set" u-profile_width_set)
                  (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "array_width" array_width)
                  (LM:setdynpropvalue (vlax-ename->vla-object get_effectivename_) "total_u-profile_depth" total_u-profile_depth)
                
                ;
                ;add more
              )
              (setq get_effectivename_ nil)
            )
          )
        ;
      )
    ;
  ;
  ;hatch_FUNC
    (defun TA:create_hatch_ (hatch_ename_ hatch_ename_getang_ hatch_ename_getsc_)
      ;example_user_input_
        ; (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
        ; (setq hatch_ename_ (car (entsel "specify Object")))
      ;
      ;get_object_name_data
        (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object hatch_ename_)))
      ;
      ;cond for filter objectname_
        (cond
          ( ;first process
            (or
              
              (= obj_name_ "AcDbPolyline")
            )
            (progn
              (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
              (setq 1st_process "AcDbPolyline")
            )
          )
          (;first process
            (or
              (= obj_name_ "AcDbBlockReference")
            )
            (progn
              (setq 1st_process "AcDbBlockReference")
              
            )
          )
        )
      ;
      
      ;pre_set_vari_
        ; (if 
        ;   (and 
        ;     (= hatch_ename_getang_ nil)
        ;     (= hatch_ename_getsc_ nil)
        ;   )
        ;   (progn
        ;     (setq  hatch_ename_getang_ 0)
        ;     (setq  hatch_ename_getsc_ 1)
            
        ;   )
        ; )
      ;
      ;presetting_hatch_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ "ANSI32")
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
      ;
      ; (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      ; (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))

      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
               ""
      )
      
      
    )
    (defun TA:create_hatch_ANSI37 (hatch_ename_ hatch_ename_getang_ hatch_ename_getsc_)
      ;example_user_input_
        ; (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
        ; (setq hatch_ename_ (car (entsel "specify Object")))
      ;
      ;get_object_name_data
        (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object hatch_ename_)))
      ;
      ;cond for filter objectname_
        (cond
          ( ;first process
            (or
              
              (= obj_name_ "AcDbPolyline")
            )
            (progn
              (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
              (setq 1st_process "AcDbPolyline")
            )
          )
          (;first process
            (or
              (= obj_name_ "AcDbBlockReference")
            )
            (progn
              (setq 1st_process "AcDbBlockReference")
              
            )
          )
        )
      ;
      
      ;pre_set_vari_
        ; (if 
        ;   (and 
        ;     (= hatch_ename_getang_ nil)
        ;     (= hatch_ename_getsc_ nil)
        ;   )
        ;   (progn
        ;     (setq  hatch_ename_getang_ 0)
        ;     (setq  hatch_ename_getsc_ 1)
            
        ;   )
        ; )
      ;
      ;presetting_hatch_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ "ANSI37")
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
      ;
      ; (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      ; (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )

      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))
      
      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
                ""
      )
      
      
      
    )
    (defun TAS:create_hatch_PPLINE_ (hatch_ename_ hatch_ename_getang_ hatch_ename_getsc_ hatch_mode)
      ;example_user_input_
        ; (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
        ; (setq hatch_ename_ (car (entsel "specify Object")))
      ;
      ;get_object_name_data
        (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object hatch_ename_)))
      ;
      ;cond for filter objectname_
        (cond
          ( ;first process
            (or
              
              (= obj_name_ "AcDbPolyline")
            )
            (progn
              (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
              (setq 1st_process "AcDbPolyline")
            )
          )
          (;first process
            (or
              (= obj_name_ "AcDbBlockReference")
            )
            (progn
              (setq 1st_process "AcDbBlockReference")
              
            )
          )
        )
      ;
      
      ;pre_set_vari_
        ; (if 
        ;   (and 
        ;     (= hatch_ename_getang_ nil)
        ;     (= hatch_ename_getsc_ nil)
        ;   )
        ;   (progn
        ;     (setq  hatch_ename_getang_ 0)
        ;     (setq  hatch_ename_getsc_ 1)
            
        ;   )
        ; )
      ;
      ;presetting_hatch_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_
          (cond 
            ( ;hatctpatt_case_
              (and (= hatch_mode 1))
              (progn 
                (setq hatch_patt_ "000_C01")
                (setq hatch_color_ 8)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 2))
              (progn 
                (setq hatch_patt_ "000_C02")
                (setq hatch_color_ 2)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 3))
              (progn 
                (setq hatch_patt_ "000_C03")
                (setq hatch_color_ 2)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 4))
              (progn 
                (setq hatch_patt_ "000_C04")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 5))
              (progn 
                (setq hatch_patt_ "000_C05")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 51))
              (progn 
                (setq hatch_patt_ "000_C05A")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 6))
              (progn 
                (setq hatch_patt_ "000_C06")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 7))
              (progn 
                (setq hatch_patt_ "000_C07")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 8))
              (progn 
                (setq hatch_patt_ "000_C08")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 9))
              (progn 
                (setq hatch_patt_ "000_C09")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 10))
              (progn 
                (setq hatch_patt_ "000_C10")
                (setq hatch_color_ 4)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 11))
              (progn 
                (setq hatch_patt_ "000_C11")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
          )
        )
        
        (setq hatch_background_ 250)
      ;
      ; (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      ; (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )

      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))
      
      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
                ""
      )
      
      
      
    )
    (defun TAS:create_Wallhatch_PPLINE_ (hatch_ename_ hatch_ename_getang_ hatch_ename_getsc_ hatch_mode)
      ;example_user_input_
        ; (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
        ; (setq hatch_ename_ (car (entsel "specify Object")))
      ;
      ;get_object_name_data
        (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object hatch_ename_)))
      ;
      ;cond for filter objectname_
        (cond
          ( ;first process
            (or
              
              (= obj_name_ "AcDbPolyline")
            )
            (progn
              (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
              (setq 1st_process "AcDbPolyline")
            )
          )
          (;first process
            (or
              (= obj_name_ "AcDbBlockReference")
            )
            (progn
              (setq 1st_process "AcDbBlockReference")
              
            )
          )
        )
      ;
      
      ;pre_set_vari_
        ; (if 
        ;   (and 
        ;     (= hatch_ename_getang_ nil)
        ;     (= hatch_ename_getsc_ nil)
        ;   )
        ;   (progn
        ;     (setq  hatch_ename_getang_ 0)
        ;     (setq  hatch_ename_getsc_ 1)
            
        ;   )
        ; )
      ;
      ;presetting_hatch_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_
          (cond 
            ( ;hatctpatt_case_
              (and (= hatch_mode 1))
              (progn 
                (setq hatch_patt_ "000_W01")
                (setq hatch_color_ 8)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 2))
              (progn 
                (setq hatch_patt_ "000_W02")
                (setq hatch_color_ 2)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 3))
              (progn 
                (setq hatch_patt_ "000_W03")
                (setq hatch_color_ 2)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 4))
              (progn 
                (setq hatch_patt_ "000_W04")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 5))
              (progn 
                (setq hatch_patt_ "000_W05")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 6))
              (progn 
                (setq hatch_patt_ "000_W06")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 7))
              (progn 
                (setq hatch_patt_ "000_W07")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 8))
              (progn 
                (setq hatch_patt_ "000_W08")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 9))
              (progn 
                (setq hatch_patt_ "000_W09")
                (setq hatch_color_ 1)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 10))
              (progn 
                (setq hatch_patt_ "000_W10")
                (setq hatch_color_ 4)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 11))
              (progn 
                (setq hatch_patt_ "000_W11")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 12))
              (progn 
                (setq hatch_patt_ "000_W12")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 13))
              (progn 
                (setq hatch_patt_ "000_W13")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 14))
              (progn 
                (setq hatch_patt_ "000_W14")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 15))
              (progn 
                (setq hatch_patt_ "000_W15")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 16))
              (progn 
                (setq hatch_patt_ "000_W16")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 17))
              (progn 
                (setq hatch_patt_ "000_W17")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 18))
              (progn 
                (setq hatch_patt_ "000_W18")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 19))
              (progn 
                (setq hatch_patt_ "000_W19")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 20))
              (progn 
                (setq hatch_patt_ "000_W20")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 21))
              (progn 
                (setq hatch_patt_ "000_W21")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 22))
              (progn 
                (setq hatch_patt_ "000_W22")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 23))
              (progn 
                (setq hatch_patt_ "000_W23")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 24))
              (progn 
                (setq hatch_patt_ "000_W24")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 25))
              (progn 
                (setq hatch_patt_ "000_W25")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 26))
              (progn 
                (setq hatch_patt_ "000_W26")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 27))
              (progn 
                (setq hatch_patt_ "000_W27")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 28))
              (progn 
                (setq hatch_patt_ "000_W28")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 29))
              (progn 
                (setq hatch_patt_ "000_W29")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
            ( ;hatctpatt_case_
              (and (= hatch_mode 30))
              (progn 
                (setq hatch_patt_ "000_W30")
                (setq hatch_color_ 3)
                (princ hatch_patt_)
              )
            )
          )
        )
        
        (setq hatch_background_ 250)
      ;
      ; (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      ; (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )

      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))
      
      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
                ""
      )
      
      
      
    )
    (defun c:hatch_obj_Metal_HHM_ ()
      ;user_input_
      (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
      
      (cond
        ( ;first process
          (or
            
            (= obj_name_ "AcDbPolyline")
          )
          (progn
            (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
            (setq 1st_process "AcDbPolyline")
          )
        )
        (;first process
          (or
            (= obj_name_ "AcDbBlockReference")
          )
          (progn
            (setq 1st_process "AcDbBlockReference")
            
          )
        )
      )
      
      
      (if 
        (and 
          (= hatch_ename_getang_ nil)
          (= hatch_ename_getsc_ nil)
        )
        (progn
          (setq  hatch_ename_getang_ 0)
          (setq  hatch_ename_getsc_ 1)
          
        )
      )
      ;preseting_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ "ANSI32")
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
        
      ;
      (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))

      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
               
      )
      
      
      
    )
    (defun c:hatch_obj_Subfame_HHSF_ ()
      ;user_input_
      (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
      
      (cond
        ( ;first process
          (or
            
            (= obj_name_ "AcDbPolyline")
          )
          (progn
            (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
            (setq 1st_process "AcDbPolyline")
          )
        )
        (;first process
          (or
            (= obj_name_ "AcDbBlockReference")
          )
          (progn
            (setq 1st_process "AcDbBlockReference")
            
          )
        )
      )
      
      
      (if 
        (and 
          (= hatch_ename_getang_ nil)
          (= hatch_ename_getsc_ nil)
        )
        (progn
          (setq  hatch_ename_getang_ 0)
          (setq  hatch_ename_getsc_ 1)
          
        )
      )
      ;preseting_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ "000_GL1200")
        (setq hatch_color_ 6)
        (setq hatch_background_ ".")
        
      ;
      ; (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      (setq hatch_ename_getang_ 270 )
      ; (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      (setq hatch_ename_getsc_ 1 )
      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))

      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                "T" 40
                ""
      )
      ; (vla-setpattern (setq s_obj_ (vlax-ename->vla-object (entlast))) acHatchPatternTypePreDefined "solid") 
    )
    (defun c:hatch_obj_Solid_HHSolid_ ()
      ;user_input_
      (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
      
      (cond
        ( ;first process
          (or
            
            (= obj_name_ "AcDbPolyline")
          )
          (progn
            (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
            (setq 1st_process "AcDbPolyline")
          )
        )
        (;first process
          (or
            (= obj_name_ "AcDbBlockReference")
          )
          (progn
            (setq 1st_process "AcDbBlockReference")
            
          )
        )
      )
      
      
      (if 
        (and 
          (= hatch_ename_getang_ nil)
          (= hatch_ename_getsc_ nil)
        )
        (progn
          (setq  hatch_ename_getang_ 0)
          (setq  hatch_ename_getsc_ 1)
          
        )
      )
      ;preseting_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ "ANSI32")
        (setq hatch_color_ 250)
        (setq hatch_background_ 250)
        
      ;
      (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))

      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
      )
      (vla-setpattern (setq s_obj_ (vlax-ename->vla-object (entlast))) acHatchPatternTypePreDefined "solid") 
    )
    (defun c:hatch_obj_Dot_HHCON_ ()
      ;user_input_
      (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
      
      (cond
        ( ;first process
          (or
            
            (= obj_name_ "AcDbPolyline")
          )
          (progn
            (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
            (setq 1st_process "AcDbPolyline")
          )
        )
        (;first process
          (or
            (= obj_name_ "AcDbBlockReference")
          )
          (progn
            (setq 1st_process "AcDbBlockReference")
            
          )
        )
      )
      
      
      (if 
        (and 
          (= hatch_ename_getang_ nil)
          (= hatch_ename_getsc_ nil)
        )
        (progn
          (setq  hatch_ename_getang_ 0)
          (setq  hatch_ename_getsc_ 1)
          
        )
      )
      ;preseting_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ "AR-CONC")
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
        
      ;
      (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))

      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
      )
      
      
    )
    (defun c:hatch_obj_Dot_HHD_ ()
      ;user_input_
      (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (setq hatch_ename_ (car (entsel "specify Object"))))))
      
      (cond
        ( ;first process
          (or
            
            (= obj_name_ "AcDbPolyline")
          )
          (progn
            (= (vla-get-closed (setq hatch_ename_obj_ (vlax-ename->vla-object hatch_ename_))) :vlax-true)
            (setq 1st_process "AcDbPolyline")
          )
        )
        (;first process
          (or
            (= obj_name_ "AcDbBlockReference")
          )
          (progn
            (setq 1st_process "AcDbBlockReference")
            
          )
        )
      )
      
      
      (if 
        (and 
          (= hatch_ename_getang_ nil)
          (= hatch_ename_getsc_ nil)
        )
        (progn
          (setq  hatch_ename_getang_ 0)
          (setq  hatch_ename_getsc_ 1)
          
        )
      )
      ;preseting_data_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ "DOTS")
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
        
      ;
      (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
      (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      (setq hatch_obj_ (vlax-ename->vla-object hatch_ename_))

      
      (command ".-hatch" "s"  hatch_ename_  
                "" 
                "c" hatch_color_ hatch_background_
                "p" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_ 
                "L" hatch_Layer_ 
                ""  
      )
      
      
    )
    (defun c:multi_hatch_obj_MHB ()
      ;selection_set
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx_ (ssget "I" 
                                              (list 
                                                (cons 0 "lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                            (cons 0 "lwpolyline") ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      ;user_input_data_
        (if 
          (and 
            (= hatch_ename_getang_ nil)
            (= hatch_ename_getsc_ nil)
          )
          (progn
            (setq  hatch_ename_getang_ 0)
            (setq  hatch_ename_getsc_ 1)
            
          )
        )
        (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
        (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      ;
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))

            (TA:create_hatch_ ss_pre_filter_set_xx_ename_ hatch_ename_getang_ hatch_ename_getsc_)  

          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
    (defun c:multi_hatch_obj_MHB2 ()
      ;hatch_setting_value_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_patt_ (getstring (strcat "\nSpecify Pattern name <" (if hatch_patt_ hatch_patt_ "") ">: ") ) )
        (setq hatch_patt_ (if (/= hatch_patt_ "") (progn (setq hatch_patt_ hatch_patt_) (setq hatch_patt_pre hatch_patt_) ) (setq hatch_patt_ hatch_patt_pre ) ))
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
      ;
      ; ;selection_set
      ;   (if  ;pre_select_ssget_or_post_select_ssget
      ;     (= 
      ;       (setq ss_pre_filter_set_xx_ (ssget "I" 
      ;                                         (list 
      ;                                           (cons 0 "lwpolyline") ;type of object
      ;                                           ; (cons 8 "*GRID*")   ;kind of layer
      ;                                           ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
      ;                                           ; (cons 62 1)           ;kind of color call sign with color code index
      ;                                         )
      ;                                   )
      ;       )
      ;       nil
      ;     )
      ;     (progn 
      ;       (setq ss_pre_filter_set_xx_ (ssget 
      ;                                     (list 
      ;                                       (cons 0 "lwpolyline") ;type of object
      ;                                       ; (cons 8 "*GRID*")   ;kind of layer
      ;                                       ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
      ;                                       ; (cons 62 1)           ;kind of color call sign with color code index
      ;                                     )
      ;                                   )
      ;       )
      ;     )
      ;     (sslength ss_pre_filter_set_xx_)
      ;   )
      ; ;
      ;user_input_data_
        (if 
          (and 
            (= hatch_ename_getang_ nil)
            (= hatch_ename_getsc_ nil)
          )
          (progn
            (setq  hatch_ename_getang_ 0)
            (setq  hatch_ename_getsc_ 1)
            
          )
        )
        (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
        (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      ;
      ;preloop_and_while
        ; (setq ss_pre_filter_set_xx_i 0)
        ; (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        ;   (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))

            (command "_-hatch" pause
            )  


            ;new_blk_entlast object
              (setq newhatch_ename (entlast))
              (setq newhatch_obj_ (vlax-ename->vla-object newhatch_ename))
              (command "_-hatchedit" newhatch_ename "P" hatch_patt_ hatch_ename_getsc_ hatch_ename_getang_   )
              (command "_-hatchedit" newhatch_ename "Co" hatch_color_ hatch_background_  )
            ;

              

        ;   (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        ; )
      ;
    )
    (defun c:multi_hatch_obj_MHB3 ()
      ;hatch_setting_value_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_mode (cond ( (getint (strcat "\nspecify hatch_mode <" (rtos (setq hatch_mode (cond (hatch_mode) (1.0) ) ) ) "> : " ) ) ) (hatch_mode) ) )       
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
      ;
      ;selection_set
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx_ (ssget "I" 
                                              (list 
                                                (cons 0 "lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                            (cons 0 "lwpolyline,region") ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      ;user_input_data_
        (if 
          (and 
            (= hatch_ename_getang_ nil)
            (= hatch_ename_getsc_ nil)
          )
          (progn
            (setq  hatch_ename_getang_ 0)
            (setq  hatch_ename_getsc_ 1)
            
          )
        )
         
        ;(setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) ) ;ปิดใช้งานไปก่อน ให้ใช้ 45degree 750sc
        (setq hatch_ename_getang_ 45 )
        ;(setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
        (setq hatch_ename_getsc_ 300 )
      ;
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))

            (TAS:create_hatch_PPLINE_ ss_pre_filter_set_xx_ename_ hatch_ename_getang_ hatch_ename_getsc_ hatch_mode)    

          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
    (defun c:multi_hatch_obj_MHB4 ()
      
      ;selection_set
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx_ (ssget "I" 
                                              (list 
                                                (cons 0 "lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                            (cons 0 "lwpolyline") ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      ;hatch_setting_value_
        (setq hatch_Layer_ "000 - H A T C H")
        (setq hatch_mode (cond ( (getint (strcat "\nspecify hatch_mode <" (rtos (setq hatch_mode (cond (hatch_mode) (1.0) ) ) ) "> : " ) ) ) (hatch_mode) ) )       
        (setq hatch_color_ 8)
        (setq hatch_background_ 250)
      ;
      ;user_input_data_
        (if 
          (and 
            (= hatch_ename_getang_ nil)
            (= hatch_ename_getsc_ nil)
          )
          (progn
            (setq  hatch_ename_getang_ 0)
            (setq  hatch_ename_getsc_ 1)
            
          )
        )
         
        ; (setq hatch_ename_getang_ (cond ( (getreal (strcat "\nspecify angle<" (rtos (setq hatch_ename_getang_ (cond (hatch_ename_getang_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getang_) ) )
        (setq hatch_ename_getang_ 45 )
        (setq hatch_ename_getsc_ 750 )
        ; (setq hatch_ename_getsc_ (cond ( (getreal (strcat "\nspecify scale<" (rtos (setq hatch_ename_getsc_ (cond (hatch_ename_getsc_) (hatch_ename_getsc_) ) ) ) "> : " ) ) ) (hatch_ename_getsc_) ) )
      ;
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))

            (TAS:create_Wallhatch_PPLINE_ ss_pre_filter_set_xx_ename_ hatch_ename_getang_ hatch_ename_getsc_ hatch_mode)    

          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
    (defun c:select_hacth_SFH ()
      ;selection_set
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx_ (ssget "I" 
                                              (list 
                                                (cons 0 "hatch") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                            (cons 0 "hatch") ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      (command "pselect" ss_pre_filter_set_xx_ "" ) 
    )
    (defun c:Recrete_hatch_SSRHB_ ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "HATCH") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "HATCH") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          
          (command "_-hatchedit" ss_pre_filter_set_xx_ename_  "B" "" "Y")
          
          
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
    (defun c:hatch_orgin_move_axis_X_HHX ()
      ;set paremeter for moving
        (setq move_length_ 25)
      ;
      ;user_input_
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq DELETE_OBJ_ (not (eq "No" (getkword "\nKeep Existing point with object? [Yes/No] <Y>: "))))
              )
            )
          )
        )
      ;
      (cond
        (;delete_case_1
          (and
              (= DELETE_OBJ_ nil)
          )
          (progn
            (setq ssset_ (ssget))
            (princ "delete_case_1")
          )
        )
        (;delete_case_2
          (and
              (= DELETE_OBJ_ nil)
          )
          (progn
            (setq ssset_ ssset_)
            (princ "delete_case_2")
          )
        )
      )
      
      (while
        (= ;condition
          (wcmatch 
            (vl-princ-to-string 
              (setq direction_val_ ;Detect the variable's result in case of a function error
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (setq direction_ (cond ( (getint (strcat "\nspecify get\n1 = +\n0 = -\n<" (rtos (setq direction_ (cond (direction_) (1.0) ) ) ) "> : " ) ) ) (direction_) ) )
                    )
                  )
                )
              )
            ) 
            "*error*"
          )
          nil
        )
        ;properties hacth
          (setq ssset_ename_ (ssname ssset_ 0))
          (setq ssset_obj_ (vlax-ename->vla-object ssset_ename_))
          (setq ssset_obj_origin_ (vlax-safearray->list 
                                  (vlax-variant-value (vla-get-origin ssset_obj_))
                                )
          )
        ;
        (cond
          (
            (and 
              (/= ssset_ nil)
              (= direction_val_ 1)
            )
            (setq sss_obj_putins_ (list 
                                    (+ (car ssset_obj_origin_) move_length_)
                                    (cadr ssset_obj_origin_)
                                    0
                                  )
            )
            (command "HATCHSETORIGIN" ssset_ "" sss_obj_putins_ )
          )
          (
            (and 
              (/= ssset_ nil)
              (= direction_val_ 0)
            )
            (setq sss_obj_putins_ (list 
                                    (- (car ssset_obj_origin_) move_length_)
                                    (cadr ssset_obj_origin_)
                                    0
                                  )
            )
            (command "HATCHSETORIGIN" ssset_ "" sss_obj_putins_ )
          )
        )
        
      )
    )
    (defun c:hatch_orgin_move_axis_Y_HHY ()
      ;set paremeter for moving
        (setq move_length_ 25)
      ;
      ;user_input_
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq DELETE_OBJ_ (not (eq "No" (getkword "\nKeep Existing point with object? [Yes/No] <Y>: "))))
              )
            )
          )
        )
      ;
      (cond
        (;delete_case_1
          (and
              (= DELETE_OBJ_ nil)
          )
          (progn
            (setq ssset_ (ssget))
            (princ "delete_case_1")
          )
        )
        (;delete_case_2
          (and
              (= DELETE_OBJ_ nil)
          )
          (progn
            (setq ssset_ ssset_)
            (princ "delete_case_2")
          )
        )
      )
      
      (while
        (= ;condition
          (wcmatch 
            (vl-princ-to-string 
              (setq direction_val_ ;Detect the variable's result in case of a function error
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (setq direction_ (cond ( (getint (strcat "\nspecify get\n1 = +\n0 = -\n<" (rtos (setq direction_ (cond (direction_) (1.0) ) ) ) "> : " ) ) ) (direction_) ) )
                    )
                  )
                )
              )
            ) 
            "*error*"
          )
          nil
        )
        ;properties hacth
          (setq ssset_ename_ (ssname ssset_ 0))
          (setq ssset_obj_ (vlax-ename->vla-object ssset_ename_))
          (setq ssset_obj_origin_ (vlax-safearray->list 
                                  (vlax-variant-value (vla-get-origin ssset_obj_))
                                )
          )
        ;
        (cond
          (
            (and 
              (/= ssset_ nil)
              (= direction_val_ 1)
            )
            (setq sss_obj_putins_ (list 
                                    (car ssset_obj_origin_)
                                    (+ (cadr ssset_obj_origin_) move_length_)
                                    0
                                  )
            )
            (command "HATCHSETORIGIN" ssset_ "" sss_obj_putins_ )
          )
          (
            (and 
              (/= ssset_ nil)
              (= direction_val_ 0)
            )
            (setq sss_obj_putins_ (list 
                                    (car ssset_obj_origin_)
                                    (- (cadr ssset_obj_origin_) move_length_)
                                    0
                                  )
            )
            (command "HATCHSETORIGIN" ssset_ "" sss_obj_putins_ )
          )
        )
        
      )
    )

  ;
  ;symbol_FUNC_
    (defun c:add_breakline_to_rectangle_ADBK ()
      ;user_input_
        (setq rec_ename_ (car (entsel "specify Object")))
        (setq dynamic_scale_ (cond ( (getreal (strcat "\nspecify_dynamic_scale_<" (rtos (setq dynamic_scale_ (cond (dynamic_scale_) (1.0) ) ) ) "> : " ) ) ) (dynamic_scale_) ) )
        
      ;

      ;get_data_
        (setq rec_obj_ (vlax-ename->vla-object rec_ename_))
        (setq rec_obj_objname_  (vla-get-objectname rec_obj_))
      
        (setq vertex_list (TA:Get_Pline_vertext_angle_case1 rec_ename_))
        (setq vertex_list_ (remove_member_list_ 2 vertex_list))
      ;
      ;preloop_and_while insertion_breakline_dynblock
        (setq vertex_list_i 0)
        (setq vertex_list_ii 1)
        (while (< vertex_list_i (length vertex_list_))
          (cond ;insert_block_case_
            (;_case_1
              (and
                  (/= vertex_list_i (- (length vertex_list_ ) 1))
              )
              (progn
                  (setq vertex_list_ename_set1 (nth  vertex_list_i vertex_list_))
                  (setq vertex_list_ename_set2 (nth  vertex_list_ii vertex_list_))
                  
                  (setq vertex_list_ename_midpoint_ (TA:midpoint (car vertex_list_ename_set1) (car vertex_list_ename_set2)))
                  (setq vertex_list_ename_distance_set1 (distance (car vertex_list_ename_set1)  vertex_list_ename_midpoint_ ))
                  (setq vertex_list_ename_distance_set2 (distance (car vertex_list_ename_set2)  vertex_list_ename_midpoint_))
                  
                  ;main_idea_code
                    (command "insert" "000SYM-BREAK_LINE_DYNBLOCK_" vertex_list_ename_midpoint_ dynamic_scale_ (cadr vertex_list_ename_set1) )
                    (setq new_dynamic_block_ (entlast))
                    (setq new_dynamic_block_obj_ (vlax-ename->vla-object new_dynamic_block_))
                    (LM:setdynpropvalue new_dynamic_block_obj_ "right_width" vertex_list_ename_distance_set1)
                    (LM:setdynpropvalue new_dynamic_block_obj_ "left_width" vertex_list_ename_distance_set2)
                    (cond
                      (;_case_1
                        (and (>= (cadr vertex_list_ename_set1) 90 ) (<= (cadr vertex_list_ename_set1) 135 ))
                        (progn
                          (LM:setdynpropvalue new_dynamic_block_obj_ "flip state1"  1)

                          
                          (princ "_case_1")
                        )
                      )
                      (;_case_2
                        (or
                            (and (>= (cadr vertex_list_ename_set1) 135 ) (<= (cadr vertex_list_ename_set1) 180 ))
                        )
                        (progn
                          (LM:setdynpropvalue new_dynamic_block_obj_ "flip state1"  0)

                          
                          
                          (princ "_case_2")
                        )
                      )
                      (;_case_3
                        (or
                            (and (>= (cadr vertex_list_ename_set1) 180 ) (<= (cadr vertex_list_ename_set1) 360 ))
                        )
                        (progn
                          (LM:setdynpropvalue new_dynamic_block_obj_ "flip state1"  1)
                          (princ "_case_3")
                        )
                      )
                    )
                  ;
                  (princ "_case_1")
              )
            )
            (;_case_2
              (and
                  (= vertex_list_i (- (length vertex_list_ ) 1))
              )
              (progn
                  (setq vertex_list_ename_set1 (nth  vertex_list_i vertex_list_))
                  (setq vertex_list_ename_set2 (nth  0 vertex_list_))
                  
                  (setq vertex_list_ename_midpoint_ (TA:midpoint (car vertex_list_ename_set1) (car vertex_list_ename_set2)))
                  (setq vertex_list_ename_distance_set1 (distance (car vertex_list_ename_set1)  vertex_list_ename_midpoint_ ))
                  (setq vertex_list_ename_distance_set2 (distance (car vertex_list_ename_set2)  vertex_list_ename_midpoint_))
                
                  ;main_idea_code
                    (command "insert" "000SYM-BREAK_LINE_DYNBLOCK_" vertex_list_ename_midpoint_ dynamic_scale_ (rad-to-deg (angle (car vertex_list_ename_set1) (car vertex_list_ename_set2) )) )
                    (setq new_dynamic_block_ (entlast))
                    (setq new_dynamic_block_obj_ (vlax-ename->vla-object new_dynamic_block_))
                    (LM:setdynpropvalue new_dynamic_block_obj_ "right_width" vertex_list_ename_distance_set1)
                    (LM:setdynpropvalue new_dynamic_block_obj_ "left_width" vertex_list_ename_distance_set2)
                    (LM:setdynpropvalue new_dynamic_block_obj_ "flip state1"  1)
                    
                  ;
                (princ "_case_2")
              )
            )
          )
          
          (setq vertex_list_i (+ vertex_list_i 1))
          (setq vertex_list_ii (+ vertex_list_ii 1))
        )
      ;
      
      
      
    )
    (defun c:edit_breakline_to_rectangle_EDBK ()
      ;selection_set_user_input
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx_ (ssget "I" 
                                              (list 
                                                (cons 0 "LINE,ARC,CIRCLE,POLYLINE,LWPOLYLINE,ELLIPSE,SPLINE,INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                
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
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      ;filter_object_to_new_ssget_
        (setq ss_set_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000SYM-BREAK_LINE_DYNBLOCK_"))
        ;preloop_and_while
          (setq ss_set_i 0)
          (while (< ss_set_i (sslength ss_set_))
            ;get_data_in_ssget_
            (setq ss_set_ename_ (ssname ss_set_ ss_set_i))
            (setq ss_get_obj_ (vlax-ename->vla-object ss_set_ename_))
            (setq ss_get_obj_rotation_ (rad-to-deg (vla-get-rotation ss_get_obj_ )))
            
            (cond
              (;rotation_cond_case_1
                (and
                    (= ss_get_obj_rotation_ 0 )
                )
                (progn
                    (LM:setdynpropvalue ss_get_obj_ "distance1" 40 )
                    (LM:setdynpropvalue ss_get_obj_ "visibility1"  1)
                    (command "draworder" ss_set_ename_ "" "f" )
                  (princ "rotation_cond_case_1")
                )
              )
              (;rotation_cond_case_2
                (and
                    (= ss_get_obj_rotation_ 90)
                    
                )
                  (progn
                      (LM:setdynpropvalue ss_get_obj_ "distance1" 0 )
                      (LM:setdynpropvalue ss_get_obj_ "visibility1"  2)
                    (princ "rotation_cond_case_2")
                  )
              )
              (;rotation_cond_case_3
                (and
                    (= ss_get_obj_rotation_ 180)
                    
                )
                (progn
                    (LM:setdynpropvalue ss_get_obj_ "distance1" 40 )
                    (LM:setdynpropvalue ss_get_obj_ "visibility1"  1)
                    (command "draworder" ss_set_ename_ "" "f" )
                    (princ "rotation_cond_case_3")
                )
              )
              (;rotation_cond_case_4
                (and
                    (= ss_get_obj_rotation_ 270)
                    
                )
                (progn
                  (LM:setdynpropvalue ss_get_obj_ "distance1" 0 )
                  (LM:setdynpropvalue ss_get_obj_ "visibility1"  2)
                  (princ "rotation_cond_case_4")
                )
              )
            )
            
            
            
            
          (setq ss_set_i (+ ss_set_i 1))
        )
      ;
      ;
    )
    (defun c:make_detail_box_mkbx_ ()
      ;get_point_data_
        (setq get_pt_ (getpoint ))
        ; (setvar "orthomode" 1)
      ;
      ;get_honrizontal_data_
        (setq dist_hon (getdist get_pt_ ) )
        (setq hon_pt_ (polar get_pt_ 0.0 dist_hon))
        (setq hon_pt_- (polar get_pt_ (deg-to-rad 180.00) dist_hon))
      ;
      ;get_vertical_data_
        (setq dist_ver (getdist get_pt_ ) )
        (setq ver_pt_ (polar get_pt_ (deg-to-rad 90.00) dist_ver))
        (setq ver_pt_- (polar get_pt_ (deg-to-rad 270.00) dist_ver))
      ;
      ;sorting_max_legth_
        (setq length_list_rec (list
                                dist_hon
                                dist_ver
                              )
        )
        (setq min-length (car (vl-sort  length_list_rec '<)))
      ;
      ;get_conner_
        (setq top_conner_ (list
                            (car hon_pt_)
                            (cadr ver_pt_)
                          )
        )
        (setq bot_conner_ (list
                            (car hon_pt_-)
                            (cadr ver_pt_-)
                          )
        )
      ;
    
      ;use_input_for_specify_fllet_rec_
        (setq fllet_rec_val "not pass" )
        (while (= fllet_rec_val "not pass")
          
          (setq fllet_rec_ (cond ( (getint (strcat "\nspecify fllet_rec_<" (rtos (setq fllet_rec_ (cond (fllet_rec_) (1.0) ) ) ) "> : " ) ) ) (fllet_rec_) ) )
          (if
            (< (LM:round (* min-length 0.9)) fllet_rec_)
            (progn
              (setq fllet_rec_val "not pass" )
              (alert "fllet rectangle more than min-length ractangle ")
            )
            (setq fllet_rec_val "pass" )
          )
        )
      ;
      ; ;make_new_object_
      ;   (command "point" get_pt_)
      ;   (command "point" top_conner_)
      ;   (command "point" bot_conner_)
        (command "rectangle" bot_conner_ top_conner_  )
        (command "fillet" "p" "r" fllet_rec_ "L" )
      ;
      ;put_prop_data_
        (setq entlast_ename_ (entlast))
        (vla-get-linetype (setq entlast_obj_ (vlax-ename->vla-object entlast_ename_)))
        (vla-put-linetype (setq entlast_obj_ (vlax-ename->vla-object entlast_ename_)) "byblock")
      ;

      
    )
    (defun c:move_to_zero_xyz_M20 ()
      ;example_user_input_main_object
        (setq main_ename_ (car (entsel "specify Object")))
      ;
      ;get_data_form_user_input_
        (setq main_obj_ (vlax-ename->vla-object main_ename_))
        (setq main_obj_get_object_name_ (vla-get-objectname main_obj_))
      ;
      ;condoitional_for_diferent_acad_object_
        (cond  ;condoitional_for_diferent_acad_object_
          ( ;conditional_case_1
          (and 
            (= main_obj_get_object_name_ "AcDbPolyline")
          )
          (progn 
              (setq center_object_ (TA:find_center main_ename_))
              (princ "conditional_case_1")
          )
          )
          ( ;conditional_case_2
          (and 
            (= main_obj_get_object_name_ "AcDbCircle")
          )
          (progn 
              (setq center_object_ (setq _obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-center main_obj_ )))))
              (princ "conditional_case_2")
          )
          )
          ( ;conditional_case_3
          (and 
            (= main_obj_get_object_name_ "AcDbBlockReference")
          )
          (progn 
              (setq center_object_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint main_obj_))))
              (princ "conditional_case_3")
          )
          )
        )
      ;
      ;move_command_process_
        (vla-move main_obj_  (vlax-3d-point center_object_) (vlax-3d-point 0 0 0)  )
      ;
        

    )
    (defun c:Multi_wipeout_mlwe ()
      ;selection_set
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx_ (ssget "I" 
                                              (list 
                                                (cons 0 "lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                            (cons 0 "lwpolyline") ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
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
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_hon_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_ename_close_line (vla-put-closed ss_pre_filter_set_xx_hon_obj_ :vlax-true))
        
          (command "wipeout" "p"  ss_pre_filter_set_xx_ename_ "n" )
          (setq wipeput_ename_ (entlast))
          (setq wipeput_ename_obj_ (vlax-ename->vla-object wipeput_ename_))
          (vla-put-layer wipeput_ename_obj_ "000 - WIPEOUT")
          (vla-put-color wipeput_ename_obj_ 256)
          (command "_draworder" wipeput_ename_ "" "b" )
          
      
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
      ;
      
      
      
      
      
      
      
    )
  ;
  ;xclip_FUNC
    (defun c:MULTI_XCILP_OBJECT_MXCV ()
      ;note_from_DEV
      ;READMORE PROCESS IN ALERT MESSAGE
        (alert
          "
          1 - selection_set_for_blk_object_
          2 - selection_circle_object_
          3 - whileloop ssname for XCILP process
          4 - complete ? not sure
          "
        )
      ;
      ;user_input_blk_object_
        ;selection_set
          (princ "selection_set_BLKOBJECT_process")
          (if  ;pre_select_ssget_or_post_select_ssget
            (= 
              (setq ss_pre_selection_blkobject_set_ (ssget "I" 
                                                (list 
                                                  (cons 0 "INSERT") ;type of object
                                                  ; (cons 8 "*GRID*")   ;kind of layer
                                                  ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                  ; (cons 62 1)           ;kind of color call sign with color code index
                                                )
                                          )
              )
              nil
            )
            (progn 
              (setq ss_pre_selection_blkobject_set_ (ssget 
                                            (list 
                                              (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                          )
              )
            )
            (sslength ss_pre_selection_blkobject_set_)
          )
        ;
      ;

      ;user_input_circle
        ;selection_set
          (princ "ss_for_circle_")
          (if  ;pre_select_ssget_or_post_select_ssget
            (= 
              (setq ss_for_circle_ (ssget "I" 
                                                (list 
                                                  (cons 0 "CIRCLE,lwpolyline") ;type of object
                                                  ; (cons 8 "*GRID*")   ;kind of layer
                                                  ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                  ; (cons 62 1)           ;kind of color call sign with color code index
                                                )
                                          )
              )
              nil
            )
            (progn 
              (setq ss_for_circle_ (ssget 
                                            (list 
                                              (cons 0 "CIRCLE,lwpolyline") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                          )
              )
            )
            (sslength ss_for_circle_)
          )
        ;
      ;
      (cond 
        (;UCS_Detect_variable_
          (and
              (= (getvar "WORLDUCS") 0)
          )
          (progn
            (alert "Please reset Worlducs variable")
          )
        )
        (;object_case_1_polygon_case
          (and
              (= (vla-get-objectname (vlax-ename->vla-object (ssname ss_for_circle_ 0))) "AcDbPolyline")
              (= (getvar "WORLDUCS") 1)
          )
          (progn
            (setq ucs_detect_error_ 1)
            (setvar "osmode" 0)
            (setq new_polygon_ename_ (ssname ss_for_circle_ 0))
            (setvar "osmode" 1279)
            (princ "object_case_1")
          )
        )
        (;object_case_2_circle_obejct_
          (and
              (= (vla-get-objectname (vlax-ename->vla-object (ssname ss_for_circle_ 0))) "AcDbCircle")
              (= (getvar "WORLDUCS") 1)
          )
          (progn
              ;tranfer_circle_to_polyogn_process
                (setvar "osmode" 0)
                (setq segment_curve_ (cond ( (getint (strcat "\nspecify fllet_rec_<" (rtos (setq segment_curve_ (cond (segment_curve_) (1.0) ) ) ) "> : " ) ) ) (segment_curve_) ) )
                (setq center_circle_ (vlax-safearray->list (vlax-variant-value (vla-get-center (vlax-ename->vla-object (ssname ss_for_circle_ 0))))))
                (setq rad_circle_ (vla-get-radius (vlax-ename->vla-object (ssname ss_for_circle_ 0))))
                (command "polygon" segment_curve_ center_circle_ "i"  rad_circle_ )
                (setq new_polygon_ename_ (entlast))
                (setq new_polygon_obj_ (vlax-ename->vla-object new_polygon_ename_))
                (setvar "osmode" 1279)
              ;
            (princ "object_case_2")
          )
        )
      )
      
      

      ;multi_xcilp_process_
        ;preloop_and_while
          (setq ss_pre_selection_blkobject_set_i 0)
          (while 
            (and
              (= (getvar "WORLDUCS") 1)
              (< ss_pre_selection_blkobject_set_i (sslength ss_pre_selection_blkobject_set_))
            )
            (setq ss_pre_selection_blkobject_set_ename_ (ssname ss_pre_selection_blkobject_set_ ss_pre_selection_blkobject_set_i))
              (command "xclip"  ss_pre_selection_blkobject_set_ename_  "" "n" "s" new_polygon_ename_)
            (setq ss_pre_selection_blkobject_set_i (+ ss_pre_selection_blkobject_set_i 1))
          )
        ;
        ;delete_object_
          (vla-delete  new_polygon_obj_)
        ;
      ;
    )
  ;
  ;scale_FUNC
    (defun c:save_dynamic_scale_scdyn_ ()
      ;user_input_
        (setq get_dynblock_ename_ (car (entsel "specify Object")))
        (setq dynamic_scale_ (cond ( (getreal (strcat "\nspecify_scale<" (rtos (setq dynamic_scale_ (cond (dynamic_scale_) (1.0) ) ) ) "> : " ) ) ) (dynamic_scale_) ) )
      ;
    
      (if (and ;condition rule
            ; (/= get_effectivename_ nil)
            (= (vla-get-isdynamicblock (vlax-ename->vla-object get_dynblock_ename_)) :vlax-true)
            ; (/= (vla-get-isdynamicblock (vlax-ename->vla-object get_effectivename_)) :vlax-true)
          )
        (progn ;add data
          ; (alert "\nplease select block object")
          ; (setq get_effectivename_ nil)
          ; (setq get_effectivename_obj_val_ nil)
          (setq get_effectivename_obj_val_ (LM:Effectivename (vlax-ename->vla-object get_dynblock_ename_)))
          (setq REF_get_att_list_ (LM:getdynprops (vlax-ename->vla-object get_dynblock_ename_)))
          (setq REF_get_att_list_total (length REF_get_att_list_))
          ;add more
        )
        (setq get_effectivename_ nil)
      )
      ;rescale_
        (setq basescale_ (vlax-3d-point dynamic_scale_ dynamic_scale_ dynamic_scale_))
        (vla-put-xscalefactor (vlax-ename->vla-object get_dynblock_ename_) dynamic_scale_ )
      ;
      ;preloop_and_while
        (setq REF_get_att_list_i 0)
        (while (< REF_get_att_list_i (length REF_get_att_list_))
          ;get_dynamic_data
            (setq REF_get_att_list_dynamicset_ (nth  REF_get_att_list_i REF_get_att_list_))
            (setq REF_get_att_list_dynamicset_name_ (nth 0 REF_get_att_list_dynamicset_) )
            (setq REF_get_att_list_dynamicset_val_ (cdr REF_get_att_list_dynamicset_))
          ;
          ;get_vis_data_
            (setq vis_name_ (LM:getvisibilityparametername (vlax-ename->vla-object get_dynblock_ename_) ))
            (setq vis_stage_ (LM:getvisibilitystate (vlax-ename->vla-object get_dynblock_ename_) ))
            (LM:SetVisibilityState (vlax-ename->vla-object get_dynblock_ename_) vis_stage_ )
          ;
          ;get_filp_data_
            (setq Flip_data_ (LM:toggleflipstate (vlax-ename->vla-object get_dynblock_ename_)))
          ;
          
          
          (if (/= REF_get_att_list_dynamicset_name_ "Origin")
            (progn
              (LM:setdynpropvalue (vlax-ename->vla-object get_dynblock_ename_) REF_get_att_list_dynamicset_name_ REF_get_att_list_dynamicset_val_ )
            )
            (princ "next ")
          )
          
          (setq REF_get_att_list_i (+ REF_get_att_list_i 1))
        )
      ;
    )
  ;
  ;EF_NAME_TO_ATT_TEXT_BLOCK_FUNC
    (defun TA:fillter_block_name_ (blk_ename_ )
      ;LEE-MAC_SUB_FUNC
        (defun LM:StringSubst ( new old str / inc len )
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
      ;Example_for_testing_
        ; (setq blk_ename_ (car (entsel "specify Object")))
      ;
      ;
      (setq blk_obj_ (vlax-ename->vla-object blk_ename_))

      (if (= (vla-get-objectname blk_obj_ ) "AcDbBlockReference")
        (progn
          (setq blk_raw_efname_ (LM:effectivename blk_obj_ ))
          ;user_setting_for_filter_ename_
            ; (setq blk_raw_efname_ "000 - DYNAMIC_VIEW_ASSCESSORIES_PHILLIPS_HEAD_SELF_DRILLING_SCREW_No.8_COMBINE_VIEW") ;FOR EXAMPLE CODING 
            (setq blk_raw_efname_ (LM:StringSubst "" "000 - " blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "DYNAMIC" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "VIEW" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "ASSCESSORIES" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "COMBINE+" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "FRONT" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "TOP" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "SIDE" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "BOT" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "BACK" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "CUT" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "ARRAY+" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "ARRAY" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "" "SET" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "_" "__" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "_" "___" blk_raw_efname_))
            (setq blk_raw_efname_ (LM:StringSubst "_" "____" blk_raw_efname_))
            
          ;
          ;front_name_setting_
            ;preloop_and_while_for_delete "_"
              (setq i 0)
              (setq ii 1)
              (setq test_text_ (substr blk_raw_efname_ ii 1))
              (while (= test_text_ "_")
                (setq test_text_ (substr blk_raw_efname_ ii 1))
                (if (/= i 0)
                  (progn
                    (setq ii (+ ii 1))
                    (setq i (+ i 1))
                  )
                  (setq i (+ i 1))
                )
              )
              (setq blk_raw_efname__strlen (strlen blk_raw_efname_))
              (if (= ii 1)
                (progn
                  (setq final_text_ blk_raw_efname_)
                )
                (setq final_text_ (substr blk_raw_efname_ (setq new_i (- ii 1)) blk_raw_efname__strlen))
              )
              

          ;
          ;bot_name_setting_
            (setq l 0)
            (setq ll 1)
            (setq final_text_l (strlen final_text_))
            (setq test_text_ (substr final_text_ final_text_l 1))
            (while (= test_text_ "_")
              (setq test_text_ (substr final_text_ final_text_l 1))
              (setq final_text_l (- final_text_l 1))
            )
            (setq final_text_last (+ final_text_l 1))
            (setq final_text_final (substr final_text_ 1 final_text_last))
          ;
        )
      )
    )
    (defun TA:remove_att_value_ (att_obj_ except_att_list_ )
      ;Note By Code_Developer
      ;This command is designed to work exclusively with attribute blocks only.
      ;It will remove all attributes in the block, but it allows certain attributes to be excluded by adding their names to an exception list.
      ;att_obj_ = vla-ename > object
      ;except_att_list_ = (list "att1" "att2" etc.)
      ;example code (TA:remove_att_value_ att_obj_ (list))
      ;example_code (setq except_att_list_ (list "NO.CODE")) 
      ;The operation of the command will read the block's attribute values and generate a set of text. n 
      ;

      ;fillter_EF_name_object_
        ; (setq att_ename_ nil)
        ; (setq att_obj_ nil)
        ; (while (= att_ename_ nil)
          ;user_input_data_  
            ; (setq att_ename_ (car (entsel "specify Object")))
          ;
          ;fillter_object_type_
            (if 
              (and
                ; (if (/= att_ename_ nil) (progn (setq att_obj_ (vlax-ename->vla-object att_ename_)) ))
                (= (vla-get-objectname att_obj_) "AcDbBlockReference")
                (= (vla-get-hasattributes att_obj_) :vlax-true )
              )
              (progn
                (setq att_tag_list_ (LM:vl-getattributevalue-tag-TA-Modifies att_obj_))
              )
              ; (setq att_ename_ nil)
            )
            (if 
              (or
                ; (= att_ename_ nil)
                (/= (vla-get-objectname att_obj_) "AcDbBlockReference")
                (if (= (vla-get-objectname att_obj_) "AcDbBlockReference") (progn (/= (vla-get-hasattributes att_obj_) :vlax-true ) ))
              )
              (progn
                (alert "Please selection attribute object")
              )
            )
          ;
        ; )
      ;
      ;preloop_and_while_for_make_sequnce_attribute
        (setq att_tag_list_i 0)
        (while (< att_tag_list_i (length att_tag_list_))
          (setq att_tag_list_tagname_ (nth  att_tag_list_i att_tag_list_))
          (if (= (TA:FIND_DUPLICATE_LIST att_tag_list_tagname_ except_att_list_) "N" )
            (progn
              (LM:vl-setattributevalue att_obj_ att_tag_list_tagname_ "" )
            )
          )
          (setq att_tag_list_i (+ att_tag_list_i 1))
        )
      ;
      
    )
    (defun c:fillter_blockname_to_text_b2text ()
      ;NOTE-FROM_DEV
        ;this is code for filler_efectivename_block_name
      ;
      ;preloop_and_while
        (setq return_code_ nil)
        (while (and 
                (= return_code_ nil)
                
              )
          ;user_input_
            (setq eee_ename_ (car (entsel "specify Object for fillter_block_name")))
            (setq fillter_block_name_ (TA:fillter_block_name_ eee_ename_))
            (setq dynamic_ename_ (car (entsel "specify Object for input fillter_block_name")))
            (setq dynamic_obj_ (vlax-ename->vla-object dynamic_ename_))
          ;
          (if (and 
                (= (setq alert_val_1 (vla-get-objectname dynamic_obj_)) "AcDbBlockReference")
                (= (setq alert_val_2 (LM:effectivename dynamic_obj_)) "CONTENT NAME3 LEFT - BUBBLE v6")
                (/= eee_ename_ dynamic_ename_)
              )
            (progn
              (LM:vl-setattributevalue dynamic_obj_ "name1" fillter_block_name_)
              (setq return_code_"full")
            )
            (setq return_code_ nil)
          )
          (if (and 
                (= return_code_ nil)
                (/= alert_val_1 "AcDbBlockReference")
              )
            (progn
              (alert (strcat "this object is " alert_val_1 "\n" "block name = nil\n" "something is incorrect"  ))
              (setq return_code_ nil)
            )

          )

        )
      ;
    )
    (defun c:effectivename_to_att_EF2text ()
      ;NOTE-FROM_DEV
        ;this is code for filler_efectivename_block_name
      ;
      ;preloop_and_while
        (setq return_code_ nil)
        (while (and 
                (= return_code_ nil)
                
              )
          ;user_input_
            (setq eee_ename_ (car (entsel "specify Object for fillter_block_name")))
            (setq fillter_block_name_ (LM:effectivename (setq eee_ename_obj_ (vlax-ename->vla-object eee_ename_))))
            (setq dynamic_ename_ (car (entsel "specify Object for input fillter_block_name")))
            (setq dynamic_obj_ (vlax-ename->vla-object dynamic_ename_))
          ;
          (if (and 
                (= (setq alert_val_1 (vla-get-objectname dynamic_obj_)) "AcDbBlockReference")
                (= (setq alert_val_2 (LM:effectivename dynamic_obj_)) "000 - BOX_EF_NAME")
                (/= eee_ename_ dynamic_ename_)
              )
            (progn
              (LM:vl-setattributevalue dynamic_obj_ "nameblk" fillter_block_name_)
              (setq return_code_"full")
            )
            (setq return_code_ nil)
          )
          (if (and 
                (= return_code_ nil)
                (/= alert_val_1 "AcDbBlockReference")
              )
            (progn
              (alert (strcat "this object is " alert_val_1 "\n" "block name = nil\n" "something is incorrect"  ))
              (setq return_code_ nil)
            )

          )

        )
      ;
    )
    (defun c:rename_block_RENBLK ()
      ;NOTE-FROM_DEV
        ;this is code for filler_efectivename_block_name
      ;
      ;user_input
        (setq eee_ename_ (car (entsel "specify Object for fillter_block_name")))
        (setq old_block_name_ (LM:effectivename (setq eee_ename_obj_ (vlax-ename->vla-object eee_ename_))))
        (setq new_ename_ (car (entsel "specify Object for input fillter_block_name")))
        (setq new_ename_obj_ (vlax-ename->vla-object new_ename_))
      ;
      ;checking_process
        (if 
          (and 
            (= (setq alert_val_1 (vla-get-objectname eee_ename_obj_)) "AcDbBlockReference")
            (= (setq alert_val_2 (LM:effectivename new_ename_obj_)) "000 - BOX_EF_NAME")
            (/= eee_ename_ dynamic_ename_)
          )
          (progn
            ;get_data_old_EF_NAME_
              (setq old_block_name_ (LM:effectivename (setq eee_ename_obj_ (vlax-ename->vla-object eee_ename_))))
            ;
            ;get_data
              (setq new_ef_name_ (LM:vl-getattributevalue new_ename_obj_ "nameblk"  ))
            ;
          )
          (alert "SOMETHING BAD")
        )
      ;
      ;Rename_process
        (command "rename" "B" old_block_name_ new_ef_name_)
      ;
          


    )
    (defun c:limit_content_name_[limittext_] ()
      ;Note By Code_Developer
      ;This command is designed to work exclusively with a block named 'CONTENT NAME3 LEFT - BUBBLE v6'.
      ;The operation of the command will read the block's attribute values and regenerate By this command can limit number of chhracters per line.
      ;Due to this code is designed to work exclusively with a block named "CONTENT NAME3 LEFT - BUBBLE v6"
      ;Fully command must have sub-functions with names starting with TA: or LM:
      ;
      ;
      ;
      ;fillter_content_name_object_
        (setq content_ename_ nil)
        (while (= content_ename_ nil)
          ;user_input_data
            (setq content_ename_ (car (entsel "specify Object")))
            (setq limit_text_length (cond ( (getint (strcat "\nSpecify limit_text_count   <" (rtos (setq limit_text_length (cond (limit_text_length) (1.0) ) ) ) "> : " ) ) ) (limit_text_length) ) )
          ;
          ;fillter_object_type_
            (if 
              (and
                (if (/= content_ename_ nil) (progn (setq content_obj_ (vlax-ename->vla-object content_ename_)) ))
                (= (vla-get-objectname content_obj_) "AcDbBlockReference")
                (= (vla-get-hasattributes content_obj_) :vlax-true )
                (= (LM:effectivename content_obj_) "CONTENT NAME3 LEFT - BUBBLE v6" )
              )
              (progn ;MAIN_IDEA
                ;getdata_limit_text_
                  (setq content_tag_list_ (LM:removenth 9 (LM:vl-getattributevalues content_obj_)))
                  (setq content_tag_list_length_ (strlen 
                                                  (cdr (nth 0 content_tag_list_))
                                                  (cdr (nth 1 content_tag_list_))
                                                  (cdr (nth 2 content_tag_list_))
                                                  (cdr (nth 3 content_tag_list_))
                                                  (cdr (nth 4 content_tag_list_))
                                                  (cdr (nth 5 content_tag_list_))
                                                  (cdr (nth 6 content_tag_list_))
                                                  (cdr (nth 7 content_tag_list_))
                                                  (cdr (nth 8 content_tag_list_))
                                                  
                                                  "_"
                                                )
                  )
                  (setq content_tag_list_value_ (strcat 
                                                  (cdr (nth 0 content_tag_list_))
                                                  (cdr (nth 1 content_tag_list_))
                                                  (cdr (nth 2 content_tag_list_))
                                                  (cdr (nth 3 content_tag_list_))
                                                  (cdr (nth 4 content_tag_list_))
                                                  (cdr (nth 5 content_tag_list_))
                                                  (cdr (nth 6 content_tag_list_))
                                                  (cdr (nth 7 content_tag_list_))
                                                  (cdr (nth 8 content_tag_list_))
                                                  
                                                  "_"
                                                )
                  )
                  
                  (setq sum_text_ (list content_tag_list_length ))
                  (setq sum_text_name (list content_tag_list_value_))
                  (setq sum_text_name (LM:lst->str sum_text_name ""))
                  (setq sum_text_name (LM:str->lst sum_text_name "_"))
                  (setq sum_text_name (TA:REMOVE_VAL_LIST_ "" sum_text_name ))
                  
                  (setq sum_text_ (TA:REMOVE_VAL_LIST_ nil sum_text_))
                ;
                ;preparing_summary_data_
                  (setq sum_text_i 0)
                  (setq sum_text_len 0)
                  ; (setq new_text_line_0 ())
                  (setq new_text_line_1 ())
                  (setq new_text_line_2 ())
                  (setq new_text_line_3 ())
                  (setq new_text_line_4 ())
                  (setq new_text_line_5 ())
                  (setq new_text_line_6 ())
                  (setq new_text_line_7 ())
                  (setq new_text_line_8 ())
                  (setq new_text_line_9 ())
                  (setq new_text_line_10 ())
                ;
                ;summary_limit_text_to_line
                  (setq limit_text_length limit_text_length)
                  (while (and (< sum_text_i (length sum_text_name)) (< sum_text_len 500))
                    (setq sum_text_ename_name (nth  sum_text_i sum_text_name))
                    (setq sum_text_len (+ (+ sum_text_len (strlen sum_text_ename_name) ) 1))
                    ;main_IDEA_limit_text_process
                      (cond
                        ( ;line_1
                          (<= sum_text_len limit_text_length)
                          (progn
                            (setq new_text_line_1 (cons sum_text_ename_name new_text_line_1 ))
                          )
                          (princ "line_1")
                        )
                        ( ;line_2
                          (and (> sum_text_len (* limit_text_length 1)) (< sum_text_len (* limit_text_length 2)) )
                          (progn
                            (setq new_text_line_2 (cons sum_text_ename_name new_text_line_2 ))
                          )
                          (princ "line_2")
                        )
                        ( ;line_3
                          (and (>= sum_text_len (* limit_text_length 2)) (< sum_text_len (* limit_text_length 3)) )
                          (progn
                            (setq new_text_line_3 (cons sum_text_ename_name new_text_line_3 ))
                          )
                          (princ "line_3")
                        )
                        ( ;line_4
                          (and (>= sum_text_len (* limit_text_length 3)) (< sum_text_len (* limit_text_length 4)) )
                          (progn
                            (setq new_text_line_4 (cons sum_text_ename_name new_text_line_4 ))
                          )
                          (princ "line_4")
                        )
                        ( ;line_5
                          (and (>= sum_text_len (* limit_text_length 4)) (< sum_text_len (* limit_text_length 5)) )
                          (progn
                            (setq new_text_line_5 (cons sum_text_ename_name new_text_line_5 ))
                          )
                          (princ "line_5")
                        )
                        ( ;line_6
                          (and (>= sum_text_len (* limit_text_length 6)) (< sum_text_len (* limit_text_length 7)) )
                          (progn
                            (setq new_text_line_6 (cons sum_text_ename_name new_text_line_6 ))
                          )
                          (princ "line_6")
                        )
                        ( ;line_7
                          (and (>= sum_text_len (* limit_text_length 7)) (< sum_text_len (* limit_text_length 8)) )
                          (progn
                            (setq new_text_line_7 (cons sum_text_ename_name new_text_line_7 ))
                          )
                          (princ "line_7")
                        )
                        ( ;line_8
                          (and (>= sum_text_len (* limit_text_length 8)) (< sum_text_len (* limit_text_length 9)) )
                          (progn
                            (setq new_text_line_8 (cons sum_text_ename_name new_text_line_8 ))
                          )
                          (princ "line_8")
                        )
                        ( ;line_9
                          (and (>= sum_text_len (* limit_text_length 9)) (< sum_text_len (* limit_text_length 10)) )
                          (progn
                            (setq new_text_line_9 (cons sum_text_ename_name new_text_line_9 ))
                          )
                          (princ "line_9")
                        )
                      )
                    ;
                    (setq sum_text_i (+ sum_text_i 1))
                  )
                  (setq limit_text_value_set_ 
                                              (TA:REMOVE_VAL_LIST_ 
                                                ""
                                                (list 
                                                  (setq new_text_line_1_sum (LM:lst->str (reverse new_text_line_1) "_" ) )
                                                  (setq new_text_line_2_sum (LM:lst->str (reverse new_text_line_2) "_" ) )
                                                  (setq new_text_line_3_sum (LM:lst->str (reverse new_text_line_3) "_" ) )
                                                  (setq new_text_line_4_sum (LM:lst->str (reverse new_text_line_4) "_" ) )
                                                  (setq new_text_line_5_sum (LM:lst->str (reverse new_text_line_5) "_" ) )
                                                  (setq new_text_line_6_sum (LM:lst->str (reverse new_text_line_6) "_" ) )
                                                  (setq new_text_line_7_sum (LM:lst->str (reverse new_text_line_7) "_" ) )
                                                  (setq new_text_line_8_sum (LM:lst->str (reverse new_text_line_8) "_" ) )
                                                  (setq new_text_line_9_sum (LM:lst->str (reverse new_text_line_9) "_" ) )
                                                )
                                              )
                  )
                ;
                ;Clear_att_process_
                  (setq except_att_list_ (list "NO.CODE") )
                  (TA:remove_att_value_ content_obj_ except_att_list_)
                ;
                ;preloop_and_while_limit_text_to_line
                    (setq limit_text_i 0)
                    (while (< limit_text_i (length limit_text_value_set_))
                      (setq content_tag_list_att (car (nth limit_text_i content_tag_list_))) ;att_tag
                      (setq limit_text_list_ (nth limit_text_i limit_text_value_set_)) ;att_value
                      
                      (if (/= limit_text_list_ nil)
                        (progn
                          (LM:vl-setattributevalue content_obj_ content_tag_list_att (strcat limit_text_list_ "_") )
                        )
                        (LM:vl-setattributevalue content_obj_ content_tag_list_att "" )
                      )
                  
                      (setq limit_text_i (+ limit_text_i 1))
                    )
                ;
                ;indicate_visibility_BLK_atttribute
                  (setq limit_text_vis_ (TA:REMOVE_VAL_LIST_ "" limit_text_value_set_))
                  (LM:setdynpropvalue content_obj_ "content_line" (rtos(length limit_text_vis_)2 0))
                ;
              
              )
              (setq content_ename_ nil)
            )
              
            
            
            (if
              (or
                (= content_ename_ nil)
                (/= (vla-get-objectname content_obj_) "AcDbBlockReference")
                (if (= (vla-get-objectname content_obj_) "AcDbBlockReference") (progn (/= (vla-get-hasattributes content_obj_) :vlax-true ) ))
              )
              (progn
                (alert "Please selection attribute object")
              )
            )
          ;
        )
      ;
    )
    (defun c:replace_text_attribute_retatt_ ()
      
      (setq replace_old_text_ (getstring (strcat "\nSpecify old_text <" (if replace_old_text_ replace_old_text_ "") ">: ") ) )
      (setq replace_new_text_ (getstring (strcat "\nSpecify new_text <" (if replace_new_text_ replace_new_text_ "") ">: ") ) )
      
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i ))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          
          (setq att_list_ (LM:vl-getattributevalues ss_pre_filter_set_xx_obj_))
          
          ;preloop_and_while
            (setq att_list_i 0)
            (while (< att_list_i (length att_list_))
              (setq att_list_head_ (car (nth  att_list_i att_list_)))
              (setq att_list_val_ (cdr (nth  att_list_i att_list_)))
              
              (LM:vl-setattributevalue ss_pre_filter_set_xx_obj_ att_list_head_ (LM:StringSubst replace_new_text_ replace_old_text_ att_list_val_))
          
              (setq att_list_i (+ att_list_i 1))
            )
          ;
          

          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;

      
      
      
      
    )

  ;
  ;Joint_FUNC
    (defun c:joint_line_JOL ()
      ;Note By Code_Developer
      ;This command is designed to work exclusively with a LWPOLYLINE espectespecially object from offset line
      ;The principle of this code is to read the insertion points (vertices) of the polyline at the head and tail,then create polylines at both insertion points and join them together.
      ;
      ;joint_pline
        ;selection_set
          (if  ;pre_select_ssget_or_post_select_ssget
            (= 
              (setq ss_pre_filter_set_xx_ (ssget "I" 
                                                (list 
                                                  (cons 0 "lwpolyline") ;type of object
                                                  ; (cons 8 "*GRID*")   ;kind of layer
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
                                              (cons 0 "lwpolyline") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                          )
              )
            )
            (sslength ss_pre_filter_set_xx_)
          )
        ;
        ;condition_rule_for_run
          (if (= (sslength ss_pre_filter_set_xx_) 2)
            (progn
              ;preloop_and_while
                (setq ss_pre_filter_set_xx_i 0)
                (setq ss_pre_filter_set_xx_ii 1)
                (while (< ss_pre_filter_set_xx_i 1)
                  ;first_pline_process
                    (setq ss_pre_filter_set_xx_i_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
                      (setq ss_pre_filter_set_xx_i_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_i_ename_))
                        (setq ss_pre_filter_set_xx_i_obj_vertex_len_ (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_i_ename_)))
                        ;reverse insertion point 
                          (if (>
                                (car (car (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_i_ename_))))
                                (car (car (reverse (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_i_ename_)))))
                              )
                            (progn
                              (command "reverse" ss_pre_filter_set_xx_i_ename_ "")
                              (setq ss_pre_filter_set_xx_i_obj_vertex_len_ (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_i_ename_)))
                            )
                          )
                        ;
                          (setq ss_pre_filter_set_xx_i_obj_vertex_len_headline_ (nth 0 ss_pre_filter_set_xx_i_obj_vertex_len_))
                          (setq ss_pre_filter_set_xx_i_obj_vertex_len_botline_ (nth (- (length ss_pre_filter_set_xx_i_obj_vertex_len_) 1) ss_pre_filter_set_xx_i_obj_vertex_len_))
                    ;copy_pline_object
                      (vla-copy ss_pre_filter_set_xx_i_obj_)
                    ;
                  ;
                  ;second_pline_process
                    (setq ss_pre_filter_set_xx_ii_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_ii))
                      (setq ss_pre_filter_set_xx_ii_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ii_ename_))

                        (setq ss_pre_filter_set_xx_ii_obj_vertex_len_ (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_ii_ename_)))
                        ;reverse insertion point 
                          (if (>
                                (car (car (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_ii_ename_))))
                                (car (car (reverse (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_ii_ename_)))))
                              )
                            (progn
                              (command "reverse" ss_pre_filter_set_xx_ii_ename_ "")
                              (setq ss_pre_filter_set_xx_ii_obj_vertex_len_ (cadr (TA:Get_Pline_vertext_ins_point_ ss_pre_filter_set_xx_ii_ename_)))
                            )
                          )
                        ;
                          (setq ss_pre_filter_set_xx_ii_obj_vertex_len_headline_ (nth 0 ss_pre_filter_set_xx_ii_obj_vertex_len_))
                          (setq ss_pre_filter_set_xx_ii_obj_vertex_len_botline_ (nth (- (length ss_pre_filter_set_xx_ii_obj_vertex_len_) 1) ss_pre_filter_set_xx_ii_obj_vertex_len_))
                    ;copy_pline_object
                      (vla-copy ss_pre_filter_set_xx_ii_obj_)
                    ;
                  ;
                  ;making_pline_process_
                    (setvar "osmode" 0)
                    (create-pline (list ss_pre_filter_set_xx_i_obj_vertex_len_headline_ ss_pre_filter_set_xx_ii_obj_vertex_len_headline_)) ;head_of_line
                      (setq new_joint_headline_ (entlast))
                    (create-pline (list ss_pre_filter_set_xx_i_obj_vertex_len_botline_ ss_pre_filter_set_xx_ii_obj_vertex_len_botline_)) ;bot_of_line
                      (setq new_joint_botline_ (entlast))
                  ;
                  ;Jointline_process
                    (command "join" new_joint_headline_ new_joint_botline_ ss_pre_filter_set_xx_i_ename_ ss_pre_filter_set_xx_ii_ename_ "")
                  ;
                  (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
                )
              ;
              (setvar "osmode" 1215)
              (command "draworder"  "L" "" "B") 

            )
          )
        ;
      ;
    )
  ;
  ;Selection_FUNC
    (defun c:filter_object_and_selection_[sscircle] () ;ssget["Depend_On_User"]
      ;Note By Code_Developer
      ;The principle of codework is to selection object by ssget method via variable name [ss_pre_filter_set_xx_]
      ;Example code 
      ;
      
      (if  ;pre_select_ssget_or_post_select_ssget
        (= 
          (setq ss_pre_filter_set_xx_ (ssget "I" 
                                            (list 
                                              (cons 0 "circle") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
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
                                          (cons 0 "circle") ;type of object
                                          ; (cons 8 "*GRID*")   ;kind of layer
                                          ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
      (command "pselect" ss_pre_filter_set_xx_ "")
    )
    (defun c:filter_object_and_selection_[ssspline] ()
      (if  ;pre_select_ssget_or_post_select_ssget
        (= 
          (setq ss_pre_filter_set_xx_ (ssget "I" 
                                            (list 
                                              (cons 0 "spline") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
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
                                          (cons 0 "spline") ;type of object
                                          ; (cons 8 "*GRID*")   ;kind of layer
                                          ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                          ; (cons 62 1)           ;kind of color call sign with color code index
                                        )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )

      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (command "pedit" ss_pre_filter_set_xx_ename_ "Y" "2"  "")
      
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      
    )
    (defun c:make_selection_set_boudary_line_OVLBOL ()
      (setq sss_ (ssget ))
      (setvar "osmode" 0)
      (setq ssssasas (TA:ss_vla-getboundingbox sss_))
      (if (= (getvar "worlducs") 1) ;รอแก้
        (progn
          (setq ssssasas (list (trans (car ssssasas) 1 0) (trans (cadr ssssasas) 1 0) ) )
        )
      )
      (command "rectangle" (car ssssasas) (cadr ssssasas) )
      (setvar "osmode" 1215)
      ;new_blk_entlast object
        (setq ss_ename (entlast))
        (setq ss_obj (vlax-ename->vla-object ss_ename))
        (vla-put-color ss_obj 08)
      ;
    )
    (defun c:make_selection_set_boudary_line_MULBOL ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT,line,lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "INSERT,line,lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (setq ss_pre_filter_set_xx_obj_getboundingbox (vla-getboundingbox ss_pre_filter_set_xx_obj_ 'min_ 'max_)) 
          (setq ss_pre_filter_set_xx_min_ (vlax-safearray->list min_)) 
          (setq ss_pre_filter_set_xx_max_ (vlax-safearray->list max_)) 
          (command "rectangle" ss_pre_filter_set_xx_min_ ss_pre_filter_set_xx_max_)
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
       (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq DELETE_OBJ_ (not (eq "No" (getkword "\nKeep Existing object? [Yes/No] <Y>: "))))
              )
            )
          )
        )
        (if (= DELETE_OBJ_ t)
          (progn
            (princ "pass")
          )
          (command "erase" ss_pre_filter_set_xx_  )
        )
    )
    (defun c:copybase_selection_set_boudary_line_CCBOL ()
      (setq sss_ (ssget ))
      (setvar "osmode" 0)
      (setq ssssasas (TA:ss_vla-getboundingbox sss_))
      (command "rectangle" (car ssssasas) (cadr ssssasas) )
      (setq new_ename_ (entlast))
      (setq new_obj_ (vlax-ename->vla-object new_ename_))
      (vla-put-color new_obj_ 0)
      (ssadd new_ename_ sss_)
      (sslength sss_)
      (command "_copybase" (LM:PolyCentroid new_ename_) sss_ "" )
      (setvar "osmode" 1215)
      (command "_pasteblock" )
      
    )
    (defun c:selection_by_handent_hand_ ()
      (setq handent_string_ (getstring "specify handent string"))
      (command "pselect"  (handent handent_string_) "" )
      
      
    )
    (defun c:lastselect_entity_lse ()
      (command "pselect"  (entlast) "" )
    )


  ;
  ;test_command
    (defun TA:dump_obj_ (dump_ename_ )
      ; (setq dump_ename_ (car (entsel "specify Object")))
      (setq dump_obj_ (vlax-ename->vla-object dump_ename_))
      (vlax-dump-object (vlax-ename->vla-object dump_ename_))
    )
    (defun C:Dumpit ( / ent) 
      (while (setq ent (entsel)) 
        (vlax-Dump-Object 
          (vlax-Ename->Vla-Object (car ent)) 
        ) 
      ) 
      (princ) 
    )
    (defun c:t1_ins_vla-getboundingbox ()
      (setq ss (vlax-ename->vla-object (car (entsel))) )
      (vla-getboundingbox ss 'ins_min 'ins_max)
                  (setq ins_min (vlax-safearray->list ins_min))
                  (setq ins_max (vlax-safearray->list ins_max))

      (command "point" ins_min)
      (command "point" ins_max)
    )
    (defun c:t2_find_objname ()
      (setq obj_name_ (vla-get-objectname (vlax-ename->vla-object (car (entsel)))))
    )
  ;
  ;ALuminium Tube FUNC
    (defun c:insert_ALTUBE_insAL ()
      ;Note By Code_Developer
      ;This command is designed to work exclusively with a block named '001 - DYNAMIC REC&SSQ SHAPE SOLID_midpoint'.
      ;principle of codework is design to work woth line object only by referce start-end point of the line is basepoint for first insertion Block object
      ;After insertion block complete, main code will keep Ename data by "enlast" method and use Lee Mac dynamic block for strech object 
      ;Fully command must have sub-functions with names starting with TA: or LM:
      ;
      ;
      ;user_input_dynammic_
        (setq user_input_width_ (cond ( (getint (strcat "\nspecify fllet_rec_<" (rtos (setq user_input_width_ (cond (user_input_width_) (1.0) ) ) ) "> : " ) ) ) (user_input_width_) ) )
      ;
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "line") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "line") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      ;while_select_block_on_condition_
          (setq blk_ename_ nil)
          (while (= blk_ename_ nil)
            (setq blk_ename_ (car (entsel "specify blk_ename Object")))
            (if
              (and ;conditional_rule_for_select_object
                (/= blk_ename_ nil)
                (setq blk_ename_obj_ (vlax-ename->vla-object blk_ename_))
                (= (vla-get-objectname blk_ename_obj_ ) "AcDbBlockReference")
                (= (vla-get-isdynamicblock blk_ename_obj_ ) :vlax-true)
                
              )
              (progn
                (setq blk_ename_efname_ (LM:effectivename blk_ename_obj_ ) )
              )
              (alert "Object invalid Please try again")
            )
          )
      ;
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          ;get_line_data
            (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
            (setq ss_pre_filter_set_xx_hon_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
            (setq ss_pre_filter_set_xx_hon_obj_start_end_pt_ (list
                                            (setq ss_pre_filter_set_xx_hon_obj_startpt_ (vlax-safearray->list
                                                                      (vlax-variant-value ( vla-get-startpoint ss_pre_filter_set_xx_hon_obj_ ))
                                                                    )
                                            )
                                            (setq ss_pre_filter_set_xx_hon_obj_endpt_ (vlax-safearray->list
                                                                      (vlax-variant-value ( vla-get-endpoint ss_pre_filter_set_xx_hon_obj_ ))
                                                                  )
                                            )
                                          )
            )
            (setq ss_pre_filter_set_xx_hon_obj_length (atoi (rtos (vla-get-length ss_pre_filter_set_xx_hon_obj_) 2 0)))
          
          ;
          ;insertion_new_object
            (command "insert" blk_ename_efname_ ss_pre_filter_set_xx_hon_obj_startpt_ 1 0)
            (LM:setdynpropvalue (vlax-ename->vla-object (entlast)) "H" ss_pre_filter_set_xx_hon_obj_length )
            (LM:setdynpropvalue (vlax-ename->vla-object (entlast)) "W" user_input_width_ )

          ;
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )

  ;
  ;Excel_sub_func
    ;get-object-Excel
    (defun TA:New_Excel_File_NEX_ (new_vla-obj_app )
      (if (= new_vla-obj_app nil)
        (progn
          (setq new_vla-obj_app (vlax-get-or-create-object "Excel.Application"))
          
        )
      )
      (if (/= new_vla-obj_app nil)
        (progn
          (setq new_vla-obj_app (vlax-get-or-create-object "Excel.Application"))
          ; (setq new_vla-obj_app (vlax-create-object "Excel.Application"))
          (setq new_Workbooks_ (vlax-get-property new_vla-obj_app 'Workbooks))
          (setq new_workbook_ (vlax-invoke-method new_Workbooks_ 'Add))
          (setq Vla_workbook_list_ (TA:Excel_Assembly_ALL-obj_list_ new_Workbooks_ ))
          (vlax-put-property new_vla-obj_app 'Visible :vlax-true)
          (setq Vla_workbook_list_ Vla_workbook_list_)
        )
      )
      ;princ main object
        (setq new_Workbooks_ new_Workbooks_)
      ;
    )
    (defun TA:Excel_Assembly_ALL-obj_list_ (books_obj_)
      ;Note By Code_Developer
      ;pripicle of code for get total _worksheet sequnce name vla-obj _sheet by sorting via sequnce  
      ;
      ;books_obj_ = #<VLA-OBJECT Sheets >
      ;preloop_and_while
        (if 
          (or
            (wcmatch (strcase (vl-prin1-to-string books_obj_)) "*<VLA-OBJECT WORKBOOKS*")
            ; (wcmatch (strcase (vl-prin1-to-string books_obj_)) "*SHEETS*")
          )
          (progn
            (setq _workbook_Vla-obj_list_ ())
            (setq _worksheet_vla-obj_name_list_ ())
            
            (setq books_obj_length (vlax-get-property books_obj_ 'count )) ;total file open in 1 app
            (setq books_obj_i 1)
            (while (<= books_obj_i books_obj_length)
              (setq _workbook_obj_ (vlax-get-property books_obj_ 'item books_obj_i))
                (setq _sheets_obj_ (vlax-get-property _workbook_obj_ 'sheets))
                  ;preloop_and_while
                    (setq _sheets_obj_length (vlax-get-property _sheets_obj_ 'count))
                    (setq _sheets_obj_i 1 )
                    (setq _worksheet_vla-obj_name_list_ ())
                      (while (<= _sheets_obj_i _sheets_obj_length)
                        (setq _worksheet_obj_ (vlax-get-property _sheets_obj_ 'item _sheets_obj_i))
                          (setq _worksheet_obj_name (vlax-get-property _worksheet_obj_ 'name))
                          (setq _worksheet_vla-obj_name_list_sum (list _sheets_obj_i _worksheet_obj_name _worksheet_obj_))
                        (setq _worksheet_vla-obj_name_list_ (cons _worksheet_vla-obj_name_list_sum _worksheet_vla-obj_name_list_))
                        (setq _sheets_obj_i (+ _sheets_obj_i 1))
                        ; (setq _worksheet_vla-obj_name_list_ (reverse _worksheet_vla-obj_name_list_))
                        (setq _worksheet_vla-obj_name_list_ (vl-sort _worksheet_vla-obj_name_list_  ;bigest open indent list
                                                        (function 
                                                          (lambda (a b) 
                                                            (< (nth 0 a) (nth 0 b))
                                                          )
                                                        )
                                                ) ;bigest close indent list
                        )
                      )
                    ;
              (setq _workbook_obj_name (vlax-get-property _workbook_obj_ 'name))
              (setq _worksheet_Vla-obj_list_sum_ (list books_obj_i _workbook_obj_name _workbook_obj_ _worksheet_vla-obj_name_list_))
              
              (setq _workbook_Vla-obj_list_ (cons _worksheet_Vla-obj_list_sum_ _workbook_Vla-obj_list_))
              (setq books_obj_i (+ books_obj_i 1))
            )
            ; (setq _workbook_Vla-obj_list_ (reverse _workbook_Vla-obj_list_ ))
            (setq _workbook_Vla-obj_list_ (vl-sort _workbook_Vla-obj_list_  ;bigest open indent list
                                            (function 
                                              (lambda (a b) 
                                                (< (nth 0 a) (nth 0 b))
                                              )
                                            )
                                    ) ;bigest close indent list
            )
            (append (list books_obj_) _workbook_Vla-obj_list_)
          )
        )
      ;preloop
    )
    (defun TA:Excel_Assembly_worksheet_obj_list_ (sheets_obj_)
      ;Note By Code_Developer
      ;pripicle of code for get total _worksheet sequnce name vla-obj _sheet by sorting via sequnce  
      ;
      ;sheets_obj_ = #<VLA-OBJECT Sheets >
      ;preloop_and_while
        (if 
          (or
            (wcmatch (strcase (vl-prin1-to-string sheets_obj_)) "*WORKBOOKS*")
            (wcmatch (strcase (vl-prin1-to-string sheets_obj_)) "*SHEETS*")
          )
          (progn
            (setq _worksheet_Vla-obj_list_ ())
            (setq sheets_obj_length (vlax-get-property sheets_obj_ 'count ))
            (setq sheets_obj_i 1)
            (while (<= sheets_obj_i sheets_obj_length)
              (setq _worksheet_obj_ (vlax-get-property sheets_obj_ 'item sheets_obj_i))
                (setq _worksheet_obj_name (vlax-get-property _worksheet_obj_ 'name))
                (setq _worksheet_Vla-obj_sum_ (list sheets_obj_i _worksheet_obj_name _worksheet_obj_ ))
              (setq _worksheet_Vla-obj_list_ (cons _worksheet_Vla-obj_sum_ _worksheet_Vla-obj_list_))
              (setq sheets_obj_i (+ sheets_obj_i 1))
            )
            (setq _worksheet_Vla-obj_list_ (reverse _worksheet_Vla-obj_list_ ))
          )
        )
      ;preloop
    )
    (defun Excel:VLA-OBJECT-Workbook->VLA-OBJECT-Sheets  (VLA-OBJECT_Workbook)
      (if 
        (wcmatch 
          (strcase (vl-princ-to-string VLA-OBJECT_Workbook))
          (strcase "*<VLA-OBJECT _Workbook*")
        )
        (progn
          (setq VLA-OBJECT-Sheets (vlax-get-property VLA-OBJECT_Workbook 'sheets))
        )
        (princ "argument invalid")
      )
    )
    (defun Excel:VLA-OBJECT-Sheets->VLA-OBJECT-Worksheet  (VLA-OBJECT-Sheets i)
      (if 
        (and
          (wcmatch 
            (strcase (vl-princ-to-string VLA-OBJECT-Sheets))
            (strcase "*<VLA-OBJECT SHEETS*")
          )
          (numberp i )
          (<= i (vlax-get-property VLA-OBJECT-Sheets 'count))
        )
        (progn
          (vlax-get-property VLA-OBJECT-Sheets 'item i)
        )
        (princ "argument invalid")
      )
    )
    (defun TA:EXCEL_put_all_rowheight (VLA-OBJECT-Worksheet rowheight_value_ )
      (vlax-put-property (vlax-get VLA-OBJECT-Worksheet 'Cells) 'rowheight rowheight_value_)
    )
    (defun TA:EXCEL_put_all_columnwidth (VLA-OBJECT-Worksheet columnwidth_value_ )
      (vlax-put-property (vlax-get VLA-OBJECT-Worksheet 'Cells) 'columnwidth columnwidth_value_)
    )
    (defun TA:EXCEL_put_columnhide (VLA-OBJECT-Worksheet column_number columnhide_value_ )
      (setq vla-object-cols_ (vlax-get-property VLA-OBJECT-Worksheet 'Columns))
        (setq vla-object-col_(vlax-get-property (vlax-variant-value (vlax-get-property vla-object-cols_ 'Item column_number)) 'EntireColumn))
          (vlax-put-property vla-object-col_ 'Hidden  columnhide_value_)
    )
    (defun TA:EXCEL_put_rowhide (VLA-OBJECT-Worksheet row_number rowhide_value_ )
      (setq vla-object-rows_ (vlax-get-property VLA-OBJECT-Worksheet 'rows))
        (setq vla-object-row_(vlax-get-property (vlax-variant-value (vlax-get-property vla-object-rows_ 'Item row_number)) 'Entirerow))
          (vlax-put-property vla-object-row_ 'Hidden rowhide_value_)
    )
    (defun TA:EXCEL_put_columnwidth (VLA-OBJECT-Worksheet column_number columnwidth_value_ )
      (setq vla-object-cols_ (vlax-get-property VLA-OBJECT-Worksheet 'Columns))
        (setq vla-object-col_(vlax-get-property (vlax-variant-value (vlax-get-property vla-object-cols_ 'Item column_number)) 'EntireColumn))
          (vlax-put-property vla-object-col_ 'ColumnWidth columnwidth_value_)
    )
    (defun TA:EXCEL_put_rowheight (VLA-OBJECT-Worksheet row_number rowheight_value_ )
      (setq vla-object-rows_ (vlax-get-property VLA-OBJECT-Worksheet 'rows))
        (setq vla-object-row_(vlax-get-property (vlax-variant-value (vlax-get-property vla-object-rows_ 'Item row_number)) 'Entirerow))
          (vlax-put-property vla-object-row_ 'rowheight rowheight_value_)
    )
    (defun TA:EXCEL_put_columnwidth_viatext  (Rangecell_row_ Rangecell_column_ Rangecell_target_row_ text_width_val)
      ;Note By Code_Developer
      ;pripicle of code for put columnwidth from string len or number len in rangecell in Excel App by While-loop method 1st-row to target-row (target-row specify by argument)
      ;
      ;Exce_sub_FUNC_list_
        ;TA:EXCEL_put_columnwidth 
      ;
      ;argument
        ;_worksheet_obj_        = <VLA-OBJECT _Worksheet >   
        ;Rangecell_row_         = "1st-Row cell in Excel App"
        ;Rangecell_target_row_  = "lowset-Row cell in Excel App"
        ;Rangecell_column_      = "Column cell in Excel App"
        ;text_width_val         = text_len per width_
      ;
      ;example_argument_
        ; (setq Rangecell_row_ 1)
        ; (setq Rangecell_column_ 2)
        
        ; (setq Rangecell_target_row_ 2) 
      
      ;preloop_and_while
        (setq rangecell_colwidth_list_ ())
        (while
          (< Rangecell_row_ (+ Rangecell_target_row_ 1))
          (setq rangecell_value_ (TA:Excel_get_data_R1C1 _worksheet_obj_ Rangecell_row_ Rangecell_column_ ))
          (if (numberp rangecell_value_)
            (progn 
              (setq col_width_ (* (strlen (rtos rangecell_value_ 2 8)) text_width_val ) )
            )
            (setq col_width_ (* (if (/= rangecell_value_ nil) (progn (strlen rangecell_value_)) 0 ) text_width_val) )
          )
          (setq rangecell_colwidth_list_ (cons col_width_ rangecell_colwidth_list_ ))
          
          
          (setq Rangecell_row_ (+ Rangecell_row_ 1))
        )
      ;
      (TA:EXCEL_put_columnwidth _worksheet_obj_ Rangecell_column_ (setq rangecell_col-max-width_ (car (vl-sort rangecell_colwidth_list_ '>))))
    )
    (defun TA:Excel_Clearcontents (VLA-OBJECT-Worksheet  )
      (setq VLA-OBJECT-Range (vlax-get-property VLA-OBJECT-Worksheet 'Cells  ) )
      (vlax-invoke-method VLA-OBJECT-Range 'ClearContents)
    )
    (defun TA:Excel_get_data_Rangecell (_worksheet_obj_ Rangecell_name_)
      ;Note By Code_Developer
      ;pripicle of code for get data from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;
      ;argument
        ;_worksheet_obj_ = <VLA-OBJECT _Worksheet >
        ;Rangecell_name_ = "Rangecell name in Excel App"
      ;
      ;Example 
        ;(vlax-get (vlax-get-property _worksheet_obj_ 'Range "AA1") "value2")  ;get_value_from_range_cell
      ;
      (vlax-get (vlax-get-property _worksheet_obj_ 'Range Rangecell_name_) "value2")
    )
    (defun TA:Excel_put_data_Rangecell (_worksheet_obj_ Rangecell_name_ Rangecell_value_)
      ;Note By Code_Developer
      ;pripicle of code for get data from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_name_  = "Rangecell name in Excel App"
        ;Rangecell_value_ = "Rangecell Value in Excel App"
      ;
      ;Example 
        ;(vlax-put (vlax-get-property _worksheet_obj_ 'Range "AA1") 'Value "XXX") ;put_value_from_range_cell
      ;
      (vlax-put (vlax-get-property _worksheet_obj_ 'Range Rangecell_name_ ) 'Value Rangecell_value_)
    )
    (defun TA:Excel_get_data_R1C1 (_worksheet_obj_  Rangecell_row_ Rangecell_column_)
      ;Note By Code_Developer
      ;pripicle of code for get data from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
        ;Rangecell_value_ = "get Rangecell Value in Excel App"
      ;
      ;Example 
        ; (vlax-get (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item 1 27)) 'Value) ;get_value_from_range_cell
      ;
      (if 
        (and 
          (= (wcmatch (vlax-get (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_)) 'NumberFormat ) "*d-mm-yy*") T)
        )
        (progn
          (vlax-get (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_)) 'text)
        )
        (vlax-get (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_)) 'Value) ;get_value_from_range_cell
      )
      
    )
    (defun TA:Excel_input_data_R1C1 (_worksheet_obj_ Rangecell_row_ Rangecell_column_ Rangecell_value_ )
      ;Note By Code_Developer
      ;pripicle of code for get data from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
        ;Rangecell_value_ = "put Rangecell Value in Excel App"
        ;
      ;
      ;Example 
        ; (vlax-put (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item 1 27)) 'Value "TESTTESTTESTTEST") ;put_value_from_range_cell
        ;(vlax-dump-object (vlax-get _worksheet_obj_ 'Cells))
        ;(vlax-put-property (vlax-get _worksheet_obj_ 'Cells) 'rowheight 22)
      ;
      (vlax-put (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_)) 'Value Rangecell_value_) ;p
    )
    (defun TA:Excel_get_font-size_R1C1 (_worksheet_obj_ Rangecell_row_ Rangecell_column_)
      ;Note By Code_Developer
      ;pripicle of code for get font-size from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
      ;
      ;example_for_testing_
        ; (setq Rangecell_row_ 1)
        ; (setq Rangecell_column_ 1)
      ;
      ;main_idea
        (vlax-get
          (vlax-get 
            (vlax-variant-value 
              (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
            )
            'font
          )
          'size
        )
      ;
    ) 
    (defun TA:Excel_put_font-size_R1C1 (_worksheet_obj_ Rangecell_row_ Rangecell_column_ font-size_value)
      ;Note By Code_Developer
      ;pripicle of code for put font-size from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
        ;font-size_value = integer for incase or decase size 
      ;
      ;example_for_testing_
        ; (setq Rangecell_row_ 1)
        ; (setq Rangecell_column_ 1)
        ; (vlax-dump-object (vlax-get (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ ) ) 'font ))
      ;
      ;main_idea
        (vlax-put
          (vlax-get 
            (vlax-variant-value 
              (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
            )
            'font
          )
          'size
          font-size_value
        )
      ;
    ) 
    (defun TA:Excel_get_font-VerticalAlignment_R1C1 (_worksheet_obj_ Rangecell_row_ Rangecell_column_)
      ;Note By Code_Developer
      ;pripicle of code for get font-size from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
      ;
      ;example_for_testing_
        ; (setq Rangecell_row_ 1)
        ; (setq Rangecell_column_ 1)
      ;
      ;main_idea
        (cond
          (;Top Align
            (= 
              (vlax-get 
                (vlax-variant-value 
                  (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
                )
                'VerticalAlignment
              )
              -4160
            )
            (progn
              (setq VerticalAlignment "Top Align")
            )
          )
          (;MIddle Align
            (= 
              (vlax-get 
                (vlax-variant-value 
                  (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
                )
                'VerticalAlignment
              )
              -4108
            )
            (progn
              (setq VerticalAlignment "Middle Align")
            )
          )
          (;Bottom Align
            (= 
              (vlax-get 
                (vlax-variant-value 
                  (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
                )
                'VerticalAlignment
              )
              -4107
            )
            (progn
              (setq VerticalAlignment "Bottom Align")
            )
          )
        )
      ;
    )
    (defun TA:Excel_put_font-VerticalAlignment_R1C1 (_worksheet_obj_ Rangecell_row_ Rangecell_column_ Alignment_value_)
      ;Note By Code_Developer
      ;pripicle of code for get font-size from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
      ;
      ;example_for_testing_
        ; (setq Rangecell_row_ 1)
        ; (setq Rangecell_column_ 1)
        ; (setq Alignment_value_ "top")
      ;
      ;main_idea
        (if
          (or
            (= (strcase Alignment_value_) "TOP")
            (= (strcase Alignment_value_) "CENTER")
            (= (strcase Alignment_value_) "BOTTOM")
          )
          (progn
            (cond
              (;Top Align
                (and 
                  (= (type  Alignment_value_) 'str)
                  (= (strcase Alignment_value_) "TOP")
                )
                (progn
                  (vlax-put 
                    (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ ) )
                    'VerticalAlignment
                    -4160
                  )
                )
              )
              (;Middle Align
                (and 
                  (= (type  Alignment_value_) 'str)
                  (= (strcase Alignment_value_) "CENTER")
                )
                (progn
                  (vlax-put 
                    (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ ) )
                    'VerticalAlignment
                    -4108
                  )
                )
              )
              (;Bottom Align
                (and 
                  (= (type  Alignment_value_) 'str)
                  (= (strcase Alignment_value_) "BOTTOM")
                )
                (progn
                  (vlax-put 
                    (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ ) )
                    'VerticalAlignment
                    -4107
                  )
                )
              )
            )
          )
          (princ "object value invalid")
        )
      ;
    )
    (defun TA:Excel_get_font-HonlizontalAlignment_R1C1 (_worksheet_obj_ Rangecell_row_ Rangecell_column_ )
      ;Note By Code_Developer
      ;pripicle of code for get font-size from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
      ;
      ;example_for_testing_
        ; (setq Rangecell_row_ 1)
        ; (setq Rangecell_column_ 1)
        ; (setq Alignment_value_ "top")
      ;
      ;main_idea
        (cond
          (;Left Align
            (and 
              (=
                (vlax-get 
                  (vlax-variant-value 
                    (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
                  )
                  'HorizontalAlignment               
                )
                -4131
              )
            )
            (progn
              (setq Alignment_value_ "Align Left")
            )
          )
          (;Middle Align
            (and 
              (=
                (vlax-get 
                  (vlax-variant-value 
                    (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
                  )
                  'HorizontalAlignment               
                )
                -4108
              )
            )
            (progn
              (setq Alignment_value_ "Align Center")
            )
          )
          (;Bottom Align
            (and 
              (=
                (vlax-get 
                  (vlax-variant-value 
                    (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ )
                  )
                  'HorizontalAlignment               
                )
                -4152
              )
            )
            (progn
              (setq Alignment_value_ "Align Right")
            )
          )
        )
      ;
    )
    (defun TA:Excel_put_font-HonlizontalAlignment_R1C1 (_worksheet_obj_ Rangecell_row_ Rangecell_column_ Alignment_value_)
      ;Note By Code_Developer
      ;pripicle of code for get font-size from rangecell in Excel App by specify <VLA-OBJECT _Worksheet
      ;argument
        ;_worksheet_obj_  = <VLA-OBJECT _Worksheet >
        ;Rangecell_row_  = "Row cell in Excel App"
        ;Rangecell_column_  = "Column cell in Excel App"
      ;
      ;example_for_testing_
        ; (setq Rangecell_row_ 1)
        ; (setq Rangecell_column_ 1)
        ; (setq Alignment_value_ "top")
      ;
      ;main_idea
        (if
          (or
            (= (strcase Alignment_value_) "LEFT")
            (= (strcase Alignment_value_) "CENTER")
            (= (strcase Alignment_value_) "RIGHT")
          )
          (progn
            (cond
              (;Left Align
                (and 
                  (= (type  Alignment_value_) 'str)
                  (= (strcase Alignment_value_) "LEFT")
                )
                (progn
                  (vlax-put
                    (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ ) )
                    'HorizontalAlignment 
                    -4131
                  )
                )
              )
              (;Middle Align
                (and 
                  (= (type  Alignment_value_) 'str)
                  (= (strcase Alignment_value_) "CENTER")
                )
                (progn
                  (vlax-put 
                    (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ ) )
                    'HorizontalAlignment
                    -4108
                  )
                )
              )
              (;Bottom Align
                (and 
                  (= (type  Alignment_value_) 'str)
                  (= (strcase Alignment_value_) "RIGHT")
                )
                (progn
                  (vlax-put 
                    (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item Rangecell_row_ Rangecell_column_ ) )
                    'HorizontalAlignment
                    -4152
                  )
                )
              )
            )
          )
          (princ "object value invalid")
        )
      ;
    )    
    (defun TA_EXCEL_RangecellName_to_R1C1 (RangeCellName_list_)
      ;preloop_and_while
        (setq RangeCellName_list_i 0)
        (setq r1c1_list_ ())
        (while (< RangeCellName_list_i (length RangeCellName_list_))
          (setq RangeCellName_list_col_ (TA:remove-numbers (nth  RangeCellName_list_i RangeCellName_list_)))
          (setq RangeCellName_list_row_ (TA:remove-alphabet (nth  RangeCellName_list_i RangeCellName_list_)))
          
          
          (setq R1C1_data_ 
                  (list 
                    (setq RangeCellName_list_col_ (TA_EXCEL_RangeCOL_to_C1 RangeCellName_list_col_ ) )
                    (atoi RangeCellName_list_row_)
                  )
          )
          (setq r1c1_list_ (cons R1C1_data_ r1c1_list_ ))

        
          
          (setq RangeCellName_list_i (+ RangeCellName_list_i 1))
        )
        (setq r1c1_list_ (reverse r1c1_list_ ))
      ;
    )
    (defun TA_EXCEL_RangeCOL_to_C1 (col)
      (setq len (strlen col)) ; หาความยาวของตัวอักษร
      (setq result 0)
      (setq i 0)
      
      ;; loop ผ่านตัวอักษรแต่ละตัวในคอลัมน์
      (repeat len
        (setq char (strcase (substr col (1+ i) 1))) ; เอาตัวอักษรทีละตัว
        (setq result (+ result (* (- (ascii char) 64) (expt 26 (- len (1+ i)))))) ; คำนวณตามฐาน 26
        (setq i (1+ i)) ; เพิ่มตัวนับ
      )
      result
    )
    (defun TA_EXCEL_method_password ()
      (setq _Workbook_obj_ (vlax-invoke-method 
                              (vlax-get-property vla-obj_app 'WorkBooks)
                              'Open
                              filePath ; 1. Filename
                              0 ; 2. UpdateLinks
                              :vlax-false ; 3. ReadOnly
                              nil ; 4. Format
                              "bb" ; 5. for input Password 
                            )
      )
    )
    (defun TA_EXCEL_Merge_cell (_worksheet_obj_ lst_cell_1 lst_cell_2 )
      ;Note By Code_Developer
      ;The principle of codework is desgined for merge cell object in Excel APP
      ;
      ;Example Argument
        ; (setq lst_cell_1 (list 1 5))
        ; (setq lst_cell_2 (list 1 8))
      ;
        (setq cell_1 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_1) (cadr lst_cell_1))))
        (setq cell_2 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_2) (cadr lst_cell_2))))
        (setq cell_range_obj_ (vlax-get-property _worksheet_obj_ 'Range cell_1 cell_2))
        (vlax-put-property cell_range_obj_ 'MergeCells  :vlax-true)
      ;

    )
    (defun TA_EXCEL_UnMerge_cell (_worksheet_obj_ lst_cell_1 lst_cell_2 )
      ;Note By Code_Developer
      ;The principle of codework is desgined for merge cell object in Excel APP
      ;
      ;Example Argument
        ; (setq lst_cell_1 (list 1 5))
        ; (setq lst_cell_2 (list 1 8))
      ;
        (setq cell_1 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_1) (cadr lst_cell_1))))
        (setq cell_2 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_2) (cadr lst_cell_2))))
        (setq cell_range_obj_ (vlax-get-property _worksheet_obj_ 'Range cell_1 cell_2))
        (vlax-put-property cell_range_obj_ 'MergeCells  :vlax-false)
      ;

    )
    (defun TA_EXCEL_get_rangeccell_color (_worksheet_obj_ lst_cell_1 lst_cell_2  )
      ;Note By Code_Developer
      ;The principle of codework is desgined for merge cell object in Excel APP
      ;
      ;Example Argument
        (setq lst_cell_1 (list 1 1))
        (setq lst_cell_2 (list 1 1))
        ; (setq color_rgb_list (list 50 50 50))
      ;
    
        (setq cell_1 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_1) (cadr lst_cell_1))))
        (setq cell_2 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_2) (cadr lst_cell_2))))
        (setq cell_range_obj_ (vlax-get-property _worksheet_obj_ 'Range cell_1 cell_2))
        (vlax-get-property
          (vlax-get-property cell_range_obj_ 'Interior  )
          'color
          
          
        )
        (vlax-dump-object (vlax-get-property cell_range_obj_ 'Interior  ))

      ;

    )
    (defun TA_EXCEL_input_rangeccell_color (_worksheet_obj_ lst_cell_1 lst_cell_2 color_rgb_list )
      ;Note By Code_Developer
      ;The principle of codework is desgined for merge cell object in Excel APP
      ;
      ;Example Argument
        ; (setq lst_cell_1 (list 1 5))
        ; (setq lst_cell_2 (list 1 8))
        ; (setq color_rgb_list (list 50 50 50))
      ;
    
        (setq cell_1 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_1) (cadr lst_cell_1))))
        (setq cell_2 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_2) (cadr lst_cell_2))))
        (setq cell_range_obj_ (vlax-get-property _worksheet_obj_ 'Range cell_1 cell_2))
        (vlax-put-property
          (vlax-get-property cell_range_obj_ 'Interior  )
          'color
          
          (car 
            (list 
              (+ (car color_rgb_list) 
                (* 256 (cadr color_rgb_list))
                (* 256 (* 256 (caddr color_rgb_list)))
              )
            )
          )
        )

      ;

    )
    (defun TA_EXCEL_input_rangeccell_colorindex (_worksheet_obj_ lst_cell_1 lst_cell_2 colorindex_code )
      ;Note By Code_Developer
      ;The principle of codework is desgined for merge cell object in Excel APP
      ;
      ;Example Argument
        ; (setq lst_cell_1 (list 1 5))
        ; (setq lst_cell_2 (list 1 8))
        ; (setq color_rgb_list (list 50 50 50))
      ;
    
        (setq cell_1 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_1) (cadr lst_cell_1))))
        (setq cell_2 (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car lst_cell_2) (cadr lst_cell_2))))
        (setq cell_range_obj_ (vlax-get-property _worksheet_obj_ 'Range cell_1 cell_2))
        (vlax-put-property
          (vlax-get-property cell_range_obj_ 'Interior  )
          'color
          
          colorindex_code
        )

      ;

    )
    (defun TA:Excel_Open-Excel_ (Using_file_mode_ clear_file_mode )
      ;Excel_file_process_ 
        ;Note By Code_Developer
          ;Principle of codework is designed for open Excel file or lasted current excel window 
          ;and keep vla-object workbook in varibale
          ;in normally this sub funcntion was developed from commmand sub code
          ;
        ;
        ;Example incase userinput via command while code running
          ; (setq Using_file_mode_ (cond ( (getint (strcat "\nOpen new Excel File = 1\nUse Exiting Excel file = 2\n<" (rtos (setq Using_file_mode_ (cond (Using_file_mode_) (1.0) ) ) ) "> : " ) ) ) (Using_file_mode_) ) )
        ;
        ;Example Argument
        ;   (setq Using_file_mode_ 1) ;integer number for indicate condition  ;open new Excel fiel
        ;   (setq Using_file_mode_ 2) ;integer number for indicate condition  ;Use curent Excel file 
        ;   (setq clear_file_mode 1) ;integer number for indicate condition   ;clear content incase currnet Excel file 
        ; ;
        ;Subfunction 
          ; (TA:Excel_Clearcontents Excel_lasted_worksheet_obj_)
        ;
        (cond
          (;Open new Excel File
            (and
              (= Using_file_mode_ 1)
            )
            (progn 
              (setq get_ExcelApp_object_ (vlax-get-or-create-object "Excel.Application"))
              (setq Workbooks_obj_ (vlax-get-property get_ExcelApp_object_ 'workbooks) )
              (setq Workbooks_obj_ (TA:New_Excel_File_NEX_ get_ExcelApp_object_))
              (setq Excel_File+sheet_data_list_ (TA:Excel_Assembly_ALL-obj_list_ Workbooks_obj_))
              (format-all-workbook-list Excel_File+sheet_data_list_)
              (setq Excel_lasted_file_ (nth (- (length Excel_File+sheet_data_list_) 1) Excel_File+sheet_data_list_))
              (format-all-worksheet-list Excel_lasted_file_)
              (setq Excel_lasted_sheet_obj_ (vlax-get-property (nth 2 Excel_lasted_file_ ) 'sheets))
              (setq Excel_lasted_worksheet_obj_ (vlax-get-property Excel_lasted_sheet_obj_ 'item 1))
              (vlax-put-property Excel_lasted_worksheet_obj_ 'name  "Summary block object")
            )
          )
          (;Exiting Excel file
            (and
              (= Using_file_mode_ 2)
              (/= (setq get_ExcelApp_object_ (vlax-get-object "Excel.Application")) nil)
              (/= (setq Workbooks_obj_ (vlax-get-property get_ExcelApp_object_ 'workbooks) ) nil)
              (/= (setq workbook_obj_ (vlax-get-property get_ExcelApp_object_ 'ActiveWorkbook)) nil)
            )
            (progn
              (setq Workbooks_obj_ (vlax-get-property get_ExcelApp_object_ 'workbooks) )
              (setq workbook_obj_ (vlax-get-property get_ExcelApp_object_ 'ActiveWorkbook))
              (setq Excel_lasted_sheet_obj_ (vlax-get-property workbook_obj_ 'sheets))
              (setq Excel_lasted_worksheet_obj_ (vlax-get-property Excel_lasted_sheet_obj_ 'item 1))
              (vlax-put-property Excel_lasted_worksheet_obj_ 'name  "Summary block object")
              ;incase userpinput
                ; (if ( = (setq clear_file_mode (cond ( (getint (strcat "\nClear Contents Excel File = 1\nKeep Existing Contents Excel file = 2\n<" (rtos (setq clear_file_mode (cond (clear_file_mode) (1.0) ) ) ) "> : " ) ) ) (clear_file_mode) ) ) 1)
                ;   (progn
                ;     (TA:Excel_Clearcontents Excel_lasted_worksheet_obj_ )
                ;   )
                ; )
              ;
              (if ( = clear_file_mode 1)
                (progn
                  (TA:Excel_Clearcontents Excel_lasted_worksheet_obj_ )
                )
              )                
            )    
          )
        )
        ; (vlax-dump-object get_ExcelApp_object_ )
        ; (vlax-dump-object (vlax-get (vlax-get get_ExcelApp_object_ 'selection  ) 'address ) )
        ; (vlax-dump-object (vlax-get get_ExcelApp_object_ 'ActiveCell  ) )
        ; (vlax-dump-object get_ExcelApp_object_ )
        ; (vlax-get get_ExcelApp_object_ 'selection  )
        (setq Excel_lasted_worksheet_obj_ Excel_lasted_worksheet_obj_)
      ;
    )
    (defun TA:EXCEL_autofit_column_ (_worksheet_obj_ coloumn_cell)
      (vlax-invoke-method
        (vlax-variant-value 
          (vlax-get-property 
            (vlax-get-property 
              _worksheet_obj_ 
              "columns"
            )
            "item"
            coloumn_cell
          )
        )
        'autofit
      )
    )
    (defun TA:EXCEL_autofit_rangecell_ (_worksheet_obj_ range_cell_1_obj_ range_cell_2_obj_ )
      ;Note By Code_Developer
      ;principle of codework is baseon VBA language 
        ;Worksheets("Sheet1").Range("A1:E1").Columns.AutoFit
      ;
      (setq range_cell_1_obj_ (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car range_cell_1) (cadr range_cell_1))))
      (setq range_cell_2_obj_ (vlax-variant-value (vlax-get-property (vlax-get _worksheet_obj_ 'Cells) 'Item (car range_cell_2) (cadr range_cell_2))))
      (vlax-invoke-method 
        (vlax-get-property 
          (setq vla-range_obj_ 
            (vlax-get-property 
              _worksheet_obj_
              'Range
              range_cell_1_obj_
              range_cell_2_obj_
            )
          )
          'columns
        )
        'autofit
      )
    )
    (defun TA:Excel_foreach_input_list_dataset_R1C1 (_worksheet_obj_ row_start_ col_start_ main_list_  )
      ;Note By Code_Developer
        ;principle of coodework is designed for input data list to Excel appication via list/gruop data,
        ;Can specify R1C1 via argument (row_start_ col_start_)

        ;Precautions when using this program 
          ;The argument main_list_ must contain data in the form of a main list that groups multiple sublists.
          ;Each sublist holds detailed data intended for display purposes.
          ;Example
            ; (setq mainlist ;main list_
            ;                (list 
            ;                  (list 54 68 6 6 32 68 3 65 6 35 65 3 35 61 64 95 3) ;sub list_
            ;                  (list 54 68 6 6 32 68 3 65 6 35 65 3 35 61 64 95 3) ;sub list_
            ;                  (list 54 68 6 6 32 68 3 65 6 35 65 3 35 61 64 95 3) ;sub list_
            ;                  (list 54 68 6 6 32 68 3 65 6 35 65 3 35 61 64 95 3) ;sub list_
            ;                )
            ; )
            ;Precautions when using this program 
              ;The argument main_list_ must contain data in the form of a main list that groups multiple sublists.
              ;Each sublist holds detailed data intended for display purposes.
              ;Example 1
                ; mainlist_
                ; └─ sublist
                ;    └─ sublist of sublist (maximun Below lv.3 )
                ; └─ sublist
                ;    └─ sublist of sublist (maximun Below lv.3 )

                ; (setq mainlist ;main list_
                ;                (list 
                ;                  (list 54 68 6 6 32 68 3 65 6 35 65 3 35 61 64 95 3) ;sub list_
                ;                  (list 54 68 6 6 32 68 3 65 6 35 65 (list "A" "B" "C" "D") 3 35 61 64 95 3) ;sub list_
                ;                  (list 54 68 6 6 32 68 3 65 6 35 65 3 35 61 64 95 3) ;sub list_
                ;                  (list 54 68 6 6 (list "A" "B" "C" "D") 32 68 3 65 6 35 65 3 35 61 64 95 3) ;sub list_
                ;                )
                ; )
              ;
            ;
          ;
        ;
      ;
      ;
      ; ;Example_argument_
      ;   (setq row_start_ 1)
      ;   (setq col_start_ 1)
      ; ;
        (foreach sub_group_ main_list_
          (setq col_ col_start_)
          (if 
            (= (listp sub_group_) T)
            (progn
              (foreach sub_list_ sub_group_  ; ← ลูปชั้นที่ 2
                (if (listp sub_list_)
                  (foreach sub_value_ sub_list_  ; ← ลูปชั้นที่ 3
                    (progn
                      (vlax-put
                        (vlax-variant-value
                          (vlax-get-property
                            (vlax-get _worksheet_obj_ 'Cells)
                            'Item
                            row_start_
                            col_
                          )
                        )
                        'Value
                        sub_value_
                      )
                      (setq col_ (+ col_ 1))
                    )
                  )
                  ;; ถ้า sub_list_ ไม่ใช่ list → แปลว่าเป็นค่าธรรมดา (อาจอยู่แค่ 2 ชั้น)
                  (progn
                    (vlax-put
                      (vlax-variant-value
                        (vlax-get-property
                          (vlax-get _worksheet_obj_ 'Cells)
                          'Item
                          row_start_
                          col_
                        )
                      )
                      'Value
                      sub_list_
                    )
                    (setq col_ (+ col_ 1))
                  )
                )
              )
            )
          )

          (setq row_start_ (+ row_start_ 1))
        )
    )
    (defun TA:EXCEL_all-cut-copy_row_ (_worksheet_obj_ row_cell method-argument-type)
      ;Note By Code_Developer
        ;input argument-type = 'copy
        ;input argument-type = 'cut
      ;
      (vlax-invoke-method
        (vlax-variant-value 
          (vlax-get-property 
            (vlax-get-property 
              _worksheet_obj_ 
              "rows"
            )
            "item"
             row_cell
          )
        )
        method-argument-type
      )
    )
    



    (defun c:Open_Excel_File_OPEX_ ()
      (if (= vla-obj_app nil)
        (progn
          (setq vla-obj_app (vlax-get-or-create-object "Excel.Application"))
          
        )
      )
      (setq filePath (getfiled "Select an Excel file"  "C:/TA/TEMP EST FILES/" "" 8)) ;open Ex-file
      (if 
        (and
          (if
            (/= filePath nil)
            (progn
              (or 
                (wcmatch (strcase filePath) "*XLSX")
                (wcmatch (strcase filePath) "*XLSM")
              )
            )
            nil          
          )
        )
        (progn
              ; (setq vla-obj_app (vlax-get-or-create-object "Excel.Application"))
                (setq _Workbook_obj_ (vlax-invoke-method (vlax-get-property vla-obj_app 'WorkBooks) 'Open filePath)) ;VLA-OBJECT _Workbook
                  (setq sheets_obj_ (vlax-get-property _Workbook_obj_ 'Sheets)) ;VLA-OBJECT Sheets
                    (setq sheets_obj_length (vlax-get-property sheets_obj_ 'count )) ;total_worksheet_in_file_
                  (setq _worksheet_obj_ (vlax-get-property sheets_obj_ 'item 1)) ;VLA-OBJECT _Worksheet
                  (setq _worksheet_obj_name (vlax-get-property _worksheet_obj_ 'name))
            (vlax-put-property vla-obj_app 'Visible :vlax-true)
        )
        (alert "invalid file please try agaian")
      )
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
  ;FINDER_FUNC_
    (defun TA:blockname_finder_ (ss_pre_filter_set_xx_ finding_mode_value_ text_list_ )
      ;user_input
        (setq finding_screw_mode_                    "1 = *wildcard*") 
        (setq font_search_                           "2 = *Character") 
        (setq back_search_                           "3 = Character*") 
        ; (setq finding_mode_value_ (cond ((getint (strcat finding_screw_mode_ "\n" font_search_ "\n" back_search_ "\n" "<" (rtos (setq finding_mode_value_ (cond (finding_mode_value_) (1.0) ) ) ) "> : " ) ) ) (finding_mode_value_) ) )
      ;
      ;selection_set_for_fillter_blk_name
        ; (if  ;pre_select_ssget_or_post_select_ssget
        ;   (=
        ;     (setq ss_pre_filter_set_xx_ (ssget "x"
        ;                                       (list
        ;                                         (cons 0 "INSERT") ;type of object
        ;                                         ; (cons 8 "*GRID*")   ;kind of layer
        ;                                         ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
        ;                                         ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                       )
        ;                                 )
        ;     )
        ;     nil
        ;   )
        ;   (progn
        ;     (setq ss_pre_filter_set_xx_ (ssget
        ;                                       (list
        ;                                         (cons 0 "INSERT") ;type of object
        ;                                         ; (cons 8 "*GRID*")   ;kind of layer
        ;                                         ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
        ;                                         ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                       )
        ;                                 )
        ;     )
        ;   )
        ;   (sslength ss_pre_filter_set_xx_)
        ; )
      ;
      (if (/= ss_pre_filter_set_xx_ nil)
        (progn
          ;preloop_and_while
            (setq ss_pre_filter_set_xx_i 0)
            (setq selection_target_ (ssadd))
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
                ;preloop_and_while
                  (if (= (vl-princ-to-string (type text_list_)) "LIST")
                      (progn
                          (setq text_list_i 0)
                          (while (< text_list_i (length text_list_))
                            (setq text_list_ename_ (nth  text_list_i text_list_))
                              (cond
                                (;if 
                                  (and
                                    (= finding_mode_value_ 1)
                                    (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcase (strcat "*" text_list_ename_  "*"))) T) ;form_1
                                    ; (= (wcmatch (LM:vl-getattributevalue ss_pre_filter_set_xx_filter_obj_ "NOOO") (strcat "*" "6264" "*") ) T ) ;form_2
                                  )
                                  (progn
                                    (setq selection_target_ (ssadd  ss_pre_filter_set_xx_ename_ selection_target_))
                                  )
                                )
                                (;if 
                                  (and
                                    (= finding_mode_value_ 2)
                                    (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcase (strcat "*" text_list_ename_  ))) T) ;form_1
                                    ; (= (wcmatch (LM:vl-getattributevalue ss_pre_filter_set_xx_filter_obj_ "NOOO") (strcat "*" "6264" "*") ) T ) ;form_2
                                  )
                                  (progn
                                    (setq selection_target_ (ssadd ss_pre_filter_set_xx_ename_ selection_target_))
                                  )
                                )
                                (;if 
                                  (and
                                    (= finding_mode_value_ 3)
                                    (= (wcmatch (strcase (LM:effectivename ss_pre_filter_set_xx_obj_ )) (strcase (strcat  text_list_ename_  "*"))) T) ;form_1
                                    ; (= (wcmatch (LM:vl-getattributevalue ss_pre_filter_set_xx_filter_obj_ "NOOO") (strcat "*" "6264" "*") ) T ) ;form_2
                                  )
                                  (progn
                                    (setq selection_target_ (ssadd  ss_pre_filter_set_xx_ename_ selection_target_))
                                  )
                                )
                              )      
                            (setq text_list_i (+ text_list_i 1))
                          )
                        ;
                      )
                      (princ "argument is not array list")
                  )
                ;      
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;selection_object_process
            ; (length selection_target_)
            ; (command "pselect"  selection_target_ "" )
            (setq selection_target_ selection_target_)
            
          ;
        )
      )
      (setq selection_target_ selection_target_)
    )
    (defun c:find_area_ ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "lwpolyline") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (setq area_i 0)
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_hon_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (setq ss_pre_filter_set_xx_hon_obj_area_ (vla-get-area ss_pre_filter_set_xx_hon_obj_ ))
          (setq area_i (+ area_i ss_pre_filter_set_xx_hon_obj_area_))
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;  
      ;convert sq.mm to sq.m
        (setq ss_pre_filter_set_xx_hon_obj_area_sqm (/ area_i 1000000))
      ;
      (alert (strcat (rtos ss_pre_filter_set_xx_hon_obj_area_sqm 2 2 ) " " "sq.m"))
    )
    (defun c:find_total_length_fiTL ()
 
      ;selection_set_for_fillter_blk_name
        ; (if  ;pre_select_ssget_or_post_select_ssget
        ;   (=
        ;     (setq ss_pre_filter_set_xx_ (ssget "i"
        ;                                       (list
        ;                                         (cons 0 "lwpolyline") ;type of object
        ;                                         ; (cons 8 "*GRID*")   ;kind of layer
        ;                                         ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
        ;                                         ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                       )
        ;                                 )
        ;     )
        ;     nil
        ;   )
        ;   (progn
        ;     (setq ss_pre_filter_set_xx_ (ssget
        ;                                       (list
        ;                                         (cons 0 "lwpolyline") ;type of object
        ;                                         ; (cons 8 "*GRID*")   ;kind of layer
        ;                                         ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
        ;                                         ; (cons 62 1)           ;kind of color call sign with color code index
        ;                                       )
        ;                                 )
        ;     )
        ;   )
        ;   (sslength ss_pre_filter_set_xx_)
        ; )
      ;

      (setq ss_pre_filter_set_xx_ (ssget "c" ss1 ss2(list (cons 0 "lwpolyline"))))
      (setq mainfinder_ename_ (car (entsel "specify Object")))
      (setq mainfinder_obj_ (vlax-ename->vla-object mainfinder_ename_))
      (setq mainfinder_obj_length (vla-get-length mainfinder_obj_))
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (setq sstarget_ (ssadd))
        (setq sstarget_ (ssadd mainfinder_ename_ sstarget_))
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (setq ss_pre_filter_set_xx_obj_TL (vla-get-length ss_pre_filter_set_xx_obj_))
          (if (= ss_pre_filter_set_xx_obj_TL mainfinder_obj_length )
            (progn
              (setq sstarget_ (ssadd ss_pre_filter_set_xx_ename_ sstarget_ ))
              (vla-move ss_pre_filter_set_xx_obj_  (vlax-3d-point ss1) (vlax-3d-point  ss11 (cadr ss1 ) 0) )
            )
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (setq ss11 (+ ss11 10))
      
    )
    (defun c:foo ()
      (setq ss1 (getpoint))
      (setq ss2 (getpoint))
      (setq ss11 (+ (car ss1) 10) )
      (setq ss11 (+ ss11 20) )
    )
    (defun c:fihand ()
      (setq handent_
        (list 
          (list "4EB8F0")
          (list "4EB308")
          (list "4EB31A")
          (list "4EB32C")
          (list "4EB33E")
          (list "4EB350")
          (list "4EB3E0")
          (list "4EB3F2")
          (list "4EB404")
          (list "4EB416")
          (list "4EB428")
          (list "4EB4A6")
          (list "4EB4B8")
          (list "4EB4CA")
          (list "4EB4DC")
          (list "4EB4EE")
          (list "4EB56C")
          (list "4EB57E")
          (list "4EB590")
          (list "4EB5A2")
          (list "4EB5B4")
          (list "4EB632")
          (list "4EB644")
          (list "4EB656")
          (list "4EB668")
          (list "4EB67A")
          (list "4EB8DE")
          (list "4F5ED7")
          (list "4F5EF3")
          (list "4F5EC9" "4EB2F6")
          (list "4EB6E6" "4EB362")
          (list "4EB6F8" "4EB3CE")
          (list "4EB70A" "4EB43A")
          (list "4EB71C" "4EB494")
          (list "4EB72E" "4EB500")
          (list "4EB740" "4EB55A")
          (list "4EB752" "4EB5C6")
          (list "4EB764" "4EB620")
          (list "4EB776" "4EB68C")
          (list "4EB860")
          (list "4EB79A" "4F5F2B")
          (list "4F5EAD" "4EB788" "4EB7AC" "4F5F01")
          (list "4F5F0F" "4F5F1D")
          (list "4F5EE5")
          (list "4EB374")
          (list "4EB386")
          (list "4EB398")
          (list "4EB44C")
          (list "4EB45E")
          (list "4EB470")
          (list "4EB512")
          (list "4EB524")
          (list "4EB536")
          (list "4EB5D8")
          (list "4EB5EA")
          (list "4EB5FC")
          (list "4EB69E")
          (list "4EB6B0")
          (list "4EB6C2")
          (list "4EB872")
          (list "4EB3AA")
          (list "4EB482")
          (list "4EB548")
          (list "4EB60E")
          (list "4EB6D4")
          (list "4F5EBB")
          (list "4F5E9F")
        )
      )

      ;preloop_and_while
        (setq handent_i 0)
        (setq handent_selection_ (ssadd))
        (while (< handent_i (length handent_))
          (setq GTP (getpoint "SSSSSSSSSSS"))
          (setq handent_list_ (nth  handent_i handent_))
          (if (= (listp handent_list_) T )
            (progn
              ;preloop_and_while
                (setq handent_list_i 0)
                (while (< handent_list_i (length handent_list_))
                  (setq handent_list_ename_ (nth  handent_list_i handent_list_))
                  (setq handent_list_obj_ (vlax-ename->vla-object (handent handent_list_ename_)))
                  (vla-move handent_list_obj_ (vlax-3d-point (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint handent_list_obj_)))) (vlax-3d-point GTP))
                  ; (setq handent_selection_ (ssadd (handent handent_list_ename_ ) handent_selection_  ))
                  (setq handent_list_i (+ handent_list_i 1))
                )
              ;
            )
            ; (setq handent_selection_ (ssadd (handent handent_list_ ) handent_selection_  ))
          )
          (setq handent_i (+ handent_i 1))
        )
      ;
      
      
    )
    (defun c:find_distance_y_fidy ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (setq ss_pre_filter_set_xx_dist ())
        (while (< ss_pre_filter_set_xx_i 2)
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
          (setq ss_pre_filter_set_xx_dist (cons (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))) ss_pre_filter_set_xx_dist ))
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;

      (alert (strcat "distance " (rtos (distance (nth 0 ss_pre_filter_set_xx_dist) (nth 1 ss_pre_filter_set_xx_dist)) 2 2) "mm."))
    )


  ;
  ;TITLE DRAWING FUNC
    (defun c:sort_heading_number_sorH ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      (setq sorted_list_ercheck_ nil)
      (if (= (vl-prin1-to-string (TA:corrd_sorting_group (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - HEADING NAME REV02-2" )) 1 )) "(nil)")
        (progn
          (setq sorted_list_ (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - HEADING NAME REV02-2" )))
          (setq sorted_list_ercheck_ T)
        )
        (setq sorted_list_ (TA:corrd_sorting_group (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - HEADING NAME REV02-2" )) 1 ))
      )
      
      ;ErrorDetect_
        (if ;Detect the variable's result in case of a function error
          (= 
            (wcmatch
              (vl-princ-to-string
                (setq variable_error_checking
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (setq sorted_list_num_ (cond ( (getint (strcat "\nspecify get heading_number \n<" (rtos (setq sorted_list_num (cond (sorted_list_num) (1.0) ) ) ) "> : " ) ) ) (sorted_list_num) ) )
                      )
                    )
                  )
                )
              )
              "*nil*,*error*"
            )
            nil
          )
          (progn
            (setq sorted_list_num sorted_list_num_)
          )
        )
      ;
      ;preloop_and_while sorting overall heaing title
        (setq sorted_list_i 0)
        (while (< sorted_list_i (length sorted_list_))
          (setq sorted_list_main_ (nth  sorted_list_i sorted_list_))
          ;preloop_and_while sub heading in sorting list 
            (setq sorted_list_main_i 0)
            (while (< sorted_list_main_i (length sorted_list_main_))
              (if (= sorted_list_ercheck_ T)
                (progn
                  (setq sorted_list_main_ename_ (nth  sorted_list_main_i (cdr sorted_list_main_)))
                  (setq sorted_list_main_i (+ (length sorted_list_main_)  1))
                )
                (setq sorted_list_main_ename_ (cadr (nth  sorted_list_main_i sorted_list_main_)))
              )
              
              (setq sorted_list_main_ename_obj_ (vlax-ename->vla-object sorted_list_main_ename_))
              (LM:vl-setattributevalue sorted_list_main_ename_obj_ "LO" sorted_list_num)
              (LM:vl-setattributevalue sorted_list_main_ename_obj_ "DETAIL_NO." sorted_list_num)
              
              (setq sorted_list_num (+ sorted_list_num 1))
              (setq sorted_list_main_i (+ sorted_list_main_i 1))
            )
          ;
          (setq sorted_list_i (+ sorted_list_i 1))
        )
      ;
    )
    (defun c:sort_box_number_sorB ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      (setq sorted_list_ercheck_ nil)
      (if (= (vl-prin1-to-string (TA:corrd_sorting_group (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "PANEL_SET.NO." )) 250 )) "(nil)")
        (progn
          (setq sorted_list_ (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "PANEL_SET.NO." )))
          (setq sorted_list_ercheck_ T)
        )
        (setq sorted_list_ (TA:corrd_sorting_group (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "PANEL_SET.NO." )) 1 ))
      )


      ;ErrorDetect_
        (if ;Detect the variable's result in case of a function error
          (= 
            (wcmatch
              (vl-princ-to-string
                (setq variable_error_checking
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (setq sorted_list_num_ (cond ( (getint (strcat "\nspecify get heading_number \n<" (rtos (setq sorted_list_num (cond (sorted_list_num) (1.0) ) ) ) "> : " ) ) ) (sorted_list_num) ) )
                      )
                    )
                  )
                )
              )
              "*nil*,*error*"
            )
            nil
          )
          (progn
            (setq sorted_list_num sorted_list_num_)
          )
        )
      ;
      ;preloop_and_while sorting overall heaing title
        (setq sorted_list_i 0)
        (while (< sorted_list_i (length sorted_list_))
          (setq sorted_list_main_ (nth  sorted_list_i sorted_list_))
          ;preloop_and_while sub heading in sorting list 
            (setq sorted_list_main_i 0)
            (while (< sorted_list_main_i (length sorted_list_main_))
              (if (= sorted_list_ercheck_ T)
                (progn
                  (setq sorted_list_main_ename_ (nth  sorted_list_main_i (cdr sorted_list_main_)))
                  (setq sorted_list_main_i (+ (length sorted_list_main_)  1))
                )
                (setq sorted_list_main_ename_ (cadr (nth  sorted_list_main_i sorted_list_main_)))
              )
              
              (setq sorted_list_main_ename_obj_ (vlax-ename->vla-object sorted_list_main_ename_))
              (LM:vl-setattributevalue sorted_list_main_ename_obj_ "PANEL_SET.NO." sorted_list_num)
              (LM:vl-setattributevalue sorted_list_main_ename_obj_ "PANEL_SET.NO." sorted_list_num)
              
              (setq sorted_list_num (+ sorted_list_num 1))
              (setq sorted_list_main_i (+ sorted_list_main_i 1))
            )
          ;
          (setq sorted_list_i (+ sorted_list_i 1))
        )
      ;
    )
    (defun c:sort_box_number_sorFu ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "001 - DYNAMIC REC&SSQ SHAPE SOLID_startpoint"))
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (setq sorted_list_ ())
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (setq sorted_list_ (cons (list ss_pre_filter_set_xx_ename_ (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))) sorted_list_))
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      ;TA:stanndard_lambda_sorting
        (setq sorted_list_sorted_ (vl-sort sorted_list_  ;bigest open indent list
                                                  (function 
                                                    (lambda (a b) 
                                                      (< (car (nth 1 a)) (car (nth 1 b)))
                                                    )
                                                  )
                              ) ;bigest close indent list
        )
      ;
      (setq sorted_list_num_ (cond ( (getint (strcat "\nspecify get heading_number \n<" (rtos (setq sorted_list_num (cond (sorted_list_num) (1.0) ) ) ) "> : " ) ) ) (sorted_list_num) ) )
      ;preloop_and_while sorting overall heaing title
        (setq sorted_list_i 0)
        (while (< sorted_list_i (length sorted_list_))
          (setq sorted_list_main_ (car (nth  sorted_list_i sorted_list_)))
          ;preloop_and_while sub heading in sorting list 
            (setq sorted_list_main_obj_ (vlax-ename->vla-object sorted_list_main_ename_))
              
              
              (LM:vl-setattributevalue sorted_list_main_obj_ "FULL_SIZE_NO." sorted_list_num)
              
              
              
              (setq sorted_list_num_ (+ sorted_list_num_ 1))
              (setq sorted_list_i (+ sorted_list_i 1))
            )
          ;

        
      ;
    )
    (defun c:sort_heading_number_sorH ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      (setq sorted_list_ercheck_ nil)
      (if (= (vl-prin1-to-string (TA:corrd_sorting_group (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "PANEL_SET.NO." )) 1 )) "(nil)")
        (progn
          (setq sorted_list_ (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "PANEL_SET.NO." )))
          (setq sorted_list_ercheck_ T)
        )
        (setq sorted_list_ (TA:corrd_sorting_group (TA:standard_list_croodinate+ename (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - HEADING NAME REV02-2" )) 1 ))
      )
      
      ;ErrorDetect_
        (if ;Detect the variable's result in case of a function error
          (= 
            (wcmatch
              (vl-princ-to-string
                (setq variable_error_checking
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (setq sorted_list_num_ (cond ( (getint (strcat "\nspecify get heading_number \n<" (rtos (setq sorted_list_num (cond (sorted_list_num) (1.0) ) ) ) "> : " ) ) ) (sorted_list_num) ) )
                      )
                    )
                  )
                )
              )
              "*nil*,*error*"
            )
            nil
          )
          (progn
            (setq sorted_list_num sorted_list_num_)
          )
        )
      ;
      ;preloop_and_while sorting overall heaing title
        (setq sorted_list_i 0)
        (while (< sorted_list_i (length sorted_list_))
          (setq sorted_list_main_ (nth  sorted_list_i sorted_list_))
          ;preloop_and_while sub heading in sorting list 
            (setq sorted_list_main_i 0)
            (while (< sorted_list_main_i (length sorted_list_main_))
              (if (= sorted_list_ercheck_ T)
                (progn
                  (setq sorted_list_main_ename_ (nth  sorted_list_main_i (cdr sorted_list_main_)))
                  (setq sorted_list_main_i (+ (length sorted_list_main_)  1))
                )
                (setq sorted_list_main_ename_ (cadr (nth  sorted_list_main_i sorted_list_main_)))
              )
              
              (setq sorted_list_main_ename_obj_ (vlax-ename->vla-object sorted_list_main_ename_))
              (LM:vl-setattributevalue sorted_list_main_ename_obj_ "LO" sorted_list_num)
              (LM:vl-setattributevalue sorted_list_main_ename_obj_ "DETAIL_NO." sorted_list_num)
              
              (setq sorted_list_num (+ sorted_list_num 1))
              (setq sorted_list_main_i (+ sorted_list_main_i 1))
            )
          ;
          (setq sorted_list_i (+ sorted_list_i 1))
        )
      ;
    )
  ;
  ;UNDO FUNC
    (defun _StartUndo ( doc ) (_EndUndo doc)
      (if (= doc nil)
        (progn
          (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
        )
      )
      (vla-StartUndoMark doc)
    )
  
    (defun _EndUndo ( doc )
      (if (= doc nil)
        (progn
          (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
        )
      )
      (if (= 8 (logand 8 (getvar 'UNDOCTL)))
        (vla-EndUndoMark doc)
      )
    )
    
  ;
  ;Common_commmand 
    (defun c:stamp_layer_to_model ()
      ;user_inpput for specify point
        (setq mk_point (getpoint "specify point"))
        (setq mk_point_y_ 0)
        (setq rotation_val (angtof "45" ))
        (setq layers_list_ (acad_strlsort (TA:get_name_layer_in_drawing)))
        (setq layers_list_i 0)
        (while (< layers_list_i (length layers_list_))
          (setq layers_list_name (nth layers_list_i layers_list_))
          
          (setq mk_point_xyz (vlax-3d-point 
                              (list 
                                (setq mk_point_x (car mk_point))
                                (setq mk_point_y (+ (cadr mk_point) mk_point_y_))
                                (setq mk_point_z (caddr mk_point))
                              )
                            )
          )
          
          (create-text-vla mk_point_xyz layers_list_name 5 rotation_val)
          (vla-put-layer (vlax-ename->vla-object (entlast)) layers_list_name  )
          (vla-put-color (vlax-ename->vla-object (entlast)) 256)
          (setq mk_point_y_ (+ mk_point_y_ -20))
          (setq layers_list_i (+ layers_list_i 1))
          
        )

    )
    (defun c:round_up_down_insertion_point_REINS ()
      ;selection_set
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq ss_pre_filter_set_xx (ssget "I" 
                                              (list 
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
            nil
          )
          (progn 
            (setq ss_pre_filter_set_xx (ssget 
                                          (list 
                                            (cons 0 "INSERT") ;type of object
                                            ; (cons 8 "*GRID*")   ;kind of layer
                                            ; (cons 2 "000-GRIDLINE_DYN")       ;kind of nameblock
                                            ; (cons 62 1)           ;kind of color call sign with color code index
                                          )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx)
        )
      ;
      ;get_efname_
        (setq blk_name_ (LM:effectivename (vlax-ename->vla-object (car (entsel)))))
      ;
      ;ssget_filtter
        (setq ss_prop_filter_ (TA:Prop_Filter_ss_set_ ss_pre_filter_set_xx "effectivename" blk_name_))
      ;
      ;preloop_and_while_rework_inspoint
        (setq ss_prop_filter_i 0)
        (while  (< ss_prop_filter_i (sslength ss_prop_filter_))
          (setq ss_prop_filter_ename_ (ssname ss_prop_filter_ ss_prop_filter_i))
          (setq ss_prop_filter_obj_ (vlax-ename->vla-object ss_prop_filter_ename_))
          (setq ss_prop_filter_obj_ins_ (TA:ename+vla-get-insertionpoint ss_prop_filter_obj_))
          
          ;re_location_inspt_
            ;get_data
              (setq new_input_ins_ (list
                                        (setq ss_prop_filter_obj_ins_x (LM:round (car (nth 1 ss_prop_filter_obj_ins_))))
                                        (setq ss_prop_filter_obj_ins_y (LM:round (cadr (nth 1 ss_prop_filter_obj_ins_))))
                                        (setq ss_prop_filter_obj_ins_z (LM:round (caddr (nth 1 ss_prop_filter_obj_ins_))))                             
                                      )
              )
            ;
            (vla-put-insertionpoint ss_prop_filter_obj_ (vlax-3d-point new_input_ins_))
          ;
          (setq ss_prop_filter_i (+ ss_prop_filter_i 1))
        )
      ;
    )
    (defun c:make_boudary_line_MKBOL ()
      ;get_osmode_process
        (setq getold_osmode_ (getvar "osmode"))
        (setq zero_osmode_ (setvar "osmode" 0))
      ;
      ;user_input
        (setq ref_pline_or_block_ (car (entsel "specify PLINE OR BLOCK OBJECT" )))
      ;
      ;MAIN_IDEA_COMMAND_
        (setq lower_upper_inspoint_ (TA:Find_boundary_line_ ref_pline_or_block_))
        (command "rectangle" (car lower_upper_inspoint_) (cadr lower_upper_inspoint_))
      ;  
      ;Change_Color_process
        (setq new_obj_ (vlax-ename->vla-object (entlast)))
        (setq new_obj_input_color_ (vla-put-color new_obj_ 250))
      ;
      ;return_osmode_process_
        (setq return_osmode_ (setvar "osmode" getold_osmode_))
      ;
    )
    (defun c:STAMP_START_POINT_STP_ ()
      
      ;Stamp_ dynamic block "000SYM-START_POINT_" /w RECTANGLE_BLOCK
      (setvar "osmode" 0)
      (setq main_rec_ename_ (car (entsel "specify Object")))
      (setq rec_point_ (TA:find_center main_rec_ename_ ))
      (command "insert" "000SYM-START_POINT_" rec_point_ 0.1 0 )
      (setvar "osmode" 1215)
    )
    (defun c:relocation_rectangle_vertex_REVX ()
        (setq rec_ename_ (car (entsel "specify Object")))
        (setq rec_obj_ (vlax-ename->vla-object rec_ename_))
      
        ; (if (and
        ;       (= (vla-get-objectname rec_obj_) "AcDbPolyline")
        ;     )
        ;   (progn
        ;     (thenexpr)
        ;   )
        ; )
        (setq rec_obj_getboundingbox (vla-getboundingbox rec_obj_ 'min_ 'max_)) 
        (setq rec_min_ (vlax-safearray->list min_)) 
        (setq rec_max_ (vlax-safearray->list max_)) 
        
      (command "rectangle" rec_min_ rec_max_ )
      (vla-delete   rec_obj_ )
      
      
    )
    (defun c:make_thickness_sheet_THS ()
      ;user_input_
        (setq 2dblank_ename_ (car (entsel "specify Object")))
        
        (setq user_input_thickness_ (cond ( (getreal (strcat "\nspecify_height blank size<" (rtos (setq user_input_thickness_ (cond (user_input_thickness_) (1.0) ) ) ) "> : " ) ) ) (user_input_thickness_) ) )
        (setq user_input_offset_ (cond ( (getreal (strcat "\n\n1 = Max 0 = Min [1/0] <" (rtos (setq user_input_offset_ (cond (user_input_offset_) (1.0) ) ) ) "> : " ) ) ) (user_input_offset_) ) )
        (cond
          (;user_input_offset_case_1
            (and
                (= user_input_offset_ 1)
            )
            (progn
              (setq user_input_offset_val "max")
              (princ "user_input_offset_case_1")
            )
          )
          (;user_input_offset_case_2
            (and
                (= user_input_offset_ 0)
            )
            (progn
              (setq user_input_offset_val "min")
              (princ "user_input_offset_case_2")
            )
          )
        )
      ;
      ;new_ssget_process_
        (setq new_ssget_ ())
        (setq new_ssget_ (ssadd))
        (setq new_ssget_ (ssadd  2dblank_ename_ new_ssget_))
        (sslength new_ssget_)
      ;
      ;get_data_
        (setq r2dblank_obj_ (vlax-ename->vla-object 2dblank_ename_))
        (setq 2dblank_objname_  (vla-get-objectname r2dblank_obj_))
      
        (setq vertex_list_  (TA:Get_Pline_vertext_ins_point_ 2dblank_ename_))
        (setq 2dblank_len_val_ (TA:get_vertex_len_ 2dblank_ename_))
      ;
      ;offset_process

        (TA:Offset_Pline_multi_vertex_ 2dblank_ename_ user_input_thickness_ user_input_offset_val)
        (setq new_line_ (entlast))
        (setq new_line_vertex_list_  (TA:Get_Pline_vertext_ins_point_ new_line_))
        (setq new_ssget_ (ssadd  new_line_ new_ssget_))
        (sslength new_ssget_)
      ;
      ;create_start_line_process
        (setq startline_
              (list
                  (nth 0 (cadr vertex_list_ ))
                  (nth 0 (cadr new_line_vertex_list_ ))
              )
        )
        (create-pline startline_ )
        (setq new_line_ (entlast))
        (setq new_ssget_ (ssadd  new_line_ new_ssget_))
        (sslength new_ssget_)
      
        (setq vertex_list_i (- (length (cadr vertex_list_ ) ) 1))
        (setq endline_
              (list
                  (nth vertex_list_i (cadr vertex_list_ ))
                  (nth vertex_list_i (cadr new_line_vertex_list_ ))
              )
        )

        (create-pline endline_ )
        (setq new_line_ (entlast))
        (setq new_ssget_ (ssadd  new_line_ new_ssget_))
        (sslength new_ssget_)
      ;
      ;joint_all_selection_set_process
        (command "pedit"  "m" new_ssget_ "" "j" "" "" )
      ;
    )
    (defun c:rotate_by_2_point_ro2point ()
      
      (setq pt1 (getpoint "specify point 1 "))
      (setq pt2 (getpoint "specify point 2 "))
      (setq blk_ename_ (car (entsel "specify Object")))
      (setq blk_obj_ (vlax-ename->vla-object blk_ename_))
      (if (= (getvar "worlducs") 1)
        (progn
          (setq angles (angle (trans pt1 1 0) (trans pt2 1 0) ) )
        )
        (setq angles (angle pt1 pt2 ) )
      )

      
      (vla-put-rotation blk_obj_ 
                        (angle 
                          (trans pt1 1 0)
                          (trans pt2 1 0)
                        )
      )
    )
    (defun c:copy_layer_text_CPLTEXT_ ()
      (setq layer_ename_ (car (entsel "specify Object")))
      (setq layer_obj_ (vlax-ename->vla-object layer_ename_))
      (TA:copytext->clipboard (vla-get-layer layer_obj_))
    )
    (defun c:Xmove ()
      (if 
        (= 
          (vl-catch-all-error-p 
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (setvar "osmode" 13)
                  (setq PT_ref_ (getpoint "specify reference point"))
                )
              )
            )
          )
          nil
        )
        (progn 
          (setq target_move_ename_ (car (entsel "specify Object")))
          (setq target_move_obj_ (vlax-ename->vla-object target_move_ename_))
          (if (= (getvar "worlducs") 1)
            (progn
              (setq target_move_ref (trans (getpoint "specify target_move_ref point") 1 1))
              (setvar "osmode" 0)
              (vla-move target_move_obj_ (vlax-3d-point (trans target_move_ref 1 0)) (vlax-3d-point (trans (list (car PT_ref_) (cadr target_move_ref) 0 ) 1 0) ) )
            )
          )
          (if (= (getvar "worlducs") 0)
            (progn
              (setq target_move_ref (getpoint "specify target_move_ref point"))
              (setvar "osmode" 0)
              (vla-move target_move_obj_ (vlax-3d-point target_move_ref) (vlax-3d-point (list (car PT_ref_) (cadr target_move_ref) 0 ) ) )
            )
            
          )
          (setvar "osmode" 1215)
          ;add on command 
            (command "line" PT_ref_ (list (car target_move_ref) (cadr PT_ref_) 0 ) "")
            (command "pselect"  (entlast) "" )
            (if (or 
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 0)
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 90)
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 180)
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 270)
                )
              (progn
                (alert "line is straight")
                (vla-delete (vlax-ename->vla-object (entlast)))
              )
            )
          ;
        )
      )
    )
    (defun c:Ymove ()
      (if 
        (= 
          (vl-catch-all-error-p 
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (setvar "osmode" 13)
                  (setq PT_ref_ (getpoint "specify reference point"))
                )
              )
            )
          )
          nil
        )
        (progn 
          (setq target_move_ename_ (car (entsel "specify Object")))
          (setq target_move_obj_ (vlax-ename->vla-object target_move_ename_))
          (if (= (getvar "worlducs") 1)
            (progn
              (setq target_move_ref (trans (getpoint "specify target_move_ref point") 1 1))
              (setvar "osmode" 0)
              (vla-move target_move_obj_ (vlax-3d-point (trans target_move_ref 1 0)) (vlax-3d-point (trans (list (car target_move_ref) (cadr PT_ref_) 0 ) 1 0) ) )
            )
          )
          (if (= (getvar "worlducs") 0)
            (progn
              (setq target_move_ref (getpoint "specify target_move_ref point"))
              (setvar "osmode" 0)
              (vla-move target_move_obj_ (vlax-3d-point target_move_ref) (vlax-3d-point (list (car target_move_ref) (cadr PT_ref_) 0 ) ) )
            )
            
          )
          (setvar "osmode" 1215)
          ;add on command 
            (command "line" PT_ref_ (list (car target_move_ref) (cadr PT_ref_) 0 ) "")
            (command "pselect"  (entlast) "" )
            (if (or 
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 0)
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 90)
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 180)
                  (= (rad-to-deg (vla-get-angle (vlax-ename->vla-object (entlast)))) 270)
                )
              (progn
                (alert "line is straight")
                (vla-delete (vlax-ename->vla-object (entlast)))
              )
            )
          ;
        )
      )
    )
    (defun c:ssXmove ()
      (setq PT_ref_ (getpoint "specify reference point"))
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq target_move_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
            nil
          )
          (progn
            (setq target_move_ (ssget
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength target_move_)
        )
      ;
      ;get_data_process_for_fillter_blk_name
      ;preloop_and_while
        (setq target_move_i 0)
        (while (< target_move_i (sslength target_move_))
          (setq target_move_ename_ (ssname target_move_ target_move_i))
          (setq target_move_obj_ (vlax-ename->vla-object  target_move_ename_))
          (command "pselect"  target_move_ename_ "" )
          (setq target_move_ref (getpoint "specify target_move_ref point"))
          (setvar "osmode" 0)
          (vla-move target_move_obj_ (vlax-3d-point target_move_ref) (vlax-3d-point (list (car PT_ref_) (cadr target_move_ref) 0 ) ) )
          (setvar "osmode" 1215)
          (setq target_move_i (+ target_move_i 1))
        )
      ;
      (command "pselect"  target_move_ "" )
    )
    (defun c:ssYmove ()
      (setq PT_ref_ (getpoint "specify reference point"))
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (= 
            (setq target_move_ (ssget "i" 
                                      (list 
                                        (cons 0 "INSERT") ;type of object
                                        ; (cons 8 "*GRID*")   ;kind of layer
                                        ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                        ; (cons 62 1)           ;kind of color call sign with color code index
                                      )
                               )
            )
            nil
          )
          (progn 
            (setq target_move_ (ssget 
                                 (list 
                                   (cons 0 "INSERT") ;type of object
                                   ; (cons 8 "*GRID*")   ;kind of layer
                                   ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                   ; (cons 62 1)           ;kind of color call sign with color code index
                                 )
                               )
            )
          )
          (sslength target_move_)
        )
      ;
      ;preloop_and_while
        (setq  target_move_i 0)
        (while (<  target_move_i (sslength  target_move_))
          (setq  target_move_ename_ (ssname  target_move_  target_move_i))
          (setq target_move_obj_ (vlax-ename->vla-object target_move_ename_))
          (command "pselect"  target_move_ename_ "" )
          (setq target_move_ref (getpoint "specify target_move_ref point"))
          (setvar "osmode" 0)
          (vla-move target_move_obj_ (vlax-3d-point target_move_ref) (vlax-3d-point (list (car target_move_ref) (cadr PT_ref_) 0 ) ) )
          (setvar "osmode" 1215)
      
          (setq  target_move_i (+  target_move_i 1))
        )
      ;
      (command "pselect"  target_move_ "" )

    )
    (defun c:PPLINE-MAKE_layer_ ()
      ;preloop_and_while
        (setq TA-FL_Layer_ (list "ssddd" "0" "Defpoints" "000 - T E X T" "000 - TITLEBLOCK" 
                              "000 - H A T C H" "000 - L I N E 0.1" "000 - D I M 0.25" 
                              "000 - WIPEOUT" "000 - GRID" "A11_ALU.SOLID SHEET" 
                              "A12_PERFORATED" "A04_TUBE SERIES" "002 - STRUCTURAL STEEL" 
                              "000 - H I D D E N" "000 - D I M" "001 - ASCESSORIES" 
                              "A02_LITEWOOD" "000 - BUBBLE" "000 - SYMBOL CON" "000 - A_XREF" 
                              "000 - GROUND" "000 - L I N E" "000 - TEMP LAYER" "001 - DOOR" 
                              "001 - WINDOWS" "002 - STEEL LRIP" "002 - STEEL TUBE" 
                              "004 - CONCRETE" "004 - DOOR WINDOW" "004 - FLOOR" 
                              "004 - VIVA BOARD" "004 - WALL" "005 - WATER CLOSET EQUIP" 
                              "006 - ROOF" "008 - LIGHTING" "A01_ACP" "A03_SUN LOUVER" 
                              "A05_AHP." "A06_PERFORMANCE LOUVERS" "A07_PRANKCAD" "A08_AEROLITE" 
                              "A09_BIFOLDING" "A10_ENTRANCE MATT" "A13_EXPANDED"
                        )
        )
        (setq ii 0)
        (command "-layer" "filter" "n" "G" "" "0" "PPLINE-FAMELINE" ""  )
        (while (< ii (length TA-FL_Layer_))
          (setq TA-FL_Layer_list_ (nth ii TA-FL_Layer_))
          
          (command "-layer" "filter"  "e" "0" "PPLINE-FAMELINE" "a" TA-FL_Layer_list_ "L" "") 
          
          
          (setq ii (+ ii 1))
        ) 
      ;
      (command "-layer" "filter" "s" "All" "")
    )
  ;
;

;DIM sub-FUNC
  (defun TA:change_dim_side_ (ss_pre_filter_set_xx_obj_ DD)
    (if (= (vla-get-objectname ss_pre_filter_set_xx_obj_) "AcDbRotatedDimension")
      (progn
        ; (vlax-dump-object ss_pre_filter_set_xx_obj_)
        (setq LI_textpos_ (vlax-safearray->list (vlax-variant-value (vlax-get-property  ss_pre_filter_set_xx_obj_  'TextPosition  ))))
        
        (setq Li_sc_ (vlax-get-property  ss_pre_filter_set_xx_obj_  'LinearScaleFactor ))
        (setq Fac_sc_ (vlax-get-property  ss_pre_filter_set_xx_obj_  'ScaleFactor  ))
        (setq dim_Precision_ (vla-get-PrimaryUnitsPrecision ss_pre_filter_set_xx_obj_ ))
        
        
        (vla-put-stylename  ss_pre_filter_set_xx_obj_  DD )
        (vlax-put-property  ss_pre_filter_set_xx_obj_  'LinearScaleFactor Li_sc_)
        (vlax-put-property  ss_pre_filter_set_xx_obj_  'ScaleFactor Fac_sc_)
        (vla-put-PrimaryUnitsPrecision ss_pre_filter_set_xx_obj_ dim_Precision_)
        (command "dimedit" "h" (vlax-vla-object->ename ss_pre_filter_set_xx_obj_) "")
        (if  (= (vlax-get-property  ss_pre_filter_set_xx_obj_  'TextMovement  ) 1)
          (progn
            (vla-put-textmovement  ss_pre_filter_set_xx_obj_  0 )
            (vla-put-textmovement  ss_pre_filter_set_xx_obj_  1 )
            (command "AIDIMTEXTMOVE" 1 (vlax-vla-object->ename ss_pre_filter_set_xx_obj_) "" (if (= (getvar "worlducs") 0)(progn (trans LI_textpos_ 0 1)) LI_textpos_ )  )
          )
        )
        
      )
    )
  )
  (defun TA:change_dim_scale_ (dim_obj_ new_lv_ new_sc_ ) ;for changing Level Dim and input new dim scale overall
    ;user-input_from_parameter_ 
      ; (setq new_sc_ (cond ( (getreal (strcat "\nSpecify New Dim Scale Overall <" (rtos (setq new_sc_ (cond (new_sc_) (1.0) ) ) ) "> : " ) ) ) (new_sc_) ) )
      ; (setq new_lv_ (cond ( (getreal (strcat "\nSpecify New Level <" (rtos (setq new_lv_ (cond (new_lv_) (1.0) ) ) ) "> : " ) ) ) (new_lv_) ) )
    ;
    
    ;standard_offset_ by 
      ; (setq standard_offset_  (* (* (* 1 1) of_point) lv_add)) ;ปิดไปก่อน
      (setq standard_offset_  (* new_sc_ 5.625))
    ;
    ;user-inbput-getdata
      ; (setq dim_ename_ (car (entsel "specify Object")))
      ; (setq dim_obj_ (vlax-ename->vla-object dim_ename_))
    ;
    (if (= (vla-get-objectname dim_obj_) "AcDbRotatedDimension")
      (progn
        ;get-prop-data
          (setq dim_ename_ (vlax-vla-object->ename dim_obj_))
          (setq dim_obj_dimsc (/ (vla-get-scalefactor dim_obj_) 10))
          (setq start_dim_ (cdr (assoc 13 (entget dim_ename_ ))))
          (setq offset_end_dim_ (cdr (assoc 10 (entget dim_ename_ ))))
          (setq end_dim_ (cdr (assoc 14 (entget dim_ename_ ))))
          (setq distance_offsetdim_raw_val_ (distance (list (car start_dim_) (cadr start_dim_) (caddr start_dim_) ) (list (car start_dim_) (cadr end_dim_) (caddr start_dim_) ) ) )
          (setq distance_offsetdim_raw_angle_ (angle (list (car start_dim_) (cadr start_dim_) (caddr start_dim_) ) (list (car start_dim_) (cadr end_dim_) (caddr start_dim_) ) ) )
          (setq distance_offsetdim_raw_offset_angle_ (angle end_dim_ offset_end_dim_ ) )
          ; (setq distance_offsetdim_val_ (/ distance_offsetdim_raw_val_ standard_offset_ ))
          (setq newoffset_dim_raw_val_ (* new_lv_ standard_offset_))
          (setq newoffset_dim_val_ (polar end_dim_ distance_offsetdim_raw_offset_angle_ newoffset_dim_raw_val_))
        ;
        ;entmod_process
          (cond
            ((= (getvar "worlducs") 1) ;รอแก้
              (progn
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (entmod 
                        (subst 
                          (cons 10 
                                newoffset_dim_val_
                          )
                          (assoc 10 (entget dim_ename_))
                          (entget dim_ename_)
                        )
                      )
                    )
                  )
                )
              )
              
            )
            ((= (getvar "worlducs") 0) ;รอแก้
              (progn
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (entmod 
                        (subst 
                          (cons 10 
                                newoffset_dim_val_
                          )
                          (assoc 10 (entget dim_ename_))
                          (entget dim_ename_)
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        ;
        ;put-propertie
          (vla-put-scalefactor dim_obj_  (* new_sc_ 10) )
        ;
      )
    )
  )
  (defun TA:SS-change_dim_lvdim (ss_pre_filter_set_xx_ new_lv_ new_sc_)
    ;user-input_from_parameter_ 
      ; (setq new_sc_ (cond ( (getreal (strcat "\nSpecify New Dim Scale Overall <" (rtos (setq new_sc_ (cond (new_sc_) (1.0) ) ) ) "> : " ) ) ) (new_sc_) ) )
      ; (setq new_lv_ (cond ( (getreal (strcat "\nSpecify New Level <" (rtos (setq new_lv_ (cond (new_lv_) (1.0) ) ) ) "> : " ) ) ) (new_lv_) ) )
    ;
    ;standard_offset_ by 
      ; (setq standard_offset_  (* (* (* 1 1) of_point) lv_add)) ;ปิดไปก่อน
      (setq standard_offset_  (* new_sc_ 5.625))
    ;
    ; (setq ss_pre_filter_set_xx_ (ssget)) ;for tesing
    ;find_higest_dimension_range
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (setq ss_pre_filter_set_xx_end_dim_list_ ())
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
          (setq end_dim_ (cdr (assoc 14 (entget ss_pre_filter_set_xx_ename_))))
          (setq start_dim_ (cdr (assoc 13 (entget ss_pre_filter_set_xx_ename_))))
          ; (command "point" (trans end_dim_ 0 1))
          ; (command "point" (trans start_dim_ 0 1))
          ;TA:stanndard_lambda_sorting
            (setq y_sorted_ (vl-sort (list (trans start_dim_ 0 1) (trans end_dim_ 0 1) )  ;bigest open indent list
                                                      (function 
                                                        (lambda (a b) 
                                                          (> (cadr a) (cadr b))
                                                        )
                                                      )
                                  ) ;bigest close indent list
            )
          ;
          (setq ss_pre_filter_set_xx_end_dim_list_ (cons 
                                                     (list 
                                                       ss_pre_filter_set_xx_ename_
                                                       (car y_sorted_)
                                                     )
                                                     ss_pre_filter_set_xx_end_dim_list_
                                                   )
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      ;TA:stanndard_lambda_sorting highest_Y
        (setq ss_pre_filter_set_xx_end_dim_list_Y_sorted_ (vl-sort ss_pre_filter_set_xx_end_dim_list_  ;bigest open indent list
                                                                 (function 
                                                                   (lambda (a b) 
                                                                     (> (nth 1 (cadr a)) (nth 1 (cadr b)) )
                                                                   )
                                                                 )
                                                        ) ;bigest close indent list
        )
        (setq highest_Y_ (car ss_pre_filter_set_xx_end_dim_list_Y_sorted_))
        ;TA:stanndard_lambda_sorting
          (setq highest_Y_sorted_ (vl-sort (cdr highest_Y_)  ;bigest open indent list
                                                    (function 
                                                      (lambda (a b) 
                                                        (> (cadr a) (cadr b))
                                                      )
                                                    )
                                ) ;bigest close indent list
          )
        ;
        ; (command "pselect"  (car highest_Y_) "" )
        (setq dim_list_ ss_pre_filter_set_xx_end_dim_list_Y_sorted_)
      ;
    ;
    ;preloop_and_while
      (setq dim_list_i 0)
      (while (< dim_list_i (length dim_list_))
        (setq dim_list_ename_ (car (nth  dim_list_i dim_list_)))
        (setq dim_list_obj_ (vlax-ename->vla-object  dim_list_ename_))
        (setq dim_list_start-dim_ (cadr (nth  dim_list_i dim_list_)))
        (setq dim_list_end-dim_ (list (car (cadr (nth  dim_list_i dim_list_))) (cadr (car highest_Y_sorted_)) (caddr (car highest_Y_sorted_)) ) )
        (setq newoffset_dim_raw_val_ (* new_lv_ standard_offset_))
        (setq stretch_point (polar dim_list_end-dim_  (deg-to-rad 90) newoffset_dim_raw_val_))
        ;entmod_process
          (cond
            ((= (getvar "worlducs") 1) ;รอแก้
              (progn
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (entmod 
                        (subst 
                          (cons 10 
                                stretch_point
                          )
                          (assoc 10 (entget dim_list_ename_))
                          (entget dim_list_ename_)
                        )
                      )
                    )
                  )
                )
              )
              
            )
            ((= (getvar "worlducs") 0) ;รอแก้
              (progn
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (entmod 
                        (subst 
                          (cons 10 
                                (trans stretch_point 1 0)
                          )
                          (assoc 10 (entget dim_list_ename_))
                          (entget dim_list_ename_)
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        ;
        ;put-properties
          (vla-put-scalefactor dim_list_obj_  (* new_sc_ 10) )
        ;
        ;command process
          (command "dimedit" "h" dim_list_ename_ "" )
        ;
        (setq dim_list_i (+ dim_list_i 1))
      )
    ;
    
  )
  (defun TA:move_dim_level_ (dim_obj_ new_sc_ symbol)
    ;user-input_from_parameter_ 
      ; (setq new_sc_ (cond ( (getreal (strcat "\nSpecify New Dim Scale Overall <" (rtos (setq new_sc_ (cond (new_sc_) (1.0) ) ) ) "> : " ) ) ) (new_sc_) ) )
      ; (setq new_lv_ (cond ( (getreal (strcat "\nSpecify New Level <" (rtos (setq new_lv_ (cond (new_lv_) (1.0) ) ) ) "> : " ) ) ) (new_lv_) ) )
    ;
    ;
      (setq standard_offset_  (* new_sc_ 5.625))
      (setq newoffset_dim_raw_val_ (* 1 standard_offset_))
    ;
    ; (setq dim_ename_ (car (entsel "specify Object")))
    ; (setq dim_obj_ (vlax-ename->vla-object dim_ename_))
    (setq dim_ename_ (vlax-vla-object->ename dim_obj_))
    (setq entget_angle_dim_
      (angle 
        (cdr (assoc 14 (entget dim_ename_)))
        (cdr (assoc 10 (entget dim_ename_)))
      )
    )
    (setq stretch_point (polar (cdr (assoc 10 (entget dim_ename_))) 
                               (angle 
                                 (cdr (assoc 14 (entget dim_ename_)))
                                 (cdr (assoc 10 (entget dim_ename_)))
                               )
                               (* symbol newoffset_dim_raw_val_)
                        )
    )
    (entmod 
      (subst 
        (cons 10 
              stretch_point
        )
        (assoc 10 (entget dim_ename_))
        (entget dim_ename_)
      )
    )

  )
  (defun TA:settting_dimstyle_TEMP ()
    (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
    (setq dimstyles (vla-get-DimStyles doc))
    (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_E-C"))
  )
;
(defun TA:make_current_ucs_ (ucs_obj_ )
  ; (setq ucs_ename_ (car (entsel "specify Object")))
  (setq ucs_obj_ (vlax-ename->vla-object ucs_ename_))
  (setq ucs_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ucs_obj_))))
  (setq ucs_obj_rotation_ (rad-to-deg (vla-get-rotation ucs_obj_ )))

  (command "ucs" "ob"  )
  (command "ucs" "z" "270")
) 
;core
  ;presetting_
    (defun c:dimsetting-ckst ()
      (command "dimstyle" "r" "FAMELINE-CKST_E-E")
      (setq scl 1)
      (setq lv_ 1)
      (setq lv_add (* lv_ 1.25))
      (setq dimprec 0)
      (setq sss_obj_linearsc_ 100)
      (setq DIM_E-C "FAMELINE-CKST_E-C")
      (setq DIM_C-C "FAMELINE-CKST_C-C")
      (setq DIM_C-E "FAMELINE-CKST_C-E")
      (setq DIM_E-E "FAMELINE-CKST_E-E")
    )
    (c:dimsetting-ckst )
    (defun c:dimsetting ()
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nCustom setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ T)
            (= ss_ T)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (0) ) ) ) "> : " ) ) ) (dimprec) ) ) 
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
                (while (and 
                        (= sss_obj_dimname_ nil)
                        (= (wcmatch (vl-princ-to-string Er-msg_sss_ename_) "*error*"))
                      )
                  (setq Er-msg_sss_ename_ (vl-catch-all-apply (function (lambda () (setq sss_ename_ (car (entsel "specify dim for set scale Object"))) ) ) ))
                  
                  (if
                    (and ;conditional_rule_for_select_object
                      ; (/= sss_ename_ nil)
                      (= (vl-catch-all-apply (function (lambda () (vla-get-objectname (vlax-ename->vla-object sss_ename_) ) ) ) ) "AcDbRotatedDimension")
                    )
                    (progn
                      (vl-catch-all-apply (function (lambda () (setq sss_obj_dimname_ (vla-get-stylename (vlax-ename->vla-object sss_ename_) )) ) ) )
                      (vl-catch-all-apply (function (lambda () (setq sss_obj_linearsc_ (vla-get-LinearScaleFactor (vlax-ename->vla-object sss_ename_) )) ) ) )
                      (vl-catch-all-apply (function (lambda () (command "dimstyle" "r" sss_obj_dimname_) ) ) )
                    )
                    (alert "Object invalid Please try again")
                  )
                )
              ;
            ;
          )
        )
        (if 
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            (setq dim_ename_ (car (entsel "specify Object")))
            (setq dim_check_ nil)
            (while
              (and
                (= dim_check_ nil)
                (/= dim_ename_ nil)
                (setq dim_obj_ (vlax-ename->vla-object dim_ename_))
              )
              (if (= (vla-get-objectname dim_obj_) "AcDbRotatedDimension")
                (progn
                  (setq dim_check_ T)
                  (setq sss_obj_dimname_ (vla-get-stylename dim_obj_ ))
                  (setq sss_obj_linearsc_ (vla-get-LinearScaleFactor dim_obj_ ))
                  (setq scl (vla-get-scalefactor dim_obj_ ))
                  (setq dim_obj_measurement_ (vlax-dump-object dim_obj_ ))
                  (command "dimstyle" "r" sss_obj_dimname_)
                  (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
                  (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
                  (setq lv_add (* lv_ 1.25))
                  (setq sc (* scl 10)) ; 5 = 50 2 = 20
                  (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
                  (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
                  (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
                  (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
                  (setvar "dimscale" sc )
                )
                (alert "Object is not AcDbRotatedDimension")
              )
            )
          )
        )
        (if 
          (and 
            (= setting_ T)
            (= ss_ T)
          )
          (progn
            
            
            (vl-catch-all-apply
              (function
                (lambda ()
                  (setq dim_ename_ (car (entsel "specify DIM E-C Object")))
                  (setq DIM_E-C (vla-get-stylename (vlax-ename->vla-object dim_ename_) )) 
                )
              )
            )
            (vl-catch-all-apply
              (function
                (lambda ()
                  (setq dim_ename_ (car (entsel "specify DIM C-C Object")))
                  (setq DIM_C-C (vla-get-stylename (vlax-ename->vla-object dim_ename_) ))
                )
              )
            )
            (vl-catch-all-apply
              (function
                (lambda ()
                  (setq dim_ename_ (car (entsel "specify DIM C-E Object")))
                  (setq DIM_C-E (vla-get-stylename (vlax-ename->vla-object dim_ename_) )) 
                )
              )
            )
            (vl-catch-all-apply
              (function
                (lambda ()
                  (setq dim_ename_ (car (entsel "specify DIM E-E Object")))
                  (setq DIM_E-E (vla-get-stylename (vlax-ename->vla-object dim_ename_) )) 
                )
              )
            )
          )
        )
      ;
    )
    (defun c:dimlsc ()
      (setq sss_obj_linearsc_ (setvar "dimlfac" (setq lfac (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lfac (cond (lfac) (1.0) ) ) ) "> : " ) ) ) (lfac) ) )))
    )
    (defun TA:preset_FAMELINE-CKST_C-C ()
      (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
      (setq dimstyles (vla-get-DimStyles doc))
      (if (= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_C-C")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR) (progn (command "DIMSTYLE" "s" "FAMELINE-CKST_C-C" ) ) )
      (setq newset__ 
        (list 
          (command "dimstyle" "r" "FAMELINE-CKST_C-C")
          ;; ===== DIMENSION SYSTEM VARIABLES =====
            ; (setvar "DIMASO" 0)              ; Create dimension objects (Off)
            (setvar "DIMADEC" 0)             ; Angular decimal places
            (setvar "DIMALT" 0)              ; Alternate units Off
            (setvar "DIMALTD" 2)             ; Alternate unit decimal places
            (setvar "DIMALTF" 25.4)          ; Alternate unit scale factor
            ; (setvar "DIMALTMZF" 100.0)       ; Alternate sub-zero factor (metric)
            (setvar "DIMALTRND" 0.0)         ; Alternate units rounding
            (setvar "DIMALTTD" 2)            ; Alternate tolerance decimal places
            (setvar "DIMALTTZ" 0)            ; Alternate tolerance zero suppression
            (setvar "DIMALTU" 2)             ; Alternate units format
            (setvar "DIMALTZ" 0)             ; Alternate unit zero suppression
            (setvar "DIMARCSYM" 0)           ; Arc length symbol
            (setvar "DIMASZ" 0.15)           ; Arrow size
            (setvar "DIMATFIT" 3)            ; Arrow & text fit
            (setvar "DIMAUNIT" 0)            ; Angular unit format
            (setvar "DIMAZIN" 0)             ; Angular zero suppression
          
            (setvar "DIMSAH" 1)              ; 0 = 1st and 2nd wil be same
            ; (setvar "DIMBLK" "Origin")       ; Arrow block
            (setvar "DIMBLK1" "Origin")             ; First arrow block
            (setvar "DIMBLK2" "Origin")             ; Second arrow block

            (setvar "DIMCEN" 0.10)           ; Center mark size
            (setvar "DIMCLRD" 256)             ; Dim line color (0 = BYBLOCK)
            (setvar "DIMCLRE" 256)             ; Extension line color (BYBLOCK)
            (setvar "DIMCLRT" 3)             ; Text color (1 = Red)

            (setvar "DIMDEC" 2)              ; Decimal places
            (setvar "DIMDLE" 0.10)           ; Dimension line extension
            (setvar "DIMDLI" 0.10)           ; Dimension line spacing
            (setvar "DIMDSEP" ".")           ; Decimal separator
            (setvar "DIMEXE" 0.10)           ; Extension above dim line
            (setvar "DIMEXO" 0.10)           ; Extension origin offset
            (setvar "DIMFRAC" 0)             ; Fraction format

            (setvar "DIMFXL" 1.0)            ; Fixed extension line length
            (setvar "DIMFXLON" 0)            ; Fixed extension line Off
            (setvar "DIMGAP" 0.05)           ; Gap text to dim line

            (setvar "DIMJOGANG" (deg-to-rad 45.0))        ; Jog angle
            (setvar "DIMJUST" 0)             ; Text justification

            (setvar "DIMLDRBLK" "") ; Leader arrow block
            (setvar "DIMLFAC" 1.0)           ; Linear scale factor
            (setvar "DIMLIM" 0)              ; Dimension limits Off
            (setvar "DIMLTYPE" "bylayer")            ; Dimension linetype BYBLOCK
            (setvar "DIMLTEX1" "bylayer")
            (setvar "DIMLTEX2" "bylayer")
            (setvar "DIMLUNIT" 2)            ; Linear unit format

            (setvar "DIMLWD" -1)             ; Dim line lineweight (BYBLOCK)
            (setvar "DIMLWE" -1)             ; Extension line lineweight (BYBLOCK)

            ;(setvar "DIMMZF" 100.0)          ; Metric sub-zero factor
            (setvar "DIMRND" 0.0)            ; Rounding value
            
            (setvar "DIMSCALE" 1.0)          ; Overall scale

            (setvar "DIMSD1" 0)              ; Suppress first dim line Off
            (setvar "DIMSD2" 0)              ; Suppress second dim line Off
            (setvar "DIMSE1" 0)              ; Suppress first extension Off
            (setvar "DIMSE2" 0)              ; Suppress second extension Off
            (setvar "DIMSOXD" 0)             ; Suppress outside dim lines Off

            (setvar "DIMTAD" 1)              ; Text above dim line
            (setvar "DIMTDEC" 2)             ; Tolerance decimal places
            (setvar "DIMTFAC" 1.0)           ; Tolerance text height scale
            (setvar "DIMTFILL" 0)            ; Text background Off
            (setvar "DIMTIH" 0)              ; Text inside horizontal Off
            (setvar "DIMTIX" 1)              ; Force text inside
            (setvar "DIMTM" 0.0)             ; Minus tolerance
            (setvar "DIMTMOVE" 2)            ; Text movement rule
            (setvar "DIMTOFL" 1)             ; Force line inside extension
            (setvar "DIMTOH" 0)              ; Text outside horizontal Off
            (setvar "DIMTOL" 0)              ; Tolerance Off
            (setvar "DIMTOLJ" 1)             ; Tolerance vertical justification
            (setvar "DIMTP" 0.0)             ; Plus tolerance
            (setvar "DIMTSZ" 0.0)            ; Tick size
            (setvar "DIMTVP" 0.0)            ; Text vertical position

            (setvar "DIMTXT" 0.30)           ; Text height
            (setvar "DIMTZIN" 0)             ; Tolerance zero suppression
            (setvar "DIMUPT" 0)              ; User positioned text Off
            (setvar "DIMZIN" 0)              ; Zero suppression
          
            

          ;;
        )
      )
      (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_C-C" "Y" "A" "" )
      (command "DIMSTYLE" "save" "FAMELINE-CKST_C-C" "Y")
    )
    (defun TA:preset_FAMELINE-CKST_C-E ()
      (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
      (setq dimstyles (vla-get-DimStyles doc))
      (if (= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_C-E")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR) (progn (command "DIMSTYLE" "s" "FAMELINE-CKST_C-E" ) ) )
      (setq newset__ 
        (list 
          ;; ===== DIMENSION SYSTEM VARIABLES =====
            ; (setvar "DIMASO" 0)              ; Create dimension objects (Off)
            (setvar "DIMADEC" 0)             ; Angular decimal places
            (setvar "DIMALT" 0)              ; Alternate units Off
            (setvar "DIMALTD" 2)             ; Alternate unit decimal places
            (setvar "DIMALTF" 25.4)          ; Alternate unit scale factor
            ; (setvar "DIMALTMZF" 100.0)       ; Alternate sub-zero factor (metric)
            (setvar "DIMALTRND" 0.0)         ; Alternate units rounding
            (setvar "DIMALTTD" 2)            ; Alternate tolerance decimal places
            (setvar "DIMALTTZ" 0)            ; Alternate tolerance zero suppression
            (setvar "DIMALTU" 2)             ; Alternate units format
            (setvar "DIMALTZ" 0)             ; Alternate unit zero suppression
            (setvar "DIMARCSYM" 0)           ; Arc length symbol
            (setvar "DIMASZ" 0.15)           ; Arrow size
            (setvar "DIMATFIT" 3)            ; Arrow & text fit
            (setvar "DIMAUNIT" 0)            ; Angular unit format
            (setvar "DIMAZIN" 0)             ; Angular zero suppression

            (setvar "DIMSAH" 1)              ; 0 = 1st and 2nd wil be same
            ; (setvar "DIMBLK" "Origin")       ; Arrow block
            (setvar "DIMBLK1" "Origin")     ; First arrow block
            (setvar "DIMBLK2" "Oblique")    ; Second arrow block
          
            (getvar "DIMBLK" )       ; Arrow block
            (getvar "DIMBLK1" )     ; First arrow block
            (getvar "DIMBLK2" )    ; Second arrow block

            (setvar "DIMCEN" 0.10)           ; Center mark size
            (setvar "DIMCLRD" 256)             ; Dim line color (0 = BYBLOCK)
            (setvar "DIMCLRE" 256)             ; Extension line color (BYBLOCK)
            (setvar "DIMCLRT" 3)             ; Text color (1 = Red)

            (setvar "DIMDEC" 2)              ; Decimal places
            (setvar "DIMDLE" 0.10)           ; Dimension line extension
            (setvar "DIMDLI" 0.10)           ; Dimension line spacing
            (setvar "DIMDSEP" ".")           ; Decimal separator
            (setvar "DIMEXE" 0.10)           ; Extension above dim line
            (setvar "DIMEXO" 0.10)           ; Extension origin offset
            (setvar "DIMFRAC" 0)             ; Fraction format

            (setvar "DIMFXL" 1.0)            ; Fixed extension line length
            (setvar "DIMFXLON" 0)            ; Fixed extension line Off
            (setvar "DIMGAP" 0.05)           ; Gap text to dim line

            (setvar "DIMJOGANG" (deg-to-rad 45.0))        ; Jog angle
            (setvar "DIMJUST" 0)             ; Text justification

            (setvar "DIMLDRBLK" "") ; Leader arrow block
            (setvar "DIMLFAC" 1.0)           ; Linear scale factor
            (setvar "DIMLIM" 0)              ; Dimension limits Off
            (setvar "DIMLTYPE" "bylayer")            ; Dimension linetype BYBLOCK
            (setvar "DIMLTEX1" "bylayer")
            (setvar "DIMLTEX2" "bylayer")
            (setvar "DIMLUNIT" 2)            ; Linear unit format

            (setvar "DIMLWD" -1)             ; Dim line lineweight (BYBLOCK)
            (setvar "DIMLWE" -1)             ; Extension line lineweight (BYBLOCK)

            ;(setvar "DIMMZF" 100.0)          ; Metric sub-zero factor
            (setvar "DIMRND" 0.0)            ; Rounding value
            
            (setvar "DIMSCALE" 1.0)          ; Overall scale

            (setvar "DIMSD1" 0)              ; Suppress first dim line Off
            (setvar "DIMSD2" 0)              ; Suppress second dim line Off
            (setvar "DIMSE1" 0)              ; Suppress first extension Off
            (setvar "DIMSE2" 0)              ; Suppress second extension Off
            (setvar "DIMSOXD" 0)             ; Suppress outside dim lines Off

            (setvar "DIMTAD" 1)              ; Text above dim line
            (setvar "DIMTDEC" 2)             ; Tolerance decimal places
            (setvar "DIMTFAC" 1.0)           ; Tolerance text height scale
            (setvar "DIMTFILL" 0)            ; Text background Off
            (setvar "DIMTIH" 0)              ; Text inside horizontal Off
            (setvar "DIMTIX" 1)              ; Force text inside
            (setvar "DIMTM" 0.0)             ; Minus tolerance
            (setvar "DIMTMOVE" 2)            ; Text movement rule
            (setvar "DIMTOFL" 1)             ; Force line inside extension
            (setvar "DIMTOH" 0)              ; Text outside horizontal Off
            (setvar "DIMTOL" 0)              ; Tolerance Off
            (setvar "DIMTOLJ" 1)             ; Tolerance vertical justification
            (setvar "DIMTP" 0.0)             ; Plus tolerance
            (setvar "DIMTSZ" 0.0)            ; Tick size
            (setvar "DIMTVP" 0.0)            ; Text vertical position
            (setvar "DIMTXSTY" "FAMELINE_FOR_CKST")    ;Text style

            (setvar "DIMTXT" 0.30)           ; Text height
            (setvar "DIMTZIN" 0)             ; Tolerance zero suppression
            (setvar "DIMUPT" 0)              ; User positioned text Off
            (setvar "DIMZIN" 0)              ; Zero suppression
          
            

          ;;
        )
      )
      (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_C-E" "Y" "A" "" )
      (command "DIMSTYLE" "save" "FAMELINE-CKST_C-E" "Y")
    )
    (defun TA:preset_FAMELINE-CKST_E-C ()
      (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
      (setq dimstyles (vla-get-DimStyles doc))
      (if (= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_E-C")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR) (progn (command "DIMSTYLE" "s" "FAMELINE-CKST_E-C" ) ) )
      (setq newset__ 
        (list 
          ;; ===== DIMENSION SYSTEM VARIABLES =====
            ; (setvar "DIMASO" 0)              ; Create dimension objects (Off)
            (setvar "DIMADEC" 0)             ; Angular decimal places
            (setvar "DIMALT" 0)              ; Alternate units Off
            (setvar "DIMALTD" 2)             ; Alternate unit decimal places
            (setvar "DIMALTF" 25.4)          ; Alternate unit scale factor
            ; (setvar "DIMALTMZF" 100.0)       ; Alternate sub-zero factor (metric)
            (setvar "DIMALTRND" 0.0)         ; Alternate units rounding
            (setvar "DIMALTTD" 2)            ; Alternate tolerance decimal places
            (setvar "DIMALTTZ" 0)            ; Alternate tolerance zero suppression
            (setvar "DIMALTU" 2)             ; Alternate units format
            (setvar "DIMALTZ" 0)             ; Alternate unit zero suppression
            (setvar "DIMARCSYM" 0)           ; Arc length symbol
            (setvar "DIMASZ" 0.15)           ; Arrow size
            (setvar "DIMATFIT" 3)            ; Arrow & text fit
            (setvar "DIMAUNIT" 0)            ; Angular unit format
            (setvar "DIMAZIN" 0)             ; Angular zero suppression

            (setvar "DIMSAH" 1)              ; 0 = 1st and 2nd wil be same
            ; (setvar "DIMBLK" "Origin")       ; Arrow block
            (setvar "DIMBLK1" "Oblique")     ; First arrow block
            (setvar "DIMBLK2" "Origin")    ; Second arrow block
          
            (getvar "DIMBLK" )       ; Arrow block
            (getvar "DIMBLK1" )     ; First arrow block
            (getvar "DIMBLK2" )    ; Second arrow block

            (setvar "DIMCEN" 0.10)           ; Center mark size
            (setvar "DIMCLRD" 256)             ; Dim line color (0 = BYBLOCK)
            (setvar "DIMCLRE" 256)             ; Extension line color (BYBLOCK)
            (setvar "DIMCLRT" 3)             ; Text color (1 = Red)

            (setvar "DIMDEC" 2)              ; Decimal places
            (setvar "DIMDLE" 0.10)           ; Dimension line extension
            (setvar "DIMDLI" 0.10)           ; Dimension line spacing
            (setvar "DIMDSEP" ".")           ; Decimal separator
            (setvar "DIMEXE" 0.10)           ; Extension above dim line
            (setvar "DIMEXO" 0.10)           ; Extension origin offset
            (setvar "DIMFRAC" 0)             ; Fraction format

            (setvar "DIMFXL" 1.0)            ; Fixed extension line length
            (setvar "DIMFXLON" 0)            ; Fixed extension line Off
            (setvar "DIMGAP" 0.05)           ; Gap text to dim line

            (setvar "DIMJOGANG" (deg-to-rad 45.0))        ; Jog angle
            (setvar "DIMJUST" 0)             ; Text justification

            (setvar "DIMLDRBLK" "") ; Leader arrow block
            (setvar "DIMLFAC" 1.0)           ; Linear scale factor
            (setvar "DIMLIM" 0)              ; Dimension limits Off
            (setvar "DIMLTYPE" "bylayer")            ; Dimension linetype BYBLOCK
            (setvar "DIMLTEX1" "bylayer")
            (setvar "DIMLTEX2" "bylayer")
            (setvar "DIMLUNIT" 2)            ; Linear unit format

            (setvar "DIMLWD" -1)             ; Dim line lineweight (BYBLOCK)
            (setvar "DIMLWE" -1)             ; Extension line lineweight (BYBLOCK)

            ;(setvar "DIMMZF" 100.0)          ; Metric sub-zero factor
            (setvar "DIMRND" 0.0)            ; Rounding value
            
            (setvar "DIMSCALE" 1.0)          ; Overall scale

            (setvar "DIMSD1" 0)              ; Suppress first dim line Off
            (setvar "DIMSD2" 0)              ; Suppress second dim line Off
            (setvar "DIMSE1" 0)              ; Suppress first extension Off
            (setvar "DIMSE2" 0)              ; Suppress second extension Off
            (setvar "DIMSOXD" 0)             ; Suppress outside dim lines Off

            (setvar "DIMTAD" 1)              ; Text above dim line
            (setvar "DIMTDEC" 2)             ; Tolerance decimal places
            (setvar "DIMTFAC" 1.0)           ; Tolerance text height scale
            (setvar "DIMTFILL" 0)            ; Text background Off
            (setvar "DIMTIH" 0)              ; Text inside horizontal Off
            (setvar "DIMTIX" 1)              ; Force text inside
            (setvar "DIMTM" 0.0)             ; Minus tolerance
            (setvar "DIMTMOVE" 2)            ; Text movement rule
            (setvar "DIMTOFL" 1)             ; Force line inside extension
            (setvar "DIMTOH" 0)              ; Text outside horizontal Off
            (setvar "DIMTOL" 0)              ; Tolerance Off
            (setvar "DIMTOLJ" 1)             ; Tolerance vertical justification
            (setvar "DIMTP" 0.0)             ; Plus tolerance
            (setvar "DIMTSZ" 0.0)            ; Tick size
            (setvar "DIMTVP" 0.0)            ; Text vertical position
            (setvar "DIMTXSTY" "FAMELINE_FOR_CKST")    ;Text style

            (setvar "DIMTXT" 0.30)           ; Text height
            (setvar "DIMTZIN" 0)             ; Tolerance zero suppression
            (setvar "DIMUPT" 0)              ; User positioned text Off
            (setvar "DIMZIN" 0)              ; Zero suppression
          
            

          ;;
        )
      )
      (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_E-C" "Y" "A" "" )
      (command "DIMSTYLE" "save" "FAMELINE-CKST_E-C" "Y")
    )
    (defun TA:preset_FAMELINE-CKST_E-E ()
      (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
      (setq dimstyles (vla-get-DimStyles doc))
      (if (= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_E-E")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR) (progn (command "DIMSTYLE" "s" "FAMELINE-CKST_E-E" ) ) )
      (setq newset__ 
        (list 
          (command "dimstyle" "r" "FAMELINE-CKST_E-E")
          ;; ===== DIMENSION SYSTEM VARIABLES =====
            ; (setvar "DIMASO" 0)              ; Create dimension objects (Off)
            (setvar "DIMADEC" 0)             ; Angular decimal places
            (setvar "DIMALT" 0)              ; Alternate units Off
            (setvar "DIMALTD" 2)             ; Alternate unit decimal places
            (setvar "DIMALTF" 25.4)          ; Alternate unit scale factor
            ; (setvar "DIMALTMZF" 100.0)       ; Alternate sub-zero factor (metric)
            (setvar "DIMALTRND" 0.0)         ; Alternate units rounding
            (setvar "DIMALTTD" 2)            ; Alternate tolerance decimal places
            (setvar "DIMALTTZ" 0)            ; Alternate tolerance zero suppression
            (setvar "DIMALTU" 2)             ; Alternate units format
            (setvar "DIMALTZ" 0)             ; Alternate unit zero suppression
            (setvar "DIMARCSYM" 0)           ; Arc length symbol
            (setvar "DIMASZ" 0.15)           ; Arrow size
            (setvar "DIMATFIT" 3)            ; Arrow & text fit
            (setvar "DIMAUNIT" 0)            ; Angular unit format
            (setvar "DIMAZIN" 0)             ; Angular zero suppression

            (setvar "DIMSAH" 1)              ; 0 = 1st and 2nd wil be same
            ; (setvar "DIMBLK" "Origin")       ; Arrow block
            (setvar "DIMBLK1" "Oblique")     ; First arrow block
            (setvar "DIMBLK2" "Oblique")    ; Second arrow block
          
            (getvar "DIMBLK" )       ; Arrow block
            (getvar "DIMBLK1" )     ; First arrow block
            (getvar "DIMBLK2" )    ; Second arrow block

            (setvar "DIMCEN" 0.10)           ; Center mark size
            (setvar "DIMCLRD" 256)             ; Dim line color (0 = BYBLOCK)
            (setvar "DIMCLRE" 256)             ; Extension line color (BYBLOCK)
            (setvar "DIMCLRT" 3)             ; Text color (1 = Red)

            (setvar "DIMDEC" 2)              ; Decimal places
            (setvar "DIMDLE" 0.10)           ; Dimension line extension
            (setvar "DIMDLI" 0.10)           ; Dimension line spacing
            (setvar "DIMDSEP" ".")           ; Decimal separator
            (setvar "DIMEXE" 0.10)           ; Extension above dim line
            (setvar "DIMEXO" 0.10)           ; Extension origin offset
            (setvar "DIMFRAC" 0)             ; Fraction format

            (setvar "DIMFXL" 1.0)            ; Fixed extension line length
            (setvar "DIMFXLON" 0)            ; Fixed extension line Off
            (setvar "DIMGAP" 0.05)           ; Gap text to dim line

            (setvar "DIMJOGANG" (deg-to-rad 45.0))        ; Jog angle
            (setvar "DIMJUST" 0)             ; Text justification

            (setvar "DIMLDRBLK" "") ; Leader arrow block
            (setvar "DIMLFAC" 1.0)           ; Linear scale factor
            (setvar "DIMLIM" 0)              ; Dimension limits Off
            (setvar "DIMLTYPE" "bylayer")            ; Dimension linetype BYBLOCK
            (setvar "DIMLTEX1" "bylayer")
            (setvar "DIMLTEX2" "bylayer")
            (setvar "DIMLUNIT" 2)            ; Linear unit format

            (setvar "DIMLWD" -1)             ; Dim line lineweight (BYBLOCK)
            (setvar "DIMLWE" -1)             ; Extension line lineweight (BYBLOCK)

            ;(setvar "DIMMZF" 100.0)          ; Metric sub-zero factor
            (setvar "DIMRND" 0.0)            ; Rounding value
            
            (setvar "DIMSCALE" 1.0)          ; Overall scale

            (setvar "DIMSD1" 0)              ; Suppress first dim line Off
            (setvar "DIMSD2" 0)              ; Suppress second dim line Off
            (setvar "DIMSE1" 0)              ; Suppress first extension Off
            (setvar "DIMSE2" 0)              ; Suppress second extension Off
            (setvar "DIMSOXD" 0)             ; Suppress outside dim lines Off

            (setvar "DIMTAD" 1)              ; Text above dim line
            (setvar "DIMTDEC" 2)             ; Tolerance decimal places
            (setvar "DIMTFAC" 1.0)           ; Tolerance text height scale
            (setvar "DIMTFILL" 0)            ; Text background Off
            (setvar "DIMTIH" 0)              ; Text inside horizontal Off
            (setvar "DIMTIX" 1)              ; Force text inside
            (setvar "DIMTM" 0.0)             ; Minus tolerance
            (setvar "DIMTMOVE" 2)            ; Text movement rule
            (setvar "DIMTOFL" 1)             ; Force line inside extension
            (setvar "DIMTOH" 0)              ; Text outside horizontal Off
            (setvar "DIMTOL" 0)              ; Tolerance Off
            (setvar "DIMTOLJ" 1)             ; Tolerance vertical justification
            (setvar "DIMTP" 0.0)             ; Plus tolerance
            (setvar "DIMTSZ" 0.0)            ; Tick size
            (setvar "DIMTVP" 0.0)            ; Text vertical position
            (setvar "DIMTXSTY" "FAMELINE_FOR_CKST")    ;Text style

            (setvar "DIMTXT" 0.30)           ; Text height
            (setvar "DIMTZIN" 0)             ; Tolerance zero suppression
            (setvar "DIMUPT" 0)              ; User positioned text Off
            (setvar "DIMZIN" 0)              ; Zero suppression
          
            

          ;;
        )
      )
      (setq dim_command_ (list 
                            (setvar "DIMCLRD" 256) ; Dimension line color
                            (setvar "DIMCLRE" 256) ; Extension line color
                            (setvar "DIMCLRT" 3) ; Text color
                            (setvar "DIMLWD" -1) ; Dimension line lineweight
                            (setvar "DIMLWE" -1) ; Extension line lineweight
                            (setvar "DIMSCALE" 1.0) ; Overall scale factor
                            (setvar "DIMLFAC" 1.0) ; Linear unit scale factor
                            (setvar "DIMTXSTY" "FAMELINE_FOR_CKST") ; Linear unit scale factor
                          )
      )
      (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_E-E" "Y" "A" "" )
      (command "DIMSTYLE" "save" "FAMELINE-CKST_E-E" "Y")
    )
    (defun c:CSKT_dimpreset ()
      (TA:preset_FAMELINE-CKST_C-C)
      (TA:preset_FAMELINE-CKST_C-E)
      (TA:preset_FAMELINE-CKST_E-C)
      (TA:preset_FAMELINE-CKST_E-E)
    )
    
    ; (defun c:dimsetting-CKST_DIM_PRESET ()
    ;   ;example of setting dimension variables by setvar
    ;     ; (list 
    ;     ;       (setvar "DIMASO" 0)              
    ;     ;       ; Create dimension objects (Off)
    ;     ;       ; DIMSTYLE เป็น read-only ข้าม
    ;     ;       (setvar "DIMADEC" 0)  ; Angular decimal places
    ;     ;       (setvar "DIMALT" 0) ; Alternate units selected (Off)
    ;     ;       (setvar "DIMALTD" 3) ; Alternate unit decimal places
    ;     ;       (setvar "DIMALTF" 0.0394) ; Alternate unit scale factor
    ;     ;       (setvar "DIMALTMZF" 100.0) ; Alternate sub-zero factor
    ;     ;       ; DIMALTMZS ไม่มีค่า ข้าม
    ;     ;       (setvar "DIMALTRND" 0.0) ; Alternate units rounding
    ;     ;       (setvar "DIMALTTD" 3) ; Alternate tolerance decimal places
    ;     ;       (setvar "DIMALTTZ" 0) ; Alternate tolerance zero suppression
    ;     ;       (setvar "DIMALTU" 2) ; Alternate units
    ;     ;       (setvar "DIMALTZ" 0) ; Alternate unit zero suppression
    ;     ;       ; DIMAPOST ไม่มีค่า ข้าม
    ;     ;       (setvar "DIMARCSYM" 0) ; Arc length symbol
    ;     ;       (setvar "DIMASZ" 2.5) ; Arrow size
    ;     ;       (setvar "DIMATFIT" 3) ; Arrow and text fit
    ;     ;       (setvar "DIMAUNIT" 0) ; Angular unit format
    ;     ;       (setvar "DIMAZIN" 0) ; Angular zero suppression
    ;     ;       ; DIMBLK / DIMBLK1 / DIMBLK2 เป็นชื่อ block (ใช้ setvar ได้ถ้าต้องการ)
    ;     ;       (setvar "DIMCEN" 2.5) ; Center mark size
    ;     ;       ; สี BYBLOCK ไม่ต้อง set ถ้าใช้ค่าเดิม
    ;     ;       (setvar "DIMDEC" 2) ; Decimal places
    ;     ;       (setvar "DIMDLE" 0.0) ; Dimension line extension
    ;     ;       (setvar "DIMDLI" 3.75) ; Dimension line spacing
    ;     ;       ; DIMDSEP "," ปกติไม่ต้องตั้งถ้าใช้ค่าเดิม
    ;     ;       (setvar "DIMEXE" 1.25) ; Extension above dimension line
    ;     ;       (setvar "DIMEXO" 0.625) ; Extension line origin offset
    ;     ;       (setvar "DIMFRAC" 0) ; Fraction format
    ;     ;       (setvar "DIMFXL" 1.0) ; Fixed Extension Line
    ;     ;       (setvar "DIMFXLON" 0) ; Enable Fixed Extension Line
    ;     ;       (setvar "DIMGAP" 0.625) ; Gap from dimension line to text
    ;     ;       (setvar "DIMJOGANG" 45) ; Radius dimension jog angle
    ;     ;       (setvar "DIMJUST" 0) ; Text justification
    ;     ;       ; DIMLDRBLK = ClosedFilled (ถ้าจะตั้งใช้ setvar "DIMLDRBLK" "ClosedFilled")
    ;     ;       (setvar "DIMLFAC" 1.0) ; Linear unit scale factor
    ;     ;       (setvar "DIMLIM" 0) ; Generate dimension limits
    ;     ;       ; Linetype BYBLOCK ข้ามได้
    ;     ;       (setvar "DIMLWD" -2) ; Dimension line lineweight
    ;     ;       (setvar "DIMLWE" -2) ; Extension line lineweight
    ;     ;       (setvar "DIMMZF" 100.0) ; Sub-zero factor
    ;     ;       ; DIMMZS ไม่มีค่า
    ;     ;       ; DIMPOST ไม่มีค่า
    ;     ;       (setvar "DIMRND" 0.0) ; Rounding value
    ;     ;       (setvar "DIMSAH" 0) ; Separate arrow blocks
    ;     ;       (setvar "DIMSCALE" 1.0) ; Overall scale factor
    ;     ;       (setvar "DIMSD1" 0) ; Suppress first dim line
    ;     ;       (setvar "DIMSD2" 0) ; Suppress second dim line
    ;     ;       (setvar "DIMSE1" 0) ; Suppress first ext line
    ;     ;       (setvar "DIMSE2" 0) ; Suppress second ext line
    ;     ;       (setvar "DIMSOXD" 0) ; Suppress outside dim lines
    ;     ;       (setvar "DIMTAD" 1) ; Text above dim line
    ;     ;       (setvar "DIMTDEC" 2) ; Tolerance decimal places
    ;     ;       (setvar "DIMTFAC" 1.0) ; Tolerance text scale
    ;     ;       (setvar "DIMTFILL" 0) ; Text background off
    ;     ;       ; DIMTFILLCLR BYBLOCK ข้าม
    ;     ;       (setvar "DIMTIH" 0) ; Text inside horizontal
    ;     ;       (setvar "DIMTIX" 0) ; Place text inside ext
    ;     ;       (setvar "DIMTM" 0.0) ; Minus tolerance
    ;     ;       (setvar "DIMTMOVE" 0) ; Text movement
    ;     ;       (setvar "DIMTOFL" 1) ; Force line inside ext
    ;     ;       (setvar "DIMTOH" 0) ; Text outside horizontal
    ;     ;       (setvar "DIMTOL" 0) ; Tolerance off
    ;     ;       (setvar "DIMTOLJ" 0) ; Tolerance justification
    ;     ;       (setvar "DIMTP" 0.0) ; Plus tolerance
    ;     ;       (setvar "DIMTSZ" 0.0) ; Tick size
    ;     ;       (setvar "DIMTVP" 0.0) ; Text vertical position
    ;     ;       ; DIMTXSTY "Standard" ใช้ (setvar "DIMTXSTY" "Standard")
    ;     ;       (setvar "DIMTXT" 2.5) ; Text height
    ;     ;       (setvar "DIMTZIN" 8) ; Tolerance zero suppression
    ;     ;       (setvar "DIMUPT" 0) ; User positioned text
    ;     ;       (setvar "DIMZIN" 8) ; Zero suppression)
    ;     ; )
    ;   ;
    ;   ;preloop_and_while
    ;     (setq dim_command_ (list 
    ;                          (list "DIMCLRD" 256) ; Dimension line color
    ;                          (list "DIMCLRE" 256) ; Extension line color
    ;                          (list "DIMCLRT" 256) ; Text color
    ;                          (list "DIMLWD" -1) ; Dimension line lineweight
    ;                          (list "DIMLWE" -1) ; Extension line lineweight
    ;                          (list "DIMSCALE" 1.0) ; Overall scale factor
    ;                          (list "DIMLFAC" 1.0) ; Linear unit scale factor
    ;                          (list "DIMTXSTY" "FAMELINE_FOR_CKST") ; Linear unit scale factor
    ;                        )
    ;     )
    ;     (setq doc (vla-get-ActiveDocument (vlax-get-Acad-Object)))
    ;     (setq dimstyles (vla-get-DimStyles doc))
    ;     (if (and 
    ;           (/= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_E-E")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR)
    ;           (/= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_E-C")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR)
    ;           (/= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_C-E")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR)
    ;           (/= (type (vl-catch-all-apply (function (lambda () (setq dimstyle (vla-Item dimstyles "FAMELINE-CKST_C-C")) ) ) ) ) 'VL-CATCH-ALL-APPLY-ERROR)
    ;         )
    ;       (progn
    ;         (setq dim_command_i 0)
    ;         (while (< dim_command_i (length dim_command_))
    ;           (setq dim_command_varname_ (car (nth  dim_command_i dim_command_)))
    ;           (setq dim_command_varval_ (cadr (nth  dim_command_i dim_command_)))
    ;           (setvar dim_command_varname_ dim_command_varval_ )
    ;           (setq dim_command_i (+ dim_command_i 1))
    ;         )
    ;         (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_E-E" "Y" "A" "" )
    ;         (command "DIMSTYLE" "save" "FAMELINE-CKST_E-E" "Y")
            
    ;         (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_E-C" "Y" "A" "" )
    ;         (command "DIMSTYLE" "save" "FAMELINE-CKST_E-C" "Y")
            
    ;         (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_C-E" "Y" "A" "" )
    ;         (command "DIMSTYLE" "save" "FAMELINE-CKST_C-E" "Y")
            
    ;         (command "DIMSTYLE" "AN" "N" "FAMELINE-CKST_C-C" "Y" "A" "" )
    ;         (command "DIMSTYLE" "save" "FAMELINE-CKST_C-C" "Y")
    ;       )
    ;     )
    ;   ;
    ; )
  ;
  ;change dim style
    (defun c:change_dim_xDEC ()

      (setq pass_lv1_ nil) ;for reset process and checking DIM EE EC CC CE value
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          (setq pass_lv1_ T)
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (and 
                (= pass_lv1_ T)
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_) )
              )
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_E-C)
          (vla-put-PrimaryUnitsPrecision ss_pre_filter_set_xx_obj_ 0)
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (command "pselect"  ss_pre_filter_set_xx_ "" )
    )
    (defun c:change_dim_xDCC ()
      (setq pass_lv1_ nil) ;for reset process and checking DIM EE EC CC CE value
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          (setq pass_lv1_ T)
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (and 
                (= pass_lv1_ T)
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_) )
              )
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_C-C)
          (vla-put-PrimaryUnitsPrecision ss_pre_filter_set_xx_obj_ 0)
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (command "pselect"  ss_pre_filter_set_xx_ "" )
    )
    (defun c:change_dim_xDCE ()
      (setq pass_lv1_ nil) ;for reset process and checking DIM EE EC CC CE value
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          (setq pass_lv1_ T)
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (and 
                (= pass_lv1_ T)
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_) )
              )
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_C-E)
          (vla-put-PrimaryUnitsPrecision ss_pre_filter_set_xx_obj_ 0)
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (command "pselect"  ss_pre_filter_set_xx_ "" )
    )
    (defun c:change_dim_xDEE ()

      (setq pass_lv1_ nil) ;for reset process and checking DIM EE EC CC CE value
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          (setq pass_lv1_ T)
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (and 
                (= pass_lv1_ T)
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_) )
              )
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_E-E)
          (vla-put-PrimaryUnitsPrecision ss_pre_filter_set_xx_obj_ 0)
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (command "pselect"  ss_pre_filter_set_xx_ "" )
    )
    (defun C:Switch_loop_dimstyle_swdims (  )
      ;presetting
        (setq dimstyle_list (list DIM_E-E DIM_C-E DIM_C-E DIM_C-C))
        (setq dimstyle_list_length (length dimstyle_list))
      ;
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "dimension") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "dimension") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ 0)) 
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_obj_dim_text_pos (vlax-safearray->list (vlax-variant-value (vla-get-textposition ss_pre_filter_set_xx_obj_))))
      ;
      ;presetting dynamic tag&val
        (command "ucs" "w")
        (setq ERR_ nil)
        (setq ex-value 0)
        (if (= vis_value nil)
          (progn
            (setq vis_value 0)
          )
          
        )
        (while 
          (and
            (= (vl-catch-all-error-p ERR_) nil)
          )
          (setq ERR_
            (vl-catch-all-apply
              (function
                (lambda ()
                  (setq vis_value (cond 
                                    ((getint 
                                       (strcat "\n0 = previous \n1 = next \n" (vla-get-stylename ss_pre_filter_set_xx_obj_ ) "\n<" (rtos (setq vis_value (cond (vis_value) (1.0) ) ) ) "> : " )
                                     )
                                    )
                                    (vis_value)
                                  )
                  )
                )
              )
            )
          )
          ;preloop_and_while
            (setq ex-value (+ ex-value vis_value))
            (setq ss_pre_filter_set_xx_i 0)
            (while (and 
                     (= (vl-catch-all-error-p ERR_) nil)
                     (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
                   ) 
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i)) 
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_dim_text_pos (vlax-safearray->list (vlax-variant-value (vla-get-textposition ss_pre_filter_set_xx_obj_))))
              (cond
                (;changing_case_1
                   (and
                      (= ex-value 1)
                   )
                   (progn
                     (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_E-E)
                     (vla-put-textposition ss_pre_filter_set_xx_obj_ (vlax-3d-point ss_pre_filter_set_xx_obj_dim_text_pos))
                     (princ "changing_case_1")
                   )
                )
                (;changing_case_2
                   (and
                      (= ex-value 2)
                   )
                   (progn
                     (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_C-E)
                     (vla-put-textposition ss_pre_filter_set_xx_obj_ (vlax-3d-point ss_pre_filter_set_xx_obj_dim_text_pos))
                     (princ "changing_case_2")
                   )
                )
                (;changing_case_3
                   (and
                      (= ex-value 3)
                   )
                   (progn
                     (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_E-C)
                     (vla-put-textposition ss_pre_filter_set_xx_obj_ (vlax-3d-point ss_pre_filter_set_xx_obj_dim_text_pos))
                     (princ "changing_case_3")
                   )
                )
                (;changing_case_4
                   (and
                      (= ex-value 4)
                   )
                   (progn
                     (TA:change_dim_side_ ss_pre_filter_set_xx_obj_ DIM_C-C)
                     (vla-put-textposition ss_pre_filter_set_xx_obj_ (vlax-3d-point ss_pre_filter_set_xx_obj_dim_text_pos))
                     (setq ex-value 0)
                     (princ "changing_case_4")
                   )
                )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          
        )
      ;

        
      ;
      (command "ucs" "p")
    )
    
  ;
  ;create dim
    (defun c:Dcc ()
      (_StartUndo doc)
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (setq new_ss_dim_ (ssadd   ))
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
              
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:Dcx ()
      (_StartUndo doc)
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (setq new_ss_dim_ (ssadd   ))
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-E ) ;metthod for layout for Fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
              
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:Dxc ()
      (_StartUndo doc)
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (setq new_ss_dim_ (ssadd   ))
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-E ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-E ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-C ) ;metthod for layout for Fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
              
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:Dex ()
      (_StartUndo doc)
      ; ;special for me only work with CKST Drwaing Construction 
      ;   (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
      ;   (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
      ;   (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
      ;   (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
      ;   (setq dimprec 0 )
      ; ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_v2_ ss_pre_filter_set_xx_ (list "000-GRID_LINE_DYN_V2" "000-GRID_LINE_DYN_V3" "000-GRID_LINE_DYN_V2-FOR-CC012")))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq new_ss_dim_ (ssadd))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      ))
                                        (vlax-3d-point (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      ))
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans 
                                                      (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      )
                                                      1
                                                      0
                                                    )
                                      )
                                      (vlax-3d-point (trans 
                                                      (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      )
                                                      1
                                                      0
                                                    )
                                      )
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (setq new_ss_dim_ (ssadd dim_ename new_ss_dim_))
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                    )
                  )
                  ((and (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2)))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                    )
                  )
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                ; (vlax-dump-object  dim_obj_  )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                ; (command "dimreassociate" dim_ename "" ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:De1x ()
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (if (and
                    (/= (TA:find-all-indexes ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (list 0 2 4 6 8 10 12 14 16 20 22 24 26 28 30 32 34 36 38 40)) nil)
                  )
                (progn
                  (cond
                    ((= (getvar "worlducs") 1) ;รอแก้
                      (progn
                        (vl-catch-all-apply 
                          (function 
                            (lambda () 
                              (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                            (vlax-3d-point (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                          ))
                                            (vlax-3d-point (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                          ))
                                            (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                            (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                              )
                            )
                          )
                        )
                      )
                      
                    )
                    ((= (getvar "worlducs") 0) ;รอแก้
                      (progn
                        (vl-catch-all-apply 
                          (function 
                            (lambda () 
                              (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                          (vlax-3d-point (trans 
                                                          (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                          )
                                                          1
                                                          0
                                                        )
                                          )
                                          (vlax-3d-point (trans 
                                                          (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                          )
                                                          1
                                                          0
                                                        )
                                          )
                                          (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                          (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                  ;new_blk_entlast object
                    (setq dim_ename (entlast))
                    (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                    (cond
                      ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                        (progn
                          ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                          (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                        )
                      )
                      ((and (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2)))
                        (progn
                          ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                          (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                        )
                      )
                      ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                        (progn
                          ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                          (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                        )
                      )
                    )
                    (vla-put-ScaleFactor  dim_obj_ sc )
                    ; (vlax-dump-object  dim_obj_  )
                    (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                    ; (command "dimreassociate" dim_ename "" ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                    (command "_AIDIMPREC" dimprec dim_ename "" )
                    
                  ;
                )
              )

              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
    )
    (defun c:De2x ()
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (if (and
                    (/= (TA:find-all-indexes ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (list 1 5 9 13 17)) nil)
                  )
                (progn
                  (cond
                    ((= (getvar "worlducs") 1) ;รอแก้
                      (progn
                        (vl-catch-all-apply 
                          (function 
                            (lambda () 
                              (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                            (vlax-3d-point (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                          ))
                                            (vlax-3d-point (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                          ))
                                            (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                            (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                              )
                            )
                          )
                        )
                      )
                      
                    )
                    ((= (getvar "worlducs") 0) ;รอแก้
                      (progn
                        (vl-catch-all-apply 
                          (function 
                            (lambda () 
                              (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                          (vlax-3d-point (trans 
                                                          (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                          )
                                                          1
                                                          0
                                                        )
                                          )
                                          (vlax-3d-point (trans 
                                                          (list 
                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                          )
                                                          1
                                                          0
                                                        )
                                          )
                                          (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                          (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                  ;new_blk_entlast object
                    (setq dim_ename (entlast))
                    (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                    (cond
                      ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                        (progn
                          ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                          (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                        )
                      )
                      ((and (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2)))
                        (progn
                          ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                          (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                        )
                      )
                      ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                        (progn
                          ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                          (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                        )
                      )
                    )
                    (vla-put-ScaleFactor  dim_obj_ sc )
                    ; (vlax-dump-object  dim_obj_  )
                    (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                    ; (command "dimreassociate" dim_ename "" ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                    (command "_AIDIMPREC" dimprec dim_ename "" )
                    
                  ;
                )
              )

              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
    )
    (defun c:DDex ()
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting  
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_v2_ ss_pre_filter_set_xx_ (list "000-GRID_LINE_DYN_V2" "000-GRID_LINE_DYN_V3" "000-GRID_LINE_DYN_V2-FOR-CC012" "000 - TRANSFER" )))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq new_ss_dim_ (ssadd   ))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (-  (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 1) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E") ; for layout for fameline
                    )
                  )
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E") ; for layout for fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:DDcx ()
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting  
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (setq new_ss_dim_ (ssadd   ))
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) OF_DIM )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (-  (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 1) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C") ; for layout for fameline
                    )
                  )
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C") ; for layout for fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (setq new_ss_dim_ (ssadd  dim_ename new_ss_dim_  ))
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
  ;
  ;create bot dim
    (defun c:Bcc ()
      (_StartUndo doc)
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (> (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) (- OF_DIM) )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (setq new_ss_dim_ (ssadd   ))
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
              
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:Bcx ()
      (_StartUndo doc)
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (> (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            ) 
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset) )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) (- OF_DIM) )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (setq new_ss_dim_ (ssadd   ))
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-C ) ;metthod for layout for Fameline
                    )
                  )
                  ((and 
                    (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (/= ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ nil)
                  )
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_C-E ) ;metthod for layout for Fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
              
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (_EndUndo doc)
    )
    (defun c:Bex ()
      (_StartUndo doc)
      ; ;special for me only work with CKST Drwaing Construction 
      ;   (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
      ;   (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
      ;   (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
      ;   (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
      ;   (setq dimprec 0 )
      ; ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color c55ode index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_v2_ ss_pre_filter_set_xx_ (list "000-GRID_LINE_DYN_V2" "000-GRID_LINE_DYN_V3" "000-GRID_LINE_DYN_V2-FOR-CC012")))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (> (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset) )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) (- OF_DIM) )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq new_ss_dim_ (ssadd))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      ))
                                        (vlax-3d-point (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      ))
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans 
                                                      (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      )
                                                      1
                                                      0
                                                    )
                                      )
                                      (vlax-3d-point (trans 
                                                      (list 
                                                        (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                        (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      )
                                                      1
                                                      0
                                                    )
                                      )
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (setq new_ss_dim_ (ssadd dim_ename new_ss_dim_))
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                    )
                  )
                  ((and (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2)))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                    )
                  )
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                      (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                ; (vlax-dump-object  dim_obj_  )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                ; (command "dimreassociate" dim_ename "" ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:BBex ()
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting  
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_v2_ ss_pre_filter_set_xx_ (list "000-GRID_LINE_DYN_V2" "000-GRID_LINE_DYN_V3")))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (> (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset) )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) (- OF_DIM) )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              ) 
            ;
            (setq new_ss_dim_ (ssadd   ))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (-  (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 1) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E") ; for layout for fameline
                    )
                  )
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E") ; for layout for fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
    (defun c:BBCx ()
      ;special for me only work with CKST Drwaing Construction 
        (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting  
        (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
        (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
        (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
        (setq dimprec 0 )
      ;
      ;Keep setting dimension
        (setq acadObj (vlax-get-acad-object))
        (setq doc (vla-get-ActiveDocument acadObj))
        (setq modelSpace (vla-get-ModelSpace doc))
        (setq layoutactive (vla-get-paperspace doc))
        (initget "Yes No")
        (setq ss_ ;Detect the variable's result in case of a function error
          (vl-catch-all-apply 
            (function 
              (lambda () 
                (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
              )
            )
          )
        )
        (if ;Keep setting dimension
          (and 
            (= setting_ nil)
            (= ss_ nil)
          )
          (progn
            ;set model
              (setq acadObj (vlax-get-acad-object))
              (setq doc (vla-get-ActiveDocument acadObj))
              (setq modelSpace (vla-get-ModelSpace doc))
              (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
              (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
              (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
              (setq lv_add (* lv_ 1.25))
              (setq sc (* scl 10)) ; 5 = 50 2 = 20
              (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
              (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
              (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
              (setvar "dimscale" sc )
              ;while_select_block_on_condition_
                (setq sss_ename_ nil)
                (setq Er-msg_sss_ename_ nil)
                (setq sss_obj_dimname_ nil)
              ;
            ;
          )
        )
      ;
      (setq pass_lv1_ nil)
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "INSERT") ;type of object
                                                    (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
          ;
          ;preloop_and_while ins Current UCS
            (setq ss_pre_filter_set_xx_i 0)
            (setq ss_pre_filter_set_xx_inslist_ ())
            (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
              (if (and
                    (= ss_pre_filter_set_xx_i 0)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                    ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                  )
                (progn
                  (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                  (command "ucs" "z" "270")
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              
              (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
              (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
              
              
              (if (= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
                )
                (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                      (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                      0 1
                                                    )
                )
              )
              (setq ss_pre_filter_set_xx_inslist_ (cons
                                                    (list 
                                                      ss_pre_filter_set_xx_ename_
                                                      ss_pre_filter_set_xx_obj_ins_
                                                    )
                                                    ss_pre_filter_set_xx_inslist_
                                                  )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
          ;TA:stanndard_lambda_sorting_X
            (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                (function 
                                                                  (lambda (a b) 
                                                                    (< (nth 0 (cadr a)) 
                                                                      (nth 0 (cadr b))
                                                                    )
                                                                  )
                                                                )
                                                      ) ;bigest close indent list
            )
          ;
          ;TA:stanndard_lambda_finding lowest highest Y
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                              (function 
                                                                                (lambda (a b) 
                                                                                  (> (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                                )
                                                                              )
                                                                      ) ;bigest close indent list
            )
            ;preloop_and_while
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset) )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda 
                                                                                        (a b)
                                                                                        (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                      )
                                                                                    )
                                                                            ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
              (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "H"))
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ "offset"))
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                            (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                            (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                            (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                      (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                            ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                      )
                                                                      ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                    )
                )
                (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
              )
              ;TA:stanndard_lambda_sorting
                (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                            )
                                                          )
                                      ) ;bigest close indent list
                )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) (- OF_DIM) )
                                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                    )
                                                                  
              )
            ;
          ;

          ;preloop_and_while
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                    (function 
                                                                                      (lambda (a b) 
                                                                                        (< (nth 0 (cadr a)) 
                                                                                          (nth 0 (cadr b))
                                                                                        )
                                                                                      )
                                                                                    )
                                                                          ) ;bigest close indent list
              ) 
            ;
            (setq new_ss_dim_ (ssadd   ))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
            (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (-  (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 1) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
              (cond
                ((= (getvar "worlducs") 1) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
                                        (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                        (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                  
                )
                ((= (getvar "worlducs") 0) ;รอแก้
                  (progn
                    (vl-catch-all-apply 
                      (function 
                        (lambda () 
                          (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ 1 0))
                                      (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                          )
                        )
                      )
                    )
                  )
                )
              )
              ;new_blk_entlast object
                (setq dim_ename (entlast))
                (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
                (setq dim_obj_ (vlax-ename->vla-object dim_ename))
                (command "_AIDIMPREC" dimprec dim_ename "" )
                (cond
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C") ; for layout for fameline
                    )
                  )
                  ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                    (progn
                      ; (vla-put-stylename dim_obj_ "DIM E-E") ; for model for TA
                      (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C") ; for layout for fameline
                    )
                  )
                )
                (vla-put-ScaleFactor  dim_obj_ sc )
                (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
                (command "_AIDIMPREC" dimprec dim_ename "" )
              ;
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "pselect"  new_ss_dim_ "" )
      (c:move_dim_level_mvdim)
      (_EndUndo doc)
    )
  ;
  ;dim text 
    (defun c:Dim_textmove_txmo ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (or 
            (= 
              (setq ss_pre_filter_set_xx_ (ssget "i" 
                                                (list 
                                                  (cons 0 "DIMENSION") ;type of object
                                                  ; (cons 8 "*GRID*")   ;kind of layer
                                                  ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                  ; (cons 62 1)           ;kind of color call sign with color code index
                                                )
                                          )
              )
              nil
            )
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (>= (sslength ss_pre_filter_set_xx_) 2)
                )
              )
            )
          )
          (progn
            (setq dimtext_ename_ (car (entsel "specify Object")))
          )
          (setq dimtext_ename_ (ssname ss_pre_filter_set_xx_ 0))
        )
      ;
      (command "ucs" "")
      (setq dim_angle (rad-to-deg (cdr (assoc 50 (entget dimtext_ename_)))))
      
      (setq dimtext_obj_ (vlax-ename->vla-object dimtext_ename_))
      (setq dimtext_obj_SC_ (vla-get-scalefactor dimtext_obj_ ))
      (setq dimtext_obj_text_height_ (* (/ (vla-get-textheight dimtext_obj_) 2) dimtext_obj_SC_ ) )
      (setq dimtext_obj_text_offset_ (* (vla-get-textgap dimtext_obj_) dimtext_obj_SC_) )
      (setq offset_text_to_center_ (+ dimtext_obj_text_height_ dimtext_obj_text_offset_))
      ; (setq dimtext_obj_textpos_ (TA:midpoint (cdr (assoc 13 (entget dimtext_ename_))) (cdr (assoc 10 (entget dimtext_ename_))))) ;method 1 
      (setq dimtext_obj_textpos_ (vlax-safearray->list (vlax-variant-value (vla-get-textposition dimtext_obj_)))) ;method 2 
      
      
      ; (command "point" (cdr (assoc 10 (entget dimtext_ename_))))
      ; (command "point" dimtext_obj_textpos_)
      (setvar "osmode" 0) 
      ; (command "point" (polar dimtext_obj_textpos_ (deg-to-rad dim_angle) 10))
      (command "ucs" dimtext_obj_textpos_ "")
      (command "ucs" "z" (list 0 0 0) (trans (polar dimtext_obj_textpos_ (deg-to-rad dim_angle) 10) 0 1))
      (if (and
            (>= dim_angle 180)
            (<= dim_angle 270)
          )
        (progn
          (command "ucs" "z"  180)
        )
      )
      
      ;preloop_and_while
        ; (setq angle_list_ (list 0 30 60 90 120 150 180 210 240 270 300 330))
        (setq angle_list_ (list 0  60  120 240 300      )) ;ลดองศา เพราะขี้เกียจกด spacebar บ่อยๆ 
        
        (setq Er-msg_input_length_ 1)
        (if (= input_length_ nil)
          (progn
            (setq input_length_ 5)
          )
        )
        (setq ist_run_ T)
        (setq lasted_angle_i angle_i)
        (while (and 
                (< angle_i (length angle_list_))
                (/= (wcmatch (vl-princ-to-string Er-msg_input_length_) "*error*") T)
              )
          (cond
            ((and ;1st way
              (= ist_run_ T)
              (= angle_val_ nil)
            )
              (progn
                (setq angle_i 0)
                (setq angle_val_ (TA:get-value_in-list_ (setq angle_i (+ 0 angle_i)) angle_list_))
                (setq angle_i (+ angle_i 1))
                (setq ist_run_ nil)
                (setq lasted_angle_i nil)
                
                (princ "e1")
              )
            )
            ((and ;1st way
              (= ist_run_ T)
              (/= angle_val_ nil)
              (= lasted_angle_i angle_i)
            )
              (progn
                (setq angle_i (car (TA:find-all-indexes angle_val_ angle_list_)))
                (setq angle_i (+ 1 angle_i))
                (setq ist_run_ nil)
                (setq lasted_angle_i nil)
                (princ "e2")
              )
            )
            ((and ;2nd way
              (/= angle_val_ nil)
              (= ist_run_ nil)
              (/= lasted_angle_i angle_i)
            )
              (progn
                (setq angle_val_ (TA:get-value_in-list_ angle_i  angle_list_))
                (setq angle_i (+ angle_i 1))
                ; (setq angle_i (car (TA:find-all-indexes angle_val_ angle_list_)))
                (princ "e3")
                (princ (strcat "angle_i = " (rtos angle_i 2 0)))
              )
            )
          )
          ; (setq angle_val_ (nth  angle_i angle_list_)) ;กรณีไม่อ้างอิง ค่าเดิม
          
          
          (command "AIDIMTEXTMOVE" "1" dimtext_ename_ "" (trans (polar (list 0 (- offset_text_to_center_) 0) (deg-to-rad angle_val_) input_length_) 1 1)  )
          (setq Er-msg_input_length_ 
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (setq input_length_  (cond ( (getint (strcat "\nspecify get length (angle = " (rtos angle_val_ 2 2) ")" "\n<" (rtos (setq input_length_  (cond (input_length_ ) (1.0) ) ) ) "> : " ) ) ) (input_length_ ) ) )
                )
              )
            )
          )
          
          

          ; (setq angle_i (+ angle_i 1))
          (if (>= angle_i (length angle_list_))
            (progn
              (setq angle_i 0)
              ; (setq angle_val_ 0)
            )
          )
        )
        (setq lasted_angle_i angle_i)
      ;
      (setvar "osmode" 1215)
    )
    (defun c:reset_textdim_ ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "DIMENSION") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "DIMENSION") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      (command "dimedit" "H" ss_pre_filter_set_xx_ "" )

    )
    (defun c:DimVarie_Dva ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "dimension") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "dimension") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
          (vla-put-textoverride ss_pre_filter_set_xx_obj_ "varies")
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
  ;
  ;create_grid
    (defun c:create_grid_line_creg ()
      (setq pt1 (getpoint "specify point 1"))
      (setq pt2 (getpoint "specify point 2"))
      (TA:vla-insertblock 
        "000-GRID_LINE_DYN_V2-FOR-CC012"
        (if (= (getvar "worlducs") 0)(progn (trans pt1 1 0)) pt1 )
        1
        (angle pt2 pt1)
      )
      ;new_blk_entlast object
        (setq newgird_ename (entlast))
        (setq newgird_obj_ (vlax-ename->vla-object newgird_ename))
        (LM:setdynpropvalue newgird_obj_ "H" (distance pt1 pt2))
        (LM:setdynpropvalue newgird_obj_ "OFSET" 1)
        (vla-put-layer newgird_obj_ "000 - GRID" )
        (vla-put-color newgird_obj_ 4 )
      ;
    )
  ;
  ;change dim level
    (defun c:change_dim_lvdim ()
      ;user-input
        (setq new_sc_ (cond ( (getreal (strcat "\nSpecify New Dim Scale Overall <" (rtos (setq new_sc_ (cond (new_sc_) (1.0) ) ) ) "> : " ) ) ) (new_sc_) ) )
        (setq new_lv_ (cond ( (getreal (strcat "\nSpecify New Level <" (rtos (setq new_lv_ (cond (new_lv_) (1.0) ) ) ) "> : " ) ) ) (new_lv_) ) )
      ;
      (setq pass_lv1_ nil) ;for reset process and checking DIM EE EC CC CE value
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          (setq pass_lv1_ T)
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      ; ;UCS process one time use 
      ;   (command "ucs" "world")
      ;   (command "line" 
      ;     (cdr (assoc 14 (entget ss_pre_filter_set_xx_ename_)))
      ;     (cdr (assoc 10 (entget ss_pre_filter_set_xx_ename_)))
      ;     ""
      ;   )
      ;   (command "ucs" "ob" (entlast) )
      ;   (command "ucs" "z" "270" )
      ;   (command "erase" (entlast) "")
      ; ;
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (and 
                (= pass_lv1_ T)
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_) )
              )
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))

          
          (setq dim_obj_ ss_pre_filter_set_xx_obj_)
          (TA:change_dim_scale_ ss_pre_filter_set_xx_obj_  new_lv_ new_sc_)
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (command "pselect"  ss_pre_filter_set_xx_ "" )
    )
    (defun c:change_dim_lvssdim ()
      (command "ucs" "world")
      ;user-input
        (setq new_sc_ (cond ( (getreal (strcat "\nSpecify New Dim Scale Overall <" (rtos (setq new_sc_ (cond (new_sc_) (1.0) ) ) ) "> : " ) ) ) (new_sc_) ) )
        (setq new_lv_ (cond ( (getreal (strcat "\nSpecify New Level <" (rtos (setq new_lv_ (cond (new_lv_) (1.0) ) ) ) "> : " ) ) ) (new_lv_) ) )
      ;
      (setq pass_lv1_ nil) ;for reset process and checking DIM EE EC CC CE value
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          (setq pass_lv1_ T)
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      ;UCS process one time use 
        (command "ucs" "world")
        (command "line" 
          (cdr (assoc 14 (entget ss_pre_filter_set_xx_ename_)))
          (cdr (assoc 10 (entget ss_pre_filter_set_xx_ename_)))
          ""
        )
        (command "ucs" "ob" (entlast) )
        (command "ucs" "z" "270" )
        (command "erase" (entlast) "")
      ;
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (and 
                (= pass_lv1_ T)
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_) )
              )
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
          ; (vlax-dump-object ss_pre_filter_set_xx_obj_)

          
          (setq dim_obj_ ss_pre_filter_set_xx_obj_)
          (TA:SS-change_dim_lvdim ss_pre_filter_set_xx_  new_lv_ new_sc_)
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
          
        )
      ;
      (command "pselect"  ss_pre_filter_set_xx_ "" )
    )
    (defun c:move_dim_level_mvdim ()
      ;user-input
        ; (setq new_sc_ (cond ( (getreal (strcat "\nSpecify New Dim Scale Overall <" (rtos (setq new_sc_ (cond (new_sc_) (1.0) ) ) ) "> : " ) ) ) (new_sc_) ) )
        ; (setq new_lv_ (cond ( (getreal (strcat "\nSpecify New Level <" (rtos (setq new_lv_ (cond (new_lv_) (1.0) ) ) ) "> : " ) ) ) (new_lv_) ) )
      ;
      (setq pass_lv1_ nil) ;for reset process and checking DIM EE EC CC CE value
      (if (and 
            (/= DIM_E-C nil)
            (/= DIM_C-C nil)
            (/= DIM_C-E nil)
            (/= DIM_E-E nil)
          )
        (progn
          (setq pass_lv1_ T)
          (setq ss_pre_filter_set_xx_ nil)
          ;selection_set_for_fillter_blk_name
            (if  ;pre_select_ssget_or_post_select_ssget
              (=
                (setq ss_pre_filter_set_xx_ (ssget "i"
                                                  (list
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
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
                                                    (cons 0 "Dimension") ;type of object
                                                    ; (cons 8 "*GRID*")   ;kind of layer
                                                    ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                    ; (cons 62 1)           ;kind of color call sign with color code index
                                                  )
                                            )
                )
              )
              (sslength ss_pre_filter_set_xx_)
            )
            (if (and 
                  (= (vla-get-objectname (vlax-ename->vla-object (entlast))) "AcDbRotatedDimension")
                  (= ss_pre_filter_set_xx_ nil)
                )
              (progn
                (setq ss_pre_filter_set_xx_ (ssadd) )
                (setq ss_pre_filter_set_xx_ (ssadd (entlast) ss_pre_filter_set_xx_) )
                (command "pselect"  ss_pre_filter_set_xx_ "" )
              )
            )
          ;
        )
        (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
      )
      (command "ucs" "world")
      ;loop input
        (setq ss_ nil)
        (while
          (and (/= (wcmatch (vl-princ-to-string ss_) "*error*") T))
          (setq ss_ ;Detect the variable's result in case of a function error
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (setq input_length (cond ( (getint (strcat "\nspecify get rotation\n<" (rtos (setq input_length (cond (input_length) (1.0) ) ) ) "> : " ) ) ) (input_length) ) )
                )
              )
            )
          )
          ;preloop_and_while
            (setq ss_pre_filter_set_xx_i 0)
            (while
              (and 
                (/= (wcmatch (vl-princ-to-string ss_) "*error*") T)
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
              )
              (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
              (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
              (setq Li_sc_ (vlax-get-property  ss_pre_filter_set_xx_obj_  'LinearScaleFactor ))
              (setq Fac_sc_ (vlax-get-property  ss_pre_filter_set_xx_obj_  'ScaleFactor  ))
              (cond
                (;_case_1
                  (and
                      (= input_length 1)
                  )
                  (progn
                    (TA:move_dim_level_ ss_pre_filter_set_xx_obj_ (/ Fac_sc_ 10) 1)
                    (princ "_case_1")
                  )
                )
                (;_case_2
                  (and
                      (= input_length 0)
                  )
                  (progn
                    (TA:move_dim_level_ ss_pre_filter_set_xx_obj_ (/ Fac_sc_ 10) -1)
                    (princ "_case_2")
                  )
                )
                (;_case_3
                  (and
                      (/= input_length 0)
                      (/= input_length 1)
                  )
                  (progn
                    (setq ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
                    (alert "fail")
                    (princ "_case_3")
                  )
                )
              )
              (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
            )
          ;
        )
      ;
    )
  ;
  ;move grid line
    (defun c:ortho_gridline_copy_OGLx ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
            nil
          )
          (progn
            (setq ss_pre_filter_set_xx_ (ssget ":S"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (command "ucs" "ob" ss_pre_filter_set_xx_ename_)
        (command "ucs" "z" "270")
        (setq ss_ nil)
        (while (and 
                ;  (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
                (/= (wcmatch (vl-princ-to-string ss_) "*error*") T)
              )
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
          
          (if (and 
                (= (getvar "worlducs") 0)
                (/= (wcmatch (vl-princ-to-string ss_) "*error*") T)
              ) ;รอแก้
            (progn
              (setq ss_ ;Detect the variable's result in case of a function error
                (vl-catch-all-apply 
                  (function 
                    (lambda () 
                      (setq inputpoint (getpoint "specify point 11 "))
                      (setq inputpoint (trans inputpoint 1 1))
                    )
                  )
                )
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (trans (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_) ) ) 0 1 ) )
              
              (if (/= (wcmatch (vl-princ-to-string ss_) "*error*") T)
                (progn
                  (vla-copy ss_pre_filter_set_xx_obj_   )
                  (vla-put-insertionpoint (vlax-ename->vla-object (entlast))
                                      (vlax-3d-point (trans (list 
                                                              (car inputpoint)
                                                              (car ss_pre_filter_set_xx_obj_ins_)
                                                              0 ;(car inputpoint)
                                                            ) 
                                                            1 0
                                                    )
                                      )
                  )
                )
              )
              
            )
          )
        )
        (if (and 
              (/= save-ucs nil)
              (/= save-ucs-ang nil)
            )
          (progn
            (TA:loaducs save-ucs save-ucs-ang)
          )
        )
        
      ;
    )
  ;
  ;select dim
    (defun c:last_ssset_dim_lsdim ()
      (command "pselect"  new_ss_dim_ "" )
    )
    (defun c:re-select_range_dim_resdim ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "dimension") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 0 "dimension") ;type of object
                                                ; (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      ;user input range 
        ; (setq input_high_range (cond ( (getint (strcat "\nspecify get input_high_range \n<" (rtos (setq input_high_range (cond (input_high_range) (1.0) ) ) ) "> : " ) ) ) (input_high_range) ) )
        ; (setq input_low_range (cond ( (getint (strcat "\nspecify get input_low_range \n<" (rtos (setq input_low_range (cond (input_low_range) (1.0) ) ) ) "> : " ) ) ) (input_low_range) ) )
        (setq input_high_range (cond ( (getint (strcat "\nspecify get input_high_range \n<" (rtos (setq input_high_range (cond (input_high_range) (1.0) ) ) ) "> : " ) ) ) (input_high_range) ) )
        (setq input_low_range (cond ( (getint (strcat "\nspecify get input_low_range \n<" (rtos (setq input_low_range (cond (input_low_range) (1.0) ) ) ) "> : " ) ) ) (input_low_range) ) )
      ;
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (setq new_ssset_ (ssadd))
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
          (if (and
              (<= (vla-get-measurement ss_pre_filter_set_xx_obj_) input_high_range)
              (>= (vla-get-measurement ss_pre_filter_set_xx_obj_) input_low_range)
              )
            (progn
              (setq new_ssset_ (ssadd ss_pre_filter_set_xx_ename_ new_ssset_ ))
            )
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (if (/= (sslength new_ssset_) 0 )
        (progn
          (command "pselect"  new_ssset_ "" )
        )
      )
    )
  ;
  ;select gird
    (defun c:select_grid_sssg ()
      ;selection_set_for_fillter_blk_name
        (if  ;pre_select_ssget_or_post_select_ssget
          (=
            (setq ss_pre_filter_set_xx_ (ssget "i"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                (cons 8 "*GRID*")   ;kind of layer
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
                                                (cons 8 "*GRID*")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                (cons 62 256)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (sslength ss_pre_filter_set_xx_)
        )
      ;
      (command "pselect"  ss_pre_filter_set_xx_ "" )
    )
    (defun c:insgl ()
      (setq grid_point (getpoint "specify grid line point"))
      (setq grid_point2 (getpoint grid_point "specify direction" ))
      (setq next_point_ (deg-to-rad (TA:ModifyRotation (rad-to-deg (angle grid_point grid_point2 )) 180)))
      (setq ERR_
        (vl-catch-all-apply
          (function
            (lambda ()
              (TA:vla-insertblock 
                "000-GRID_LINE_DYN_V2"
                (polar grid_point next_point_ -4)
                1
                next_point_
              )
              ;new_blk_entlast object
                (setq new_grid_ename (entlast))
                (setq new_grid_obj (vlax-ename->vla-object new_grid_ename))
                (vla-put-layer new_grid_obj "000 - GRID")
                (LM:setdynpropvalue new_grid_obj "H" (distance grid_point grid_point2))
              ;
            )
          )
        )
      )
    )
  ;
  (defun c:G+ ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              (cons 8 "*GRID*")   ;kind of layer
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
                                              (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
      (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
      (command "ucs" "ob" ss_pre_filter_set_xx_ename_)
      (command "ucs" "z" "270")
    ;
    (setq ss_ nil)
    (while
      (and (/= (wcmatch (vl-princ-to-string ss_) "*error*") T))
      (setq ss_ ;Detect the variable's result in case of a function error
        (vl-catch-all-apply 
          (function 
            (lambda () 
              (setq input_length (cond ( (getint (strcat "\nspecify get rotation\n<" (rtos (setq input_length (cond (input_length) (1.0) ) ) ) "> : " ) ) ) (input_length) ) )
            )
          )
        )
      )
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (while (and 
                (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
                (/= (wcmatch (vl-princ-to-string ss_) "*error*") T)
              )
          (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
          (setq grid_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
          (if (= (getvar "worlducs") 0) ;รอแก้
            (progn
              
              
              
              (setq grid_obj_ins_ (trans (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint grid_obj_) ) ) 0 1 ) )
              (setq grid_obj_ins_newins (list 
                                          (car grid_obj_ins_)
                                          (+ (cadr grid_obj_ins_) input_length)
                                          (caddr grid_obj_ins_)
                                        )
              )
              (vla-put-insertionpoint grid_obj_ (vlax-3d-point (trans grid_obj_ins_newins 1 0)) )
            )
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
    )
  )
  (defun c:z626_grid_line_length_GYY ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              (cons 8 "*GRID*")   ;kind of layer
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
                                              (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_v2_ ss_pre_filter_set_xx_ (list "000-GRID_LINE_DYN_V2" "000-GRID_LINE_DYN_V3" "000-GRID_LINE_DYN_V2-FOR-CC012" "000 - TRANSFER" )))
    ;
    ;preloop_and_while ins Current UCS
      (setq ss_pre_filter_set_xx_i 0)
      (setq ss_pre_filter_set_xx_inslist_ ())
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
        (if (and
              (= ss_pre_filter_set_xx_i 0)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
            )
          (progn
            (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
            (command "ucs" "z" "270")
          )
        )
        (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
        
        (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
        (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
        
        
        (if (= (getvar "worlducs") 1) ;รอแก้
          (progn
            (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
          )
          (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                0 1
                                              )
          )
        )
        (setq ss_pre_filter_set_xx_inslist_ (cons
                                              (list 
                                                ss_pre_filter_set_xx_ename_
                                                ss_pre_filter_set_xx_obj_ins_
                                              )
                                              ss_pre_filter_set_xx_inslist_
                                            )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    ;TA:stanndard_lambda_sorting_X
      (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 0 (cadr a)) 
                                                                (nth 0 (cadr b))
                                                              )
                                                            )
                                                          )
                                                ) ;bigest close indent list
      )
    ;
    ;input length process
      (setq ss_pre_filter_set_xx_inslist_sorted_X_ename_ (car (nth 0 ss_pre_filter_set_xx_inslist_sorted_X_)))
      (setq ss_pre_filter_set_xx_inslist_sorted_X_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_X_ename_))
      (setq ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_inslist_sorted_X_obj_))))
      (setq get-point_ (getpoint (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1) ))
      (setq get-dist_ (distance (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1) 
                                  (list 
                                    (car (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1))                                           
                                    (cadr get-point_)                                           
                                    (caddr (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1))                                           
                                  )
                      )
      )
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (LM:setdynpropvalue ss_pre_filter_set_xx_obj_ "H" get-dist_)
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  )
  
  (defun c:z626_grid_line_length_gff ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              (cons 8 "*GRID*")   ;kind of layer
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
                                              (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_v2_ ss_pre_filter_set_xx_ (list "000-GRID_LINE_DYN_V2" "000-GRID_LINE_DYN_V2-FOR-CC012" "000 - TRANSFER")))
    ;
    ;preloop_and_while ins Current UCS
      (setq ss_pre_filter_set_xx_i 0)
      (setq ss_pre_filter_set_xx_inslist_ ())
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
        (if (and
              (= ss_pre_filter_set_xx_i 0)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
              ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
            )
          (progn
            (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
            (command "ucs" "z" "270")
          )
        )
        (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
        
        (setq ss_pre_filter_set_xx_obj_H (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "H"))
        (setq ss_pre_filter_set_xx_obj_offset (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "offset"))
        
        
        (if (= (getvar "worlducs") 1) ;รอแก้
          (progn
            (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
          )
          (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                0 1
                                              )
          )
        )
        (setq ss_pre_filter_set_xx_inslist_ (cons
                                              (list 
                                                ss_pre_filter_set_xx_ename_
                                                ss_pre_filter_set_xx_obj_ins_
                                              )
                                              ss_pre_filter_set_xx_inslist_
                                            )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    ;TA:stanndard_lambda_sorting_X
      (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                          (function 
                                                            (lambda (a b) 
                                                              (< (nth 0 (cadr a)) 
                                                                (nth 0 (cadr b))
                                                              )
                                                            )
                                                          )
                                                ) ;bigest close indent list
      )
    ;
    ;input length process
      (setq ss_pre_filter_set_xx_inslist_sorted_X_ename_ (car (nth 0 ss_pre_filter_set_xx_inslist_sorted_X_)))
      (setq ss_pre_filter_set_xx_inslist_sorted_X_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_X_ename_))
      (setq ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_inslist_sorted_X_obj_))))
      (setq get-point_ (getpoint (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1) ))
      (setq get-dist_ (distance (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1) 
                                  (list 
                                    (car (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1))                                           
                                    (cadr get-point_)                                           
                                    (caddr (trans ss_pre_filter_set_xx_inslist_sorted_X_obj_ins_ 0 1))                                           
                                  )
                      )
      )
    ;
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (LM:setdynpropvalue ss_pre_filter_set_xx_obj_ "offset" get-dist_)
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    (command "pselect"  ss_pre_filter_set_xx_ "" )
  )
  (defun c:grid_line_slope_length_gslope ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
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
                                              ; (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
    ;
    (setq line_ename_ (car (entsel "specify Object")))
    (setq line_obj_ (vlax-ename->vla-object line_ename_))
    (setq line_obj_start_end_pt_ (list
                                    (setq line_obj_startpt_ (vlax-safearray->list
                                                               (vlax-variant-value ( vla-get-startpoint line_obj_ ))
                                                             )
                                    )
                                    (setq line_obj_endpt_ (vlax-safearray->list
                                                              (vlax-variant-value ( vla-get-endpoint line_obj_ ))
                                                           )
                                    )
                                  )
    )
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i)) 
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_obj_inters_ (car (LM:intersections ss_pre_filter_set_xx_obj_ line_obj_ acextendnone  )))
        (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
        (setq ss_pre_filter_set_xx_obj_gridline_length_ (LM:setdynpropvalue ss_pre_filter_set_xx_obj_ "H" (distance ss_pre_filter_set_xx_obj_inters_ ss_pre_filter_set_xx_obj_ins_)))
        
        
        
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  )
  (defun c:grid_line_slope_offset_ofslope ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
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
                                              ; (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
      (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000-GRID_LINE_DYN_V2"))
    ;
    (setq line_ename_ (car (entsel "specify Object")))
    (setq line_obj_ (vlax-ename->vla-object line_ename_))
    (setq line_obj_start_end_pt_ (list
                                    (setq line_obj_startpt_ (vlax-safearray->list
                                                               (vlax-variant-value ( vla-get-startpoint line_obj_ ))
                                                             )
                                    )
                                    (setq line_obj_endpt_ (vlax-safearray->list
                                                              (vlax-variant-value ( vla-get-endpoint line_obj_ ))
                                                           )
                                    )
                                  )
    )
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i)) 
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_obj_inters_ (car (LM:intersections ss_pre_filter_set_xx_obj_ line_obj_ acextendnone  )))
        (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
        (setq ss_pre_filter_set_xx_obj_gridline_length_ (LM:setdynpropvalue ss_pre_filter_set_xx_obj_ "offset" (distance ss_pre_filter_set_xx_obj_inters_ ss_pre_filter_set_xx_obj_ins_)))
        
        
        
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
  )
;
;special_dimfor-block
  (defun c:CEX ()
    ; ;special for me only work with CKST Drwaing Construction 
    ;   (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
    ;   (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
    ;   (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
    ;   (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
    ;   (setq dimprec 0 )
    ; ;
    ;Keep setting dimension
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq modelSpace (vla-get-ModelSpace doc))
      (setq layoutactive (vla-get-paperspace doc))
      (initget "Yes No")
      (setq ss_ ;Detect the variable's result in case of a function error
        (vl-catch-all-apply 
          (function 
            (lambda () 
              (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
            )
          )
        )
      )
      (if ;Keep setting dimension
        (and 
          (= setting_ nil)
          (= ss_ nil)
        )
        (progn
          ;set model
            (setq acadObj (vlax-get-acad-object))
            (setq doc (vla-get-ActiveDocument acadObj))
            (setq modelSpace (vla-get-ModelSpace doc))
            (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
            (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
            (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
            (setq lv_add (* lv_ 1.25))
            (setq sc (* scl 10)) ; 5 = 50 2 = 20
            (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
            (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
            (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
            (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
            (setvar "dimscale" sc )
            ;while_select_block_on_condition_
              (setq sss_ename_ nil)
              (setq Er-msg_sss_ename_ nil)
              (setq sss_obj_dimname_ nil)
            ;
          ;
        )
      )
    ;
    (setq pass_lv1_ nil)
    (_StartUndo doc)
    (if (and 
          (/= DIM_E-C nil)
          (/= DIM_C-C nil)
          (/= DIM_C-E nil)
          (/= DIM_E-E nil)
        )
      (progn
        ;selection_set_for_fillter_blk_name
          (if  ;pre_select_ssget_or_post_select_ssget
            (=
              (setq ss_pre_filter_set_xx_ (ssget "i"
                                                (list
                                                  (cons 0 "INSERT") ;type of object
                                                  ; (cons 8 "*GRID*")   ;kind of layer
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
                                                  (cons 8 "000 - GRID,001 - ASCESSORIES")   ;kind of layer
                                                  ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                  ; (cons 62 1)           ;kind of color call sign with color code index
                                                )
                                          )
              )
            )
            (sslength ss_pre_filter_set_xx_)
          )
          (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - DYNAMIC_COMBINE+VIEW_ASSCESSORIES_FAMELINE_GALV.BRACKET_FITTING_U-PROFILE_CC-01-4_COMBINE_VIEW"))
        ;
        ;preloop_and_while ins Current UCS
          (setq ss_pre_filter_set_xx_i 0)
          (setq ss_pre_filter_set_xx_inslist_ ())
          (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
            (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
            (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
            (setq ss_pre_filter_set_xx_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_obj_)))
            (if (and
                  (= ss_pre_filter_set_xx_i 0)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                )
              (progn
                (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                (command "ucs" "z" "270")
              )
            )
            (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
            
            (setq ss_pre_filter_set_xx_obj_H 0)
            (setq ss_pre_filter_set_xx_obj_offset -50)
            
            
            (if (= (getvar "worlducs") 1) ;รอแก้
              (progn
                (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                    (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_)))
                                                    0 1
                                                  )
              )
            )
            (setq ss_pre_filter_set_xx_inslist_ (cons
                                                  (list 
                                                    ss_pre_filter_set_xx_ename_
                                                    ss_pre_filter_set_xx_obj_ins_
                                                  )
                                                  ss_pre_filter_set_xx_inslist_
                                                )
            )
            (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
          )
        ;
        ;TA:stanndard_lambda_sorting_X
          (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                              (function 
                                                                (lambda (a b) 
                                                                  (< (nth 0 (cadr a)) 
                                                                    (nth 0 (cadr b))
                                                                  )
                                                                )
                                                              )
                                                    ) ;bigest close indent list
          )
        ;
        ;TA:stanndard_lambda_finding lowest highest Y
          (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                            (function 
                                                                              (lambda (a b) 
                                                                                (> (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                              )
                                                                            )
                                                                    ) ;bigest close indent list
          )
          ;preloop_and_while
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
            (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_obj_H)
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset ss_pre_filter_set_xx_obj_offset)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                          (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                          (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                        )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                    (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                          ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                    )
                                                                    ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                  )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
            )
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                  (function 
                                                                                    (lambda 
                                                                                      (a b)
                                                                                      (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                    )
                                                                                  )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
            (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
            (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_obj_H)
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset ss_pre_filter_set_xx_obj_offset)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                          (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                          (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                        )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                    (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                          ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                    )
                                                                    ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                  )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
            )
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                        (function 
                                                          (lambda (a b) 
                                                            (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                          )
                                                        )
                                    ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                    (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                    (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) (- OF_DIM) )
                                                                    (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                  )
                                                                
            )
          ;
        ;

        ;preloop_and_while
          ;TA:stanndard_lambda_sorting
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                  (function 
                                                                                    (lambda (a b) 
                                                                                        (> (nth 0 (cadr a)) 
                                                                                        (nth 0 (cadr b))
                                                                                      )
                                                                                    )
                                                                                  )
                                                                        ) ;bigest close indent list
            )
          ;
          (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
          (setq new_ss_dim_ (ssadd))
          (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (vla-get-rotation ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (cond
              ((= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                    ))
                                      (vlax-3d-point (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                    ))
                                      (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                        )
                      )
                    )
                  )
                )
                
              )
              ((= (getvar "worlducs") 0) ;รอแก้
                (progn
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                    (vlax-3d-point (trans 
                                                    (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                    )
                                                    1
                                                    0
                                                  )
                                    )
                                    (vlax-3d-point (trans 
                                                    (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                    )
                                                    1
                                                    0
                                                  )
                                    )
                                    (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                    (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                        )
                      )
                    )
                  )
                )
              )
            )
            ;new_blk_entlast object
              (setq dim_ename (entlast))
              (setq dim_obj_ (vlax-ename->vla-object dim_ename))
              (cond
                ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                  (progn
                    ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                    (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                  )
                )
                ((and (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2)))
                  (progn
                    ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                    (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                  )
                )
                ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                  (progn
                    ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                    (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                  )
                )
              )
              (vla-put-ScaleFactor  dim_obj_ sc )
              ; (vlax-dump-object  dim_obj_  )
              (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
              ; (command "dimreassociate" dim_ename "" ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
              (command "_AIDIMPREC" dimprec dim_ename "" )
              
              (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
          )
        ;
      )
      (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
    )
    (_EndUndo doc)
    (command "pselect"  new_ss_dim_ "" )
  )
  (defun c:Cdim ()
    ; ;special for me only work with CKST Drwaing Construction 
    ;   (setq DIM_E-C "FAMELINE-CKST_E-C") ;Ref from C:dimsetting 
    ;   (setq DIM_C-C "FAMELINE-CKST_C-C") ;Ref from C:dimsetting 
    ;   (setq DIM_C-E "FAMELINE-CKST_C-E") ;Ref from C:dimsetting 
    ;   (setq DIM_E-E "FAMELINE-CKST_E-E") ;Ref from C:dimsetting 
    ;   (setq dimprec 0 )
    ; ;
    ;Keep setting dimension
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq modelSpace (vla-get-ModelSpace doc))
      (setq layoutactive (vla-get-paperspace doc))
      (initget "Yes No")
      (setq ss_ ;Detect the variable's result in case of a function error
        (vl-catch-all-apply 
          (function 
            (lambda () 
              (setq setting_ (not (eq "No" (getkword "\nKeep setting dimension ? \nSpecify Dim Scale Overall [Yes/No] <Y>: " ))))
            )
          )
        )
      )
      (if ;Keep setting dimension
        (and 
          (= setting_ nil)
          (= ss_ nil)
        )
        (progn
          ;set model
            (setq acadObj (vlax-get-acad-object))
            (setq doc (vla-get-ActiveDocument acadObj))
            (setq modelSpace (vla-get-ModelSpace doc))
            (setq scl (cond ( (getreal (strcat "\nSpecify Dim Scale Overall <" (rtos (setq scl (cond (scl) (1.0) ) ) ) "> : " ) ) ) (scl) ) )
            (setq lv_ (cond ( (getreal (strcat "\nSpecify Level <" (rtos (setq lv_ (cond (lv_) (1.0) ) ) ) "> : " ) ) ) (lv_) ) )
            (setq dimprec (cond ( (getreal (strcat "\nSpecify _AIDIMPREC <" (rtos (setq dimprec (cond (dimprec) (1.0) ) ) ) "> : " ) ) ) (dimprec) ) )
            (setq lv_add (* lv_ 1.25))
            (setq sc (* scl 10)) ; 5 = 50 2 = 20
            (setq of_point 4.5); OF_DIM OFFSET FROM pt2 = 6 mm.
            (setq hi_point 4); OF_DIM OFFSET FROM pt2 = 6 mm.
            (setq OF_DIM (*(* (* scl 1) of_point) lv_add))
            (setq HI_DIM (*(* (* scl 1) hi_point) lv_add))
            (setvar "dimscale" sc )
            ;while_select_block_on_condition_
              (setq sss_ename_ nil)
              (setq Er-msg_sss_ename_ nil)
              (setq sss_obj_dimname_ nil)
            ;
          ;
        )
      )
    ;
    (setq pass_lv1_ nil)
    (_StartUndo doc)
    (if (and 
          (/= DIM_E-C nil)
          (/= DIM_C-C nil)
          (/= DIM_C-E nil)
          (/= DIM_E-E nil)
        )
      (progn
        (setq ss_pre_filter_set_xx_ (ssadd))
        (setq pt1 (getpoint "specify point" ))
        (setq pt2 (getpoint pt1 "specify point" ))
        (command "point" pt1)
        (setq ss_pre_filter_set_xx_ (ssadd (entlast) ss_pre_filter_set_xx_ ))
        (command "point" pt2)
        (setq ss_pre_filter_set_xx_ (ssadd (entlast) ss_pre_filter_set_xx_ ))
        ;preloop_and_while ins Current UCS
          (setq ss_pre_filter_set_xx_i 0)
          (setq ss_pre_filter_set_xx_inslist_ ())
          (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
            (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
            (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
            (if (and
                  (= ss_pre_filter_set_xx_i 0)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "0.00000") T)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "90.00000") T)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "180.00000") T)
                  ; (= (/= (rtos ss_pre_filter_set_xx_obj_rotation 2 5) "270.00000") T)
                )
              (progn
                (command "ucs" "ob" ss_pre_filter_set_xx_ename_ )
                (command "ucs" "z" "270")
              )
            )
            (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-coordinates ss_pre_filter_set_xx_obj_))))
            
            (setq ss_pre_filter_set_xx_obj_H 0)
            (setq ss_pre_filter_set_xx_obj_offset 0)
            
            
            (if (= (getvar "worlducs") 1) ;รอแก้
              (progn
                (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-coordinates ss_pre_filter_set_xx_obj_))))
              )
              (setq ss_pre_filter_set_xx_obj_ins_ (trans
                                                    (vlax-safearray->list (vlax-variant-value (vla-get-coordinates ss_pre_filter_set_xx_obj_)))
                                                    0 1
                                                  )
              )
            )
            (setq ss_pre_filter_set_xx_inslist_ (cons
                                                  (list 
                                                    ss_pre_filter_set_xx_ename_
                                                    ss_pre_filter_set_xx_obj_ins_
                                                  )
                                                  ss_pre_filter_set_xx_inslist_
                                                )
            )
            (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
          )
        ;
        ;TA:stanndard_lambda_sorting_X
          (setq ss_pre_filter_set_xx_inslist_sorted_X_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                              (function 
                                                                (lambda (a b) 
                                                                  (< (nth 0 (cadr a)) 
                                                                    (nth 0 (cadr b))
                                                                  )
                                                                )
                                                              )
                                                    ) ;bigest close indent list
          )
        ;
        ;TA:stanndard_lambda_finding lowest highest Y
          (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ (vl-sort ss_pre_filter_set_xx_inslist_  ;bigest open indent list
                                                                            (function 
                                                                              (lambda (a b) 
                                                                                (> (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                                              )
                                                                            )
                                                                    ) ;bigest close indent list
          )
          ;preloop_and_while
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ ())
            (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;highest_Y
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_obj_H)
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset ss_pre_filter_set_xx_obj_offset)
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y (list 
                                                                          (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          (+ (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                          (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                        )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (cons 
                                                                    (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                          ss_pre_filter_set_xx_inslist_sorted_highest_newins_Y
                                                                    )
                                                                    ss_pre_filter_set_xx_inslist_sorted_highest_Y_
                                                                  )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
            )
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                  (function 
                                                                                    (lambda 
                                                                                      (a b)
                                                                                      (> (nth 1 ( cadr a ) ) (nth 1 ( cadr b ) ) )
                                                                                    )
                                                                                  )
                                                                          ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i 0)
            (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ ())
            (while (< ss_pre_filter_set_xx_inslist_sorted_find_Y_i (length ss_pre_filter_set_xx_inslist_sorted_find_Y_)) ;loweset_Y
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_find_Y_i ss_pre_filter_set_xx_inslist_sorted_find_Y_)))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_))
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H ss_pre_filter_set_xx_obj_H)
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset ss_pre_filter_set_xx_obj_offset)
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y (list 
                                                                          (+ (car ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                          (- ( - (cadr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_H) ss_pre_filter_set_xx_inslist_sorted_find_Y_obj_offset )
                                                                          (+ (caddr ss_pre_filter_set_xx_inslist_sorted_find_Y_ins_) 0)
                                                                        )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_ (cons 
                                                                    (list ss_pre_filter_set_xx_inslist_sorted_find_Y_ename_ 
                                                                          ss_pre_filter_set_xx_inslist_sorted_lowest_newins_Y
                                                                    )
                                                                    ss_pre_filter_set_xx_inslist_sorted_lowest_Y_
                                                                  )
              )
              (setq ss_pre_filter_set_xx_inslist_sorted_find_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_find_Y_i 1))
            )
            ;TA:stanndard_lambda_sorting
              (setq ss_pre_filter_set_xx_inslist_sorted_lowest_Y_sorted_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_lowest_Y_  ;bigest open indent list
                                                        (function 
                                                          (lambda (a b) 
                                                            (< (nth 1 (cadr a ) ) (nth 1 (cadr b ) ) )
                                                          )
                                                        )
                                    ) ;bigest close indent list
              )
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ (cadr (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_  (list 
                                                                    (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) 0 )
                                                                    (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_) (- 3) )
                                                                    (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_))
                                                                  )
                                                                
            )
          ;
        ;

        ;preloop_and_while
          ;TA:stanndard_lambda_sorting
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ (vl-sort ss_pre_filter_set_xx_inslist_sorted_highest_Y_  ;bigest open indent list
                                                                                  (function 
                                                                                    (lambda (a b) 
                                                                                        (> (nth 0 (cadr a)) 
                                                                                        (nth 0 (cadr b))
                                                                                      )
                                                                                    )
                                                                                  )
                                                                        ) ;bigest close indent list
            )
          ;
          (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
          (setq new_ss_dim_ (ssadd))
          (while (< ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_ (car (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation (rad-to-deg (angle pt1 pt2)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ (cadr (nth  ss_pre_filter_set_xx_inslist_sorted_highest_Y_i ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_ (cadr (nth  (+ 1 ss_pre_filter_set_xx_inslist_sorted_highest_Y_i) ss_pre_filter_set_xx_inslist_sorted_highest_Y_)))
            (cond
              ((= (getvar "worlducs") 1) ;รอแก้
                (progn
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                      (vlax-3d-point (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                    ))
                                      (vlax-3d-point (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                    ))
                                      (vlax-3d-point ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_)
                                      (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                        )
                      )
                    )
                  )
                )
                
              )
              ((= (getvar "worlducs") 0) ;รอแก้
                (progn
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                    (vlax-3d-point (trans 
                                                    (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_) 0 )
                                                    )
                                                    1
                                                    0
                                                  )
                                    )
                                    (vlax-3d-point (trans 
                                                    (list 
                                                      (+ (car ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (cadr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                      (+ (caddr ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_) 0 )
                                                    )
                                                    1
                                                    0
                                                  )
                                    )
                                    (vlax-3d-point (trans ss_pre_filter_set_xx_inslist_sorted_highest_Y_val_ 1 0))
                                    (deg-to-rad (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_obj_rotation 90 ))
                        )
                      )
                    )
                  )
                )
              )
            )
            ;new_blk_entlast object
              (setq dim_ename (entlast))
              (setq dim_obj_ (vlax-ename->vla-object dim_ename))
              (cond
                ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
                  (progn
                    ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                    (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                  )
                )
                ((and (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2)))
                  (progn
                    ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                    (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                  )
                )
                ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
                  (progn
                    ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                    (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
                  )
                )
              )
              (vla-put-ScaleFactor  dim_obj_ sc )
              ; (vlax-dump-object  dim_obj_  )
              (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
              ; (command "dimreassociate" dim_ename "" ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
              (command "_AIDIMPREC" dimprec dim_ename "" )
              
              (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
            ;
            (setq ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (+ ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 1))
          )
        ;
      )
      (alert "please go to C:Dimsettin /nand set DIM EE EC CC CE")
    )
    (_EndUndo doc)
    (command "erase" ss_pre_filter_set_xx_  "" )
    (command "pselect"  new_ss_dim_ "" )
  )
  (defun c:C01L ()
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                              ; (cons 8 "*GRID*")   ;kind of layer
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
                                              ; (cons 8 "*GRID*")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
    ;
    (setq ss_pre_filter_set_xx_ (TA:EF_Filter_ss_set_ ss_pre_filter_set_xx_ "000 - DYNAMIC_COMBINE+VIEW_ASSCESSORIES_FAMELINE_GALV.BRACKET_FITTING_U-PROFILE_CC-01-4_COMBINE_VIEW"))
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (setq new_ss_dim_ (ssadd))
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_obj_ro (vla-get-rotation  ss_pre_filter_set_xx_obj_))
        (setq ss_pre_filter_set_xx_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint ss_pre_filter_set_xx_obj_))))
        
        (setq staterblk_obj_dist_array_length (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "array_length"))
        (setq staterblk_obj_dist_fragment_length (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "fragment_length"))
        (setq staterblk_obj_dist_fragment_start (LM:getdynpropvalue ss_pre_filter_set_xx_obj_ "fragment_start"))
        (if (= ( LM:getdynpropvalue ss_pre_filter_set_xx_obj_  "view") "7_dynamic_length_view")
          (progn
            (setq staterblk_obj_dist_sum_ staterblk_obj_dist_fragment_start)
          )
          (setq staterblk_obj_dist_sum_ (+ staterblk_obj_dist_array_length staterblk_obj_dist_fragment_length))
        )
        (cond
          ((= (getvar "worlducs") 1) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                  (vlax-3d-point ss_pre_filter_set_xx_obj_ins_)
                                  (vlax-3d-point (polar ss_pre_filter_set_xx_obj_ins_ (deg-to-rad (rad-to-deg ss_pre_filter_set_xx_obj_ro)) staterblk_obj_dist_sum_)) 
                                  (vlax-3d-point (polar ss_pre_filter_set_xx_obj_ins_ (deg-to-rad 180) 150))
                                  (deg-to-rad (rad-to-deg ss_pre_filter_set_xx_obj_ro))
                    )
                  )
                )
              )
            )
            
          )
          ((= (getvar "worlducs") 0) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                (vlax-3d-point (trans ss_pre_filter_set_xx_obj_ins_ 1 0))
                                (vlax-3d-point (trans (polar ss_pre_filter_set_xx_obj_ins_ (deg-to-rad 90) staterblk_obj_dist_sum_) 1 0))
                                (vlax-3d-point (trans (polar ss_pre_filter_set_xx_obj_ins_ (deg-to-rad 0) 3) 1 0))
                                (deg-to-rad 90)
                    )
                  )
                )
              )
            )
          )
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (cond
            ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0)
              (progn
                ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
              )
            )
            ((and (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i 0) (= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2)))
              (progn
                ; (vla-put-stylename dim_obj_ "DIM E-C") ;metthod for model for TA
                (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
              )
            )
            ((= ss_pre_filter_set_xx_inslist_sorted_highest_Y_i (- (length ss_pre_filter_set_xx_inslist_sorted_highest_Y_) 2))
              (progn
                ; (vla-put-stylename dim_obj_ "DIM C-E") ;metthod for model for TA
                (vla-put-stylename dim_obj_ DIM_E-E) ;metthod for layout for Fameline
              )
            )
          )
          (vla-put-ScaleFactor  dim_obj_ 500 )
          ; (vlax-dump-object  dim_obj_  )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          ; (command "dimreassociate" dim_ename "" ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_cur-ins_ ss_pre_filter_set_xx_inslist_sorted_highest_Y_ename_next-ins_)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
        ;
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    
  )
  (defun c:starter_dim_stdim ()
    ;presetting
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq modelSpace (vla-get-ModelSpace doc))
      (setq layoutactive (vla-get-paperspace doc))
    ;
    (setq new_ss_dim_ (ssadd   ))
    (setq staterblk_ename_ (car (entsel "specify Object")))
    (setq staterblk_obj_ (vlax-ename->vla-object staterblk_ename_))
    (setq staterblk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint staterblk_obj_))))
    (setq staterblk_obj_rotation_ (vla-get-rotation staterblk_obj_))
    ; (setq staterblk_obj_dist_1 (LM:getdynpropvalue staterblk_obj_ "distance1"))
    (setq staterblk_obj_dist_2 (LM:getdynpropvalue staterblk_obj_ "distance2"))
    ; (setq staterblk_obj_dist_3 (LM:getdynpropvalue staterblk_obj_ "distance3"))
    (setq staterblk_obj_dist_4 (LM:getdynpropvalue staterblk_obj_ "distance4"))
    ; ;dist_1
    ;   (cond
    ;     ((= (getvar "worlducs") 1) ;รอแก้
    ;         (progn
    ;           (vl-catch-all-apply 
    ;             (function 
    ;               (lambda () 
    ;                 (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
    ;                               (vlax-3d-point staterblk_obj_ins_)
    ;                               (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 180) staterblk_obj_dist_1))
    ;                               (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 90) 3))
    ;                               (deg-to-rad 180)
    ;                 )
    ;               )
    ;             )
    ;           )
    ;         )
    ;       )
    ;       ((= (getvar "worlducs") 0) ;รอแก้
    ;         (progn
    ;           (vl-catch-all-apply 
    ;             (function 
    ;               (lambda () 
    ;                 (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
    ;                             (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
    ;                             (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) staterblk_obj_dist_1) 1 0))
    ;                             (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 90) 3) 1 0))
    ;                             (deg-to-rad 180)
    ;                 )
    ;               )
    ;             )
    ;           )
    ;         )
    ;       )
    ;   )
    ;   ;new_blk_entlast object
    ;     (setq dim_ename (entlast))
    ;     (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
    ;     (setq dim_obj_ (vlax-ename->vla-object dim_ename))
    ;     (command "_AIDIMPREC" dimprec dim_ename "" )
    ;     (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
    ;     (vla-put-ScaleFactor  dim_obj_ (/ sc 2) )
    ;     (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
    ;     (vla-put-PrimaryUnitsPrecision dim_obj_ 2)
    ;     ; (command "_AIDIMPREC" dimprec dim_ename "" )
    ;   ;
    ; ;
    ;dist_2
      (cond
        ((= (getvar "worlducs") 1) ;รอแก้
          (progn
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                (vlax-3d-point staterblk_obj_ins_)
                                (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 90) staterblk_obj_dist_2))
                                (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 180) 3))
                                (deg-to-rad 90)
                  )
                )
              )
            )
          )
          
        )
        ((= (getvar "worlducs") 0) ;รอแก้
          (progn
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                              (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                              (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 90) staterblk_obj_dist_2) 1 0))
                              (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 0) 3) 1 0))
                              (deg-to-rad 90)
                  )
                )
              )
            )
          )
        )
      )
      ;new_blk_entlast object
        (setq dim_ename (entlast))
        (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
        (setq dim_obj_ (vlax-ename->vla-object dim_ename))
        (command "_AIDIMPREC" dimprec dim_ename "" )
        (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
        (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
        (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
        (vla-put-PrimaryUnitsPrecision dim_obj_ 2)
        ; (command "_AIDIMPREC" dimprec dim_ename "" )
      ;
    ;
    ; ;dist_3
    ;   (cond
    ;     ((= (getvar "worlducs") 1) ;รอแก้
    ;       (progn
    ;         (vl-catch-all-apply 
    ;           (function 
    ;             (lambda () 
    ;               (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
    ;                             (vlax-3d-point staterblk_obj_ins_)
    ;                             (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 0) staterblk_obj_dist_3))
    ;                             (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 270) 3))
    ;                             (deg-to-rad 0)
    ;               )
    ;             )
    ;           )
    ;         )
    ;       )
          
    ;     )
    ;     ((= (getvar "worlducs") 0) ;รอแก้
    ;       (progn
    ;         (vl-catch-all-apply 
    ;           (function 
    ;             (lambda () 
    ;               (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
    ;                           (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
    ;                           (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 0) staterblk_obj_dist_3) 1 0))
    ;                           (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 270) 3) 1 0))
    ;                           (deg-to-rad 0)
    ;               )
    ;             )
    ;           )
    ;         )
    ;       )
    ;     )
    ;   )
    ;   ;new_blk_entlast object
    ;     (setq dim_ename (entlast))
    ;     (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
    ;     (setq dim_obj_ (vlax-ename->vla-object dim_ename))
    ;     (command "_AIDIMPREC" dimprec dim_ename "" )
    ;     (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
    ;     (vla-put-ScaleFactor  dim_obj_ (/ sc 2) )
    ;     (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
    ;     (vla-put-PrimaryUnitsPrecision dim_obj_ 2)
    ;     ; (command "_AIDIMPREC" dimprec dim_ename "" )
    ;   ;
    ; ;
    ;dist_4
      (cond
        ((= (getvar "worlducs") 1) ;รอแก้
          (progn
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                (vlax-3d-point staterblk_obj_ins_)
                                (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 270) staterblk_obj_dist_4))
                                (vlax-3d-point (polar staterblk_obj_ins_ (deg-to-rad 180) 3))
                                (deg-to-rad 90)
                  )
                )
              )
            )
          )
          
        )
        ((= (getvar "worlducs") 0) ;รอแก้
          (progn
            (vl-catch-all-apply 
              (function 
                (lambda () 
                  (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                              (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                              (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 270) staterblk_obj_dist_4) 1 0))
                              (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) 3) 1 0))
                              (deg-to-rad 90)
                  )
                )
              )
            )
          )
        )
      )
      ;new_blk_entlast object
        (setq dim_ename (entlast))
        (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
        (setq dim_obj_ (vlax-ename->vla-object dim_ename))
        (command "_AIDIMPREC" dimprec dim_ename "" )
        (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
        (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
        (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
        (vla-put-PrimaryUnitsPrecision dim_obj_ 2)
        ; (command "_AIDIMPREC" dimprec dim_ename "" )
      ;
    ;
  )
  (defun c:starter_dim_stdimss2 ()
    (command "ucs" "W")
    ;presetting
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq modelSpace (vla-get-ModelSpace doc))
      (setq layoutactive (vla-get-paperspace doc))
      (setq sc 10)
    ;
      (setq new_ss_dim_ (ssadd   ))
      (setq staterblk_ename_ (car (entsel "specify Object")))
      (setq staterblk_obj_ (vlax-ename->vla-object staterblk_ename_))
      (setq staterblk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint staterblk_obj_))))
      (setq staterblk_obj_rotation_ (rad-to-deg (vla-get-rotation staterblk_obj_)))
      ; (setq staterblk_obj_dist_1 (LM:getdynpropvalue staterblk_obj_ "distance1"))
      (setq staterblk_obj_dist_2 (LM:getdynpropvalue staterblk_obj_ "distance2"))
      ; (setq staterblk_obj_dist_3 (LM:getdynpropvalue staterblk_obj_ "distance3"))
      (setq staterblk_obj_dist_4 (LM:getdynpropvalue staterblk_obj_ "distance4"))
    ;
    (if (> staterblk_obj_dist_2 3)
      (progn
        (cond
          ((and (= (getvar "worlducs") 1) (> staterblk_obj_dist_2 3)) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                  (vlax-3d-point (setq new_pt (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) (* 5.625 0))))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) staterblk_obj_dist_2))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) -5.625 ))
                                  (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ -90))
                    )
                  )
                )
              )
            )
            
          )
          ((= (getvar "worlducs") 0) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) 3) 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) 3) 1 0))
                                (deg-to-rad 90)
                    )
                  )
                )
              )
            )
          )
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    (if (> staterblk_obj_dist_4 3)
      (progn
        (cond
          ((and (= (getvar "worlducs") 1) (> staterblk_obj_dist_4 3)) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                  (vlax-3d-point (setq new_pt (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) (* 5.625 0))))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 270)) staterblk_obj_dist_4))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) -5.625)) 
                                     
                                  (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ -90))
                    )
                  )
                )
              )
            )
            
          )
          ((= (getvar "worlducs") 0) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if (/= (getvar "ctab") "Model") (progn layoutactive) modelSpace) 
                                (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) 3) 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) 3) 1 0))
                                (deg-to-rad 90)
                    )
                  )
                )
              )
            )
          )
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    ;
    ;
    ;
    (command "pselect"  new_ss_dim_ "" )
    (c:move_dim_level_mvdim)
    (command "ucs" "W")
  )
  (defun c:starter_dim_stdimss3 ()
    (command "ucs" "W")
    ;presetting
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq modelSpace (vla-get-ModelSpace doc))
      (setq layoutactive (vla-get-paperspace doc))
      (setq sc 1000)
    ;
      (setq new_ss_dim_ (ssadd   ))
      (setq staterblk_ename_ (car (entsel "specify Object")))
      (setq staterblk_obj_ (vlax-ename->vla-object staterblk_ename_))
      (setq staterblk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint staterblk_obj_))))
      (setq staterblk_obj_rotation_ (rad-to-deg (vla-get-rotation staterblk_obj_)))
      ; (setq staterblk_obj_dist_1 (LM:getdynpropvalue staterblk_obj_ "distance1"))
      (setq staterblk_obj_dist_2 (LM:getdynpropvalue staterblk_obj_ "distance2"))
      ; (setq staterblk_obj_dist_3 (LM:getdynpropvalue staterblk_obj_ "distance3"))
      (setq staterblk_obj_dist_4 (LM:getdynpropvalue staterblk_obj_ "distance4"))
    ;
    (if (> staterblk_obj_dist_2 3)
      (progn
        (cond
          ((and (= (getvar "worlducs") 1) (> staterblk_obj_dist_2 3)) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                  (vlax-3d-point (setq new_pt (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) (* 500 0))))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) staterblk_obj_dist_2))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) -500 ))
                                  (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ -90))
                    )
                  )
                )
              )
            )
            
          )
          ((= (getvar "worlducs") 0) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) 3) 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) 3) 1 0))
                                (deg-to-rad 90)
                    )
                  )
                )
              )
            )
          )
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") 
          (vla-put-textcolor dim_obj_ 256)
          
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    (if (> staterblk_obj_dist_4 3)
      (progn
        (cond
          ((and (= (getvar "worlducs") 1) (> staterblk_obj_dist_4 3)) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                  (vlax-3d-point (setq new_pt (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) (* 500 0))))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 270)) staterblk_obj_dist_4))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) -500)) 
                                     
                                  (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ -90))
                    )
                  )
                )
              )
            )
            
          )
          ((= (getvar "worlducs") 0) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) 3) 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) 3) 1 0))
                                (deg-to-rad 90)
                    )
                  )
                )
              )
            )
          )
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    ;
    ;
    ;
    (command "pselect"  new_ss_dim_ "" )
    (c:move_dim_level_mvdim)
    (command "ucs" "W")
  )
  (defun c:starter_dim_stdimss4 ()
    ;this code for "000 - STARTER SYMBOL_REV03"
    (command "ucs" "W")
    ;presetting
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq modelSpace (vla-get-ModelSpace doc))
      (setq layoutactive (vla-get-paperspace doc))
      (setq sc 1000)
    ;
      (setq new_ss_dim_ (ssadd   ))
      (setq staterblk_ename_ (car (entsel "specify Object")))
      (setq staterblk_obj_ (vlax-ename->vla-object staterblk_ename_))
      (setq staterblk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint staterblk_obj_))))
      (setq staterblk_obj_rotation_ (rad-to-deg (vla-get-rotation staterblk_obj_)))
      ; (setq staterblk_obj_dist_1 (LM:getdynpropvalue staterblk_obj_ "distance1"))
      (setq staterblk_obj_dist_2 (LM:getdynpropvalue staterblk_obj_ "distance2"))
      ; (setq staterblk_obj_dist_3 (LM:getdynpropvalue staterblk_obj_ "distance3"))
      (setq staterblk_obj_dist_4 (LM:getdynpropvalue staterblk_obj_ "distance4"))
    ;
    (if (> staterblk_obj_dist_2 500000000)
      (progn
        (cond
          ((and (= (getvar "worlducs") 1) (> staterblk_obj_dist_2 3)) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                  (vlax-3d-point (setq new_pt (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) (* 500 0))))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) staterblk_obj_dist_2))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) -500 ))
                                  (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ -90))
                    )
                  )
                )
              )
            )
            
          )
          ((= (getvar "worlducs") 0) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) 3) 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) 3) 1 0))
                                (deg-to-rad 90)
                    )
                  )
                )
              )
            )
          )
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    (if (> staterblk_obj_dist_4 3)
      (progn
        (cond
          ((and (= (getvar "worlducs") 1) (> staterblk_obj_dist_4 3)) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (setq new_pt (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) (* 1000 0)))
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 270)) (+ 0 staterblk_obj_dist_4))) 
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) (+ 0 staterblk_obj_dist_2)))
                                  (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 0)) -1000)) 
                                     
                                  (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ -90))
                    )
                  )
                )
              )
            )
            
          )
          ((= (getvar "worlducs") 0) ;รอแก้
            (progn
              (vl-catch-all-apply 
                (function 
                  (lambda () 
                    (vla-adddimrotated (if 
                                         (and 
                                          ;  (/= (getvar "ctab") "Model")
                                           (/= (getvar "cvport") 3)
                                         )
                                         (progn 
                                           layoutactive
                                         )
                                         modelSpace
                                       ) 
                                (vlax-3d-point (trans staterblk_obj_ins_ 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad (TA:ModifyRotation staterblk_obj_rotation_ 90)) 3) 1 0))
                                (vlax-3d-point (trans (polar staterblk_obj_ins_ (deg-to-rad 180) 3) 1 0))
                                (deg-to-rad 90)
                    )
                  )
                )
              )
            )
          )
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_C-C")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    ;
    ;
    ;
    (command "pselect"  new_ss_dim_ "" )
    (c:move_dim_level_mvdim)
    (command "ucs" "W")
  )
;
;AS-BUILT -DIMENSION
  (defun c:300Hk_asheaddims ()
    ;presetting
      (setvar "osmode" 0)
      (command "ucs" "w")
      (setq layoutactive (vla-get-paperspace (vla-get-ActiveDocument (vlax-get-acad-object))))
      (setq modelSpace (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
      (setq sc 1000)
      (setq new_ss_dim_ (ssadd))
    ;
    (setq 300hk_ename_ (car (entsel "specify Object")))
    (setq 300hk_obj_ (vlax-ename->vla-object 300hk_ename_))
    (setq 300hk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint 300hk_obj_))))
    (if (= (LM:getdynpropvalue 300hk_obj_ "Flip state1") 0)
      (progn
        (setq 300hk_obj_ins_head_ (polar 300hk_obj_ins_ (vla-get-rotation 300hk_obj_) (LM:getdynpropvalue 300hk_obj_ "array_length")))
        (vla-adddimrotated
                      (cond 
                        ( 
                          (and 
                            (= (getvar "ctab") "Model")
                            (> (getvar "cvport") 2)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (> (getvar "cvport") 1)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (= (getvar "cvport") 1)
                          )
                          (progn layoutactive)
                        )
                      ) 
                      (vlax-3d-point (setq new_pt (polar 300hk_obj_ins_head_ (vla-get-rotation 300hk_obj_) (* 1000 0))))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) -1000 ))
                      (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) -90))
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E ASB")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    
    (if (= (LM:getdynpropvalue 300hk_obj_ "Flip state1") 1)
      (progn
        (setq 300hk_obj_ins_head_ (polar 300hk_obj_ins_ (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) (LM:getdynpropvalue 300hk_obj_ "array_length")))
        (vla-adddimrotated 
                      (cond 
                        ( 
                          (and 
                            (= (getvar "ctab") "Model")
                            (> (getvar "cvport") 2)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (> (getvar "cvport") 1)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (= (getvar "cvport") 1)
                          )
                          (progn layoutactive)
                        )
                      ) 
                      (vlax-3d-point (setq new_pt (polar 300hk_obj_ins_head_ (vla-get-rotation 300hk_obj_) (* 1000 0))))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) +1000 ))
                      (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) -90))
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E ASB")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    
    ;while selection process
      (setq ERR_ nil)
      (while ;for keep insertion point and dist. fix length one side
        (and
          (= (vl-catch-all-error-p ERR_) nil)
        )
        (setq ERR_
          (vl-catch-all-apply
            (function
              (lambda ()
                (setq input_gap_dist_ (cond ( (getint (strcat "\nspecify get input_gap_dist_ \n<" (rtos (setq input_gap_dist_ (cond (input_gap_dist_) (1.0) ) ) ) "> : " ) ) ) (input_gap_dist_) ) )
              )
            )
          )
        )
        (if 
          (and
            (= (vl-catch-all-error-p ERR_) nil)
          )
          (progn
            (if (and (= newgapdim_obj_obj_name_  "AcDbRotatedDimension")
                      (/= newgapdim_ename dim_ename)
                )
              (progn
                (command "erase"  newgapdim_ename  "" )
              )
            )
            ; (setq new_gap_point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
            (setq newnew_pt (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (+ (LM:getdynpropvalue 300hk_obj_ "panel_width") input_gap_dist_)))
            ; (command "dimcontinue" dim_ename  newnew_pt "" ""   )
            (command "dimcontinue" dim_ename   )
          )
        )
        
      )
    ;
    ;presetting
      (setvar "osmode" 1215)
    ;
  )
  (defun c:300Hk_asbotdims ()
    ;presetting
      (setvar "osmode" 0)
      (command "ucs" "w")
      (setq layoutactive (vla-get-paperspace (vla-get-ActiveDocument (vlax-get-acad-object))))
      (setq modelSpace (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
      (setq sc 1000)
      (setq new_ss_dim_ (ssadd))
    ;
    (setq 300hk_ename_ (car (entsel "specify Object")))
    (setq 300hk_obj_ (vlax-ename->vla-object 300hk_ename_))
    (setq 300hk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint 300hk_obj_))))
    (if (= (LM:getdynpropvalue 300hk_obj_ "Flip state1") 0)
      (progn
        (setq 300hk_obj_ins_head_ (polar 300hk_obj_ins_ (vla-get-rotation 300hk_obj_) 0))
        (vla-adddimrotated 
                      (cond 
                        ( 
                          (and 
                            (= (getvar "ctab") "Model")
                            (> (getvar "cvport") 2)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (> (getvar "cvport") 1)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (= (getvar "cvport") 1)
                          )
                          (progn layoutactive)
                        )
                      )          
                      (vlax-3d-point (setq new_pt (polar 300hk_obj_ins_head_ (vla-get-rotation 300hk_obj_) (* 1000 0))))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) +1000 ))
                      (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) -90))
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E ASB")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    
    (if (= (LM:getdynpropvalue 300hk_obj_ "Flip state1") 1)
      (progn
        (setq 300hk_obj_ins_head_ (polar 300hk_obj_ins_ (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 0)) 0))
        (vla-adddimrotated 
                      (cond 
                        ( 
                          (and 
                            (= (getvar "ctab") "Model")
                            (> (getvar "cvport") 2)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (> (getvar "cvport") 1)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (= (getvar "cvport") 1)
                          )
                          (progn layoutactive)
                        )
                      ) 
                      (vlax-3d-point (setq new_pt (polar 300hk_obj_ins_head_ (vla-get-rotation 300hk_obj_) (* 1000 0))))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) -1000 ))
                      (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) -90))
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E ASB")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    
    ;while selection process
      (setq ERR_ nil)
      (while ;for keep insertion point and dist. fix length one side
        (and
          (= (vl-catch-all-error-p ERR_) nil)
        )
        (setq ERR_
          (vl-catch-all-apply
            (function
              (lambda ()
                (setq input_gap_dist_ (cond ( (getint (strcat "\nspecify get input_gap_dist_ \n<" (rtos (setq input_gap_dist_ (cond (input_gap_dist_) (1.0) ) ) ) "> : " ) ) ) (input_gap_dist_) ) )
              )
            )
          )
        )
        (if 
          (and
            (= (vl-catch-all-error-p ERR_) nil)
          )
          (progn
            (if (and (= newgapdim_obj_obj_name_  "AcDbRotatedDimension")
                      (/= newgapdim_ename dim_ename)
                )
              (progn
                (command "erase"  newgapdim_ename  "" )
              )
            )
            (setvar "osmode" 0  )
            ; (setq new_gap_point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
            (setq newnew_pt (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (+ (LM:getdynpropvalue 300hk_obj_ "panel_width") input_gap_dist_)))
            ; (command "dimcontinue" dim_ename  newnew_pt "" ""   )
            (command "dimcontinue"   )
            (setvar "osmode" 1215)
            ; (command "dimcontinue" dim_ename    )
          )
        )
        
      )
    ;
    ;presetting
      (setvar "osmode" 1215)
    ;
  )
  (defun c:300Hk_asmiddims ()
    ;presetting
      (setvar "osmode" 0)
      (command "ucs" "w")
      (setq layoutactive (vla-get-paperspace (vla-get-ActiveDocument (vlax-get-acad-object))))
      (setq modelSpace (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
      (setq sc 1000)
      (setq new_ss_dim_ (ssadd))
    ;
    (setq 300hk_ename_ (car (entsel "specify Object")))
    (setq 300hk_obj_ (vlax-ename->vla-object 300hk_ename_))
    (setq 300hk_obj_ins_ (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint 300hk_obj_))))
    (if (= (LM:getdynpropvalue 300hk_obj_ "Flip state1") 0)
      (progn
        (setq 300hk_obj_ins_head_ (polar 300hk_obj_ins_ (vla-get-rotation 300hk_obj_) (/ (LM:getdynpropvalue 300hk_obj_ "array_length") 2)))
        (vla-adddimrotated 
                      (cond 
                        ( 
                          (and 
                            (= (getvar "ctab") "Model")
                            (> (getvar "cvport") 2)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (> (getvar "cvport") 1)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (= (getvar "cvport") 1)
                          )
                          (progn layoutactive)
                        )
                      ) 
                      (vlax-3d-point (setq new_pt (polar 300hk_obj_ins_head_ (vla-get-rotation 300hk_obj_) (* 1000 0))))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) -1000 ))
                      (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) -90))
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E ASB")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    
    (if (= (LM:getdynpropvalue 300hk_obj_ "Flip state1") 1)
      (progn
        (setq 300hk_obj_ins_head_ (polar 300hk_obj_ins_ (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) (/ (LM:getdynpropvalue 300hk_obj_ "array_length") 2)))
        (vla-adddimrotated 
                      (cond 
                        ( 
                          (and 
                            (= (getvar "ctab") "Model")
                            (> (getvar "cvport") 2)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (> (getvar "cvport") 1)
                          )
                          (progn modelSpace)
                        )
                        ( 
                          (and 
                            (/= (getvar "ctab") "Model")
                            (= (getvar "cvport") 1)
                          )
                          (progn layoutactive)
                        )
                      ) 
                      (vlax-3d-point (setq new_pt (polar 300hk_obj_ins_head_ (vla-get-rotation 300hk_obj_) (* 1000 0))))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
                      (vlax-3d-point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 180)) +1000 ))
                      (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) -90))
        )
        ;new_blk_entlast object
          (setq dim_ename (entlast))
          (setq new_ss_dim_ (ssadd dim_ename  new_ss_dim_))
          (setq dim_obj_ (vlax-ename->vla-object dim_ename))
          (vla-put-layer dim_obj_ "000 - SYMBOL CON_2_COMMENT_ASBUILT_WALL_DIMS") (vla-put-textcolor dim_obj_ 256)
          (command "_AIDIMPREC" dimprec dim_ename "" )
          (vla-put-stylename dim_obj_ "FAMELINE-CKST_E-E ASB")
          (vla-put-ScaleFactor  dim_obj_ (/ sc 1) )
          (vla-put-linearscalefactor  dim_obj_ sss_obj_linearsc_ )
          (vla-put-PrimaryUnitsPrecision dim_obj_ 0)
          (vla-put-ExtensionLineOffset dim_obj_ 0.2)
          ; (command "_AIDIMPREC" dimprec dim_ename "" )
        ;
      )
    )
    
    ;while selection process
      (setq ERR_ nil)
      (while ;for keep insertion point and dist. fix length one side
        (and
          (= (vl-catch-all-error-p ERR_) nil)
        )
        (setq ERR_
          (vl-catch-all-apply
            (function
              (lambda ()
                (setq input_gap_dist_ (cond ( (getint (strcat "\nspecify get input_gap_dist_ \n<" (rtos (setq input_gap_dist_ (cond (input_gap_dist_) (1.0) ) ) ) "> : " ) ) ) (input_gap_dist_) ) )
              )
            )
          )
        )
        (if 
          (and
            (= (vl-catch-all-error-p ERR_) nil)
          )
          (progn
            (if (and (= newgapdim_obj_obj_name_  "AcDbRotatedDimension")
                      (/= newgapdim_ename dim_ename)
                )
              (progn
                (command "erase"  newgapdim_ename  "" )
              )
            )
            ; (setq new_gap_point (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (LM:getdynpropvalue 300hk_obj_ "panel_width")))
            (setq newnew_pt (polar new_pt (deg-to-rad (TA:ModifyRotation (rad-to-deg (vla-get-rotation 300hk_obj_)) 90)) (+ (LM:getdynpropvalue 300hk_obj_ "panel_width") input_gap_dist_)))
            ; (command "dimcontinue" dim_ename  newnew_pt "" ""   )
            (command "dimcontinue" dim_ename   )
          )
        )
        
      )
    ;
    ;presetting
      (setvar "osmode" 1215)
    ;
  )
;






