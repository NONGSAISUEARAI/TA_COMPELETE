  (defun c:PPLINE_CKST_SMOKE_create ()
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_GLASS_FIN_MAIN_COLOR" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_GLASS_FIN_SUB_COLOR_1" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_GLASS_FIN_SUB_COLOR_2" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_GLASS_FIN_HATCH" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_GLASS_FIN_WIPEOUT" "")
    
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_BARRIER_MAIN_COLOR" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_BARRIER_SUB_COLOR_1" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_BARRIER_SUB_COLOR_2" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_BARRIER_HATCH" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_BARRIER_WIPEOUT" "")

    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_ACESSORIES_MAIN_COLOR" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_ACESSORIES_SUB_COLOR_1" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_ACESSORIES_SUB_COLOR_2" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_ACESSORIES_HATCH" "")
    (command "-layer" "n" "000_PPLINE_CKST_SMOKE_ACESSORIES_WIPEOUT" "")

    (command "-layer" "c" 3 "000_PPLINE_CKST_SMOKE_GLASS_FIN_MAIN_COLOR" "" ) 
    (command "-layer" "c" 1 "000_PPLINE_CKST_SMOKE_GLASS_FIN_SUB_COLOR_1" "" ) 
    (command "-layer" "c" 1 "000_PPLINE_CKST_SMOKE_GLASS_FIN_SUB_COLOR_2" "" ) 
    (command "-layer" "c" 251 "000_PPLINE_CKST_SMOKE_GLASS_FIN_HATCH" "" ) 
    (command "-layer" "c" 250 "000_PPLINE_CKST_SMOKE_GLASS_FIN_WIPEOUT" "" ) 
    
    (command "-layer" "c" 2 "000_PPLINE_CKST_SMOKE_BARRIER_MAIN_COLOR" "" ) 
    (command "-layer" "c" 1 "000_PPLINE_CKST_SMOKE_BARRIER_SUB_COLOR_1" "" ) 
    (command "-layer" "c" 1 "000_PPLINE_CKST_SMOKE_BARRIER_SUB_COLOR_2" "" ) 
    (command "-layer" "c" 251 "000_PPLINE_CKST_SMOKE_BARRIER_HATCH" "" ) 
    (command "-layer" "c" 250 "000_PPLINE_CKST_SMOKE_BARRIER_WIPEOUT" "" ) 
    
    (command "-layer" "c" 1 "000_PPLINE_CKST_SMOKE_ACESSORIES_MAIN_COLOR" "" ) 
    (command "-layer" "c" 1 "000_PPLINE_CKST_SMOKE_ACESSORIES_SUB_COLOR_1" "" ) 
    (command "-layer" "c" 1 "000_PPLINE_CKST_SMOKE_ACESSORIES_SUB_COLOR_2" "" ) 
    (command "-layer" "c" 251 "000_PPLINE_CKST_SMOKE_ACESSORIES_HATCH" "" ) 
    (command "-layer" "c" 250 "000_PPLINE_CKST_SMOKE_GLASS_FIN_WIPEOUT" "" ) 

    ; (command "-layer" "filter" "n" "G" "" "*000 - CSD_PL_*" "CSD" ""  )
    (setq MAIN-filter_1 "SMOKE")
    (setq MAIN-filter_1-1 "PPLINE_CKST_SMOKE_GLASS_FIN")
    (setq MAIN-filter_1-2 "PPLINE_CKST_SMOKE_BARRIER")
    (setq MAIN-filter_1-3 "PPLINE_CKST_SMOKE_ACESSORIES")
  
    (command "-layer" "filter" "new" "group" "" "*000_PPLINE_CKST_SMOKE_*" MAIN-filter_1 ""  )
    (command "-LAYER" "filter" "new" "group"  MAIN-filter_1 "*000_PPLINE_CKST_SMOKE_G*" MAIN-filter_1-1 "" ) 
    (command "-LAYER" "filter" "new" "group"  MAIN-filter_1 "*000_PPLINE_CKST_SMOKE_BARRIER*" MAIN-filter_1-2 "" ) 
    (command "-LAYER" "filter" "new" "group"  MAIN-filter_1 "*000_PPLINE_CKST_SMOKE_ACESSORIES*" MAIN-filter_1-3 "" ) 
  )
  
