    (defun c:Check_overlap_object_COBJ_ (/ *error*
                                    TA:COBJ-effectivename
                                    TA:COBJ-ename+insertionpoint
                                    ss_pre_filter_set_xx_
                                    ss_pre_filter_set_xx_i
                                    ss_pre_filter_set_xx_count_
                                    ss_pre_filter_set_xx_ename_
                                    ss_pre_filter_set_xx_obj_
                                    tolerance_dist_
                                    EFNAME_
                                    EFNAME_obj_
                                    EFNAME_MAIN_
                                    cancel_
                                    sum_list
                                    sum_list_
                                    sum_list_i
                                    sum_list_count_
                                    sum_list_obj_ins_
                                    check_list_
                                    check_list_scan_
                                    check_duplicate_
                                    check_final_
                                    newssset_
                                    percent
                                 )
      ;Note By Code_Developer
      ;This command is designed to work exclusively with a Block Object
      ;The principle of the code is to find blocks with the same effective name
      ;Duplicate checking uses insertion-point distance, not geometry intersection
      ;Select extra blocks and keep one representative for each checked location
      ;Fully command must have sub-functions with names starting with TA: or LM:
      ;
      ;

      ;sub_function_ effective block name
        (defun TA:COBJ-effectivename (obj)
          (if (vlax-property-available-p obj 'EffectiveName)
            (vla-get-effectivename obj)
            (vla-get-name obj)
          )
        )
      ;
      ;sub_function_ entity name and WCS insertion point
        (defun TA:COBJ-ename+insertionpoint (obj)
          (list
            (vlax-vla-object->ename obj)
            (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint obj)))
          )
        )
      ;
      ;error_handler_
        (defun *error* (msg)
          (if
            (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*BREAK*")))
            (princ (strcat "\nError: " msg))
          )
          (princ)
        )
        (vl-load-com)
      ;
      ;selection_set_for_fillter_blk_name
        (if ;pre_select_ssget_or_post_select_ssget
          (not
            (setq ss_pre_filter_set_xx_ (ssget "_I"
                                              (list
                                                (cons 0 "INSERT") ;type of object
                                                ; (cons 8 "000 - GRID")   ;kind of layer
                                                ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                                ; (cons 62 1)           ;kind of color call sign with color code index
                                              )
                                        )
            )
          )
          (setq ss_pre_filter_set_xx_ (ssget
                                            (list
                                              (cons 0 "INSERT") ;type of object
                                            )
                                      )
          )
        )
      ;
      (if ss_pre_filter_set_xx_
        (progn
          ;user_input_
            (if
              (not
                (and
                  (numberp *TA:COBJ-tolerance-dist_*)
                  (> *TA:COBJ-tolerance-dist_* 0.0)
                )
              )
              (setq *TA:COBJ-tolerance-dist_* 0.001)
            )
            (initget 6) ;reject zero and negative distances; allow Enter
            (setq tolerance_dist_
              (cond
                ((getdist (strcat "\nSpecify tolerance_dist_ <"
                                  (rtos *TA:COBJ-tolerance-dist_* 2 6)
                                  "> : "
                          )
                 )
                )
                (*TA:COBJ-tolerance-dist_*)
              )
            )
            (setq *TA:COBJ-tolerance-dist_* tolerance_dist_)
            ;while_select_block_on_condition_
              (setq EFNAME_MAIN_ nil)
              (setq cancel_ nil)
              (while (and (null EFNAME_MAIN_) (not cancel_))
                (setq EFNAME_ (car (entsel "\nSpecify EFNAME Object <cancel>: ")))
                (cond
                  ((null EFNAME_)
                    (setq cancel_ T)
                  )
                  ((= (vla-get-objectname
                        (setq EFNAME_obj_ (vlax-ename->vla-object EFNAME_))
                      )
                      "AcDbBlockReference"
                   )
                    (setq EFNAME_MAIN_ (TA:COBJ-effectivename EFNAME_obj_))
                  )
                  (T
                    (alert "Object invalid Please try again")
                  )
                )
              )
            ;
          ;
          (if (not cancel_)
            (progn
              ;preloop_and_while ;get_data_process_for_fillter_blk_name
                (setq ss_pre_filter_set_xx_i 0)
                (setq ss_pre_filter_set_xx_count_ (sslength ss_pre_filter_set_xx_))
                (setq sum_list_ ())
                (while (< ss_pre_filter_set_xx_i ss_pre_filter_set_xx_count_)
                  (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ (float ss_pre_filter_set_xx_i)))
                  (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object ss_pre_filter_set_xx_ename_))
                  (if (= (strcase EFNAME_MAIN_) (strcase (TA:COBJ-effectivename ss_pre_filter_set_xx_obj_)))
                    (progn
                      (setq sum_list (TA:COBJ-ename+insertionpoint ss_pre_filter_set_xx_obj_))
                      (setq sum_list_ (cons sum_list sum_list_))
                    )
                  )
                  (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
                  ;screen process
                    (setq percent (fix (* (/ (float ss_pre_filter_set_xx_i) ss_pre_filter_set_xx_count_) 100)))
                    (princ (strcat "tranfering for_fillter_blk_name " (rtos ss_pre_filter_set_xx_i 2 0) "/" (rtos ss_pre_filter_set_xx_count_ 2 0) " (" (rtos percent 2 0) "%" ")" "\n"))
                    (textscr)
                  ;
                )
                (setq sum_list_ (reverse sum_list_)) ;preserve selection-set order
              ;
              ;preloop_and_while for_filter overlapped object
                (setq sum_list_i 0)
                (setq sum_list_count_ (length sum_list_))
                (setq check_list_ ()) ;representatives that will be kept
                (setq newssset_ (ssadd)) ;extra blocks that will be selected
                (foreach sum_list_obj_ins_ sum_list_
                  (setq check_duplicate_ nil)
                  (setq check_list_scan_ check_list_)
                  (while (and check_list_scan_ (not check_duplicate_))
                    (if
                      (< (distance (cadr sum_list_obj_ins_)
                                   (cadr (car check_list_scan_))
                         )
                         tolerance_dist_
                      )
                      (setq check_duplicate_ T)
                    )
                    (setq check_list_scan_ (cdr check_list_scan_))
                  )
                  (if check_duplicate_
                    (setq newssset_ (ssadd (car sum_list_obj_ins_) newssset_))
                    (setq check_list_ (cons sum_list_obj_ins_ check_list_))
                  )
                  (setq sum_list_i (+ sum_list_i 1))
                  ;screen process
                    (setq percent (fix (* (/ (float sum_list_i) sum_list_count_) 100)))
                    (princ (strcat "tranfering overlapped object " (rtos sum_list_i 2 0) "/" (rtos sum_list_count_ 2 0) " (" (rtos percent 2 0) "%" ")" "\n"))
                    (textscr)
                  ;
                )
              ;
              ;selection_process_ selection set for extra overlapp object
                (setq check_final_ newssset_)
                (if (> (sslength check_final_) 0)
                  (sssetfirst nil check_final_)
                  (sssetfirst nil nil)
                )
                (princ (strcat "\nBlock name: " EFNAME_MAIN_
                               " | Checked: " (itoa sum_list_count_)
                               " | Kept: " (itoa (length check_list_))
                               " | Duplicates selected: " (itoa (sslength check_final_))
                       )
                )
              ;
            )
            (princ "\nCommand cancelled.")
          )
        )
        (princ "\nNo block selected.")
      )
      (princ)
    ) 

(princ "\nLoaded command: Check_overlap_object_COBJ_")
(princ)
