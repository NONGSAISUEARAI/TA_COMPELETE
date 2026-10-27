;;; TA_DYE_LAYER_GROUP_REV02.lsp
;;; Move selected objects, including geometry inside selected blocks, to layers
;;; belonging to a selected component in the saved Layer Filter hierarchy.
;;;
;;; Filter hierarchy:
;;;   selected root -> main group -> component -> member layers
;;;
;;; Layer roles inside the selected component:
;;;   MAIN_COLOR_n, SUB_COLOR_n, CUT_COLOR_n
;;;   TEXT, HATCH_, WIPEOUT_, HIDDEN_, SYMBOL_, DEF_SUB
;;; ATTRIB/ATTDEF use TEXT (retain attribute data); ACI 8/9/251 maps to 251.
;;; Prefer TEXT_COLOR_n; keep explicit text color when using a shared _TEXT.
;;; HATCH/WIPEOUT always use their type roles. Other objects on Defpoints
;;; (or a layer named Defpoint) use DEF_SUB before color/manual role rules.
;;; AUTO geometry keeps MAIN/SUB/CUT from its source layer's _*_COLOR_ token.
;;; Geometry without such a source role defaults to MAIN as before.
;;;
;;; Requires TA_LAYER_FILTER_TREE.lsp.  REV02 tries to load that file when the
;;; public filter-tree function is not already available.
;;;
;;; Selection modes: Objects (standalone), Blocks (including contents), Both.
;;; Command: DYING_OBJECT_LAYER_dyeobjlayer_

(vl-load-com)