;STR_FUNC
  (defun TA:rightstr (str_value_ right_value_)
    ; (setq str_value_ "abcdefg")
    ; (setq right_value_ 2)
    (setq str_value_length (strlen str_value_))
    (substr str_value_ (- (+ str_value_length 1) right_value_ ) 100)
  )
  (defun TAS:StringSubst-for-createlayer (new old str / inc len) 
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
;prototype for filter layer
  (defun TA:generate_filter_list1 (1st_filter_ 2nd_filter_ 3rd_filter_ 4th_filter)
    ;example_for_use
      ; (setq 1st_filter_ "PPLINE-FAMELINE")
      ; (setq 2nd_filter_ "000_CLIP-IN_" )
      ; (setq 3rd_filter_ (list ;
      ;                   "PANEL_" ;
      ;                   "ACESSORIES_" ;
      ;                   "SUBFAME_" ;
      ;                   )
      ; )
      ; (setq 4th_filter_ (list  ;4th_filter
      ;                         (list "MAIN_COLOR_1" 3) ;
      ;                         (list "MAIN_COLOR_2" 2) ;
      ;                         (list "SUB_COLOR_1" 1) ;
      ;                         (list "SUB_COLOR_2" 1) ;
      ;                         (list "HATCH_" 251) ;
      ;                         (list "WIPEOUT_" 250) ;
      ;                         (list "HIDDEN_" 251) ;
      ;                         (list "SYMBOL_" 251) ;
      ;                   )
      ; )
    ;
    ;core
      (setq overall_line ())
      (setq 1st_line_ (list 1st_filter_ 2nd_filter_))
      ;preloop_and_while 3rd
        (setq 3rd_filter_i 0)
        (setq 3rd_line_ ())
        (while (< 3rd_filter_i (length 3rd_filter_))
          (setq 3rd_filter_val_ (nth  3rd_filter_i 3rd_filter_))
          (setq 3rd_filter_val_strcat_ (strcat 2nd_filter_ 3rd_filter_val_ ))
          (setq 3rd_line_ (cons 3rd_filter_val_strcat_ 3rd_line_))
          (setq 3rd_filter_i (+ 3rd_filter_i 1))
        )
        (setq 3rd_line_ (append (list 2nd_filter_) (reverse 3rd_line_) ))
      ;
      ;preloop_and_while 4th
        (setq 3rd_filter_i 0)
        (setq 4th_line_ ())
        (setq 4th_line_sub ())
        (while (< 3rd_filter_i (length 3rd_filter_))
          (setq 3rd_filter_val_ (strcat 2nd_filter_ (nth 3rd_filter_i 3rd_filter_)))
          ;preloop_and_while
            (setq 4th_filter_i 0)
            (setq 4th_line_sub ())
            (while (< 4th_filter_i (length 4th_filter_))
              (setq 4th_filter_val_ (car (nth  4th_filter_i 4th_filter_)))
              (setq 4th_line_sub (cons (strcat 2nd_filter_ (substr (nth 3rd_filter_i 3rd_filter_) 1 2) "_"  4th_filter_val_ ) 4th_line_sub))

              (setq 4th_filter_i (+ 4th_filter_i 1))
            )
          ;
          (setq 4th_line_sub (append (list 3rd_filter_val_ ) (reverse 4th_line_sub )))
          (setq 4th_line_ (cons 4th_line_sub 4th_line_))
          (setq 4th_line_ (reverse 4th_line_))
          
          (setq 3rd_filter_i (+ 3rd_filter_i 1))
        )
      ;
      (setq overall_line (append (List 1st_line_) (List 3rd_line_) 4th_line_ ))
    ;
  )
  
  (defun c:create_main_and_sub_filter_creF3 ()
    ;presettting
      (setq Prefix_filter_name_ "000_CLIP-IN_")
      (setq Prefix_filter_name_LV1 "PANEL_")
      (setq Prefix_filter_name_LV2 "ACESSORIES_")
      (setq Prefix_filter_name_LV3 "SUBFAME_")
      (setq main_filter_name_ (list 
                                (List "PPLINE-FAMELINE" (strcat Prefix_filter_name_))
                                (list 
                                  (strcat Prefix_filter_name_) 
                                  (strcat Prefix_filter_name_ Prefix_filter_name_LV1) 
                                  (strcat Prefix_filter_name_ Prefix_filter_name_LV2)
                                  (strcat Prefix_filter_name_ Prefix_filter_name_LV3)
                                )
                                (list (strcat Prefix_filter_name_ Prefix_filter_name_LV1) 
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV1 "MAIN_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV1 "SUB_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV1 "HATCH_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV1 "WIPEOUT_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV1 "HIDDEN_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV1 "SYMBOL_" )
                                )
                                (list (strcat Prefix_filter_name_ Prefix_filter_name_LV2) 
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "MAIN_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "SUB_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "HATCH_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "WIPEOUT_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "HIDDEN_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "SYMBOL_" )
                                )
                                (list (strcat Prefix_filter_name_ Prefix_filter_name_LV3) 
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "MAIN_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "SUB_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "HATCH_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "WIPEOUT_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "HIDDEN_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "SYMBOL_" )
                                )
                              )
      )
      (setq wildcard_layer_name_ "*0*")
    ;
    ;preloop_and_while_main_filter
      (setq main_filter_name_i 0)
      (while (< main_filter_name_i (length main_filter_name_))
        (setq main_filter_name_val_ (nth  main_filter_name_i main_filter_name_))
        (if (= (type main_filter_name_val_) 'list)
          (progn
            ;preloop_and_while
              (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ (car main_filter_name_val_) ""  )
              (setq main_filter_name_val_i 1)
              (while (< main_filter_name_val_i (length main_filter_name_val_))
                (setq main_filter_name_val_sval_ (nth  main_filter_name_val_i main_filter_name_val_))
                ; (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ main_filter_name_val_sval_ ""  )    
                (command "-LAYER" "filter" "new" "group"  
                         (car main_filter_name_val_)
                         "" ;(add layer name to filter, Can use wildcard for adding)
                         main_filter_name_val_sval_ 
                         "" )
                (setq main_filter_name_val_i (+ main_filter_name_val_i 1))
              )
            ;
          )
          (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ main_filter_name_val_ ""  )
        )
        (setq main_filter_name_i (+ main_filter_name_i 1))
      )
    ;
  )
  (defun c:add_layer_main_and_sub_filter_addLFilter ()
    ;presettting
      ;Note By Code_Developer
        ;fist val in list   = filter name
        ;second val in list = wildcard_layer name
        ;sub array list in filter name must be 2 val only 
      ;
        ; (setq main_filter_name_ (list 
        ;                           (list "A1" "*FIN*")
        ;                           (list "B2" "*HATCH*")
        ;                           (list "C2" "*MAIN*")
        ;                           (list "D1" "*SUB*")
        ;                           (list "A2" "")
        ;                           (list "A1" "HATCH")
        ;                         )
        ; )
        (setq main_filter_name_ (list 
                                  (list (strcat Prefix_filter_name_ Prefix_filter_name_LV1) (strcat "*" Prefix_filter_name_ Prefix_filter_name_LV1 "*"))
                                  (list (strcat Prefix_filter_name_ Prefix_filter_name_LV2) (strcat "*" Prefix_filter_name_ Prefix_filter_name_LV2 "*"))
                                  (list (strcat Prefix_filter_name_ Prefix_filter_name_LV3) (strcat "*" Prefix_filter_name_ Prefix_filter_name_LV3 "*"))
                                )
        )
      ;
      ;
    ;
    ;preloop_and_while_main_filter
      (setq main_filter_name_i 0)
      (while (< main_filter_name_i (length main_filter_name_))
        (setq main_filter_name_val_ (nth  main_filter_name_i main_filter_name_))
        (if (and 
              (= (type main_filter_name_val_) 'list)
              (= (length main_filter_name_val_) 2)
            )
          (progn
            ;preloop_and_while
              (setq main_filter_name_val_i 0)
                (setq main_filter_name_val_sval1_ (car main_filter_name_val_))
                (setq main_filter_name_val_sval2_ (cadr main_filter_name_val_))
                ; (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ main_filter_name_val_sval_ ""  )    
                
                (command "-layer"
                         "filter"
                         "edit"
                         main_filter_name_val_sval1_ ; (Filter name must be sensitibe case)
                         "add"
                         main_filter_name_val_sval2_ ;(add layer name to filter, Can use wildcard for adding)
                         "x" ""
                )
            ;
          )
        )
        (setq main_filter_name_i (+ main_filter_name_i 1))
      )
    ;
  )
  (defun c:add_layer_main_and_sub_filter_addLFilter_ADD_LF2 ()
    ;presettting
      ;Note By Code_Developer
        ;fist val in list   = filter name
        ;second val in list = wildcard_layer name
        ;sub array list in filter name must be 2 val only 
      ;
        ; (setq main_filter_name_ (list 
        ;                           (list "A1" "*FIN*")
        ;                           (list "B2" "*HATCH*")
        ;                           (list "C2" "*MAIN*")
        ;                           (list "D1" "*SUB*")
        ;                           (list "A2" "")
        ;                           (list "A1" "HATCH")
        ;                         )
        ; )
        (setq main_filter_name_ (list 
                                  (list (strcat Prefix_filter_name_ Prefix_filter_name_LV1) )
                                  (list (strcat Prefix_filter_name_ Prefix_filter_name_LV2) )
                                  (list (strcat Prefix_filter_name_ Prefix_filter_name_LV3) )
                                )
        )
        (setq sub_filter_nameset_ (list 
                                    "MAIN_COLOR_"
                                    "SUB_COLOR_"
                                    "HATCH_"
                                    "WIPEOUT_"
                                    "HIDDEN_"
                                    "SYMBOL_"
                                  )
        )
      ;
      ;
    ;
    ;preloop_and_while_main_filter
      (setq main_filter_name_i 0)
      (while (< main_filter_name_i (length main_filter_name_))
        (setq main_filter_name_val_ (car (nth  main_filter_name_i main_filter_name_)))
        (if (and 
              (= 1 1)
            )
          (progn
            ;preloop_and_while
              ;preloop_and_while
                (setq sub_filter_nameset_i 0)
                (while (< sub_filter_nameset_i (length sub_filter_nameset_))
                  (setq sub_filter_nameset_val_ (nth  sub_filter_nameset_i sub_filter_nameset_))
                  
                  (command "-layer"
                          "filter"
                          "edit"
                          (strcat main_filter_name_val_ sub_filter_nameset_val_) ; (Filter name must be sensitibe case)
                          "add"
                          (strcat "*" main_filter_name_val_ sub_filter_nameset_val_ "*") ;(add layer name to filter, Can use wildcard for adding)
                          "x" ""
                  )

                  (setq sub_filter_nameset_i (+ sub_filter_nameset_i 1))
                )
              ;
                ; (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ main_filter_name_val_sval_ ""  )    
                
                
            ;
          )
        )
        (setq main_filter_name_i (+ main_filter_name_i 1))
      )
    ;
  )
  (defun c:create_layerset_ ()
    ;presetting_
      (setq Prefix_filter_name_ "000_CLIP-IN_")
      (setq layer_prefix_overall_ (list 
                                   (setq Prefix_filter_name_LV1 "PANEL_")
                                   (setq Prefix_filter_name_LV2 "ACESSORIES_")
                                   (setq Prefix_filter_name_LV3 "SUBFAME_")
                                 )
      )
      (setq layer_subfix_name_ (list
                                  (list "MAIN_COLOR_1" 3)
                                  (list "MAIN_COLOR_2" 2)
                                  (list "SUB_COLOR_1" 1 )
                                  (list "SUB_COLOR_2" 1)
                                  (list "HATCH_" 251)
                                  (list "WIPEOUT_" 250)
                                  (list "HIDDEN_" 251)
                                  (list "SYMBOL_" 251)
                                )
      )
    ;
    ;preloop_and_while
      (setq layer_prefix_overall_i 0)
      (while (< layer_prefix_overall_i (length layer_prefix_overall_))
        (setq layer_overall_val_ (nth  layer_prefix_overall_i layer_prefix_overall_))
        ;preloop_and_while
          (setq layer_subfix_name_i 0)
          (while (< layer_subfix_name_i (length layer_subfix_name_))
            (setq layer_subfix_name_val_ (car (nth  layer_subfix_name_i layer_subfix_name_)))
            (setq layer_subfix_name_color_ (cadr (nth  layer_subfix_name_i layer_subfix_name_)))
            (setq layer_name_set_ (strcat 
                                    Prefix_filter_name_ 
                                    layer_overall_val_
                                    layer_subfix_name_val_
                                  )
            )
            (command "-layer" "n" layer_name_set_ "")
            (command "-layer" "c" layer_subfix_name_color_ layer_name_set_ "" )
            (setq layer_subfix_name_i (+ layer_subfix_name_i 1))
          )
        ;
        (setq layer_prefix_overall_i (+ layer_prefix_overall_i 1))
      )
    ;
  )
;


  (defun TA:generate_filter_list (1st_filter_ 2nd_filter_val_main 3rd_filter_val_main 4th_filter_val_main)
    ;example_for_use
      ; (setq 1st_filter_ "PPLINE-FAMELINE")
      ; (setq 2nd_filter_ "000_CLIP-IN_")
      ; (setq 3rd_filter_ (list ;
      ;                   "PANEL_" ;
      ;                   "ACESSORIES_" ;
      ;                   "SUBFAME_" ;
      ;                   )
      ; )
      ; (setq 4th_filter_ (list  ;4th_filter
      ;                                 (list "MAIN_COLOR_1" 3) ;
      ;                                 (list "MAIN_COLOR_2" 2) ;
      ;                                 (list "SUB_COLOR_1" 1) ;
      ;                                 (list "SUB_COLOR_2" 1) ;
      ;                                 (list "SUB_COLOR_3" 251) ;
      ;                                 (list "HATCH_" 251) ;
      ;                                 (list "WIPEOUT_" 250) ;
      ;                                 (list "HIDDEN_" 251) ;
      ;                                 (list "SYMBOL_" 251) ;
      ;                                 (list "DEF_SUB" 250) ;
      ;                           )
      ; )
    ;
    ;core
      (setq  1st_filter_ 1st_filter_
              2nd_filter_ 2nd_filter_val_main
             3rd_filter_ 3rd_filter_val_main
              4th_filter_ 4th_filter_val_main
              
      
      )
      (setq overall_line ())
      (setq 1st_line_ (list 1st_filter_ 2nd_filter_))
      ;preloop_and_while 3rd
        (setq 3rd_filter_i 0)
        (setq 3rd_line_ ())
        (while (< 3rd_filter_i (length 3rd_filter_))
          (setq 3rd_filter_val_ (nth  3rd_filter_i 3rd_filter_))
          (setq 3rd_filter_val_strcat_ (strcat 2nd_filter_ 3rd_filter_val_ ))
          (setq 3rd_line_ (cons 3rd_filter_val_strcat_ 3rd_line_))
          (setq 3rd_filter_i (+ 3rd_filter_i 1))
        )
        (setq 3rd_line_ (append (list 2nd_filter_) (reverse 3rd_line_) ))
      ;
      ;preloop_and_while 4th
        (setq 3rd_filter_i 0)
        (setq 4th_line_ ())
        (setq 4th_line_sub ())
        (while (< 3rd_filter_i (length 3rd_filter_))
          (setq 3rd_filter_val_ (strcat 2nd_filter_ (nth 3rd_filter_i 3rd_filter_)))
          ;preloop_and_while
            (setq 4th_filter_i 0)
            (setq 4th_line_sub ())
            (while (< 4th_filter_i (length 4th_filter_))
              (setq 4th_filter_val_ (car (nth  4th_filter_i 4th_filter_)))
              
              (if (or 
                    (= (wcmatch 4th_filter_val_ "*_2" ) nil)
                    (= (wcmatch 4th_filter_val_ "*_3" ) nil)
                  )
                (progn
                  (setq 4th_line_sub (cons (strcat 2nd_filter_ (substr (nth 3rd_filter_i 3rd_filter_) 1 20) "_"  4th_filter_val_ ) 4th_line_sub)) ;บรรทัดนี่ ใช้ทำตัว ac = acessories
                )
              )             
              (setq 4th_filter_i (+ 4th_filter_i 1))
            )
          ;
          (setq 4th_line_sub (append (list 3rd_filter_val_ ) (reverse 4th_line_sub )))
          (setq 4th_line_ (cons 4th_line_sub 4th_line_))
          (setq 4th_line_ (reverse 4th_line_))
          
          (setq 3rd_filter_i (+ 3rd_filter_i 1))
        )
      ;
      (setq overall_line (append (List 1st_line_) (List 3rd_line_) 4th_line_ ))
      ; (setq overall_line2 (append overall_line (list 4th_filter_)  ))
    ;
    ;process command
      (c:create_main_and_sub_filter_creF4 overall_line)
      (c:create_layerset_Lset4 2nd_filter_val_main 3rd_filter_val_main 4th_filter_val_main)
      (c:add_layer_main_and_sub_filter_addLFilter_ADD_LF4 2nd_filter_val_main 3rd_filter_val_main 4th_filter_val_main)
    ;
  )
  (defun c:create_main_and_sub_filter_creF4 (main_filter_name_)
    ;presettting
      ; example
        ; (setq Prefix_filter_name_ "000_CLIP-IN_")
      ;   (setq Prefix_filter_name_LV1 "PANEL_")
      ;   (setq Prefix_filter_name_LV2 "ACESSORIES_")
      ;   (setq Prefix_filter_name_LV3 "SUBFAME_")
      ;   (setq main_filter_name_ (list 
      ;                             (List "PPLINE-FAMELINE" (strcat Prefix_filter_name_))
      ;                             (list 
      ;                               (strcat Prefix_filter_name_) 
      ;                               (strcat Prefix_filter_name_ Prefix_filter_name_LV1) 
      ;                               (strcat Prefix_filter_name_ Prefix_filter_name_LV2)
      ;                               (strcat Prefix_filter_name_ Prefix_filter_name_LV3)
      ;                             )
      ;                             (list (strcat Prefix_filter_name_ Prefix_filter_name_LV1) 
      ;                                   (strcat (substr Prefix_filter_name_LV1 1 2) "_" "MAIN_COLOR_" )
      ;                                   (strcat (substr Prefix_filter_name_LV1 1 2) "_" "SUB_COLOR_" )
      ;                                   (strcat (substr Prefix_filter_name_LV1 1 2) "_" "HATCH_" )
      ;                                   (strcat (substr Prefix_filter_name_LV1 1 2) "_" "WIPEOUT_" )
      ;                                   (strcat (substr Prefix_filter_name_LV1 1 2) "_" "HIDDEN_" )
      ;                                   (strcat (substr Prefix_filter_name_LV1 1 2) "_" "SYMBOL_" )
      ;                             )
      ;                             (list (strcat Prefix_filter_name_ Prefix_filter_name_LV2) 
      ;                                   (strcat (substr Prefix_filter_name_LV2 1 2) "_" "MAIN_COLOR_" )
      ;                                   (strcat (substr Prefix_filter_name_LV2 1 2) "_" "SUB_COLOR_" )
      ;                                   (strcat (substr Prefix_filter_name_LV2 1 2) "_" "HATCH_" )
      ;                                   (strcat (substr Prefix_filter_name_LV2 1 2) "_" "WIPEOUT_" )
      ;                                   (strcat (substr Prefix_filter_name_LV2 1 2) "_" "HIDDEN_" )
      ;                                   (strcat (substr Prefix_filter_name_LV2 1 2) "_" "SYMBOL_" )
      ;                             )
      ;                             (list (strcat Prefix_filter_name_ Prefix_filter_name_LV3) 
      ;                                   (strcat (substr Prefix_filter_name_LV3 1 2) "_"  "MAIN_COLOR_" )
      ;                                   (strcat (substr Prefix_filter_name_LV3 1 2) "_"  "SUB_COLOR_" )
      ;                                   (strcat (substr Prefix_filter_name_LV3 1 2) "_"  "HATCH_" )
      ;                                   (strcat (substr Prefix_filter_name_LV3 1 2) "_"  "WIPEOUT_" )
      ;                                   (strcat (substr Prefix_filter_name_LV3 1 2) "_"  "HIDDEN_" )
      ;                                   (strcat (substr Prefix_filter_name_LV3 1 2) "_"  "SYMBOL_" )
      ;                             )
      ;                           )
      ;   )
      
      (setq wildcard_layer_name_ "*0*")
      ;
      ; (setq main_filter_name_ (nth 1 main_filter_name_ovl_))
      (setq main_filter_name_ main_filter_name_)
    ;
    ;preloop_and_while_main_filter
      (setq main_filter_name_i 0)
      (while (< main_filter_name_i (length main_filter_name_))
        (setq main_filter_name_val_ (nth  main_filter_name_i main_filter_name_))
        (if (= (type main_filter_name_val_) 'list)
          (progn
            ;preloop_and_while
              (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ (car main_filter_name_val_) ""  )
              (setq main_filter_name_val_i 1)
              (while (< main_filter_name_val_i (length main_filter_name_val_))
                (setq main_filter_name_val_sval_ (nth  main_filter_name_val_i main_filter_name_val_))
                ; (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ main_filter_name_val_sval_ ""  )    
                (if (and 
                      (= main_filter_name_val_i 1)
                      (/= (wcmatch main_filter_name_val_sval_ "*_2") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_3") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_4") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_5") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_6") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_7") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_8") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_9") T)
                      (/= (wcmatch main_filter_name_val_sval_ "*_251") T)
                    )
                  (progn
                    (command "-LAYER" "filter" "new" "group"  
                         (car main_filter_name_val_)
                         "" ;(add layer name to filter, Can use wildcard for adding)
                         main_filter_name_val_sval_ 
                         "" 
                    )
                  )
                  (if (and 
                        (/= (wcmatch main_filter_name_val_sval_ "*_2") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_3") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_4") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_5") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_6") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_7") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_8") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_9") T)
                        (/= (wcmatch main_filter_name_val_sval_ "*_251") T)
                      )
                    (progn
                      (command "-LAYER" "filter" "new" "group"  
                          (car main_filter_name_val_)
                          "" ;(add layer name to filter, Can use wildcard for adding)
                          main_filter_name_val_sval_ 
                          "" 
                      )
                    )
                  )
                  ; (command "-LAYER" "filter" "new" "group"  
                  ;       (car main_filter_name_val_)
                  ;       "" ;(add layer name to filter, Can use wildcard for adding)
                  ;       main_filter_name_val_sval_ 
                  ;       "" 
                  ; )
                )
                (setq main_filter_name_val_i (+ main_filter_name_val_i 1))
              )
            ;
          )
          (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ main_filter_name_val_ ""  )
        )
        (setq main_filter_name_i (+ main_filter_name_i 1))
      )
    ;
  )
  (defun c:create_layerset_Lset4 (2nd_filter_val_main 3rd_filter_val_main 4th_filter_val_main)
    ;presetting_
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
      (setq Prefix_filter_name_ 2nd_filter_val_main)
      (setq layer_prefix_overall_ 3rd_filter_val_main )
      (setq layer_subfix_name_ 4th_filter_val_main ) 
    ;
    ;preloop_and_while
      (setq layer_prefix_overall_i 0)
      (while (< layer_prefix_overall_i (length layer_prefix_overall_))
        (setq layer_overall_val_ (nth  layer_prefix_overall_i layer_prefix_overall_))
        ;preloop_and_while
          (setq layer_subfix_name_i 0)
          (while (< layer_subfix_name_i (length layer_subfix_name_))
            (setq layer_subfix_name_length_ (nth  layer_subfix_name_i layer_subfix_name_))
            (setq layer_subfix_name_val_ (car (nth  layer_subfix_name_i layer_subfix_name_)))
            (setq layer_subfix_name_color_ (cadr (nth  layer_subfix_name_i layer_subfix_name_)))
            (setq layer_name_set_ (strcat 
                                    Prefix_filter_name_ 
                                    layer_overall_val_
                                    "_"
                                    layer_subfix_name_val_
                                  )
            )
            (setq layers (vla-get-Layers doc))
            (setq layObj (vla-Add layers layer_name_set_))
            (if (= (length layer_subfix_name_length_) 4)
              (progn
                (cdr layer_subfix_name_length_)
                (setq layObj (vla-Item 
                               (vla-get-Layers doc)
                               layer_name_set_ ; ← ชื่อ Layer
                             )
                )
                (setq truecolor_obj_ (vla-get-truecolor layObj ))
                (vla-setrgb 
                  truecolor_obj_ 
                            (car (cdr layer_subfix_name_length_)) 
                            (cadr (cdr layer_subfix_name_length_)) 
                            (caddr (cdr layer_subfix_name_length_)) 
                )
                (vla-put-TrueColor  layObj truecolor_obj_)
              )
              (vla-put-color layObj layer_subfix_name_color_)
            )
            
            (setq layer_subfix_name_i (+ layer_subfix_name_i 1))
          )
        ;
        (setq layer_prefix_overall_i (+ layer_prefix_overall_i 1))
      )
    ;
  )
  (defun c:add_layer_main_and_sub_filter_addLFilter_ADD_LF4 ( 2nd_filter_val_main 3rd_filter_val_main 4th_filter_val_main)
    ;presettting
      ;Note By Code_Developer
        ;fist val in list   = filter name
        ;second val in list = wildcard_layer name
        ;sub array list in filter name must be 2 val only 
      ;
        ; (setq main_filter_name_next_ (list 
        ;                           (list "A1" "*FIN*")
        ;                           (list "B2" "*HATCH*")
        ;                           (list "C2" "*MAIN*")
        ;                           (list "D1" "*SUB*")
        ;                           (list "A2" "SSS")
        ;                           (list "A1" "HATCH")
        ;                         )
        ; )
        (setq Prefix_filter_name_ 2nd_filter_val_main)
        (setq main_filter_name_next_ 3rd_filter_val_main )
        (setq sub_filter_nameset_ 4th_filter_val_main)
      ;
      ;
    ;
    ;preloop_and_while_main_filter
      (setq main_filter_name_next_i 0)
      (while (< main_filter_name_next_i (length main_filter_name_next_))
        (setq main_filter_name_next_val_ (nth  main_filter_name_next_i main_filter_name_next_))
        (if (and 
              (= 1 1)
            )
          (progn
            ;preloop_and_while
              ;preloop_and_while
                (setq sub_filter_nameset_i 0)
                (while (< sub_filter_nameset_i (length sub_filter_nameset_))
                  (setq sub_filter_nameset_val_ (car (nth  sub_filter_nameset_i sub_filter_nameset_)))
                  (setq bypass_lv nil)
                  (command "-layer" 
                           "filter"
                           "edit"
                            (strcat Prefix_filter_name_  
                                    (substr main_filter_name_next_val_ 1 20)
                                    "_"
                                    (TAS:StringSubst-for-createlayer 
                                      "_1"
                                    (cond
                                      ( ;case1
                                        (or 
                                          (= (wcmatch sub_filter_nameset_val_ "*_1") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_2") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_3") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_4") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_5") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_6") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_7") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_8") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_9") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_10") T )
                                        )
                                        (progn 
                                          (TA:rightstr sub_filter_nameset_val_ 2)
                                        )
                                      )
                                      ( ;case2
                                        (or 
                                          (= (wcmatch sub_filter_nameset_val_ "*_251") T )
                                        )
                                        (progn 
                                          (TA:rightstr sub_filter_nameset_val_ 4)
                                        )
                                      )
                                      ( ;case1
                                        (and
                                          (/= (wcmatch sub_filter_nameset_val_ "*_1") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_2") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_3") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_4") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_5") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_6") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_7") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_8") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_9") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_10") T )
                                          (/= (wcmatch sub_filter_nameset_val_ "*_251") T )
                                        )
                                        (progn 
                                          "XIOIOXIOXOXIOXชื่อมั่วๆ"
                                        )
                                      )
                                    )
                                      sub_filter_nameset_val_
                                    )
                            ); (Filter name must be sensitibe case)
                          "add"
                          (strcat "*" Prefix_filter_name_ main_filter_name_next_val_ "_" sub_filter_nameset_val_ "*") ;(add layer name to filter, Can use wildcard for adding)
                          "x" ""
                  )

                  (setq sub_filter_nameset_i (+ sub_filter_nameset_i 1))
                )
              ;
                ; (command "-layer" "filter" "new" "group" "" wildcard_layer_name_ main_filter_name_next_val_sval_ ""  )    
                
                
            ;
          )
        )
        (setq main_filter_name_next_i (+ main_filter_name_next_i 1))
      )
    ;
  )
  (defun c:xref_filter ()
    (setq all-layer_ (TA:get_name_layer_in_drawing))
    ;ละเอียดนะ อินพุดที่โค้ดเถอะ
    ;preloop_and_while filter xref
      (setq prefix_filter_namefile_ "W-1-PP17-AR-4150-01-A -test")
      (setq prefix_filter_main-name_ "009 - AHP_06_")
      (setq all-layer_i 0)
      (setq xref-filter ())
      (while (< all-layer_i (length all-layer_))
        (setq all-layer_name_ (nth  all-layer_i all-layer_))
        (if (and 
              (= (wcmatch all-layer_name_ (strcat "" prefix_filter_namefile_ "*")) T)
              (= (wcmatch all-layer_name_ (strcat "*|" prefix_filter_main-name_ "*")) T)
            )
          (progn
            (setq xref-filter (cons all-layer_name_ xref-filter))
            (setq xref-filter_length (length xref-filter))
          )
        )
    
        (setq all-layer_i (+ all-layer_i 1))
      )
    ;
    (TA:generate_filter_list
      (setq 1st_filter_ (strcat "xref" "_" prefix_filter_namefile_)) ;1s_filter
      (setq 2nd_filter_val_main (strcat prefix_filter_main-name_  )) ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                      "PANEL" ;
                                      "BK" 
                                      "FRAMING" ;
                                      "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN" 0 100 100) ;
                                      (list "SUB" 0 100 100) ;
                                )
      )
    )
    
    ;preloop_and_while ;add xref prefix to filter floder
      ;lv1
      (setq 3rd_filter_val_main_i 0)
      (while (< 3rd_filter_val_main_i (length 3rd_filter_val_main))
        (setq 3rd_filter_val_main_ (nth  3rd_filter_val_main_i 3rd_filter_val_main))
        (command "-LAYER" "FILTER" "rename" 
                 (strcat prefix_filter_main-name_ 3rd_filter_val_main_ )
                 (strcat "xref" "_" prefix_filter_main-name_ 3rd_filter_val_main_ )
                 "exit"
                 ""
        )
        ;preloop_and_while
          (setq 4th_filter_val_main_i 0)
          (while (< 4th_filter_val_main_i (length 4th_filter_val_main))
            (setq 4th_filter_val_main_ename_ (car (nth  4th_filter_val_main_i 4th_filter_val_main)))
            (command "-LAYER" "FILTER" "rename" 
                 (strcat prefix_filter_main-name_ 3rd_filter_val_main_ "_" 4th_filter_val_main_ename_)
                 (strcat "xref" "_"prefix_filter_main-name_ 3rd_filter_val_main_ "_" 4th_filter_val_main_ename_ )
                 "exit"
                 ""
            )
            (setq 4th_filter_val_main_i (+ 4th_filter_val_main_i 1))
          )
        ;   
    
        (setq 3rd_filter_val_main_i (+ 3rd_filter_val_main_i 1))
      )
      (command "-LAYER" "FILTER" "rename" 
                 (strcat prefix_filter_main-name_  )
                 (strcat "xref" "_" prefix_filter_main-name_  )
                 "exit"
                 ""
      )
    ;
  )

  ;COMMENT_FUNC
    (defun c:crelaycomment ()
      (TA:generate_filter_list
        (setq 1st_filter_ "000 - ") ;1s_filter
        (setq 2nd_filter_val_main "FAMELINE-COMMENT_") ;2nd_filter
        (setq 3rd_filter_val_main (list ;3rd_filter
                                    "CEILING" ;
                                    "CL-REV" ;
                                  )
        )
        (setq 4th_filter_val_main (list  ;4th_filter
                                        (list "MAIN_COLOR_1" 255 0 0) ;
                                        (list "MAIN_COLOR_2" 255 255 0) ;
                                        (list "MAIN_COLOR_3" 0 255 0) ;
                                        (list "MAIN_COLOR_4" 0 255 255) ;
                                        (list "MAIN_COLOR_5" 0 0 255) ;
                                        (list "SUB_COLOR_1" 255 0 0) ;
                                        (list "SUB_COLOR_2" 255 255 0) ;
                                        (list "SUB_COLOR_3" 0 255 0) ;
                                        (list "SUB_COLOR_4" 0 255 255) ;
                                        (list "SUB_COLOR_4" 0 127 255) ;
                                        (list "HATCH_" 251) ;
                                        (list "WIPEOUT_" 250) ;
                                        (list "HIDDEN_" 251) ;
                                        (list "SYMBOL_" 255 0 0) ;
                                        (list "DEF_SUB" 250) ;
                                        (list "TEXT" 5) ;
                                        (list "DIMS" 0 0 255) ;
                                  )
        )
      )
    )
  ;
  ;ASBUILT_FUNC
    (defun c:crelayAS2 ()
      (TA:generate_filter_list
        (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
        (setq 2nd_filter_val_main "000 - SYMBOL CON_2_") ;2nd_filter
        (setq 3rd_filter_val_main (list ;3rd_filter
                                    "ASBUILT_WALL" ;
                                    "COMMENT_ASBUILT_WALL" ;
                                  )
        )
        (setq 4th_filter_val_main (list  ;4th_filter
                                        (list "MAIN_COLOR_1" 255 0 0) ;
                                        (list "MAIN_COLOR_2"  255 135 0) ;
                                        (list "SUB_COLOR_1" 0 255 0) ;
                                        (list "SUB_COLOR_2" 255 0 255) ;
                                        (list "SUB_COLOR_3" 0 255 255) ;
                                        (list "SUB_COLOR_4" 0 127 255) ;
                                        (list "HATCH_" 251) ;
                                        (list "WIPEOUT_" 250) ;
                                        (list "HIDDEN_" 251) ;
                                        (list "SYMBOL_" 255 0 0) ;
                                        (list "DEF_SUB" 250) ;
                                        (list "TEXT" 5) ;
                                        (list "DIMS" 0 0 255) ;
                                  )
        )
      )
    )
    (defun c:crelayAS3 ()
      (TA:generate_filter_list
        (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
        (setq 2nd_filter_val_main "000 - SYMBOL CON_3_") ;2nd_filter
        (setq 3rd_filter_val_main (list ;3rd_filter
                                    "ASBUILT_WALL" ;
                                    "COMMENT_ASBUILT_WALL" ;
                                  )
        )
        (setq 4th_filter_val_main (list  ;4th_filter
                                        (list "MAIN_COLOR_1" 255 0 0) ;
                                        (list "MAIN_COLOR_2"  255 135 0) ;
                                        (list "SUB_COLOR_1" 152 5 190) ;
                                        (list "SUB_COLOR_2" 1) ;
                                        (list "SUB_COLOR_3" 251) ;
                                        (list "HATCH_" 251) ;
                                        (list "WIPEOUT_" 250) ;
                                        (list "HIDDEN_" 251) ;
                                        (list "SYMBOL_" 255 0 0) ;
                                        (list "DEF_SUB" 250) ;
                                        (list "TEXT" 5) ;
                                        (list "DIMS" 0 0 255) ;
                                  )
        )
      )
    )
  ;
  (defun c:runset1 ()
    (defun TA:choice_ (i)
      (setq main_filter_name_ovl_
        (list  
          (TA:generate_filter_list
            "PPLINE-FAMELINE" ;1s_filter
            (setq 2nd_filter_val_main "000_CLIP-IN_") ;2nd_filter
            (setq 3rd_filter_val_main (list ;3rd_filter
                                        "PANEL_" ;
                                        "ACESSORIES_" ;
                                        "SUBFAME_" ;
                                  )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                        (list "MAIN_COLOR_1" 3) ;
                                        (list "MAIN_COLOR_2" 2) ;
                                        (list "SUB_COLOR_1" 1) ;
                                        (list "SUB_COLOR_2" 1) ;
                                        (list "SUB_COLOR_3" 251) ;
                                        (list "HATCH_" 251) ;
                                        (list "WIPEOUT_" 250) ;
                                        (list "HIDDEN_" 251) ;
                                        (list "SYMBOL_" 251) ;
                                        (list "DEF_SUB" 250) ;
                                  )
            )
          )
          
          (TA:generate_filter_list
            (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
            (setq 2nd_filter_val_main "000 - SYMBOL CON_") ;2nd_filter
            (setq 3rd_filter_val_main (list ;3rd_filter
                                        "TYPEICAL" ;
                                        "ASBUILT_WALL" ;
                                      )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "MAIN_COLOR_1" 255 0 0) ;
                                            (list "MAIN_COLOR_2"  255 135 0) ;
                                            (list "SUB_COLOR_1" 152 5 190) ;
                                            (list "SUB_COLOR_2" 1) ;
                                            (list "SUB_COLOR_3" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                            (list "TEXT" 5) ;
                                      )
            )
          )
          (TA:generate_filter_list
            (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
            (setq 2nd_filter_val_main "000_FASTERN_") ;2nd_filter
            (setq 3rd_filter_val_main (list ;3rd_filter
                                        "HEX-BOLT" ;
                                        "BRACKET" ;
                                  )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "MAIN_COLOR_1" 3) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "SUB_COLOR_1" 1) ;
                                            (list "SUB_COLOR_2" 3) ;
                                            (list "SUB_COLOR_3" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                      )
            )
          )
          (TA:generate_filter_list 
            (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
            (setq 2nd_filter_val_main "FRAMING_") ;2nd_filter
            (setq 3rd_filter_val_main (list  ;3rd_filter
                                            "ACESSORIES"
                                            "CC-01" ;
                                            "HR-02A" ;
                                            "HR-02B" ;
                                            "HR-09B" ;
                                            "HANGING" ;
                                      )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
            )
          )
          
          ;light
          (TA:generate_filter_list 
            (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
            (setq 2nd_filter_val_main "008 - LIGHT_") ;2nd_filter
            (setq 3rd_filter_val_main (list  ;3rd_filter
                                            "FLUORESCENT" ;
                                            "DN" ;
                                      )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "CUT_COLOR_1" 1) ;
                                            (list "CUT_COLOR_2" 2) ;
                                            (list "CUT_COLOR_3" 3) ;
                                            (list "CUT_COLOR_4" 4) ;
                                            (list "CUT_COLOR_5" 5) ;
                                            (list "CUT_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_1" 1) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "MAIN_COLOR_3" 3) ;
                                            (list "MAIN_COLOR_4" 4) ;
                                            (list "MAIN_COLOR_5" 5) ;
                                            (list "MAIN_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_251" 251) ;
                                            (list "SUB_COLOR_1" 2) ;
                                            (list "SUB_COLOR_2" 2) ;
                                            (list "SUB_COLOR_3" 3) ;
                                            (list "SUB_COLOR_4" 4) ;
                                            (list "SUB_COLOR_5" 5) ;
                                            (list "SUB_COLOR_6" 6) ;
                                            (list "SUB_COLOR_8" 8) ;
                                            (list "SUB_COLOR_251" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                            (list "TEXT_COLOR_1" 1) ;
                                            ;
                                      )
            )
          )
          (TA:generate_filter_list 
            (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
            (setq 2nd_filter_val_main "008 - AIR_") ;2nd_filter
            (setq 3rd_filter_val_main (list  ;3rd_filter
                                            "MASK" ;
                                      )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "CUT_COLOR_1" 1) ;
                                            (list "CUT_COLOR_2" 2) ;
                                            (list "CUT_COLOR_3" 3) ;
                                            (list "CUT_COLOR_4" 4) ;
                                            (list "CUT_COLOR_5" 5) ;
                                            (list "CUT_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_1" 1) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "MAIN_COLOR_3" 3) ;
                                            (list "MAIN_COLOR_4" 4) ;
                                            (list "MAIN_COLOR_5" 5) ;
                                            (list "MAIN_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_251" 251) ;
                                            (list "SUB_COLOR_1" 2) ;
                                            (list "SUB_COLOR_2" 2) ;
                                            (list "SUB_COLOR_3" 3) ;
                                            (list "SUB_COLOR_4" 4) ;
                                            (list "SUB_COLOR_5" 5) ;
                                            (list "SUB_COLOR_6" 6) ;
                                            (list "SUB_COLOR_8" 8) ;
                                            (list "SUB_COLOR_251" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                            (list "TEXT_COLOR_1" 1) ;
                                            ;
                                      )
            )
          )
          (TA:generate_filter_list 
            (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
            (setq 2nd_filter_val_main "008 - E&M_") ;2nd_filter
            (setq 3rd_filter_val_main (list  ;3rd_filter
                                            "ACESSORIES" ;
                                            "ALARM" ;
                                      )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "CUT_COLOR_1" 1) ;
                                            (list "CUT_COLOR_2" 2) ;
                                            (list "CUT_COLOR_3" 3) ;
                                            (list "CUT_COLOR_4" 4) ;
                                            (list "CUT_COLOR_5" 5) ;
                                            (list "CUT_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_1" 1) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "MAIN_COLOR_3" 3) ;
                                            (list "MAIN_COLOR_4" 4) ;
                                            (list "MAIN_COLOR_5" 5) ;
                                            (list "MAIN_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_251" 251) ;
                                            (list "SUB_COLOR_1" 2) ;
                                            (list "SUB_COLOR_2" 2) ;
                                            (list "SUB_COLOR_3" 3) ;
                                            (list "SUB_COLOR_4" 4) ;
                                            (list "SUB_COLOR_5" 5) ;
                                            (list "SUB_COLOR_6" 6) ;
                                            (list "SUB_COLOR_8" 8) ;
                                            (list "SUB_COLOR_251" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                            (list "TEXT_COLOR_1" 1) ;
                                            ;
                                      )
            )
          )
        )
      ) 
      (nth i main_filter_name_ovl_)
    )
    (TA:choice_ 1)
    (setq i 0)
    (setq main_filter_name_ (nth 0 main_filter_name_ovl_))
    (c:create_main_and_sub_filter_creF4 (TA:choice_ i))
    (c:c reate_layerset_Lset4)
    (c:add_layer_main_and_sub_filter_addLFilter_ADD_LF4)
  )
  (defun c:crelaylight ()
    (TA:generate_filter_list 
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "008 - LIGHT_") ;2nd_filter
      (setq 3rd_filter_val_main (list  ;3rd_filter
                                      "FLUORESCENT" ;
                                      "DN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                )
      )
    )
    (TA:generate_filter_list 
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "008 - AIR_") ;2nd_filter
      (setq 3rd_filter_val_main (list  ;3rd_filter
                                      "MASK" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                )
      )
    )
    (TA:generate_filter_list 
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "008 - E&M_") ;2nd_filter
      (setq 3rd_filter_val_main (list  ;3rd_filter
                                      "SIGNAGE" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 1) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                )
      )
    )
    (TA:generate_filter_list 
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "008 - E&M_") ;2nd_filter
      (setq 3rd_filter_val_main (list  ;3rd_filter
                                      "ACESSORIES" ;
                                      "ALARM" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                )
      )
    )
  )
  (defun c:crelaysymbol ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - SYMBOL CON_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "TYPICAL" ;
                                  "ASBUILT_WALL" ;
                                  "COMMENT_ASBUILT_WALL" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 255 0 0) ;
                                      (list "MAIN_COLOR_2"  255 135 0) ;
                                      (list "SUB_COLOR_1" 152 5 190) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 5) ;
                                )
      )
    )
  )
  (defun c:creestimate ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - ESTIMATE_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "ASPG" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter

                                      ;; MAIN
                                      (list "MAIN_COLOR_1" 255 0 0) ; Red
                                      (list "MAIN_COLOR_2" 255 255 0) ; Yellow
                                      (list "MAIN_COLOR_3" 0 255 0) ; Green
                                      (list "MAIN_COLOR_4" 0 255 255) ; Cyan
                                      (list "MAIN_COLOR_5" 0 0 255) ; Blue
                                      (list "MAIN_COLOR_6" 255 0 255) ; Magenta
                                      (list "MAIN_COLOR_7" 0 0 0) ; Black

                                      ;; SUB
                                      (list "SUB_COLOR_1" 255 0 0) ; red
                                      (list "SUB_COLOR_2" 255 255 0) ; Yellow
                                      (list "SUB_COLOR_3" 0 255 0) ; Green
                                      (list "SUB_COLOR_4" 0 255 255) ; Cyan
                                      (list "SUB_COLOR_5" 0 0 255) ; Blue
                                      (list "SUB_COLOR_6" 255 0 255) ; Magenta
                                      (list "SUB_COLOR_7" 0 0 0) ; Black

                                      ;; OTHER
                                      (list "HATCH_" 251)
                                      (list "WIPEOUT_" 250)
                                      (list "HIDDEN_" 251)
                                      (list "SYMBOL_" 251)
                                      (list "DEF_SUB" 250)

                                      ;; TEXT
                                      (list "TEXT_COLOR_1" 255 0 0) ; Red
                                      (list "TEXT_COLOR_2" 255 255 0) ; Yellow
                                      (list "TEXT_COLOR_3" 0 255 0) ; Green
                                      (list "TEXT_COLOR_4" 0 255 255) ; Cyan
                                      (list "TEXT_COLOR_5" 0 0 255) ; Blue
                                      (list "TEXT_COLOR_6" 255 0 255) ; Magenta
                                      (list "TEXT_COLOR_7" 0 0 0) ; Black
                                )
      )
    )
  )
  (defun c:crelayfas ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000_FASTERN_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "HEX-BOLT" ;
                                  "BRACKET" ;
                            )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 3) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                )
      )
    )
  )
  (defun c:crelayaltray ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "009_ALTRAY_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL" ;
                            )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 3) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 251) ;
                                )
      )
    )
  )
  (defun c:crelayaltray ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "009_ALTRAY_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "DIMS" ;
                            )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 255 0 0) ;
                                )
      )
    )
  )
  (defun c:crelayarea ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000_AREA_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "C02" ;
                                  "C03" ;
                                  "C04" ;
                                  "C05" ;
                                  "C06" ;
                                  "C07" ;
                                  "C08" ;
                                  "C09" ;
                                  "C10" ;
                                  "C11"
                                  "ASPG_AREA" ;
                            )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 255 135 0) ;
                                      (list "HATCH_" 255 135 0) ;

                                )
      )
    )
  )
  (defun c:crelayAHP06 ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "009 - AHP_06_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "BK"
                                  "PANEL" ;
                                  "FRAMING" ;
                                  "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "009 - AHP_06_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "DIMS" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "OVERALL" 1) ;
                                      (list "NOM" 1) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "009 - AHP_07_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL" ;
                                  "FRAMING" ;
                                  "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "009 - AHP_07_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "DIMS" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "OVERALL" 1) ;
                                      (list "NOM" 1) ;
                                       ;
                                )
      )
    )
  )
  (defun c:crelaysmoke ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-SUBPLIER") ;1s_filter
      (setq 2nd_filter_val_main "SMOKE_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "GL -FIN" ;
                                  "FRAMING" ;
                                  "BARRIER" ;
                                  "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    
  )
  (defun c:crelayASPG ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - ASPG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "EXTR" ;
                                  "FRAMING" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "CUT_COLOR_6" 6) ;
                                  
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                  
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                  
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - ASPG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "ACCESSORIES" ;
                                  "FLASHING" ;
                                  "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - ASPG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "DIMS" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "OVERALL" 1) ;
                                      (list "NOM" 1) ;
                                       ;
                                )
      )
    )
  )
  (defun c:crelaynewsmoke ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "020 - SMOKE") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "FRAMING" ;
                                  "ACCESORIES" ;
                                  "GLASS_FIN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    
    
  )
  (defun c:crelayASPGSTFRAME ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - STRUCTURE_STEEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "FRAMING" ;
                                  "ROOF" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "CUT_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - STRUCTURE_STEEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "ACCESORIES" ;
                                  "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_1" 2) ;
                                      (list "MAIN_COLOR_2" 1) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
  )

  (defun c:crelayexbuilding ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - EXISTING_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "BUILDING" ;
                                  "FINISHING-WALL" ;
                                  "MANSORY-WALL" ;
                                  "AAC-WALL" ;
                                  "COLUMN" ;
                                  "LOUVERS"
                                  "CANOPY"
                                  "DIM"
                                  "PRECAST"
                                  "CONCRETE" ;
                                  "STEEL-STRUCTURE" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "CUT_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 5) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                      ;
                                )
      )
    ) 
     
  )
  (defun c:crelay ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - CONCRETE_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "COL" ;
                                  "WALL" ;
                                  "PRECAST" ;
                                  "PLENUM-WALL" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
  )
  (defun c:crelayHIDEOBJ_ ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - 0_HIDE_OBJ_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "FRAMING" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "DEF_SUB_1" 250) ;
                                      (list "DEF_SUB_2" 250) ;
                                      (list "DEF_DIMS" 250) ;

                                       ;
                                )
      )
    )
    
  )
  (defun c:crelayFLsymbol_1 ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - 0_SYM_DWG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "GRIDLINE" ;
                                  "GRID-BUBBLE" ;
                                  "BUBBLE" ;
                                  "HIDDENlINE" ;
                                  "DIMS" ;
                                  "LEVEL" ;
                                  "INDICATOR" ;
                                  "BREAKER" ;
                                  "GROUND" ;
                                  "TITTLE-BLOCK";
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "CUT_COLOR_251" 251) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_8" 8) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT_COLOR_1" 1) ;
                                      (list "TEXT_COLOR_2" 2) ;
                                      (list "TEXT_COLOR_3" 3) ;
                                      (list "TEXT_COLOR_4" 4) ;
                                      (list "TEXT_COLOR_5" 5) ;
                                      (list "TEXT_COLOR_6" 6) ;
                                      (list "TEXT_COLOR_251" 251) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - 0_SYM_DWG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "HEADING" ;
                                  "SECTION" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "CUT_COLOR_251" 251) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_8" 8) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT_COLOR_1" 1) ;
                                      (list "TEXT_COLOR_2" 2) ;
                                      (list "TEXT_COLOR_3" 3) ;
                                      (list "TEXT_COLOR_4" 4) ;
                                      (list "TEXT_COLOR_5" 5) ;
                                      (list "TEXT_COLOR_6" 6) ;
                                      (list "TEXT_COLOR_251" 251) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - 0_SYM_DWG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "DIMS" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_9" 9) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_9" 9) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT_COLOR_1" 1) ;
                                      (list "TEXT_COLOR_2" 2) ;
                                      (list "TEXT_COLOR_3" 3) ;
                                      (list "TEXT_COLOR_4" 4) ;
                                      (list "TEXT_COLOR_5" 5) ;
                                      (list "TEXT_COLOR_6" 6) ;
                                       ;
                                )
      )
    )
  )
  (defun c:crelayFLsymbol_2 ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - 0_SYM_DWG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "STAMPBOX" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT_COLOR_1" 1) ;
                                      (list "TEXT_COLOR_2" 2) ;
                                      (list "TEXT_COLOR_3" 3) ;
                                      (list "TEXT_COLOR_4" 4) ;
                                      (list "TEXT_COLOR_5" 5) ;
                                      (list "TEXT_COLOR_6" 6) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - 0_SYM_DWG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "DIMS" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT_COLOR_1" 1) ;
                                      (list "TEXT_COLOR_2" 2) ;
                                      (list "TEXT_COLOR_3" 3) ;
                                      (list "TEXT_COLOR_4" 4) ;
                                      (list "TEXT_COLOR_5" 5) ;
                                      (list "TEXT_COLOR_6" 6) ;
                                       ;
                                )
      )
    )  
  )
  (defun c:crelayFLsymbol_3 ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - 0_SYM_DWG_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "SECTION-SYM" ;
                                  "SLOPE-SYM" ;
                                  
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_6" 6) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT_COLOR_1" 1) ;
                                      (list "TEXT_COLOR_2" 2) ;
                                      (list "TEXT_COLOR_3" 3) ;
                                      (list "TEXT_COLOR_4" 4) ;
                                      (list "TEXT_COLOR_5" 5) ;
                                      (list "TEXT_COLOR_6" 6) ;
                                       ;
                                )
      )
    )
  )
  (defun c:crelayFLpart ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - PART-SYMBOL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "SECTION-SYM" ;
                                  "SLOPE-SYM" ;
                                  "GRIDLINE" ;
                                  "GRID-BUBBLE" ;
                                  "HIDDENlINE" ;
                                  "DIMS" ;
                                  "LEVEL" ;
                                  "INDICATOR" ;
                                  "BREAKER" ;
                                  "GROUND" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "CUT_COLOR_251" 251) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "000 - PART-SYMBOL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "TITTLE-BLOCK" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "CUT_COLOR_1" 1) ;
                                      (list "CUT_COLOR_2" 2) ;
                                      (list "CUT_COLOR_3" 3) ;
                                      (list "CUT_COLOR_4" 4) ;
                                      (list "CUT_COLOR_5" 5) ;
                                      (list "CUT_COLOR_251" 251) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "MAIN_COLOR_251" 251) ;
                                      (list "SUB_COLOR_1" 2) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
  )
  (defun c:crelaytemp ()
    (c:crelayarea)
    (c:crelaylight)
    (c:crelaysymbol)
    (c:crelayfram)
    (c:crelayfas)
    (c:crelayaltray)
  )
  (defun c:crelayaspgset ()
    (c:crelayHIDEOBJ_)
    (c:crelayASPG)
    (c:crelayASPGSTFRAME)
    (c:crelayHIDEOBJ_)
    (c:crelayFLsymbol_)
  )
  (defun c:crelay300HK ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "C0x_300HK_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL" ;
                                  "CODE" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "C04" 1) ;
                                      (list "C05" 1) ;
                                      (list "C08" 3) ;
                                      (list "C09" 5) ;
                                      (list "C10" 1) ;
                                      (list "MAIN_COLOR_1" 1) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 3) ;
                                      (list "MAIN_COLOR_4" 4) ;
                                      (list "MAIN_COLOR_5" 5) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 2) ;
                                      (list "SUB_COLOR_3" 3) ;
                                      (list "SUB_COLOR_4" 4) ;
                                      (list "SUB_COLOR_5" 5) ;
                                      (list "SUB_COLOR_6" 6) ;
                                      (list "SUB_COLOR_8" 8) ;
                                      (list "SUB_COLOR_251" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
                                      (list "TEXT" 3) ;
                                       ;
                                )
      )
    )
  )
  (defun c:crelayalutray_ ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - ALU_TRAY_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL" ;
                                  "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "CUT_COLOR_1" 1) ;
                                            (list "CUT_COLOR_2" 2) ;
                                            (list "CUT_COLOR_3" 3) ;
                                            (list "CUT_COLOR_4" 4) ;
                                            (list "CUT_COLOR_5" 5) ;
                                            (list "CUT_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_1" 1) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "MAIN_COLOR_3" 3) ;
                                            (list "MAIN_COLOR_4" 4) ;
                                            (list "MAIN_COLOR_5" 5) ;
                                            (list "MAIN_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_251" 251) ;
                                            (list "SUB_COLOR_1" 2) ;
                                            (list "SUB_COLOR_2" 2) ;
                                            (list "SUB_COLOR_3" 3) ;
                                            (list "SUB_COLOR_4" 4) ;
                                            (list "SUB_COLOR_5" 5) ;
                                            (list "SUB_COLOR_6" 6) ;
                                            (list "SUB_COLOR_8" 8) ;
                                            (list "SUB_COLOR_251" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                            (list "TEXT_COLOR_1" 1) ;
                                            ;
                                      )
            )
    )
  )
  (defun c:crelayalutray_ ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - ALU_TRAY_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "SOLID-SHEET" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "CUT_COLOR_1" 1) ;
                                            (list "CUT_COLOR_2" 2) ;
                                            (list "CUT_COLOR_3" 3) ;
                                            (list "CUT_COLOR_4" 4) ;
                                            (list "CUT_COLOR_5" 5) ;
                                            (list "CUT_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_1" 1) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "MAIN_COLOR_3" 3) ;
                                            (list "MAIN_COLOR_4" 4) ;
                                            (list "MAIN_COLOR_5" 5) ;
                                            (list "MAIN_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_251" 251) ;
                                            (list "SUB_COLOR_1" 2) ;
                                            (list "SUB_COLOR_2" 2) ;
                                            (list "SUB_COLOR_3" 3) ;
                                            (list "SUB_COLOR_4" 4) ;
                                            (list "SUB_COLOR_5" 5) ;
                                            (list "SUB_COLOR_6" 6) ;
                                            (list "SUB_COLOR_8" 8) ;
                                            (list "SUB_COLOR_251" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                            (list "TEXT_COLOR_1" 1) ;
                                            ;
                                      )
            )
    )
  )
  (defun c:crelayC10panel ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - C10_PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL";
                                  "BACK-PANEL";
                                  "SOLID-SHEET"
                                  "SOLID-SHEET"
                                  "ACCESSORIES"
                                  "ACCESSORIES-HR-A"
                                  "ACCESSORIES-HR-B"
                                  "ACCESSORIES-HR-09"
                                  "ACCESSORIES-BK-07"
                                  "ACCESSORIES-BK-08"
                                  "ACCESSORIES-FASTERN"
                                  "FRAMING" ;
                                  "FRAMING-CC01" ;
                                  "FASTERN" ;
                                  "DIMS"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - C10_PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "CLAMP-LOCK" ;
                                  "CLAMP-RAIL" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
  )
  (defun c:crelayC07panel ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - C07_PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL";
                                  "ACCESSORIES"
                                  "AG25"
                                  "FASTERN"
                                  "FRAMING" ;
                                  "FASTERN" ;
                                  "DIMS"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - C07_PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "AG25"
                                  "FASTERN"

                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - C07_PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "MN-BK"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
  )
  (defun c:crelay300panel ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - 300-PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL";
                                  "BACK-PANEL";
                                  "ACCESSORIES"
                                  "ACCESSORIES-HR-A"
                                  "ACCESSORIES-HR-B"
                                  "ACCESSORIES-HR-09"
                                  "ACCESSORIES-BK-07"
                                  "ACCESSORIES-BK-08"
                                  "ACCESSORIES-FASTERN"
                                  "FRAMING" ;
                                  "FASTERN" ;
                                  "DIMS"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
    
  )
  (defun c:crelayextrusion_rail ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - EXTRUSION-RAIL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "EXTRUSION_LINE";
                                  "ACCESSORIES"
                                  "FASTERN" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
  )
  (defun c:crelayC02panel ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - C02_PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL";
                                  "SOLID-SHEET"
                                  "CLAMP-LOCK" ;
                                  "CLAMP-RAIL" ;
                                  "FRAMING" ;
                                  "ACESSORIES" ;
                                  "FASTERN" ;
                                  "DIMS"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 1) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
  )
  (defun c:crelay3000panel ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - Cxx_300-PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL";
                                  "PERFORATED";
                                  "ACCESSORIES"
                                  "U-HOOK"
                                  "V-HOOK"
                                  "FRAMING" ;
                                  "FASTERN" ;
                                  "DIMS"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 2) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
    
  )
  (defun c:crelayC10existing ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "010 - C10_EXISTING_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "EX" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "CUT_COLOR_1" 1) ;
                                            (list "CUT_COLOR_2" 2) ;
                                            (list "CUT_COLOR_3" 3) ;
                                            (list "CUT_COLOR_4" 4) ;
                                            (list "CUT_COLOR_5" 5) ;
                                            (list "CUT_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_1" 1) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "MAIN_COLOR_3" 3) ;
                                            (list "MAIN_COLOR_4" 4) ;
                                            (list "MAIN_COLOR_5" 5) ;
                                            (list "MAIN_COLOR_6" 6) ;
                                            (list "MAIN_COLOR_251" 251) ;
                                            (list "SUB_COLOR_1" 2) ;
                                            (list "SUB_COLOR_2" 2) ;
                                            (list "SUB_COLOR_3" 3) ;
                                            (list "SUB_COLOR_4" 4) ;
                                            (list "SUB_COLOR_5" 5) ;
                                            (list "SUB_COLOR_6" 6) ;
                                            (list "SUB_COLOR_8" 8) ;
                                            (list "SUB_COLOR_251" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
                                            (list "TEXT_COLOR_1" 1) ;
                                            (list "TEXT_COLOR_2" 2) ;
                                            (list "TEXT_COLOR_3" 3) ;
                                            (list "TEXT_COLOR_3" 3) ;
                                            (list "TEXT_COLOR_4" 4) ;
                                            (list "TEXT_COLOR_5" 5) ;
                                            (list "TEXT_COLOR_6" 6) ;
                                            ;
                                      )
            )
    )
  )
  (defun c:CcrelayC02C03 ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "002 - C02-PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL";
                                  "SOLID-SHEET"
                                  "ACCESSORIES"
                                  "FRAMING" ;
                                  "FASTERN" ;
                                  "DIMS"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 2) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "003 - C03-PANEL_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "PANEL";
                                  "SOLID-SHEET"
                                  "ACCESSORIES"
                                  "FRAMING" ;
                                  "FASTERN" ;
                                  "DIMS"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 2) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
  )
  (defun c:crelaycombineaspg ()
    (TA:generate_filter_list
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "COMBINE_") ;2nd_filter
      (setq 3rd_filter_val_main (list ;3rd_filter
                                  "SINGLE-BLADE";
                                  "DOUBLE-BLADE"
                                  "ACCESSORIES"
                                  "EXTR-FRAMING" ;
                                  "FASTERN" ;
                                  "DIMS"
                                  "TEXT"
                                  "BRAKCET"
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                    (list "CUT_COLOR_1" 1) ;
                                    (list "CUT_COLOR_2" 2) ;
                                    (list "CUT_COLOR_3" 3) ;
                                    (list "CUT_COLOR_4" 4) ;
                                    (list "CUT_COLOR_5" 5) ;
                                    (list "CUT_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_1" 1) ;
                                    (list "MAIN_COLOR_2" 2) ;
                                    (list "MAIN_COLOR_3" 3) ;
                                    (list "MAIN_COLOR_4" 4) ;
                                    (list "MAIN_COLOR_5" 5) ;
                                    (list "MAIN_COLOR_6" 6) ;
                                    (list "MAIN_COLOR_251" 251) ;
                                    (list "SUB_COLOR_1" 2) ;
                                    (list "SUB_COLOR_2" 2) ;
                                    (list "SUB_COLOR_3" 3) ;
                                    (list "SUB_COLOR_4" 4) ;
                                    (list "SUB_COLOR_5" 5) ;
                                    (list "SUB_COLOR_6" 6) ;
                                    (list "SUB_COLOR_8" 8) ;
                                    (list "SUB_COLOR_251" 251) ;
                                    (list "HATCH_" 251) ;
                                    (list "WIPEOUT_" 250) ;
                                    (list "HIDDEN_" 251) ;
                                    (list "SYMBOL_" 251) ;
                                    (list "DEF_SUB" 250) ;
                                    (list "TEXT_COLOR_1" 1) ;
                                    (list "TEXT_COLOR_2" 2) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_3" 3) ;
                                    (list "TEXT_COLOR_4" 4) ;
                                    (list "TEXT_COLOR_5" 5) ;
                                    (list "TEXT_COLOR_6" 6) ;
                                    ;
                              )
      )
    )
  )
  

      

