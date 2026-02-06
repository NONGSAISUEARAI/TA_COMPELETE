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

    ;(command "-layer" "filter" "n" "G" "" "*000 - CSD_PL_*" "CSD" ""  )
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
      ;   (setq Prefix_filter_name_ "000_CLIP-IN_")
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
                (if (= main_filter_name_val_i 1)
                  (progn
                    (command "-LAYER" "filter" "new" "group"  
                         (car main_filter_name_val_)
                         "" ;(add layer name to filter, Can use wildcard for adding)
                         main_filter_name_val_sval_ 
                         "" 
                    )
                  )
                    (command "-LAYER" "filter" "new" "group"  
                         (car main_filter_name_val_)
                         "" ;(add layer name to filter, Can use wildcard for adding)
                         main_filter_name_val_sval_ 
                         "" 
                    )
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
        ;                           (list "A2" "")
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
                  
                  (command "-layer" 
                           "filter"
                           "edit"
                            (strcat Prefix_filter_name_ 
                                    (substr main_filter_name_next_val_ 1 20)
                                    "_"
                                    (LM:StringSubst 
                                      "_1"
                                      (if 
                                        (or 
                                          (= (wcmatch sub_filter_nameset_val_ "*_1") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_2") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_3") T )
                                          (= (wcmatch sub_filter_nameset_val_ "*_4") T )
                                        )
                                        (progn 
                                          (TA:rightstr sub_filter_nameset_val_ 2)
                                        )
                                        "XIOIOXIOXOXIOXชื่อมั่วๆ"
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
                                            "CC-01" ;
                                            "HR-02A" ;
                                            "HR-02B" ;
                                            "HR-09B" ;
                                            "HANGING" ;
                                      )
            )
            (setq 4th_filter_val_main (list  ;4th_filter
                                            (list "MAIN_COLOR_1" 3) ;
                                            (list "MAIN_COLOR_2" 2) ;
                                            (list "MAIN_COLOR_3" 2) ;
                                            (list "MAIN_COLOR_5" 2) ;
                                            (list "SUB_COLOR_1" 1) ;
                                            (list "SUB_COLOR_2" 1) ;
                                            (list "SUB_COLOR_3" 251) ;
                                            (list "SUB_COLOR_4" 251) ;
                                            (list "SUB_COLOR_4" 251) ;
                                            (list "HATCH_" 251) ;
                                            (list "WIPEOUT_" 250) ;
                                            (list "HIDDEN_" 251) ;
                                            (list "SYMBOL_" 251) ;
                                            (list "DEF_SUB" 250) ;
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
  (defun c:crelayfram ()
    (TA:generate_filter_list 
      (setq 1st_filter_ "PPLINE-FAMELINE") ;1s_filter
      (setq 2nd_filter_val_main "FRAMING_") ;2nd_filter
      (setq 3rd_filter_val_main (list  ;3rd_filter
                                      "CC-01" ;
                                      "HR-02A" ;
                                      "HR-02B" ;
                                      "HR-09B" ;
                                      "HANGING" ;
                                )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 3) ;
                                      (list "MAIN_COLOR_2" 2) ;
                                      (list "MAIN_COLOR_3" 2) ;
                                      (list "MAIN_COLOR_5" 2) ;
                                      (list "SUB_COLOR_1" 1) ;
                                      (list "SUB_COLOR_2" 1) ;
                                      (list "SUB_COLOR_3" 251) ;
                                      (list "SUB_COLOR_4" 251) ;
                                      (list "SUB_COLOR_4" 251) ;
                                      (list "HATCH_" 251) ;
                                      (list "WIPEOUT_" 250) ;
                                      (list "HIDDEN_" 251) ;
                                      (list "SYMBOL_" 251) ;
                                      (list "DEF_SUB" 250) ;
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
                                  "C11" ;
                            )
      )
      (setq 4th_filter_val_main (list  ;4th_filter
                                      (list "MAIN_COLOR_1" 255 135 0) ;
                                      (list "HATCH_" 255 135 0) ;

                                )
      )
    )
  )
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
  (defun c:crelaytemp ()
    (c:crelayarea)
    (c:crelaylight)
    (c:crelaysymbol)
    (c:crelayfram)
    (c:crelayfas)
    (c:crelayaltray)
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
(test)
(setq lay (vla-item 
            (vla-get-layers 
              (vla-get-activedocument (vlax-get-acad-object))
            )
            "0"
          )
)
(entget (vlax-vla-object->ename lay))
(entget (tblobjname "LAYER" "0"))



(setq xdict (cdr (assoc 330 (entget (tblobjname "LAYER" "0")))))
(vla-getextensiondictionary (vlax-ename->vla-object (cdr (assoc 360 (entget (cdr (assoc 360 (entget (tblobjname "LAYER" "layer1")))))))))
(vlax-dump-object (vlax-ename->vla-object xdict))
(setq didct (dictsearch (entget (tblobjname "LAYER" "0")) "AcDbLayerTableRecord" ) )
(setq didct (dictsearch (entget (tblobjname "LAYER" "layer1")) "AcDbLayerTableRecord" ) )

(setq xdict 
  (cdr 
    (assoc 360 
           (entget (tblobjname "LAYER" "layer1"))
    )
  )
  ; "ACLYDICTIONARY"
)
(dictsearch (entget xdict) "ACAD_LAYEROVERRIDE")

(dictsearch
 (assoc 100
 (entget
    (cdr
      (assoc 360
        (dictsearch
          (cdr (assoc 360 (entget (tblobjname "LAYER" "ARW"))))
          "ADSK_XREC_LAYER_COLOR_OVR"
        )
      )
    )
  ) 
)"ADSK_XREC_LAYER_COLOR_OVR")

;; Get viewport layer overrides using entget
(setq layers (vla-get-Layers activeDoc))
(setq layerSettings '())
(vlax-for layer layers
(setq layerName (vla-get-Name layer))
(setq vpOverrides (entget (tblobjname "LAYER" layerName))))

(setq vpOverrides (entget (tblobjname "LAYER" "ARW")))
;; Access VP-specific properties directly with checks
(setq vpColor (if (numberp (cdr (assoc 62 vpOverrides))) (cdr (assoc 62 vpOverrides)) 0))
(setq vpLineWeight (if (numberp (cdr (assoc 370 vpOverrides))) (cdr (assoc 370 vpOverrides)) 0))
(setq vpLineType (if (cdr (assoc 6 vpOverrides)) (cdr (assoc 6 vpOverrides)) "ByLayer"))
(setq vpPlotStyle (if (cdr (assoc 390 vpOverrides)) (cdr (assoc 390 vpOverrides)) ""))
(setq vpTransparency (if (numberp (cdr (assoc 440 vpOverrides))) (cdr (assoc 440 vpOverrides)) 0))
(setq vpVisibility (if (numberp (cdr (assoc 70 vpOverrides))) (cdr (assoc 70 vpOverrides)) 0))


;; Iterate through each layer and get the VP properties
(setq targetVP (vla-get-ActivePViewport activeDoc))
(setq layers (vla-get-Layers activeDoc))
(vlax-for layer layers
(setq lyr (vla-get-Name layer))
(if (setq ext (cdr (assoc 360 (entget (tblobjname "LAYER" lyr)))))
(foreach prp '("COLOR" "LINETYPE" "LINEWT" "ALPHA" "PLOTSTYLE")
(if (setq rec (dictsearch ext (strcat "ADSK_XREC_LAYER_" prp "_OVR")))
(foreach vpl (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= (car x) 335)) rec))
(if (and vpl (setq lay (cdr (assoc 410 (entget vpl)))))
(if (not (member lay lays))
(setq lays (cons lay lays))
)
)))))
)





 


 

 