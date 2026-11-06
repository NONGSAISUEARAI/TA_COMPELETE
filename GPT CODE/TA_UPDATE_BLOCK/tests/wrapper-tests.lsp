;;; Run in a fresh AutoCAD Core Console session, without NETLOAD.
(defun TAUBTEST:Assert (condition message)
  (if condition
    (princ (strcat "\nPASS: " message))
    (progn (princ (strcat "\nFAIL: " message)) (exit))))

;; Replace the unloaded DLL entry point with a stub to inspect API arguments.
(defun TA-UPDATE-BLOCK (source block targets backup)
  (setq taubtest:args (list source block targets backup))
  '(2 0 "OK A.dwg\nOK B.dwg"))
(defun TAUB-PICK-FOLDER (initial)
  (setq taubtest:initial initial)
  taubtest:folder-result)

(TAUBTEST:Assert (TAUB:_ready-p) "Both exported functions are checked before use")

(TAUBTEST:Assert
  (equal (TAUB:Run "C:/MASTER.dwg" "TEST_BLOCK" '("C:/A.dwg" "C:/B.dwg") T)
         '(2 0 "OK A.dwg\nOK B.dwg"))
  "Successful DLL result is returned")
(TAUBTEST:Assert
  (equal taubtest:args '("C:/MASTER.dwg" "TEST_BLOCK" "C:/A.dwg|C:/B.dwg" 1))
  "DWG targets and backup flag reach the DLL correctly")
(TAUB:Run "C:/MASTER.dwg" "TEST_BLOCK" '("C:/A.dwg") nil)
(TAUBTEST:Assert (= 0 (nth 3 taubtest:args)) "No backup maps to flag zero")
(setq taubtest:files
  (TAUB:_folder-files "C:\\Users\\tawan.t\\Documents\\GitHub\\TA_COMPELETE"))
(TAUBTEST:Assert
  (member "C:\\Users\\tawan.t\\Documents\\GitHub\\TA_COMPELETE\\Drawing1.dwg" taubtest:files)
  "Folder enumeration returns full paths to existing DWGs")
(TAUBTEST:Assert
  (null (TAUB:_folder-files
    "C:\\Users\\tawan.t\\Documents\\GitHub\\TA_COMPELETE\\GPT CODE\\TA_UPDATE_BLOCK\\tests"))
  "Folder without DWGs returns nil")

(setq taubtest:folder-result nil)
(TAUBTEST:Assert (null (TAUB:_pick-folder)) "Cancel returns nil")
(setq taubtest:folder-result '(nil))
(TAUBTEST:Assert (and (null (TAUB:_pick-folder)) (= *TAUB:pick-status* 'CANCEL))
  "Actual ResultBuffer Cancel list is recognized")
(setq taubtest:folder-result "C:\\Users\\tawan.t\\Documents\\GitHub\\TA_COMPELETE\\GPT CODE")
(TAUBTEST:Assert (equal (TAUB:_pick-folder) taubtest:folder-result)
  "Selected directory is returned from the picker")
(TAUB:_pick-folder)
(TAUBTEST:Assert (equal taubtest:initial taubtest:folder-result)
  "Next folder dialog starts at the previous selected directory")
(setq taubtest:folder-result (list taubtest:folder-result))
(TAUBTEST:Assert (equal (TAUB:_pick-folder) (car taubtest:folder-result))
  "Actual ResultBuffer path list is accepted")
(setq taubtest:folder-result "C:\\TAUB-folder-that-does-not-exist")
(TAUBTEST:Assert (null (TAUB:_pick-folder)) "Nonexistent directory is rejected")
(princ "\nTAUB_WRAPPER_TESTS_PASSED\n")
(princ)
