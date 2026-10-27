;;; TA_LAYER_FILTER_TREE.lsp
;;; Read the saved AutoCAD Layer Filter hierarchy without modifying the DWG.
;;;
;;; Public functions:
;;;   (TA:GetLayerFilterTree)
;;;     Returns a recursive list of filter nodes.
;;;
;;;   (TA:GetLayerFilterOrder)
;;;     Returns a pre-order flat list.  Each item is:
;;;       (path class layer-names)
;;;
;;;   (TA:GetLayerFilterBranch "PPLINE-FAMELINE")
;;;     Returns the first matching filter node, including its children.
;;;
;;; Test command:
;;;   TAFILTERTREE
;;;
;;; Node format:
;;;   ((NAME . "filter name")
;;;    (CLASS . "AcLyLayerGroup")
;;;    (PATH "root" "child")
;;;    (DEPTH . 1)
;;;    (LAYERS "layer 1" "layer 2")
;;;    (CHILDREN ...nodes...))

(vl-load-com)

(defun TA-LF:dictionary-values (dictionary / data pair result)
  ;; Read all soft-owned objects from a dictionary without using DICTNEXT.
  ;; This is recursion-safe because the complete dictionary is read first.
  (if (and dictionary (setq data (entget dictionary)))
    (foreach pair data
      (if (and (= (car pair) 350) (entget (cdr pair)))
        (setq result (cons (cdr pair) result))
      )
    )
  )
  (reverse result)
)

