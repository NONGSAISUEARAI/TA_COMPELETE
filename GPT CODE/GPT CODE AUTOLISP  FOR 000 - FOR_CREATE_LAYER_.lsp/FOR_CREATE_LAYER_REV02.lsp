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
    
    (command "_.-LAYER" "_Filter" "_New" "_Group" "" "" layer_val_ "")
  )
)
(Setq layer_val_ "sadsd")
(TA:create-filter-lv1 "yre")

(defun TA:create-filter-lv1 (filter-name / iferror_)

  (setq iferror_
    (vl-catch-all-apply
      ':LayerFilterList
      '()
    )
  )

  (if
    (and
      (not (vl-catch-all-error-p iferror_))
      (member
        (strcase filter-name)
        (mapcar 'strcase iferror_)
      )
    )

    ;; Filter มีอยู่แล้ว
    "filter name is already had"

    ;; Filter ยังไม่มี
    (command
      "_.-LAYER"
      "_Filter"
      "_New"
      "_Group"
      ""
      ""
      filter-name
      ""
    )
  )
)




(defun TA:read-filter-tree 
  (/ layer0 layer-table table-data xdict filter-dict)

  (setq layer0
    (tblobjname "LAYER" "0")
  )

  (setq layer-table
    (cdr
      (assoc 330
        (entget layer0)
      )
    )
  )

  (setq table-data
    (entget layer-table)
  )

  (setq xdict
    (cdr
      (assoc 360
        (member
          '(102 . "{ACAD_XDICTIONARY")
          table-data
        )
      )
    )
  )

  (if
    (and
      xdict
      (setq filter-dict
        (dictsearch xdict "ACLYDICTIONARY")
      )
    )
    (TA:read-filter-branch filter-dict)
    nil
  )
)

(nth 1 (nth 1 (reverse (TA:read-filter-tree))))
(nth 0 (nth 0 (TA:read-filter-tree)))

(defun TA:sort-filter-tree (filter-tree / item result)

  ;; เรียง Filter ลูกของแต่ละรายการก่อน
  (foreach item filter-tree
    (setq result
      (cons
        (list
          (car item)
          (if (cadr item)
            (TA:sort-filter-tree (cadr item))
            nil
          )
        )
        result
      )
    )
  )

  ;; เรียง Filter ในระดับปัจจุบันตามชื่อ
  (vl-sort
    (reverse result)
    '(lambda (item1 item2)
       (<
         (strcase (car item1))
         (strcase (car item2))
       )
     )
  )
)
 (TA:sort-filter-tree (TA:read-filter-tree))