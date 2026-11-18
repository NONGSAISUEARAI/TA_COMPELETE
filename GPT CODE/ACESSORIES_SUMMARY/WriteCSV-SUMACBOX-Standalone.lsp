; Standalone copy of SUMARAY_ACESSORIES_BOX_SUMACBOX and its dependencies.
; Sources: z00x_TA_standard_sun_func_and_MAIN.lsp and WriteCSV-V1-1.lsp.
; Load this file only, then run SUMARAY_ACESSORIES_BOX_SUMACBOX.

(vl-load-com)

; Effective Block Name - Lee Mac
(defun LM:effectivename (obj)
  (vlax-get-property obj
    (if (vlax-property-available-p obj 'effectivename)
      'effectivename
      'name
    )
  )
)

; Attribute values in block attribute order.
(defun LM:vl-getattributevalue-val-TA-Modifies (blk)
  (mapcar '(lambda (att) (vla-get-textstring att))
    (vlax-invoke blk 'getattributes)
  )
)

; Filter a selection set by a list of effective block names.
(defun TA:EF_Filter_ss_set_v2_ (ss_pre_filter_set_ effectivename_list / ss_post_filter_set_ ss_pre_filter_set_i ss_pre_filter_set_ename ss_pre_filter_set_obj)
  (setq ss_post_filter_set_ (ssadd))
  (setq ss_pre_filter_set_i 0)
  (while (< ss_pre_filter_set_i (sslength ss_pre_filter_set_))
    (setq ss_pre_filter_set_ename (ssname ss_pre_filter_set_ ss_pre_filter_set_i))
    (setq ss_pre_filter_set_obj (vlax-ename->vla-object ss_pre_filter_set_ename))
    (if (member (LM:effectivename ss_pre_filter_set_obj) effectivename_list)
      (ssadd ss_pre_filter_set_ename ss_post_filter_set_)
    )
    (setq ss_pre_filter_set_i (+ ss_pre_filter_set_i 1))
  )
  ss_post_filter_set_
)

; Sum dotted pairs by their full, exact item name. Skip empty names.
(defun TA:GroupSum_ (lst / result item head_ val found)
  (foreach item lst
    (setq head_ (car item))
    (setq val (cdr item))
    (if (/= head_ "")
      (if (setq found (assoc head_ result))
        (setq result
          (subst (cons head_ (+ val (cdr found))) found result)
        )
        (setq result (cons (cons head_ val) result))
      )
    )
  )
  (reverse result)
)

; First attribute value is the group name for each block.
(defun TA:Group_Accessories_By_Name_ (block_data_list_ / group_list_ block_data_ group_name_ found_ group_)
  (setq group_list_ ())
  (foreach block_data_ block_data_list_
    (if block_data_
      (progn
        (setq group_name_ (caar block_data_))
        (if (setq found_ (assoc group_name_ group_list_))
          (setq group_list_
            (subst
              (cons group_name_ (append (cdr found_) block_data_))
              found_
              group_list_
            )
          )
          (setq group_list_
            (append group_list_ (list (cons group_name_ block_data_)))
          )
        )
      )
    )
  )
  (mapcar
    '(lambda (group_)
       (cons (car group_) (TA:GroupSum_ (cdr group_)))
     )
    group_list_
  )
)

; Build three string columns: GROUP_NAME, ITEM_NAME, QTY.
(defun TA:Grouped_Accessories_To_CSVRows_ (grouped_data_ / csv_rows_ group_ item_)
  (setq csv_rows_ (list (list "GROUP_NAME" "ITEM_NAME" "QTY")))
  (foreach group_ grouped_data_
    (foreach item_ (cdr group_)
      (setq csv_rows_
        (append csv_rows_
          (list
            (list (car group_) (car item_)
              (vl-princ-to-string (cdr item_))
            )
          )
        )
      )
    )
  )
  csv_rows_
)

; String substitution - Lee Mac
(defun LM:StringSubst (new old str / inc len)
  (setq len (strlen new) inc 0)
  (while (setq inc (vl-string-search old str inc))
    (setq str (vl-string-subst new old str inc)
          inc (+ inc len)
    )
  )
  str
)

; Write CSV - Lee Mac (from WriteCSV-V1-1.lsp)
(defun LM:writecsv (lst csv / des sep)
  (if (setq des (open csv "w"))
    (progn
      (setq sep
        (cond
          ((vl-registry-read "HKEY_CURRENT_USER\\Control Panel\\International" "sList"))
          (",")
        )
      )
      (foreach row lst (write-line (LM:lst->csv row sep) des))
      (close des)
      t
    )
  )
)

(defun LM:lst->csv (lst sep)
  (if (cdr lst)
    (strcat (LM:csv-addquotes (car lst) sep) sep (LM:lst->csv (cdr lst) sep))
    (LM:csv-addquotes (car lst) sep)
  )
)

(defun LM:csv-addquotes (str sep / pos)
  (cond
    ((wcmatch str (strcat "*[\`" sep "\"]*"))
      (setq pos 0)
      (while (setq pos (vl-string-position 34 str pos))
        (setq str (vl-string-subst "\"\"" "\"" str pos)
              pos (+ pos 2)
        )
      )
      (strcat "\"" str "\"")
    )
    (str)
  )
)

(defun c:sumaray_acessories_box_sumacbox (/ ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i ss_pre_filter_set_xx_ename_ ss_pre_filter_set_xx_obj_ ss_pre_filter_set_xx_aclist_ data_ result_ grouped_acsummary_ csv_rows_ filepath filename_ fitler_ename_ comma_pos_)
  ;selection_set_for_fillter_blk_name
    (if
      (= (setq ss_pre_filter_set_xx_
           (ssget "i"
             (list
               (cons 0 "INSERT") ;type of object
               ; (cons 8 "000 - GRID") ;kind of layer
               ; (cons 2 "000-GRID_LINE_DYN") ;kind of nameblock
               ; (cons 62 1) ;kind of color
             )
           )
         ) nil)
      (setq ss_pre_filter_set_xx_
        (ssget
          (list
            (cons 0 "INSERT") ;type of object
            ; (cons 8 "000 - GRID") ;kind of layer
            ; (cons 2 "000-GRID_LINE_DYN") ;kind of nameblock
            ; (cons 62 1) ;kind of color
          )
        )
      )
      (sslength ss_pre_filter_set_xx_)
    )
  ;
  (if ss_pre_filter_set_xx_
    (progn
      (setq ss_pre_filter_set_xx_
        (TA:EF_Filter_ss_set_v2_ ss_pre_filter_set_xx_
          (list "facade_1_acessoriesset" "facade_1_MAXLEN")
        )
      )
      ;preloop_and_while
        (setq ss_pre_filter_set_xx_i 0)
        (setq ss_pre_filter_set_xx_aclist_ ())
        (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
          (setq ss_pre_filter_set_xx_ename_
            (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i)
          )
          (setq ss_pre_filter_set_xx_obj_
            (vlax-ename->vla-object ss_pre_filter_set_xx_ename_)
          )
          (setq data_
            (LM:vl-getattributevalue-val-TA-Modifies ss_pre_filter_set_xx_obj_)
          )
          (setq result_
            (mapcar
              '(lambda (item_ / comma_pos_)
                 (if (setq comma_pos_ (vl-string-search "," item_))
                   (cons
                     (substr item_ 1 comma_pos_)
                     (atoi (substr item_ (+ comma_pos_ 2)))
                   )
                   (cons item_ 0)
                 )
               )
              data_
            )
          )
          ;Keep each block's result_ as a separate group candidate.
          (setq ss_pre_filter_set_xx_aclist_
            (append ss_pre_filter_set_xx_aclist_ (list result_))
          )
          (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
        )
      ;
      (setq grouped_acsummary_
        (TA:Group_Accessories_By_Name_ ss_pre_filter_set_xx_aclist_)
      )
      (setq csv_rows_
        (TA:Grouped_Accessories_To_CSVRows_ grouped_acsummary_)
      )
      (setq filepath (getvar "DWGPREFIX"))
      (setq filename_
        (strcat (LM:StringSubst "" ".dwg" (getvar "DWGNAME")) ".csv")
      )
      (if (findfile (strcat filepath filename_))
        (LM:writecsv csv_rows_
          (strcat filepath
            (LM:StringSubst "-" "." (rtos (getvar "CDATE") 2 8))
            "-" filename_
          )
        )
        (LM:writecsv csv_rows_ (strcat filepath filename_))
      )
    )
  )
  (princ)
)

(princ "\nLoaded SUMARAY_ACESSORIES_BOX_SUMACBOX.")
(princ)