(defun TA-LF:acly-dictionary (/ layer0 layer-table table-data marker xdict record)
  ;; Layer filters are stored under the extension dictionary of LayerTable.
  (if (and
        (setq layer0 (tblobjname "LAYER" "0"))
        (setq layer-table (cdr (assoc 330 (entget layer0))))
        (setq table-data (entget layer-table))
        (setq marker (member '(102 . "{ACAD_XDICTIONARY") table-data))
        (setq xdict (cdr (assoc 360 marker)))
        (setq record (dictsearch xdict "ACLYDICTIONARY"))
      )
    (cdr (assoc -1 record))
  )
)

(defun TA-LF:child-dictionary (filter-data / holder holder-data nested nested-data)
  ;; In saved drawings the child-filter dictionary is normally reached through
  ;; two 360 references.  The direct-dictionary case is also accepted.
  (if (setq holder (cdr (assoc 360 filter-data)))
    (progn
      (setq holder-data (entget holder))
      (cond
        ((and holder-data
              (setq nested (cdr (assoc 360 holder-data)))
              (setq nested-data (entget nested))
              (= (cdr (assoc 0 nested-data)) "DICTIONARY"))
          nested
        )
        ((and holder-data
              (= (cdr (assoc 0 holder-data)) "DICTIONARY"))
          holder
        )
      )
    )
  )
)

(defun TA-LF:member-layers (filter-data / name-pair tail pair layer-data layer-name result)
  ;; Only 330 references after code 300 are possible group members.  Checking
  ;; entity type prevents an owner/reference handle from becoming a layer.
  (if (setq name-pair (assoc 300 filter-data))
    (setq tail (member name-pair filter-data))
  )
  (foreach pair tail
    (if (and
          (= (car pair) 330)
          (setq layer-data (entget (cdr pair)))
          (= (cdr (assoc 0 layer-data)) "LAYER")
          (setq layer-name (cdr (assoc 2 layer-data)))
          (not (member layer-name result))
        )
      (setq result (cons layer-name result))
    )
  )
  (if result (acad_strlsort result))
)

(defun TA-LF:node-name (node)
  (cdr (assoc 'NAME node))
)

(defun TA-LF:insert-node (node nodes / name first-name)
  ;; Stable alphabetical insertion.  Unlike VL-SORT, duplicate names are kept.
  (setq name (strcase (TA-LF:node-name node)))
  (cond
    ((not nodes) (list node))
    ((< name (strcase (TA-LF:node-name (car nodes))))
      (cons node nodes)
    )
    (T
      (cons (car nodes) (TA-LF:insert-node node (cdr nodes)))
    )
  )
)

(defun TA-LF:sort-nodes (nodes / node result)
  (foreach node nodes
    (setq result (TA-LF:insert-node node result))
  )
  result
)

(defun TA-LF:read-dictionary (dictionary parent-path depth / entity data name class path child-dict children node result)
  ;; Read this level completely before recursion.  This avoids nested DICTNEXT
  ;; calls disturbing the iterator of the parent dictionary.
  (foreach entity (TA-LF:dictionary-values dictionary)
    (if (and
          (setq data (entget entity))
          (setq name (cdr (assoc 300 data)))
        )
      (progn
        (setq class (cdr (assoc 1 data)))
        (setq path (append parent-path (list name)))
        (setq child-dict (TA-LF:child-dictionary data))
        (setq children
          (if child-dict
            (TA-LF:read-dictionary child-dict path (1+ depth))
          )
        )
        (setq node
          (list
            (cons 'NAME name)
            (cons 'CLASS class)
            (cons 'PATH path)
            (cons 'DEPTH depth)
            (cons 'LAYERS (TA-LF:member-layers data))
            (cons 'CHILDREN children)
          )
        )
        (setq result (cons node result))
      )
    )
  )
  (TA-LF:sort-nodes (reverse result))
)

(defun TA:GetLayerFilterTree (/ dictionary caught)
  ;; Main read-only API.  NIL means that no saved filter dictionary was found
  ;; or that AutoCAD returned an unreadable internal filter structure.
  (setq TA-LF:LastError nil)
  (setq caught
    (vl-catch-all-apply
      '(lambda ()
        (if (setq dictionary (TA-LF:acly-dictionary))
          (TA-LF:read-dictionary dictionary nil 0)
        )
      )
    )
  )
  (if (vl-catch-all-error-p caught)
    (progn
      (setq TA-LF:LastError (vl-catch-all-error-message caught))
      nil
    )
    caught
  )
)

(defun TA-LF:find-node (name nodes / node found)
  (while (and nodes (not found))
    (setq node (car nodes))
    (if (= (strcase name) (strcase (TA-LF:node-name node)))
      (setq found node)
      (setq found
        (TA-LF:find-node name (cdr (assoc 'CHILDREN node)))
      )
    )
    (setq nodes (cdr nodes))
  )
  found
)

(defun TA:GetLayerFilterBranch (filter-name / tree)
  ;; Names are not required to be unique in AutoCAD.  This helper returns the
  ;; first match; use PATH from TA:GetLayerFilterOrder to disambiguate.
  (if (setq tree (TA:GetLayerFilterTree))
    (TA-LF:find-node filter-name tree)
  )
)

(defun TA-LF:flatten (nodes / node result)
  (foreach node nodes
    (setq result
      (append
        result
        (list
          (list
            (cdr (assoc 'PATH node))
            (cdr (assoc 'CLASS node))
            (cdr (assoc 'LAYERS node))
          )
        )
        (TA-LF:flatten (cdr (assoc 'CHILDREN node)))
      )
    )
  )
  result
)

(defun TA:GetLayerFilterOrder (/ tree)
  ;; Flat pre-order result: (path class layer-names).
  (if (setq tree (TA:GetLayerFilterTree))
    (TA-LF:flatten tree)
  )
)

(defun TA-LF:indent (depth)
  (repeat depth (princ "  "))
)

(defun TA-LF:print-tree (nodes / node layers)
  (foreach node nodes
    (princ "\n")
    (TA-LF:indent (cdr (assoc 'DEPTH node)))
    (princ (strcat "- " (TA-LF:node-name node)))
    (if (setq layers (cdr (assoc 'LAYERS node)))
      (princ (strcat "  [" (itoa (length layers)) " layers]"))
    )
    (TA-LF:print-tree (cdr (assoc 'CHILDREN node)))
  )
)

(defun c:TAFILTERTREE (/ tree)
  (if (setq tree (TA:GetLayerFilterTree))
    (progn
      (princ "\nSaved Layer Filter hierarchy:")
      (TA-LF:print-tree tree)
    )
    (if TA-LF:LastError
      (princ (strcat "\nTAFILTERTREE: " TA-LF:LastError))
      (princ "\nTAFILTERTREE: no saved Layer Filter hierarchy was found.")
    )
  )
  (princ)
)
(c:TAFILTERTREE)
(princ "\nTA_LAYER_FILTER_TREE loaded. Type TAFILTERTREE to inspect the hierarchy.")
(princ)
