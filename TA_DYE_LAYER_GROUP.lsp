;;; TA_DYE_LAYER_GROUP.lsp
;;; Move selected objects (including geometry inside selected blocks) to an
;;; existing layer group. The object's effective ACI chooses the color suffix.
;;; AUTO uses the editable entity-type/role list below. A manual role overrides
;;; that list. Only an existing target layer with matching ACI is used.
;;; Explicit ByBlock objects go to MAIN_COLOR_3, except HATCH/WIPEOUT.
;;; HATCH and WIPEOUT are always routed to their dedicated layers.
;;; Block definitions are shared: editing one changes every reference to it.

(vl-load-com)

;;; Edit this list to assign other entity types to MAIN, SUB, CUT or TEXT.
;;; An entity type absent from the list is skipped in AUTO mode.
(setq TA-DYE:type-role-map
  '(("LINE" . "MAIN")
    ("LWPOLYLINE" . "MAIN")
    ("POLYLINE" . "MAIN")
    ("ARC" . "MAIN")
    ("SPLINE" . "MAIN")
    ("ELLIPSE" . "MAIN")
    ("CIRCLE" . "MAIN")
    ("TEXT" . "TEXT")
    ("MTEXT" . "TEXT"))
)

(defun TA-DYE:ends-with (s suffix / n)
  (setq n (strlen suffix))
  (and (>= (strlen s) n)
       (= (strcase (substr s (1+ (- (strlen s) n)))) (strcase suffix)))
)

(defun TA-DYE:group-base (name / token position digits base)
  (foreach token '("MAIN_COLOR_" "SUB_COLOR_" "CUT_COLOR_" "TEXT_COLOR_")
    (if (and (not base)
             (setq position (vl-string-search token (strcase name))))
      (progn
        (setq digits (substr name (+ position (strlen token) 1)))
        (if (and (> (strlen digits) 0)
                 (<= 1 (atoi digits) 255)
                 (= digits (itoa (atoi digits))))
          (setq base (substr name 1 position))
        )
      )
    )
  )
  (foreach token '("HATCH_" "WIPEOUT_" "HIDDEN_" "SYMBOL_" "DEF_SUB" "TEXT")
    (if (and (not base) (TA-DYE:ends-with name token))
      (setq base (substr name 1 (- (strlen name) (strlen token))))
    )
  )
  base
)

(defun TA-DYE:unique-sorted (items / result)
  (foreach item items
    (if (not (member item result)) (setq result (cons item result)))
  )
  (acad_strlsort result)
)

(defun TA-DYE:groups (/ row name prefix result)
  (setq row (tblnext "LAYER" T))
  (while row
    (setq name (cdr (assoc 2 row)))
    (if (setq prefix (TA-DYE:group-base name))
      (progn
        (if (not (member prefix result)) (setq result (cons prefix result)))
      )
    )
    (setq row (tblnext "LAYER"))
  )
  (TA-DYE:unique-sorted result)
)

(defun TA-DYE:top-key (base / position)
  (cond
    ((and (>= (strlen base) 6) (= (substr base 4 3) " - "))
      (substr base 1 6))
    ((setq position (vl-string-search "_" base))
      (substr base 1 (1+ position)))
    (T base)
  )
)

(defun TA-DYE:shared-family (first second / index limit last)
  (setq index 1 limit (min (strlen first) (strlen second)) last 0)
  (while (and (<= index limit)
              (= (substr first index 1) (substr second index 1)))
    (if (= (substr first index 1) "_") (setq last index))
    (setq index (1+ index))
  )
  (if (> last 0) (substr first 1 last) "")
)

(defun TA-DYE:family-key (base peers / top best shared)
  (setq top (TA-DYE:top-key base) best "")
  (foreach peer peers
    (if (/= peer base)
      (progn
        (setq shared (TA-DYE:shared-family base peer))
        (if (and (> (strlen shared) (strlen top))
                 (> (strlen shared) (strlen best)))
          (setq best shared)
        )
      )
    )
  )
  (if (= best "") base best)
)

(defun TA-DYE:choose (title options / number index item)
  (cond
    ((not options) nil)
    ((= (length options) 1)
      (princ (strcat "\n" title ": " (car options)))
      (car options))
    (T
      (princ (strcat "\n" title ":"))
      (setq index 1)
      (foreach item options
        (princ (strcat "\n  " (itoa index) ". " item))
        (setq index (1+ index))
      )
      (setq number (getint "\nChoose number: "))
      (if (and number (<= 1 number (length options)))
        (nth (1- number) options)
      )
    )
  )
)

