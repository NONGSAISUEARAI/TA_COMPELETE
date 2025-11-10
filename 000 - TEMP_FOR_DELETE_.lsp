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

;prototype for filter layer
  (defun c:create_main_and_sub_filter_creF2 ()
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
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV1 "DEFPOINT_" )
                                )
                                (list (strcat Prefix_filter_name_ Prefix_filter_name_LV2) 
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "MAIN_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "SUB_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "HATCH_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "WIPEOUT_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "HIDDEN_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "SYMBOL_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV2 "DEFPOINT_" )
                                )
                                (list (strcat Prefix_filter_name_ Prefix_filter_name_LV3) 
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "MAIN_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "SUB_COLOR_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "HATCH_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "WIPEOUT_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "HIDDEN_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "SYMBOL_" )
                                      (strcat Prefix_filter_name_ Prefix_filter_name_LV3 "DEFPOINT_" )
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
                                    "DEFPOINT_"
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
  (defun c:create_layerset_LF1 ()
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
                                  (list "SUB_COLOR_1" 1 )
                                  (list "SUB_COLOR_2" 1)
                                  (list "HATCH_" 251)
                                  (list "WIPEOUT_" 250)
                                  (list "HIDDEN_" 251)
                                  (list "SYMBOL_" 251)
                                  (list "DEFPOINT_" 250)
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