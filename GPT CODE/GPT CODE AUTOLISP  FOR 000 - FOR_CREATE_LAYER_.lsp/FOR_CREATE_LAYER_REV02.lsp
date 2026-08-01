(defun TA:create-filter-lv1 (layer_val_)
  (if (=  (type (setq iferror_ ;Detect the variable's result in case of a function error
                  (vl-catch-all-apply 
                    (function 
                      (lambda () 
                        (setq iferror_val_ (vla-Item (vla-get-layers (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))) layer_val_))
                      )
                    )
                  )
                )
            
            ) 
          'VLA-OBJECT
        )
    (progn
      "layer name is already had"
    )
    
    (command "_.-LAYER" "_Filter" "_New" "_Group" "" "" filter-name "")
  )
)