(defun TA-DYE:choose-group (/ groups tops top peers families family members)
  (setq groups (TA-DYE:groups))
  (setq tops (TA-DYE:unique-sorted (mapcar 'TA-DYE:top-key groups)))
  (if (setq top (TA-DYE:choose "Level 1 / section" tops))
    (progn
      (setq peers (vl-remove-if-not
                    '(lambda (base) (= (TA-DYE:top-key base) top))
                    groups))
      (setq families (TA-DYE:unique-sorted
                       (mapcar '(lambda (base) (TA-DYE:family-key base peers)) peers)))
      (if (setq family (TA-DYE:choose "Level 2 / family" families))
        (progn
          (setq members (vl-remove-if-not
                          '(lambda (base) (= (TA-DYE:family-key base peers) family))
                          peers))
          (TA-DYE:choose "Level 3 / component" members)
        )
      )
    )
  )
)

(defun TA-DYE:layer-aci (name / row color)
  (if (setq row (tblsearch "LAYER" name))
    (progn
      (setq color (cdr (assoc 62 row)))
      (if color (abs color))
    )
  )
)

(defun TA-DYE:effective-aci (data parent / color layer)
  (cond
    ((or (assoc 420 data) (assoc 430 data)) nil)
    ((and (setq color (cdr (assoc 62 data))) (<= 1 color 255)) color)
    ((and color (= color 0)) parent)
    (T
      (setq layer (cdr (assoc 8 data)))
      (if (and parent (= (strcase layer) "0"))
        parent
        (TA-DYE:layer-aci layer)
      )
    )
  )
)

(defun TA-DYE:role-for-type (role type / pair)
  (cond
    ((= type "HATCH") "HATCH")
    ((= type "WIPEOUT") "WIPEOUT")
    ((/= role "AUTO") role)
    ((setq pair (assoc type TA-DYE:type-role-map)) (cdr pair))
  )
)

(defun TA-DYE:matching-color-layer (prefix role color / key cached row name stem exact matches result)
  (setq key (list prefix role color))
  (if (setq cached (assoc key TA-DYE:target-cache))
    (cdr cached)
    (progn
      (setq stem (strcat prefix role "_COLOR_"))
      (setq exact (strcat stem (itoa color)))
      (setq row (tblnext "LAYER" T))
      (while row
        (setq name (cdr (assoc 2 row)))
        (if (and (>= (strlen name) (strlen stem))
                 (= (strcase (substr name 1 (strlen stem))) (strcase stem))
                 (= (TA-DYE:group-base name) prefix)
                 (= (TA-DYE:layer-aci name) color))
          (setq matches (cons name matches))
        )
        (setq row (tblnext "LAYER"))
      )
      (setq result
        (cond
          ((member exact matches) exact)
          (matches (car (acad_strlsort matches)))
        )
      )
      (setq TA-DYE:target-cache (cons (cons key result) TA-DYE:target-cache))
      result
    )
  )
)

(defun TA-DYE:target-layer (prefix role type color / suffix target)
  (setq suffix
    (cond
      ((= role "HATCH") "HATCH_")
      ((= role "WIPEOUT") "WIPEOUT_")
      ((= role "HIDDEN") "HIDDEN_")
      ((= role "SYMBOL") "SYMBOL_")
      ((= role "DEFSUB") "DEF_SUB")
    )
  )
  (cond
    (suffix
      (setq target (strcat prefix suffix))
      (if (tblsearch "LAYER" target) target)
    )
    ((and color (<= 1 color 255))
      (TA-DYE:matching-color-layer prefix role color)
    )
  )
)

(defun TA-DYE:set-layer-bylayer (entity target / data newdata)
  (setq data (entget entity))
  (setq newdata
    (vl-remove-if
      '(lambda (pair) (member (car pair) '(62 420 430)))
      data
    )
  )
  (setq newdata (subst (cons 8 target) (assoc 8 newdata) newdata))
  (if (entmod newdata)
    (progn (entupd entity) T)
  )
)

(defun TA-DYE:record-skip (reason)
  (setq TA-DYE:skipped (1+ TA-DYE:skipped))
  (if (not (member reason TA-DYE:reasons))
    (setq TA-DYE:reasons (cons reason TA-DYE:reasons))
  )
)

(defun TA-DYE:block-external-p (name / row flags)
  (if (setq row (tblsearch "BLOCK" name))
    (progn
      (setq flags (cdr (assoc 70 row)))
      (/= 0 (logand flags (+ 4 8 16)))
    )
    T
  )
)

(defun TA-DYE:walk-block (name parent prefix role / header entity data type child color)
  (cond
    ((TA-DYE:block-external-p name) (TA-DYE:record-skip (strcat "xref/missing block: " name)))
    ((member (strcase name) TA-DYE:visited) nil)
    ((setq header (tblobjname "BLOCK" name))
      (setq TA-DYE:visited (cons (strcase name) TA-DYE:visited))
      (setq entity (entnext header))
      (while (and entity
                  (/= (cdr (assoc 0 (setq data (entget entity)))) "ENDBLK"))
        (setq type (cdr (assoc 0 data)))
        (setq color (TA-DYE:effective-aci data parent))
        (if (= type "INSERT")
          (progn
            (setq child (cdr (assoc 2 data)))
            (if child (TA-DYE:walk-block child color prefix role))
          )
          (if (not (member type '("VERTEX" "SEQEND" "ATTRIB")))
            (TA-DYE:move-one entity data color prefix role)
          )
        )
        (setq entity (entnext entity))
      )
    )
  )
)

(defun TA-DYE:move-one (entity data color prefix role / target type resolved-role byblock)
  (setq type (cdr (assoc 0 data)))
  (setq byblock (and (not (member type '("HATCH" "WIPEOUT")))
                     (equal (cdr (assoc 62 data)) 0)))
  (setq resolved-role (if byblock "MAIN" (TA-DYE:role-for-type role type)))
  (cond
    (byblock
      (if (tblsearch "LAYER" (strcat prefix "MAIN_COLOR_3"))
        (setq target (strcat prefix "MAIN_COLOR_3"))
      )
    )
    (resolved-role
      (setq target (TA-DYE:target-layer prefix resolved-role type color))
    )
  )
  (cond
    ((not resolved-role)
      (TA-DYE:record-skip (strcat "no AUTO role for " type))
    )
    ((not target)
      (TA-DYE:record-skip
        (if byblock
          (strcat "no MAIN_COLOR_3 layer for ByBlock " type)
          (strcat "no suitable " resolved-role " layer for " type " / ACI "
                  (if color (itoa color) "RGB/unknown"))
        )
      )
    )
    ((TA-DYE:set-layer-bylayer entity target)
      (setq TA-DYE:moved (1+ TA-DYE:moved))
    )
    (T (TA-DYE:record-skip (strcat "cannot edit " type)))
  )
)

(defun TA-DYE:run (selection prefix role / i entity data type color)
  (setq TA-DYE:moved 0 TA-DYE:skipped 0 TA-DYE:reasons nil
        TA-DYE:visited nil TA-DYE:target-cache nil)
  (setq i 0)
  (while (< i (sslength selection))
    (setq entity (ssname selection i))
    (setq data (entget entity))
    (setq type (cdr (assoc 0 data)))
    (setq color (TA-DYE:effective-aci data nil))
    (if (= type "INSERT")
      (TA-DYE:walk-block (cdr (assoc 2 data)) color prefix role)
      (TA-DYE:move-one entity data color prefix role)
    )
    (setq i (1+ i))
  )
  (list TA-DYE:moved TA-DYE:skipped (reverse TA-DYE:reasons))
)

(defun c:TADYE (/ *error* doc prefix role selection result undo-open)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (defun *error* (message)
    (if undo-open (vla-EndUndoMark doc))
    (if (and message (/= message "Function cancelled"))
      (princ (strcat "\nTADYE: " message))
    )
    (princ)
  )
  (if (setq prefix (TA-DYE:choose-group))
    (progn
          (initget "Auto Main Sub Cut Text Hidden Symbol DefSub")
          (setq role (getkword "\nRole [Auto/Main/Sub/Cut/Text/Hidden/Symbol/DefSub] <Auto>: "))
          (if (not role) (setq role "Auto"))
          (setq role (strcase role))
          (princ "\nSelect objects or block references to dye: ")
          (if (setq selection (ssget))
            (progn
              (vla-StartUndoMark doc)
              (setq undo-open T)
              (setq result (TA-DYE:run selection prefix role))
              (vla-EndUndoMark doc)
              (setq undo-open nil)
              (vla-Regen doc 1)
              (princ (strcat "\nTADYE: changed " (itoa (car result))
                             ", skipped " (itoa (cadr result)) "."))
              (foreach reason (caddr result)
                (princ (strcat "\n  " reason))
              )
              (princ "\nBlock definitions are shared by all their references. UNDO reverses this command.")
            )
          )
    )
  )
  (princ)
)

(princ "\nTADYE loaded. Type TADYE to dye selected objects into an existing layer group.")
(princ)