(setq TA-DYE2:filter-reader-path
  "C:/TA/TA_COMPELETE/GPT CODE/GPT CODE AUTOLISP  FOR 000 - FOR_CREATE_LAYER_.lsp/TA_LAYER_FILTER_TREE.lsp"
)
(if (not (boundp 'TA-DYE2:choice-memory))
  (setq TA-DYE2:choice-memory nil)
)
(if (not (boundp 'TA-DYE2:selection-mode))
  (setq TA-DYE2:selection-mode "Both")
)

;;; Edit this list to assign additional entity types in AUTO mode.
(setq TA-DYE2:type-role-map
  '(("LINE" . "MAIN")
    ("LWPOLYLINE" . "MAIN")
    ("POLYLINE" . "MAIN")
    ("ARC" . "MAIN")
    ("SPLINE" . "MAIN")
    ("ELLIPSE" . "MAIN")
    ("CIRCLE" . "MAIN")
    ("TEXT" . "TEXT")
    ("MTEXT" . "TEXT")
    ("ATTRIB" . "TEXT")
    ("ATTDEF" . "TEXT"))
)

(defun TA-DYE2:filter-api-ready-p (/ tree-call)
  (setq tree-call
    (vl-catch-all-apply 'TA:GetLayerFilterTree '())
  )
  (not (vl-catch-all-error-p tree-call))
)

(defun TA-DYE2:ensure-filter-api (/ path loaded)
  (cond
    ((TA-DYE2:filter-api-ready-p) T)
    ((setq path
       (cond
         ((findfile "TA_LAYER_FILTER_TREE.lsp"))
         ((findfile TA-DYE2:filter-reader-path))
       )
     )
      (setq loaded (vl-catch-all-apply 'load (list path)))
      (and
        (not (vl-catch-all-error-p loaded))
        (TA-DYE2:filter-api-ready-p)
      )
    )
  )
)

(defun TA-DYE2:node-name (node)
  (cdr (assoc 'NAME node))
)

(defun TA-DYE2:node-children (node)
  (cdr (assoc 'CHILDREN node))
)

(defun TA-DYE2:node-layers (node)
  (cdr (assoc 'LAYERS node))
)

(defun TA-DYE2:node-path (node)
  (cdr (assoc 'PATH node))
)

(defun TA-DYE2:component-layers (node / result child layer)
  ;; Include the role filters below this component without another menu.
  (setq result (TA-DYE2:node-layers node))
  (foreach child (TA-DYE2:node-children node)
    (foreach layer (TA-DYE2:component-layers child)
      (if (not (member layer result))
        (setq result (cons layer result))
      )
    )
  )
  (if result (acad_strlsort result))
)

(defun TA-DYE2:remember-choice (memory-key node / previous)
  ;; Store the selected path instead of only its number.  If alphabetical
  ;; ordering changes, the same filter can still become the numeric default.
  (if (and memory-key node)
    (progn
      (setq previous (assoc memory-key TA-DYE2:choice-memory))
      (if previous
        (setq TA-DYE2:choice-memory
          (subst
            (cons memory-key (TA-DYE2:node-path node))
            previous
            TA-DYE2:choice-memory
          )
        )
        (setq TA-DYE2:choice-memory
          (cons
            (cons memory-key (TA-DYE2:node-path node))
            TA-DYE2:choice-memory
          )
        )
      )
    )
  )
  node
)

(defun TA-DYE2:remembered-number (memory-key nodes / previous saved-path index node result)
  (if (setq previous (assoc memory-key TA-DYE2:choice-memory))
    (progn
      (setq saved-path (cdr previous)
            index 1)
      (while (and nodes (not result))
        (setq node (car nodes))
        (if (equal saved-path (TA-DYE2:node-path node))
          (setq result index)
        )
        (setq index (1+ index)
              nodes (cdr nodes))
      )
    )
  )
  result
)

(defun TA-DYE2:member-layer-text (node / layers index layer result)
  (if (setq layers (TA-DYE2:node-layers node))
    (progn
      (setq index 1)
      (setq result "")
      (foreach layer layers
        (setq result
          (strcat
            result
            "\n       L" (itoa index) " = " layer
          )
        )
        (setq index (1+ index))
      )
      result
    )
    ""
  )
)

(defun TA-DYE2:print-member-layers (node / text)
  (setq text (TA-DYE2:member-layer-text node))
  (if (/= text "")
    (princ text)
  )
  (princ)
)

(defun TA-DYE2:choose-node (title nodes memory-key / number default index node prompt selected menu-text)
  (cond
    ((not nodes) nil)
    (T
      (setq menu-text (strcat "\n" title ":"))
      (setq index 1)
      (foreach node nodes
        (setq menu-text
          (strcat
            menu-text
            "\n  " (itoa index) " = " (TA-DYE2:node-name node)
            (if (TA-DYE2:node-layers node)
              (strcat "  (" (itoa (length (TA-DYE2:node-layers node))) " layers)")
              ""
            )
          )
        )
        (setq index (1+ index))
      )
      (setq default (TA-DYE2:remembered-number memory-key nodes))
      (setq prompt
        (if default
          (strcat "\nChoose number <" (itoa default) ">: ")
          "\nChoose number: "
        )
      )
      (setq prompt (strcat menu-text prompt))
      (initget 6)
      (setq number (getint prompt))
      (if (and (not number) default)
        (setq number default)
      )
      (if (and number (<= 1 number (length nodes)))
        (progn
          (setq selected (nth (1- number) nodes))
          (TA-DYE2:remember-choice memory-key selected)
        )
      )
    )
  )
)

(defun TA-DYE2:choose-component (/ tree selected children next level cancelled members)
  (if (setq tree (TA:GetLayerFilterTree))
    (progn
      (setq selected
        (TA-DYE2:choose-node
          "Root filter"
          tree
          "ROOT"
        )
      )
      (setq level 1)
      (while (and selected (< level 3) (TA-DYE2:node-children selected) (not cancelled))
        (setq children (TA-DYE2:node-children selected))
        (setq next
          (TA-DYE2:choose-node
            (if (= level 1) "Main group" "Component")
            children
            (strcat
              "CHILD|"
              (TA-DYE2:join-path (TA-DYE2:node-path selected))
            )
          )
        )
        (if next
          (progn
            (setq selected next)
            (setq level (1+ level))
          )
          (setq cancelled T selected nil)
        )
      )
      (if (and selected (setq members (TA-DYE2:component-layers selected)))
        (subst (cons 'LAYERS members) (assoc 'LAYERS selected) selected)
        (progn
          (if selected
            (princ
              (strcat
                "\nTADYE2: filter '" (TA-DYE2:node-name selected)
                "' has no member layers."
              )
            )
          )
          nil
        )
      )
    )
    (progn
      (princ
        "\nTADYE2: no saved Layer Filter hierarchy was found."
      )
      nil
    )
  )
)

(defun TA-DYE2:join-path (items / result item)
  (foreach item items
    (setq result
      (if result
        (strcat result " > " item)
        item
      )
    )
  )
  result
)

(defun TA-DYE2:ends-with (text suffix / text-length suffix-length)
  (setq text-length (strlen text)
        suffix-length (strlen suffix))
  (and
    (>= text-length suffix-length)
    (=
      (strcase (substr text (1+ (- text-length suffix-length))))
      (strcase suffix)
    )
  )
)

(defun TA-DYE2:contains-text (text token)
  (not (null (vl-string-search (strcase token) (strcase text))))
)

(defun TA-DYE2:layer-aci (name / row color)
  (if (setq row (tblsearch "LAYER" name))
    (progn
      (setq color (cdr (assoc 62 row)))
      (if color (abs color))
    )
  )
)

(defun TA-DYE2:normalize-aci (color)
  (if (member color '(8 9 251)) 251 color)
)

(defun TA-DYE2:effective-aci (data parent / color layer)
  (cond
    ((or (assoc 420 data) (assoc 430 data)) nil)
    ((and (setq color (cdr (assoc 62 data))) (<= 1 color 255)) color)
    ((and color (= color 0)) parent)
    (T
      (setq layer (cdr (assoc 8 data)))
      (if (and parent (= (strcase layer) "0"))
        parent
        (TA-DYE2:layer-aci layer)
      )
    )
  )
)

(defun TA-DYE2:role-for-type (role type / pair)
  (cond
    ((= type "HATCH") "HATCH")
    ((= type "WIPEOUT") "WIPEOUT")
    ((member type '("ATTRIB" "ATTDEF")) "TEXT")
    ((/= role "AUTO") role)
    ((setq pair (assoc type TA-DYE2:type-role-map)) (cdr pair))
  )
)

(defun TA-DYE2:role-for-entity (role data / resolved layer)
  (setq resolved (TA-DYE2:role-for-type role (cdr (assoc 0 data))))
  ;; Infer color roles for AUTO geometry only. Text/Hatch/Wipeout and an
  ;; explicitly selected manual role keep their own routing rules.
  (if (and (= role "AUTO") (= resolved "MAIN")
           (setq layer (cdr (assoc 8 data))))
    (cond
      ((TA-DYE2:contains-text layer "_CUT_COLOR_") "CUT")
      ((TA-DYE2:contains-text layer "_SUB_COLOR_") "SUB")
      (T resolved)
    )
    resolved
  )
)

(defun TA-DYE2:defpoints-p (data / layer)
  (and
    (setq layer (cdr (assoc 8 data)))
    (member (strcase layer) '("DEFPOINTS" "DEFPOINT"))
  )
)

(defun TA-DYE2:unique-target (matches description / sorted)
  (setq sorted (if matches (acad_strlsort matches)))
  (cond
    ((not sorted) nil)
    ((= (length sorted) 1) (car sorted))
    (T
      (setq TA-DYE2:last-target-error
        (strcat "ambiguous " description ": " (car sorted) " / " (cadr sorted))
      )
      nil
    )
  )
)

(defun TA-DYE2:fixed-role-layer (members role / suffix layer matches)
  (setq suffix
    (cdr
      (assoc role
        '(("TEXT" . "_TEXT")
          ("HATCH" . "_HATCH_")
          ("WIPEOUT" . "_WIPEOUT_")
          ("HIDDEN" . "_HIDDEN_")
          ("SYMBOL" . "_SYMBOL_")
          ("DEFSUB" . "_DEF_SUB"))
      )
    )
  )
  (if suffix
    (foreach layer members
      (if (and
            (tblsearch "LAYER" layer)
            (TA-DYE2:ends-with layer suffix)
          )
        (setq matches (cons layer matches))
      )
    )
  )
  (TA-DYE2:unique-target matches role)
)

(defun TA-DYE2:color-role-layer (members role color / stem exact layer matches exact-match)
  (setq stem (strcat "_" role "_COLOR_")
        exact (strcat stem (itoa color)))
  (foreach layer members
    (if (and
          (tblsearch "LAYER" layer)
          (TA-DYE2:contains-text layer stem)
          (= (TA-DYE2:layer-aci layer) color)
        )
      (progn
        (setq matches (cons layer matches))
        (if (TA-DYE2:ends-with layer exact)
          (setq exact-match layer)
        )
      )
    )
  )
  (if exact-match
    exact-match
    (TA-DYE2:unique-target matches (strcat role " ACI " (itoa color)))
  )
)

(defun TA-DYE2:target-layer (members role color / key cached target text-target)
  (setq color (TA-DYE2:normalize-aci color))
  (setq key (list role color))
  (if (setq cached (assoc key TA-DYE2:target-cache))
    (cdr cached)
    (progn
      (setq TA-DYE2:last-target-error nil)
      (setq target
        (cond
          ((= role "TEXT")
            (if (and color (<= 1 color 255)
                     (setq text-target (TA-DYE2:color-role-layer members "TEXT" color)))
              text-target
              (TA-DYE2:fixed-role-layer members "TEXT")
            )
          )
          ((member role '("HATCH" "WIPEOUT" "HIDDEN" "SYMBOL" "DEFSUB"))
            (TA-DYE2:fixed-role-layer members role)
          )
          ((and color (<= 1 color 255))
            (TA-DYE2:color-role-layer members role color)
          )
        )
      )
      (setq TA-DYE2:target-cache
        (cons (cons key target) TA-DYE2:target-cache)
      )
      target
    )
  )
)

(defun TA-DYE2:set-layer-bylayer (entity target text-color / data newdata)
  (setq data (entget entity))
  (setq newdata
    (vl-remove-if
      '(lambda (pair) (member (car pair) '(62 420 430)))
      data
    )
  )
  (setq newdata (subst (cons 8 target) (assoc 8 newdata) newdata))
  ;; A single _TEXT layer may serve several text colors. Keep the requested
  ;; color explicitly when no matching TEXT_COLOR_n layer exists.
  (setq newdata
    (append newdata
      (list
        (cons 62
          (if (and text-color (/= (TA-DYE2:layer-aci target) text-color))
            text-color
            256
          )
        )
      )
    )
  )
  (if (entmod newdata)
    (progn
      (entupd entity)
      T
    )
  )
)

(defun TA-DYE2:record-skip (reason)
  (setq TA-DYE2:skipped (1+ TA-DYE2:skipped))
  (if (not (member reason TA-DYE2:reasons))
    (setq TA-DYE2:reasons (cons reason TA-DYE2:reasons))
  )
)

(defun TA-DYE2:block-external-p (name / row flags)
  (if (setq row (tblsearch "BLOCK" name))
    (progn
      (setq flags (cdr (assoc 70 row)))
      (/= 0 (logand flags (+ 4 8 16)))
    )
    T
  )
)

(defun TA-DYE2:walk-block (name parent members role / header entity data type child color)
  (cond
    ((TA-DYE2:block-external-p name)
      (TA-DYE2:record-skip (strcat "xref/missing block: " name))
    )
    ((member (strcase name) TA-DYE2:visited) nil)
    ((setq header (tblobjname "BLOCK" name))
      (setq TA-DYE2:visited (cons (strcase name) TA-DYE2:visited))
      (setq entity (entnext header))
      (while (and entity
                  (/= (cdr (assoc 0 (setq data (entget entity)))) "ENDBLK"))
        (setq type (cdr (assoc 0 data)))
        (setq color (TA-DYE2:effective-aci data parent))
        (if (= type "INSERT")
          (progn
            (setq child (cdr (assoc 2 data)))
            (if child
              (progn
                (TA-DYE2:walk-block child color members role)
                (if (not (TA-DYE2:block-external-p child))
                  (progn
                    (if (TA-DYE2:defpoints-p data)
                      (TA-DYE2:move-one entity data color members role)
                    )
                    (TA-DYE2:walk-insert-attributes entity color members role)
                  )
                )
              )
            )
          )
          (if (not (member type '("VERTEX" "SEQEND" "ATTRIB")))
            (TA-DYE2:move-one entity data color members role)
          )
        )
        (setq entity (entnext entity))
      )
    )
  )
)

(defun TA-DYE2:move-one (entity data color members role / target type resolved-role byblock text-color)
  (setq type (cdr (assoc 0 data)))
  (setq color (TA-DYE2:normalize-aci color))
  (setq byblock
    (and
      (not (member type '("HATCH" "WIPEOUT" "ATTRIB" "ATTDEF")))
      (not (TA-DYE2:defpoints-p data))
      (equal (cdr (assoc 62 data)) 0)
    )
  )
  (setq resolved-role
    (cond
      ((member type '("HATCH" "WIPEOUT")) type)
      ((TA-DYE2:defpoints-p data) "DEFSUB")
      (byblock "MAIN")
      (T (TA-DYE2:role-for-entity role data))
    )
  )
  (setq TA-DYE2:last-target-error nil)
  (if (and (= resolved-role "TEXT") color)
    (setq text-color color)
  )
  (cond
    (byblock
      (setq target (TA-DYE2:target-layer members "MAIN" 3))
    )
    (resolved-role
      (setq target (TA-DYE2:target-layer members resolved-role color))
    )
  )
  (cond
    ((not resolved-role)
      (TA-DYE2:record-skip (strcat "no AUTO role for " type))
    )
    ((not target)
      (TA-DYE2:record-skip
        (cond
          (TA-DYE2:last-target-error TA-DYE2:last-target-error)
          (byblock (strcat "no MAIN_COLOR_3 member layer for ByBlock " type))
          (T
            (strcat
              "no suitable " resolved-role " member layer for " type " / ACI "
              (if color (itoa color) "RGB/unknown")
            )
          )
        )
      )
    )
    ((TA-DYE2:set-layer-bylayer entity target text-color)
      (setq TA-DYE2:moved (1+ TA-DYE2:moved))
    )
    (T
      (TA-DYE2:record-skip (strcat "cannot edit " type))
    )
  )
)

(defun TA-DYE2:walk-insert-attributes (insert parent members role / entity data)
  ;; ATTRIB references belong to each INSERT, outside its block definition.
  (if (= (cdr (assoc 66 (entget insert))) 1)
    (progn
      (setq entity (entnext insert))
      (while (and entity
                  (= (cdr (assoc 0 (setq data (entget entity)))) "ATTRIB"))
        (TA-DYE2:move-one entity data
          (TA-DYE2:effective-aci data parent) members role)
        (setq entity (entnext entity))
      )
      (entupd insert)
    )
  )
)

(defun TA-DYE2:run (selection members role / index entity data type color)
  (setq TA-DYE2:moved 0
        TA-DYE2:skipped 0
        TA-DYE2:reasons nil
        TA-DYE2:visited nil
        TA-DYE2:target-cache nil
        TA-DYE2:last-target-error nil)
  (setq index 0)
  (while (< index (sslength selection))
    (setq entity (ssname selection index))
    (setq data (entget entity))
    (setq type (cdr (assoc 0 data)))
    (setq color (TA-DYE2:effective-aci data nil))
    (if (= type "INSERT")
      (progn
        (TA-DYE2:walk-block (cdr (assoc 2 data)) color members role)
        (if (not (TA-DYE2:block-external-p (cdr (assoc 2 data))))
          (progn
            (if (TA-DYE2:defpoints-p data)
              (TA-DYE2:move-one entity data color members role)
            )
            (TA-DYE2:walk-insert-attributes entity color members role)
          )
        )
      )
      (TA-DYE2:move-one entity data color members role)
    )
    (setq index (1+ index))
  )
  (list TA-DYE2:moved TA-DYE2:skipped (reverse TA-DYE2:reasons))
)
<<<<<<< Updated upstream
 
(defun c:TADYE2 (/ *error* doc component members role selection result undo-open)
=======

(defun TA-DYE2:select-objects (/ mode)
  ;; Keep the original mixed selection as the initial default. Remember a
  ;; subsequent choice for the rest of this AutoCAD session, including reloads.
  (if (not (member TA-DYE2:selection-mode '("Objects" "Blocks" "Both")))
    (setq TA-DYE2:selection-mode "Both")
  )
  (initget "Objects Blocks Both")
  (setq mode
    (getkword
      (strcat "\nSelection [Objects/Blocks/Both] <" TA-DYE2:selection-mode ">: ")
    )
  )
  (if mode (setq TA-DYE2:selection-mode mode))
  (cond
    ((= TA-DYE2:selection-mode "Objects")
      (princ "\nSelect standalone objects to dye (blocks excluded): ")
      (ssget '((0 . "~INSERT")))
    )
    ((= TA-DYE2:selection-mode "Blocks")
      (princ "\nSelect block references to dye their contents: ")
      (ssget '((0 . "INSERT")))
    )
    (T
      (princ "\nSelect objects or block references to dye: ")
      (ssget)
    )
  )
)

(defun c:DYING_OBJECT_LAYER_dyeobjlayer_ (/ *error* doc component members role selection result undo-open)
>>>>>>> Stashed changes
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (defun *error* (message)
    (if undo-open (vla-EndUndoMark doc))
    (if (and message (/= message "Function cancelled"))
      (princ (strcat "\nTADYE2: " message))
    )
    (princ)
  )
  (cond
    ((not (TA-DYE2:ensure-filter-api))
      (princ
        (strcat
          "\nTADYE2: cannot load TA_LAYER_FILTER_TREE.lsp."
          " Load it first or add its folder to Trusted/Support Paths."
        )
      )
    )
    ((setq component (TA-DYE2:choose-component))
      (setq members (TA-DYE2:node-layers component))
      (princ
        (strcat
          "\nSelected filter: "
          (TA-DYE2:join-path (TA-DYE2:node-path component))
        )
      )
      (princ "\nMember layers:")
      (TA-DYE2:print-member-layers component)
      (initget "Auto Main Sub Cut Text Hidden Symbol DefSub")
      (setq role
        (getkword
          "\nRole [Auto/Main/Sub/Cut/Text/Hidden/Symbol/DefSub] <Auto>: "
        )
      )
      (if (not role) (setq role "Auto"))
      (setq role (strcase role))
      (if (setq selection (TA-DYE2:select-objects))
        (progn
          (vla-StartUndoMark doc)
          (setq undo-open T)
          (setq result (TA-DYE2:run selection members role))
          (vla-EndUndoMark doc)
          (setq undo-open nil)
          (vla-Regen doc 1)
          (princ
            (strcat
              "\nTADYE2: changed " (itoa (car result))
              ", skipped " (itoa (cadr result)) "."
            )
          )
          (foreach reason (caddr result)
            (princ (strcat "\n  " reason))
          )
          (if (/= TA-DYE2:selection-mode "Objects")
            (princ
              "\nBlock definitions are shared by all references. UNDO reverses this command."
            )
          )
        )
      )
    )
  )
  (princ)
)

(princ
  "\nDYING_OBJECT_LAYER_dyeobjlayer_ loaded. Type DYING_OBJECT_LAYER_dyeobjlayer_; choose Objects, Blocks or Both when selecting."
)
(princ)