;
(defun :LayerFilterList (/ :SubFilterList) 

  ; su returns list of main filter and sub filters right behind
  (defun :SubFilterList (dict / ent lst) 
    (foreach ent 
      (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= (car x) 350)) dict))
      (setq lst (append lst 
                        (cons ent 
                              (if (assoc 360 (entget ent)) 
                                (:SubFilterList 
                                  (entget 
                                    (cdr 
                                      (assoc 360 
                                             (entget (cdr (assoc 360 (entget ent))))
                                      )
                                    )
                                  )
                                )
                              )
                        )
                )
      )
    )
    lst
  )

  (mapcar '(lambda (x) (cdr (assoc 300 (entget x)))) 
          (:SubFilterList 
            (dictsearch 
              (vlax-vla-object->ename 
                (vla-getextensiondictionary 
                  (vla-get-layers 
                    (vla-get-activedocument 
                      (vlax-get-acad-object)
                    )
                  )
                )
              )
              "ACLYDICTIONARY"
            )
          )
  )
)
(defun test (/ dict topLevel ed ents) 
  (if 
    (setq dict (dictsearch 
                 (vlax-vla-object->ename 
                   (vla-getextensiondictionary 
                     (vla-get-layers 
                       (vla-get-activedocument 
                         (vlax-get-acad-object)
                       )
                     )
                   )
                 )
                 "ACLYDICTIONARY"
               )
    )
    (progn 
      (setq topLevel (mapcar 'cdr 
                             (vl-remove-if-not '(lambda (x) (= (car x) 350)) dict)
                     )
      )
      
      (foreach ent topLevel 
        (setq ed (entget ent))
        (if (assoc 360 ed) 

          (setq ents (append topLevel 
                             (mapcar 'cdr 
                                     (vl-remove-if-not 
                                       '(lambda (x) (= (car x) 350))
                                       (entget 
                                         (cdr 
                                           (assoc 360 
                                                  (entget (cdr (assoc 360 ed)))
                                           )
                                         )
                                       )
                                     )
                             )
                     )
          )
        )
      )
    )
  )
  (mapcar '(lambda (x) (cdr (assoc 300 (entget x)))) ents)
)

(setq lay (vla-item 
            (vla-get-layers 
              (vla-get-activedocument (vlax-get-acad-object))
            )
            "0"
          )
)


(car (:LayerFilterList))


(vl-load-com)

;; https://forums.autodesk.com/t5/visual-lisp-autolisp-and-general/retrieve-layer-names-from-group-layer-filter/m-p/8805768
(defun :grouplayerfilterswlayernames nil 
  ((lambda (foo) 
     (foo (entget (cdr (assoc 330 (entget (tblobjname "layer" "0"))))))
   ) 
   (lambda (enx / dic i itm rtn) 
     (and (setq dic (cdr (assoc 360 (member '(102 . "{ACAD_XDICTIONARY") enx)))) 
          (setq dic (cdr (assoc -1 (dictsearch dic "aclydictionary"))))
          (while (setq itm (dictnext dic (not itm))) 
            (if (= "AcLyLayerGroup" (cdr (assoc 1 itm))) 
              (setq i   (assoc 300 itm)
                    rtn (cons 
                          (list (cdr i) 
                                (mapcar 
                                  '(lambda (y) (cdr (assoc 2 (entget (cdr y)))))
                                  (vl-remove-if '(lambda (x) (/= 330 (car x))) 
                                                (member i itm)
                                  )
                                )
                          )
                          rtn
                        )
              )
            )
          )
     )
     (reverse rtn)
   )
  )
)
(:grouplayerfilterswlayernames )




(defun :layergroupon (name / lst)
  (if (setq lst (cadr (assoc name (:grouplayerfilterswlayernames))))
    (progn
      (command "_.layer")
      (foreach l lst (command "_on" l))
      (command ""))))

(defun :layergroupoff (name / lst)
  (if (setq lst (cadr (assoc name (:grouplayerfilterswlayernames))))
    (progn
      (command "_.layer")
      (if (vl-position (getvar 'clayer) lst)  ; if current layer is about to off
	(command "_t" "0" "_s" "0" "_u" ""))  ; than make 0 current.
      (foreach l lst (command "_off" l))
      (command ""))))

(defun c:PaperSpaceOn nil  (:layergroupon  "PAPER SPACE") (princ))
(defun c:PaperSpaceOff nil (:layergroupoff "PAPER SPACE") (princ))


(defun GetFilterTree (dic / itm result)
  (while (setq itm (dictnext dic (not itm)))
    (setq result
      (cons
        (list
          (cdr (assoc 300 itm)) ; filter name
          (if (assoc 360 itm)
            (GetFilterTree
              (cdr (assoc -1
                          (dictsearch
                            (cdr (assoc 360 itm))
                            ""
                          )
                    )
              )
            )
          )
        )
        result
      )
    )
  )
  (reverse result)
)





(defun dbg-step1 ( / lay0 ed owner )
  (setq lay0 (tblobjname "layer" "0"))
  (setq ed   (entget lay0))
  (setq owner (cdr (assoc 330 ed)))

  (princ "\n--- STEP 1 ---")
  (princ "\nLayer 0 ename: ") (princ lay0)
  (princ "\nOwner (LayerTable): ") (princ owner)
  (princ)
)
(defun dbg-step2 ( / lay0 ed owner xdict )
  (setq lay0 (tblobjname "layer" "0"))
  (setq ed   (entget lay0))
  (setq owner (cdr (assoc 330 ed)))
  (setq ed   (entget owner))

  (setq xdict
        (cdr
          (assoc 360
                 (member '(102 . "{ACAD_XDICTIONARY") ed)
          )
        )
  )

  (princ "\n--- STEP 2 ---")
  (princ "\nExtension Dictionary: ")
  (princ xdict)
  (princ)
)
(defun dbg-step3 ( / lay0 ed owner xdict acly )
  (setq lay0 (tblobjname "layer" "0"))
  (setq ed   (entget lay0))
  (setq owner (cdr (assoc 330 ed)))
  (setq ed   (entget owner))

  (setq xdict
        (cdr
          (assoc 360
                 (member '(102 . "{ACAD_XDICTIONARY") ed)
          )
        )
  )

  (setq acly
        (cdr
          (assoc -1
                 (dictsearch xdict "ACLYDICTIONARY")
          )
        )
  )

  (princ "\n--- STEP 3 ---")
  (princ "\nACLYDICTIONARY ename: ")
  (princ acly)
  (princ)
)
(defun dbg-step4 ( / lay0 ed owner xdict acly itm )
  (setq lay0 (tblobjname "layer" "0"))
  (setq ed   (entget lay0))
  (setq owner (cdr (assoc 330 ed)))
  (setq ed   (entget owner))

  (setq xdict
        (cdr
          (assoc 360
                 (member '(102 . "{ACAD_XDICTIONARY") ed)
          )
        )
  )

  (setq acly
        (cdr
          (assoc -1
                 (dictsearch xdict "ACLYDICTIONARY")
          )
        )
  )

  (princ "\n--- STEP 4 ---")

  (while (setq itm (dictnext acly (not itm)))
    (princ "\nFilter Class: ")
    (princ (cdr (assoc 1 itm)))
    (princ " | Name: ")
    (princ (cdr (assoc 300 itm)))
  )

  (princ)
)
(defun dbg-step5 ( / lay0 ed owner xdict acly itm )

  (setq lay0 (tblobjname "layer" "0"))
  (setq ed   (entget lay0))
  (setq owner (cdr (assoc 330 ed)))
  (setq ed   (entget owner))

  (setq xdict
        (cdr
          (assoc 360
                 (member '(102 . "{ACAD_XDICTIONARY") ed)
          )
        )
  )

  (setq acly
        (cdr
          (assoc -1
                 (dictsearch xdict "ACLYDICTIONARY")
          )
        )
  )

  (princ "\n--- STEP 5 ---")

  (while (setq itm (dictnext acly (not itm)))
    (if (= "AcLyLayerGroup" (cdr (assoc 1 itm)))
      (progn
        (princ "\n\nGroup Filter: ")
        (princ (cdr (assoc 300 itm)))

        (foreach x itm
          (if (= 330 (car x))
            (progn
              (princ "\n  Layer: ")
              (princ
                (cdr (assoc 2 (entget (cdr x))))
              )
            )
          )
        )
      )
    )
  )

  (princ)
)
(defun dbg-check-nested ( / lay0 ed owner xdict acly itm )

  (setq lay0 (tblobjname "layer" "0"))
  (setq ed   (entget lay0))
  (setq owner (cdr (assoc 330 ed)))
  (setq ed   (entget owner))

  (setq xdict
        (cdr
          (assoc 360
                 (member '(102 . "{ACAD_XDICTIONARY") ed)
          )
        )
  )

  (setq acly
        (cdr
          (assoc -1
                 (dictsearch xdict "ACLYDICTIONARY")
          )
        )
  )

  (while (setq itm (dictnext acly (not itm)))
    (if (assoc 360 itm)
      (progn
        (princ "\nFilter has sub-dictionary: ")
        (princ (cdr (assoc 300 itm)))
      )
    )
  )

  (princ)
)

