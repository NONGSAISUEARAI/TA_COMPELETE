(defun c:qmsave ()
  (setq FILEPATH (getvar "DWGPREFIX"))
  (setq FILENAME (getvar "DWGNAME"))
  (setq sum (strcat FILEPATH FILENAME))
  (setq sum 
    (strcat 
      "C:\\TA\\TA_WORK\\รถไฟฟ้า\\PPLINE ITD\\PPLINE PRESENT AREA\\PP27\\"
      FILENAME
    ) 
  )
  (COMMAND "_SAVEAS" 
          "2010"
          sum
          "Y"
  )
  ; (setq acadObj (vlax-get-acad-object))
  ; (setq docs (vla-get-Documents acadObj))
  ; (setq curDoc (vla-get-ActiveDocument acadObj))
  ; (vla-Close curDoc :vlax-false)
  ; (vla-Close curDoc )
  ; (command "quit" "n" )
  ; (command "close")

)
(defun c:ARqmsave ()
  (setq FILEPATH (getvar "DWGPREFIX"))
  (setq FILENAME (getvar "DWGNAME"))
  (setq sum (strcat FILEPATH (strcat "000-AREA_" FILENAME)))
  
  (COMMAND "_SAVEAS" 
          "2010"
          sum
      
  )
  ; (setq acadObj (vlax-get-acad-object))
  ; (setq docs (vla-get-Documents acadObj))
  ; (setq curDoc (vla-get-ActiveDocument acadObj))
  ; (vla-Close curDoc :vlax-false)
  ; (vla-Close curDoc )
  ; (command "quit" "n" )
  (command "close")

)
(defun c:ARq1msave ()
  (setq FILEPATH (getvar "DWGPREFIX"))
  (setq FILENAME (getvar "DWGNAME"))
  (setq sum (strcat FILEPATH (strcat "000-AREA_" FILENAME)))
  
  (COMMAND "_SAVEAS" 
          "2010"
          sum
      
  )
  ; (setq acadObj (vlax-get-acad-object))
  ; (setq docs (vla-get-Documents acadObj))
  ; (setq curDoc (vla-get-ActiveDocument acadObj))
  ; (vla-Close curDoc :vlax-false)
  ; (vla-Close curDoc )
  ; (command "quit" "n" )
  

)

; (c:qmsave)

;(alert "TA:AUTOMATION TEST")
