;;; TA_HIGHLIGHT_LAYER_FILTER.lsp
;;; Select/highlight visible-space objects whose layers belong to a saved
;;; Layer Filter folder. Nested child folders are included. For an INSERT,
;;; a matching entity inside its block definition selects the whole INSERT.
;;; Nothing in the drawing database is edited.
;;;
;;; Commands: TAHIGHLIGHTFILTER (or TAHFFOLDER), TAHFCLEAR
;;; Dependency: TA_LAYER_FILTER_TREE.lsp in the same support path, or choose
;;; its file when prompted.

(vl-load-com)

(defun TA-HF:api-ready-p (/ result)
  (setq result (vl-catch-all-apply 'TA:GetLayerFilterTree '()))
  (not (vl-catch-all-error-p result))
)

(defun TA-HF:ensure-api (/ path loaded)
  (cond
    ((TA-HF:api-ready-p) T)
    (T
      (setq path
        (or
          (findfile "TA_LAYER_FILTER_TREE.lsp")
          (getfiled "Select TA_LAYER_FILTER_TREE.lsp"
                    "TA_LAYER_FILTER_TREE.lsp" "lsp" 0)
        )
      )
      (if path
        (progn
          (setq loaded (vl-catch-all-apply 'load (list path)))
          (and (not (vl-catch-all-error-p loaded))
               (TA-HF:api-ready-p))
        )
      )
    )
  )
)

(defun TA-HF:node-name (node)
  (cdr (assoc 'NAME node))
)

(defun TA-HF:node-children (node)
  (cdr (assoc 'CHILDREN node))
)

(defun TA-HF:node-layers (node)
  (cdr (assoc 'LAYERS node))
)

(defun TA-HF:join-path (parts / result part)
  (setq result "")
  (foreach part parts
    (setq result
      (strcat result (if (= result "") "" " > ") part)
    )
  )
  result
)

(defun TA-HF:collect-layers (node / result child layer)
  (setq result (TA-HF:node-layers node))
  (foreach child (TA-HF:node-children node)
    (foreach layer (TA-HF:collect-layers child)
      (if (not (member layer result))
        (setq result (cons layer result))
      )
    )
  )
  result
)

(defun TA-HF:choose-folder (tree / nodes current choice index item chosen done)
  (setq nodes tree current nil done nil)
  (while (and nodes (not done))
    (princ
      (strcat "\nLayer Filter: "
              (if current
                (TA-HF:join-path (cdr (assoc 'PATH current)))
                "root"))
    )
    (if current
      (princ (strcat "\n  0 = Use this folder: " (TA-HF:node-name current)))
    )
    (setq index 1)
    (foreach item nodes
      (princ
        (strcat "\n  " (itoa index) " = " (TA-HF:node-name item))
      )
      (setq index (1+ index))
    )
    (initget 4)
    (setq choice (getint "\nChoose folder number <Enter to cancel>: "))
    (cond
      ((not choice) (setq done T chosen nil))
      ((and (= choice 0) current)
        (setq chosen current done T)
      )
      ((and (<= 1 choice) (<= choice (length nodes)))
        (setq current (nth (1- choice) nodes))
        (if (setq nodes (TA-HF:node-children current))
          nil
          (setq chosen current done T)
        )
      )
      (T (princ "\nInvalid number. Choose one of the listed folders."))
    )
  )
  chosen
)

(defun TA-HF:layer-match-p (name)
  (and name (member (strcase name) TA-HF:layer-keys))
)

(defun TA-HF:block-match-p (name / key cached header entity data type result)
  (setq key (if name (strcase name)))
  (cond
    ((not key) nil)
    ((setq cached (assoc key TA-HF:block-cache)) (cdr cached))
    ((member key TA-HF:visiting) nil)
    (T
      (setq TA-HF:visiting (cons key TA-HF:visiting))
      (if (setq header (tblobjname "BLOCK" name))
        (progn
          (setq entity (entnext header))
          (while (and entity (not result)
                      (setq data (entget entity))
                      (/= (cdr (assoc 0 data)) "ENDBLK"))
            (setq type (cdr (assoc 0 data)))
            (if (or
                  (TA-HF:layer-match-p (cdr (assoc 8 data)))
                  (and (= type "INSERT")
                       (TA-HF:block-match-p (cdr (assoc 2 data))))
                )
              (setq result T)
            )
            (setq entity (entnext entity))
          )
        )
      )
      (setq TA-HF:visiting (vl-remove key TA-HF:visiting))
      (setq TA-HF:block-cache (cons (cons key result) TA-HF:block-cache))
      result
    )
  )
)

(defun TA-HF:attributes-match-p (insert / next data result)
  (if (equal (cdr (assoc 66 (entget insert))) 1)
    (progn
      (setq next (entnext insert))
      (while (and next (not result)
                  (setq data (entget next))
                  (/= (cdr (assoc 0 data)) "SEQEND"))
        (if (TA-HF:layer-match-p (cdr (assoc 8 data)))
          (setq result T)
        )
        (setq next (entnext next))
      )
    )
  )
  result
)

(defun TA-HF:entity-match-p (entity data / type)
  (setq type (cdr (assoc 0 data)))
  (and
    (not (and (= type "VIEWPORT")
              (equal (cdr (assoc 69 data)) 1)))
    (or
      (TA-HF:layer-match-p (cdr (assoc 8 data)))
      (and (= type "INSERT")
           (or
             (TA-HF:block-match-p (cdr (assoc 2 data)))
             (TA-HF:attributes-match-p entity)
           )
      )
    )
  )
)

(defun TA-HF:active-space ()
  (if (or (= (getvar "TILEMODE") 1)
          (> (getvar "CVPORT") 1))
    "Model"
    (getvar "CTAB")
  )
)

(defun TA-HF:highlight (folder / layers all selected index entity data)
  (setq layers (TA-HF:collect-layers folder))
  (setq TA-HF:layer-keys (mapcar 'strcase layers)
        TA-HF:block-cache nil
        TA-HF:visiting nil)
  (setq selected (ssadd))
  (setq all (ssget "_X" (list (cons 410 (TA-HF:active-space)))))
  (if all
    (progn
      (setq index 0)
      (while (< index (sslength all))
        (setq entity (ssname all index)
              data (entget entity))
        (if (and data (TA-HF:entity-match-p entity data))
          (ssadd entity selected)
        )
        (setq index (1+ index))
      )
    )
  )
  (sssetfirst nil nil)
  (if (> (sslength selected) 0)
    (sssetfirst nil selected)
  )
  (princ
    (strcat
      "\nTAHF: " (itoa (sslength selected)) " objects highlighted on "
      (itoa (length layers)) " member layers."
    )
  )
  (princ
    "\nNested matches highlight the whole block reference; no layers or objects were changed."
  )
)

(defun c:TAHIGHLIGHTFILTER (/ tree folder)
  (cond
    ((not (TA-HF:ensure-api))
      (princ "\nTAHF: TA_LAYER_FILTER_TREE.lsp could not be loaded.")
    )
    ((not (setq tree (TA:GetLayerFilterTree)))
      (princ "\nTAHF: no saved Layer Filter folders found in this drawing.")
    )
    ((setq folder (TA-HF:choose-folder tree))
      (princ
        (strcat "\nSelected folder: "
                (TA-HF:join-path (cdr (assoc 'PATH folder))))
      )
      (TA-HF:highlight folder)
    )
  )
  (princ)
)

(defun c:TAHFFOLDER ()
  (c:TAHIGHLIGHTFILTER)
)

(defun c:TAHFCLEAR ()
  (sssetfirst nil nil)
  (princ "\nTAHF: highlight cleared.")
  (princ)
)

(princ "\nTA_HIGHLIGHT_LAYER_FILTER loaded. Type TAHFFOLDER to select a filter folder and highlight its objects; TAHFCLEAR clears the selection.")
(princ)
