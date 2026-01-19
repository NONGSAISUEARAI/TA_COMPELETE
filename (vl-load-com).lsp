(vl-load-com)

(defun c:SetColor (/ *error* ss acDoc oTrueColor)

  (defun *error* (msg)
    (if acDoc
      (vla-endundomark acDoc)
    )
    (cond ((not msg))                                                   ; Normal exit
          ((member msg '("Function cancelled" "quit / exit abort")))    ; <esc> or (quit)
          ((princ (strcat "\n** Error: " msg " ** ")))                  ; Fatal error, display it
    )
    (princ)
  )

  (if (setq ss (ssget ":S:E"))
    (progn
      (vla-startundomark
        (setq acDoc (vla-get-activedocument (vlax-get-acad-object)))
      )
      (setvar
        'cecolor
        (if
          (= acColorMethodByRGB
             (vla-get-colormethod
               (setq oTrueColor
                      (vla-get-truecolor
                        (vlax-ename->vla-object (ssname ss 0))
                      )
               )
             )
          )
           (strcat
             "RGB:"
             (itoa (vla-get-red oTrueColor))
             ","
             (itoa (vla-get-green oTrueColor))
             ","
             (itoa (vla-get-blue oTrueColor))
           )
           (itoa (vla-get-colorindex oTrueColor))
        )
      )
    )
  )

  (*error* nil)
)