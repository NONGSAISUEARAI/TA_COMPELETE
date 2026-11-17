; presetting
; Overall table scale relative to the current Table Style.
; 1.0 = original size, 2.0 = double size, 0.5 = half size.
; Must be greater than zero. Applied to newly created tables only.
; This value comes directly from this file; saved .cfg does not override it.
(setq count:table-scale 1.0)

; 2. Merge adjacent equal block names in the Name column of Lookup tables.
; T = merge, nil = repeat the name on every row. New tables only.
; Preview, Lookup value, and Count cells remain separate.
(setq count:merge-name-cells T)

; Default settings for Count V1.6.
; Existing saved settings (.cfg / BLKCOUNTSETTINGS) take priority.
; Lookup reports always show Name, Preview, Lookup value, and Count.
(setq count:defaults
   '(
        (out "tab")       ; Output: "tab", "txt", "csv", "com"
        (tg1 "1")         ; Title row: "1" show, "0" hide
        (tg2 "1")         ; Preview column: "1" show, "0" hide (normal count)
        (tg3 "1")         ; Quantity column: "1" show, "0" hide (normal count)
        (ed1 "Block Data") ; Table/report title
        (ed2 "Preview")    ; Preview heading
        (ed3 "Block Name") ; Block name heading (normal count)
        (ed4 "Count")      ; Quantity heading (normal count)
        (srt "blk")        ; File/command sort: "blk" name then value, "qty" quantity
                          ; Tables always group by block name, then Lookup value.
        (ord "asc")        ; Order: "asc" ascending, "des" descending
    )
)

;;--------------=={ Count.lsp - Advanced Block Counter }==--------------;;
;;                                                                      ;;
;;  This program enables the user to record the quantities of a         ;;
;;  selection or all standard or dynamic blocks in the working drawing. ;;
;;  The results of the block count may be displayed at the AutoCAD      ;;
;;  command-line, written to a Text or CSV file, or displayed in an     ;;
;;  AutoCAD Table, where available.                                     ;;
;;                                                                      ;;
;;  Upon issuing the command syntax 'count' at the AutoCAD              ;;
;;  command-line, the user is prompted to make a selection of standard  ;;
;;  or dynamic blocks to be counted by the program. At this prompt,     ;;
;;  the user may right-click or press 'Enter' to automatically count    ;;
;;  all blocks in the drawing.                                          ;;
;;                                                                      ;;
;;  Depending on the output setting, the results may then be printed    ;;
;;  to the AutoCAD command-line and displayed in the Text Window, or    ;;
;;  the user will be prompted to specify an insertion point for the     ;;
;;  table, or a filename & location for the Text or CSV output file.    ;;
;;                                                                      ;;
;;  The program settings may be configured using the 'countsettings'    ;;
;;  command; this command will present the user with a dialog interface ;;
;;  through which the data output, table & file headings, displayed     ;;
;;  columns, sorting field & sort order may each be altered.            ;;
;;----------------------------------------------------------------------;;
;;  Author:  Lee Mac, Copyright � 2014  -  www.lee-mac.com              ;;
;;----------------------------------------------------------------------;;
;;  Version 1.0    -    2010-06-05                                      ;;
;;                                                                      ;;
;;  - First release.                                                    ;;
;;----------------------------------------------------------------------;;
;;  Version 1.1    -    2010-06-06                                      ;;
;;                                                                      ;;
;;  - Updated code to include Settings dialog.                          ;;
;;  - Added Undo Marks.                                                 ;;
;;----------------------------------------------------------------------;;
;;  Version 1.2    -    2010-06-06                                      ;;
;;                                                                      ;;
;;  - Fixed bug with 64-bit systems.                                    ;;
;;----------------------------------------------------------------------;;
;;  Version 1.3    -    2011-03-02                                      ;;
;;                                                                      ;;
;;  - Program completely rewritten.                                     ;;
;;  - Updated code to work without error on 64-bit systems by fixing    ;;
;;    bug with ObjectID subfunction - my thanks go to member 'Jeff M'   ;;
;;    at theSwamp.org forums for helping me solve this problem.         ;;
;;  - Added ability to write block count to Text/CSV Files.             ;;
;;----------------------------------------------------------------------;;
;;  Version 1.4    -    2014-06-15                                      ;;
;;                                                                      ;;
;;  - Program completely rewritten.                                     ;;
;;----------------------------------------------------------------------;;
;;  Version 1.5    -    2015-06-07                                      ;;
;;                                                                      ;;
;;  - Minor update to enable full compatibility with ZWCAD.             ;;
;;    (regeneratetablesuppressed property not available)                ;;
;;----------------------------------------------------------------------;;
;;  Version 1.6    -    2026-11-17                                      ;;
;;                                                                      ;;
;;  - Added TA:blk-count command with compound filters for block name,  ;;
;;    layer, visibility state, lookup property, and attribute value.    ;;
;;  - Numbered Lookup/property value menus, All, saved preferences.     ;;
;;  - Multi-name Include/Exclude filter; Lookup report adds Name before;;
;;    Preview and separates quantities by block name and Lookup value. ;;
;;----------------------------------------------------------------------;;

(setq count:version "1-6")

;;----------------------------------------------------------------------;;

(defun count:fixdir ( dir )
    (vl-string-right-trim "\\" (vl-string-translate "/" "\\" dir))
)

;;----------------------------------------------------------------------;;

(defun count:getsavepath ( / tmp )
    (cond      
        (   (setq tmp (getvar 'roamablerootprefix))
            (strcat (count:fixdir tmp) "\\Support")
        )
        (   (setq tmp (findfile "acad.pat"))
            (count:fixdir (vl-filename-directory tmp))
        )
        (   (count:fixdir (vl-filename-directory (vl-filename-mktemp))))
    )
)

;;----------------------------------------------------------------------;;

(setq count:savepath (count:getsavepath) ;; Save path for DCL & Config files
      count:dclfname (strcat count:savepath "\\LMAC_count_V" count:version ".dcl")
      count:cfgfname (strcat count:savepath "\\LMAC_count_V" count:version ".cfg")
)

;;----------------------------------------------------------------------;;

(defun c:blkcount

    (
        /
        *error*
        all
        col
        des dir
        ed1 ed2 ed3 ed4
        fil flt fnm fun
        hgt
        idx ins
        lst lookup
        ord out
        row range
        sel srt
        tab tablescale tg1 tg2 tg3 tmp
        xrf itm txt sym
    )

    (defun *error* ( msg )
        (if (= 'file (type des))
            (close des)
        )
        (if (and (= 'vla-object (type tab))
                 (null (vlax-erased-p tab))
                 (= "AcDbTable" (vla-get-objectname tab))
                 (vlax-write-enabled-p tab)
                 (vlax-property-available-p tab 'regeneratetablesuppressed t)
            )
            (vla-put-regeneratetablesuppressed tab :vlax-false)
        )
        (if (and (= 'vla-object (type count:wshobject))
                 (not (vlax-object-released-p count:wshobject))
            )
            (progn
                (vlax-release-object count:wshobject)
                (setq count:wshobject nil)
            )
        )
        (count:endundo (count:acdoc))
        (if (and msg (not (wcmatch (strcase msg t) "*break,*cancel*,*exit*")))
            (princ (strcat "\nError: " msg))
        )
        (princ)
    )

    (if (not (findfile count:cfgfname))
        (count:writecfg count:cfgfname (mapcar 'cadr count:defaults))
    )
    (count:readcfg count:cfgfname (mapcar 'car count:defaults))
    (foreach sym count:defaults
        (if (not (boundp (car sym))) (apply 'set sym))
    )
    (if (and (= "tab" out) (not (vlax-method-applicable-p (vla-get-modelspace (count:acdoc)) 'addtable)))
        (setq out "txt")
    )
    
    (count:startundo (count:acdoc))

    (while (setq tmp (tblnext "block" (null tmp)))
        (if (= 4 (logand 4 (cdr (assoc 70 tmp))))
            (setq xrf (vl-list* "," (cdr (assoc 2 tmp)) xrf))
        )
    )
    (if xrf
        (setq fil  (list '(0 . "INSERT") '(-4 . "<NOT") (cons 2 (apply 'strcat (cdr xrf))) '(-4 . "NOT>")))
        (setq fil '((0 . "INSERT")))
    )
    
    (cond
        (   (null (setq all (ssget "_X" fil)))
            (count:popup
                "No Blocks Found" 64
                (princ "No blocks were found in the active drawing.")
            )
        )
        (   (and (= "tab" out) (= 4 (logand 4 (cdr (assoc 70 (tblsearch "layer" (getvar 'clayer)))))))
            (count:popup
                "Current Layer Locked" 64
                (princ "Please unlock the current layer before using this program.")
            )
        )
        (   (progn
                (setq sel (count:selectblocks fil all))
                (null sel)
            )
        )
        (   (and count:usefilters
                 (progn
                     (setq flt (count:getfilters sel)
                           sel (count:filterselection sel flt))
                     (null sel)
                 )
            )
            (count:popup "No Matching Blocks" 64
                (princ "No blocks matched the specified filters.")
            )
        )
        (   (or (= "com" out)
                (and (=  "tab" out) (setq ins (getpoint "\nSpecify point for table: ")))
                (and (/= "tab" out)
                    (setq fnm
                        (getfiled "Create Output File"
                            (cond
                                (   (and (setq dir (getenv "LMac\\countdir"))
                                         (vl-file-directory-p (setq dir (count:fixdir dir)))
                                    )
                                    (strcat dir "\\")
                                )
                                (   (getvar 'dwgprefix))
                            )
                            out 1
                        )
                    )
                )
            )
            (setq lookup (cdr (assoc 'lookup flt))
                  lst (count:buildreport sel lookup))
            (if lookup
                (setq ed3 (strcat "Lookup: " (car lookup))
                      ed4 "Count" tg2 "1" tg3 "1"))
            (setq lst (count:sortreport lst (if (= "tab" out) "blk" srt) ord))
            (cond
                (   (= "com" out)
                    (defun prinn ( x ) (princ "\n") (princ x))
                    (prinn (count:padbetween "" "" "=" 60))
                    (if (= "1" tg1)
                        (progn
                            (prinn ed1)
                            (prinn (count:padbetween "" "" "-" 60))
                        )
                    )
                    (prinn (count:padbetween (if lookup (strcat "Name / " ed3) ed3) ed4 " " 55))
                    (prinn (count:padbetween "" "" "-"   60))
                    (if (= "1" tg3)
                        (foreach itm lst
                            (prinn (count:lst->str (car (count:reporttextrows (list itm) "1" lookup)) "\t"))
                        )
                        (foreach itm lst (prinn (car itm)))
                    )
                    (prinn (count:padbetween "" "" "=" 60))
                    (textpage)
                )
                (   (= "tab" out)
                    (setq hgt
                        (vla-gettextheight
                            (vla-item
                                (vla-item (vla-get-dictionaries (count:acdoc)) "acad_tablestyle")
                                (getvar 'ctablestyle)
                            )
                            acdatarow
                        )
                    )
                    (setq tab
                        (vla-addtable
                            (vlax-get-property (count:acdoc) (if (= 1 (getvar 'cvport)) 'paperspace 'modelspace))
                            (vlax-3D-point (trans ins 1 0))
                            (+ (length lst) 2)
                            (+ 1 (atoi tg2) (atoi tg3) (if lookup 1 0))
                            (* 2.5 hgt)
                            (* hgt
                                (max
                                    (apply 'max
                                        (mapcar 'strlen
                                            (append
                                                (if (= "1" tg2) (list ed2))
                                                (if (= "1" tg3) (list ed4))
                                                (if lookup (list "Name"))
                                                (cons ed3 (apply 'append (count:reporttextrows lst tg3 lookup)))
                                            )
                                        )
                                    )
                                    (if (= "1" tg1) (/ (strlen ed1) (+ 1 (atoi tg2) (atoi tg3) (if lookup 1 0))) 0)
                                )
                            )
                        )
                    )
                    (if (vlax-property-available-p tab 'regeneratetablesuppressed t)
                        (vla-put-regeneratetablesuppressed tab :vlax-true)
                    )
                    (vla-put-stylename tab (getvar 'ctablestyle))
                    (setq col 0)
                    (mapcar
                       '(lambda ( a b ) (if (= "1" a) (progn (vla-settext tab 1 col b) (setq col (1+ col)))))
                        (list (if lookup "1" "0") tg2 "1" tg3)
                        (list "Name" ed2 ed3 ed4)
                    )
                    (setq row 2)
                    (foreach itm lst
                        (setq col -1)
                        (if lookup (vla-settext tab row (setq col (1+ col)) (cadddr itm)))
                        (if (= "1" tg2)
                            (count:setblocktablerecord tab row (setq col (1+ col)) (caddr itm))
                        )
                        (foreach txt (car (count:reporttextrows (list itm) tg3 nil))
                            (vla-settext tab row (setq col (1+ col)) txt)
                        )
                        (setq row (1+ row))
                    )
                    (if (= "1" tg1)
                        (vla-settext tab 0 0 ed1)
                        (vla-deleterows tab 0 1)
                    )
                    (if lookup
                        (foreach range (count:namemergegroups lst (if (= "1" tg1) 2 1) count:merge-name-cells)
                            (vla-mergecells tab (car range) (cdr range) 0 0)))
                    (setq tablescale (count:tablescalefactor))
                    (if (/= 1.0 tablescale)
                        (progn
                            (if (vlax-property-available-p tab 'regeneratetablesuppressed t)
                                (vla-put-regeneratetablesuppressed tab :vlax-false))
                            (vla-scaleentity tab (vlax-3D-point (trans ins 1 0)) tablescale)
                        )
                    )
                )
                (   (setenv "LMac\\countdir" (count:fixdir (vl-filename-directory fnm)))
                    (if
                        (
                            (if (= "txt" out)
                                count:writetxt
                                count:writecsv
                            )
                            (append
                                (if (= "1" tg1)
                                    (list (list ed1))
                                )
                                (if (= "1" tg3)
                                    (cons (append (if lookup (list "Name")) (list ed3 ed4)) (count:reporttextrows lst tg3 lookup))
                                    (cons (append (if lookup (list "Name")) (list ed3)) (count:reporttextrows lst tg3 lookup))
                                )
                            )
                            fnm
                        )
                        (princ (strcat "\nBlock data written to " fnm))
                        (count:popup "Unable to Create Output File" 48
                            (princ
                                (strcat
                                    "The program was unable to create the following file:\n\n"
                                    fnm
                                    "\n\nPlease ensure that you have write-permissions for the above directory."
                                )
                            )
                        )
                    )
                )
            )
        )
    )
    (*error* nil)
    (princ)
)

;;----------------------------------------------------------------------;;

(defun c:TA:blk-count ( / result )
    (setq count:usefilters t
          result (vl-catch-all-apply 'c:blkcount)
          count:usefilters nil
    )
    (if (vl-catch-all-error-p result)
        (princ (strcat "\nError: " (vl-catch-all-error-message result)))
    )
    (princ)
)

;;----------------------------------------------------------------------;;

(defun count:tablescalefactor nil
    (if (and (numberp count:table-scale) (< 0 count:table-scale))
        count:table-scale
        (progn
            (princ "\nInvalid count:table-scale; using 1.0. Enter a number greater than zero in presetting.")
            1.0))
)

(defun count:selectblocks ( fil all / selected )
    (cond
        ((setq selected (ssget "_I" fil)) selected)
        (t
            (princ "\nSelect blocks of any names; add/remove freely, then Enter <all>: ")
            (setq selected (vl-catch-all-apply 'ssget (list fil)))
            (cond
                ((vl-catch-all-error-p selected) nil)
                ((null selected) all)
                (t selected))))
)

(defun count:blocknames ( sel / idx name names )
    (setq idx 0)
    (repeat (sslength sel)
        (setq name (count:effectivename (ssname sel idx)) idx (1+ idx))
        (if (not (member name names)) (setq names (cons name names))))
    (vl-sort names '(lambda (a b) (< (strcase a) (strcase b))))
)

;; Name selection is optional and always enumerates the original selection.
;; Spec: (include name...) / (exclude name...) / (all).
(defun count:selectnames ( sel previous / names mode chosen done index choice name allnames )
    (setq names (count:blocknames sel))
    (initget "Include Exclude All")
    (setq mode (getkword "\nName filter [Include/Exclude/All] <Include>: "))
    (if (null mode) (setq mode "Include"))
    (if (= "All" mode)
        '(all)
        (progn
            (setq mode (if (= "Exclude" mode) 'exclude 'include))
            (if (and (listp previous) (eq mode (car previous)))
                (setq chosen (cdr previous)))
            (while (not done)
                (princ (strcat "\n--- " (vl-symbol-name mode) " block names ---\n  0 = All names"))
                (setq index 0)
                (foreach name names
                    (setq index (1+ index))
                    (princ (strcat "\n  " (itoa index)
                                   (if (member name chosen) " [X] " " [ ] ") name)))
                (initget 4)
                (setq choice (getint "\nToggle name number; repeat for multiple names <Done>: "))
                (cond
                    ((null choice) (setq done t))
                    ((= 0 choice) (setq chosen nil allnames t done t))
                    ((<= 1 choice (length names))
                        (setq name (nth (1- choice) names)
                              chosen (if (member name chosen) (vl-remove name chosen)
                                         (append chosen (list name)))))
                    (t (princ "\nNumber is not in the name list."))))
            (if allnames '(all) (cons mode chosen))))
)

(defun count:matchname ( name spec / matched )
    (cond
        ((or (null spec) (eq 'all (car (if (listp spec) spec nil)))) t)
        ((= 'str (type spec)) (count:wcmatch name spec))
        (t
            (setq matched (not (null (member (strcase name) (mapcar 'strcase (cdr spec))))))
            (if (eq 'exclude (car spec)) (not matched) matched)))
)

(defun count:getfilters ( sel / done flt key val )
    (princ "\nFilters support wildcards (* and ?); different types use AND.")
    (princ (strcat "\nSelected: " (itoa (sslength sel)) " blocks, "
                   (itoa (length (count:blocknames sel))) " block names."))
    (princ "\nName optionally includes/excludes multiple names. Lookup rows show Name + value.")
    (while (not done)
        (initget "Name Layer Visibility Lookup Attribute Clear Done")
        (setq key (getkword
            (strcat "\nFilter [Name/Layer/Visibility/Lookup/Attribute/Clear/Done] <Done>"
                    (count:filterdescription flt) ": "
            )
        ))
        (cond
            ((or (null key) (= "Done" key)) (setq done t))
            ((= "Clear" key) (setq flt nil) (princ "\nAll filters cleared."))
            ((= "Name" key)
                (setq val (count:selectnames sel (cdr (assoc 'name flt)))
                      flt (if (eq 'all (car val)) (vl-remove (assoc 'name flt) flt)
                              (count:setfilter 'name val flt))))
            ((= "Layer" key)
                (if (/= "" (setq val (getstring t "\nLayer name pattern <cancel>: ")))
                    (setq flt (count:setfilter 'layer val flt))))
            ((= "Visibility" key)
                (if (/= "" (setq val (getstring t "\nVisibility state pattern <cancel>: ")))
                    (setq flt (count:setfilter 'visibility val flt))))
            ((= "Lookup" key)
                (if (setq val (count:selectlookup sel flt))
                    (setq flt (count:setfilter 'lookup val flt))))
            ((= "Attribute" key)
                (if (/= "" (setq val (getstring t "\nAttribute TAG=VALUE (use *=VALUE for any tag) <cancel>: ")))
                    (setq flt (count:setfilter 'attribute (count:splitfilter val "*") flt))))
        )
    )
    flt
)

;;----------------------------------------------------------------------;;

(defun count:setfilter ( key val flt / old )
    (if (setq old (assoc key flt))
        (subst (cons key val) old flt)
        (cons (cons key val) flt)
    )
)

(defun count:splitfilter ( str default / pos )
    (if (setq pos (vl-string-position 61 str))
        (list (if (= 0 pos) default (substr str 1 pos)) (substr str (+ pos 2)))
        (list default str)
    )
)

(defun count:filterdescription ( flt / item key out )
    (foreach key '(name layer visibility lookup attribute)
        (if (setq item (assoc key flt))
            (setq out (cons
                (strcat (vl-symbol-name key) "="
                    (cond
                        ((and (= key 'name) (listp (cdr item)))
                            (strcat (vl-symbol-name (cadr item)) ": "
                                    (if (cddr item) (count:lst->str (cddr item) ", ") "(none)")))
                        ((= key 'lookup)
                            (strcat (cadr item) "="
                                (if (= 'all (caddr item)) "All"
                                    (count:variantstring (caddr item)))))
                        ((listp (cdr item)) (strcat (cadr item) "=" (caddr item)))
                        (t (cdr item))))
                out)))
    )
    (if out (strcat " {" (count:lst->str (reverse out) "; ") "}") " {none}")
)

;;----------------------------------------------------------------------;;

(defun count:filterselection ( sel flt / ent idx out total )
    (if (null flt)
        sel
        (progn
            (setq out (ssadd) total (sslength sel) idx 0)
            (repeat total
                (setq ent (ssname sel idx) idx (1+ idx))
                (if (count:matchesfilters ent flt) (ssadd ent out))
            )
            (princ (strcat "\nFilter result: " (itoa (sslength out))
                           " of " (itoa total) " block(s)."))
            (if (< 0 (sslength out)) out)
        )
    )
)

(defun count:matchesfilters ( ent flt / dat )
    (setq dat (entget ent))
    (and
        (count:matchname (count:effectivename ent) (cdr (assoc 'name flt)))
        (or (null (assoc 'layer flt))
            (count:wcmatch (cdr (assoc 8 dat)) (cdr (assoc 'layer flt))))
        (or (null (assoc 'visibility flt))
            (count:wcmatch (count:getvisibilitystate (vlax-ename->vla-object ent)) (cdr (assoc 'visibility flt))))
        (or (null (assoc 'lookup flt))
            (count:entitylookupentry ent (cdr (assoc 'lookup flt))))
        (or (null (assoc 'attribute flt))
            (count:matchattribute (vlax-ename->vla-object ent) (cdr (assoc 'attribute flt))))
    )
)

(defun count:wcmatch ( value pattern )
    (and value pattern (wcmatch (strcase value) (strcase pattern)))
)

(defun count:variantstring ( value )
    (cond
        ((= 'str  (type value)) value)
        ((= 'int  (type value)) (itoa value))
        ((= 'real (type value)) (rtos value 2 12))
        ((vl-princ-to-string value))
    )
)

;;----------------------------------------------------------------------;;

(defun count:getdynamicproperties ( obj / result )
    (if (and (vlax-property-available-p obj 'isdynamicblock)
             (= :vlax-true (vla-get-isdynamicblock obj)))
        (progn
            (setq result (vl-catch-all-apply 'vlax-invoke
                             (list obj 'getdynamicblockproperties)))
            (if (not (vl-catch-all-error-p result)) result)
        )
    )
)

(defun count:matchdynamicproperty ( obj spec / found prop )
    (foreach prop (count:getdynamicproperties obj)
        (if (and (count:wcmatch (vla-get-propertyname prop) (car spec))
                 (count:wcmatch
                     (count:variantstring (vlax-variant-value (vla-get-value prop)))
                     (cadr spec)))
            (setq found t))
    )
    found
)

;; Lookup menu records: (uppercase-property-name property-name typed-values).
;; Filter: (property-name typed-value-or-ALL), independent of block names.
;; Preferences store identities, never menu positions.

(defun count:aslist ( value / result )
    (cond
        ((= 'variant (type value)) (count:aslist (vlax-variant-value value)))
        ((= 'safearray (type value))
            (setq result (vl-catch-all-apply 'vlax-safearray->list (list value)))
            (if (not (vl-catch-all-error-p result)) result))
        ((listp value) value)
    )
)

(defun count:lookupvalueequal ( a b )
    (if (and (numberp a) (numberp b))
        (= a b)
        (and (= 'str (type a)) (= 'str (type b)) (= (strcase a) (strcase b)))
    )
)

(defun count:appendvalue ( value values )
    (if (or (not (member (type value) '(str int real)))
            (vl-some '(lambda ( x ) (count:lookupvalueequal value x)) values))
        values
        (append values (list value))
    )
)

(defun count:propertyvalues ( prop / result values value )
    (setq result (vl-catch-all-apply 'vlax-get (list prop 'allowedvalues)))
    (if (not (vl-catch-all-error-p result))
        (foreach value (count:aslist result)
            (if (= 'variant (type value)) (setq value (vlax-variant-value value)))
            (setq values (count:appendvalue value values))))
    (setq result (vl-catch-all-apply 'vla-get-value (list prop)))
    (if (not (vl-catch-all-error-p result))
        (setq values (count:appendvalue (vlax-variant-value result) values)))
    values
)

;; Read lookup parameter metadata to also recognise renamed Lookup properties.
;; Match against the actual published property names in the reference.
(defun count:lookupnames ( obj / blk data pair field names )
    (if (and (vlax-property-available-p obj 'effectivename)
             (setq blk (vla-item (vla-get-blocks (vla-get-document obj))
                                (vla-get-effectivename obj)))
             (= :vlax-true (vla-get-hasextensiondictionary blk)))
        (foreach pair (dictsearch
                          (vlax-vla-object->ename (vla-getextensiondictionary blk))
                          "ACAD_ENHANCEDBLOCK")
            (if (and (= 360 (car pair))
                     (setq data (entget (cdr pair)))
                     (= "BLOCKLOOKUPPARAMETER" (cdr (assoc 0 data))))
                (foreach field data
                    (if (and (<= 300 (car field) 309) (= 'str (type (cdr field))))
                        (setq names (cons (strcase (cdr field)) names)))))))
    names
)

(defun count:addlookuprecord ( name values records / key old value )
    (setq key (strcase name))
    (if (setq old (assoc key records))
        (progn
            (foreach value values
                (setq old (list key (cadr old)
                               (count:appendvalue value (caddr old)))))
            (subst old (assoc key records) records))
        (append records (list (list key name values))))
)

(defun count:lookupcatalog ( sel / idx ent obj names vis prop name values records fallback result )
    (setq idx 0)
    (repeat (sslength sel)
        (setq ent (ssname sel idx) idx (1+ idx)
              obj (vlax-ename->vla-object ent)
              result (vl-catch-all-apply 'count:lookupnames (list obj))
              names (if (not (vl-catch-all-error-p result)) result)
              result (vl-catch-all-apply 'count:getvisibilityparametername (list obj))
              vis (if (not (vl-catch-all-error-p result)) result))
        (foreach prop (count:getdynamicproperties obj)
            (setq name (vla-get-propertyname prop)
                  values (count:propertyvalues prop))
            (cond
                ((or (member (strcase name) names) (wcmatch (strcase name) "*LOOKUP*"))
                    (setq records (count:addlookuprecord name values records)))
                ((and values (= 'str (type (car values)))
                      (or (null vis) (/= (strcase name) (strcase vis))))
                    (setq fallback (count:addlookuprecord name values fallback)))
            )
        )
    )
    (if (and (null records) fallback)
        (progn
            (princ "\nLookup metadata unavailable; showing text dynamic properties for selection.")
            (setq records fallback)))
    records
)

;; Bounds are checked before NTH; Enter accepts only a valid default.
(defun count:menuint ( prompt maximum default / choice done )
    (while (not done)
        (initget 4)
        (setq choice (getint (strcat prompt " <" (itoa default) ">: ")))
        (if (null choice) (setq choice default))
        (if (<= 0 choice maximum)
            (setq done t)
            (princ (strcat "\nEnter a number from 0 to " (itoa maximum) "."))))
    choice
)

(defun count:lookupmemory ( / file line result memory key item value )
    (if (setq file (open (strcat count:savepath "\\TA_count_V1-6_lookup.cfg") "r"))
        (progn
            (setq line (read-line file))
            (close file)
            (if line
                (progn
                    (setq result (vl-catch-all-apply 'read (list line)))
                    (if (and (not (vl-catch-all-error-p result)) (listp result))
                        (progn
                            ;; Migrate the earlier block-scoped preferences.
                            (foreach item result
                                (setq key (car item) value (cdr item))
                                (cond
                                    ((eq key 'last)
                                        (if (listp value) (setq value (cadr value))))
                                    ((listp key) (setq key (cadr key))))
                                (if (or (eq key 'last) (= 'str (type key)))
                                    (setq memory (count:setfilter key value memory))))
                            memory))))))
)

(defun count:selectlookup ( sel flt / records memory last default index chosen key values old choice result candidate record value )
    ;; An optional Name filter is retained in either menu order.
    (setq candidate (count:filterselection sel (vl-remove (assoc 'lookup flt) flt)))
    (cond
        ((null candidate) (princ "\nNo blocks remain under the other filters."))
        ((null (setq records (count:lookupcatalog candidate)))
            (princ "\nNo Lookup properties were found in the selected blocks."))
        (t
            (setq memory (count:lookupmemory) last (cdr (assoc 'last memory))
                  default 1 index 0)
            (princ "\n--- Lookup properties (all block names) ---\n  0 = Back")
            (foreach record records
                (setq index (1+ index))
                (princ (strcat "\n  " (itoa index) " = " (cadr record)))
                (if (equal (car record) last) (setq default index)))
            (setq choice (count:menuint "\nSelect Lookup number" (length records) default))
            (if (< 0 choice)
                (progn
                    (setq chosen (nth (1- choice) records) key (car chosen)
                          values (caddr chosen) old (assoc key memory)
                          default 0 index 0)
                    (princ (strcat "\n--- " (cadr chosen)
                                   " values ---\n  0 = All (separate row per used value)"))
                    (foreach value values
                        (setq index (1+ index))
                        (princ (strcat "\n  " (itoa index) " = " (vl-prin1-to-string value)))
                        (if (and old (count:lookupvalueequal value (cdr old)))
                            (setq default index)))
                    (setq choice (count:menuint "\nSelect Lookup value number" (length values) default)
                          choice (if (= 0 choice) 'all (nth (1- choice) values))
                          result (list (cadr chosen) choice)
                          memory (count:setfilter 'last key memory)
                          memory (count:setfilter key choice memory))
                    (if (not (count:writecfg
                                  (strcat count:savepath "\\TA_count_V1-6_lookup.cfg") (list memory)))
                        (princ "\nLookup selected, but preferences could not be saved."))
                )
            )
        )
    )
    result
)

(defun count:dynamicpairs ( obj / prop pairs )
    (foreach prop (count:getdynamicproperties obj)
        (setq pairs (cons (cons (vla-get-propertyname prop)
                               (vlax-variant-value (vla-get-value prop))) pairs)))
    pairs
)

(defun count:lookupentry ( obj spec / pair value found )
    (foreach pair (count:dynamicpairs obj)
        (if (= (strcase (car pair)) (strcase (car spec)))
            (progn
                (setq value (cdr pair))
                (if (or (eq 'all (cadr spec)) (count:lookupvalueequal value (cadr spec)))
                    (setq found (list value))))))
    found
)

(defun count:matchlookup ( obj spec )
    (not (null (count:lookupentry obj spec)))
)

(defun count:entitylookupentry ( ent spec )
    (count:lookupentry (vlax-ename->vla-object ent) spec)
)

;; Report rows: (display-label quantity preview-block-record-name effective-name).
;; Keep the actual DXF 2 block record so dynamic previews show the selected state.
(defun count:addreportrow ( value preview name rows / old )
    (if (setq old (vl-some
            '(lambda ( x ) (if (and (= (strcase name) (strcase (cadddr x)))
                                   (count:lookupvalueequal value (car x))) x)) rows))
        (subst (list (car old) (1+ (cadr old)) (caddr old) (cadddr old)) old rows)
        (append rows (list (list value 1 preview name))))
)

(defun count:buildreport ( sel lookup / idx ent entry name rows )
    (setq idx 0)
    (repeat (sslength sel)
        (setq ent (ssname sel idx) idx (1+ idx) name (count:effectivename ent))
        (if lookup
            (if (setq entry (count:entitylookupentry ent lookup))
                (setq rows (count:addreportrow (car entry) (cdr (assoc 2 (entget ent))) name rows)))
            (setq rows (count:addreportrow name name name rows))))
    (mapcar '(lambda ( x ) (list (count:variantstring (car x)) (cadr x) (caddr x) (cadddr x))) rows)
)

(defun count:reportless ( a b field order / an bn av bv left right )
    (setq an (strcase (cadddr a)) bn (strcase (cadddr b))
          av (strcase (car a)) bv (strcase (car b)))
    (cond
        ((and (= "blk" field) (/= an bn)) (setq left an right bn))
        ((and (= "qty" field) (/= (cadr a) (cadr b)))
            (setq left (cadr a) right (cadr b)))
        ((/= av bv) (setq left av right bv))
        ((/= an bn) (setq left an right bn)))
    (and left (if (= "des" order) (> left right) (< left right)))
)

(defun count:sortreport ( rows field order )
    (mapcar '(lambda ( index ) (nth index rows))
        (vl-sort-i rows '(lambda ( a b ) (count:reportless a b field order))))
)

;; Zero-based inclusive ranges for adjacent equal names; excludes single rows.
;; first is after any title removal so header cells can never be included.
(defun count:namemergegroups ( rows first enabled / index start previous name row groups )
    (if enabled
        (progn
            (setq index first start first)
            (foreach row rows
                (setq name (strcase (cadddr row)))
                (if (and previous (/= previous name))
                    (progn
                        (if (< start (1- index)) (setq groups (cons (cons start (1- index)) groups)))
                        (setq start index)))
                (setq previous name index (1+ index)))
            (if (and previous (< start (1- index)))
                (setq groups (cons (cons start (1- index)) groups)))
            (reverse groups)))
)

(defun count:reporttextrows ( rows quantity named )
    (mapcar '(lambda ( x )
        (append (if named (list (cadddr x)))
                (if (= "1" quantity) (list (car x) (itoa (cadr x))) (list (car x))))) rows)
)

;;----------------------------------------------------------------------;;

(defun count:getvisibilityparametername ( obj / blk vis )
    (if
        (and
            (vlax-property-available-p obj 'effectivename)
            (setq blk (vl-catch-all-apply 'vla-item
                (list (vla-get-blocks (vla-get-document obj)) (vla-get-effectivename obj))))
            (not (vl-catch-all-error-p blk))
            (= :vlax-true (vla-get-isdynamicblock blk))
            (= :vlax-true (vla-get-hasextensiondictionary blk))
            (setq vis
                (vl-some
                   '(lambda ( pair )
                        (if (and (= 360 (car pair))
                                 (= "BLOCKVISIBILITYPARAMETER"
                                    (cdr (assoc 0 (entget (cdr pair))))))
                            (cdr pair)))
                    (dictsearch
                        (vlax-vla-object->ename (vla-getextensiondictionary blk))
                        "ACAD_ENHANCEDBLOCK")))
        )
        (cdr (assoc 301 (entget vis)))
    )
)

(defun count:getvisibilitystate ( obj / name value prop )
    (if (setq name (count:getvisibilityparametername obj))
        (foreach prop (count:getdynamicproperties obj)
            (if (= (strcase name) (strcase (vla-get-propertyname prop)))
                (setq value
                    (count:variantstring (vlax-variant-value (vla-get-value prop)))))))
    value
)

;;----------------------------------------------------------------------;;

(defun count:getattributes ( obj / atts method result )
    (foreach method '(getattributes getconstantattributes)
        (setq atts (vl-catch-all-apply 'vlax-invoke (list obj method)))
        (if (not (vl-catch-all-error-p atts))
            (setq result (append atts result)))
    )
    result
)

(defun count:matchattribute ( obj spec / att found )
    (foreach att (count:getattributes obj)
        (if (and (count:wcmatch (vla-get-tagstring att) (car spec))
                 (count:wcmatch (vla-get-textstring att) (cadr spec)))
            (setq found t))
    )
    found
)

;;----------------------------------------------------------------------;;

(defun c:blkcountsettings

    (
        /
        *error*
        dch des
        ord out out-fun
        srt
        tg1 tg1-fun tg2 tg2-fun tg3 tg3-fun
    )

    (defun *error* ( msg )
        (if (= 'file (type des))
            (close des)
        )
        (if (and (= 'int (type dch))
                 (< 0 dch)
            )
            (unload_dialog dch)
        )
        (if (and (= 'vla-object (type count:wshobject))
                 (not (vlax-object-released-p count:wshobject))
            )
            (progn
                (vlax-release-object count:wshobject)
                (setq count:wshobject nil)
            )
        )
        (if (and msg (not (wcmatch (strcase msg t) "*break,*cancel*,*exit*")))
            (princ (strcat "\nError: " msg))
        )
        (princ)
    )

    (if (not (findfile count:cfgfname))
        (count:writecfg count:cfgfname (mapcar 'cadr count:defaults))
    )
    (count:readcfg count:cfgfname (mapcar 'car count:defaults))
    (foreach sym count:defaults
        (if (not (boundp (car sym))) (apply 'set sym))
    )
    (cond
        (   (not (count:writedcl count:dclfname))
            (count:popup "DCL file could not be written" 48
                (princ
                    (strcat
                        "The DCL file required by this program could not be written to the following location:\n\n"
                        count:dclfname
                        "\n\nPlease ensure that you have write-permissions for the above directory."
                    )
                )
            )
        )
        (   (<= (setq dch (load_dialog count:dclfname)) 0)
            (count:popup "DCL file could not be loaded" 48
                (princ
                    (strcat
                        "The following DCL file required by this program could not be loaded:\n\n"
                        count:dclfname
                        "\n\nPlease verify the integrity of this file."
                    )
                )
            )
        )
        (   (not (new_dialog "dia" dch))
            (count:popup "DCL file contains an error" 48
                (princ
                    (strcat
                        "The program dialog could not be displayed as the following DCL file file contains an error:\n\n"
                        count:dclfname
                        "\n\nPlease verify the integrity of this file."
                    )
                )
            )
        )
        (   t
            (set_tile "dcl"
                (strcat
                    "Count.lsp Version "
                    (vl-string-translate "-" "." count:version)
                    " \\U+00A9 Lee Mac "
                    (menucmd "m=$(edtime,0,yyyy)")
                )
            )
            (if (and (= "tab" out) (not (vlax-method-applicable-p (vla-get-modelspace (count:acdoc)) 'addtable)))
                (progn
                    (mode_tile "tab" 1)
                    (setq out "txt")
                )
            )
            (   (setq tg1-fun (lambda ( val ) (mode_tile "ed1" (- 1 (atoi (setq tg1 val)))))) (set_tile "tg1" tg1))
            (action_tile "tg1" "(tg1-fun $value)")

            (   (setq tg2-fun (lambda ( val ) (mode_tile "ed2" (- 1 (atoi (setq tg2 val)))))) (set_tile "tg2" tg2))
            (action_tile "tg2" "(tg2-fun $value)")

            (   (setq tg3-fun (lambda ( val ) (mode_tile "ed4" (- 1 (atoi (setq tg3 val)))))) (set_tile "tg3" tg3))
            (action_tile "tg3" "(tg3-fun $value)")

            (foreach key '("ed1" "ed2" "ed3" "ed4")
                (set_tile key (eval (read key)))
                (action_tile key (strcat "(setq " key " $value)"))
            )
            (set_tile out "1")
            (   (setq out-fun
                    (lambda ( val )
                        (if (= "tab" (setq out val))
                            (progn
                                (mode_tile "tg2" 0)
                                (mode_tile "ed2" (- 1 (atoi tg2)))
                            )
                            (progn
                                (mode_tile "tg2" 1)
                                (mode_tile "ed2" 1)
                            )
                        )
                    )
                )
                out
            )
            (foreach key '("tab" "txt" "csv" "com")
                (action_tile key "(out-fun $key)")
            )
            (set_tile srt "1")
            (foreach key '("blk" "qty")
                (action_tile key "(setq srt $key)")
            )
            (set_tile ord "1")
            (foreach key '("asc" "des")
                (action_tile key "(setq ord $key)")
            )
            (if (= 1 (start_dialog))
                (count:writecfg count:cfgfname (mapcar 'eval (mapcar 'car count:defaults)))
            )
        )
    )
    (*error* nil)
    (princ)
)

;;----------------------------------------------------------------------;;
                
(defun count:popup ( ttl flg msg / err )
    (setq err (vl-catch-all-apply 'vlax-invoke-method (list (count:wsh) 'popup msg 0 ttl flg)))
    (if (null (vl-catch-all-error-p err))
        err
    )
)
 
;;----------------------------------------------------------------------;;
 
(defun count:wsh nil
    (cond (count:wshobject) ((setq count:wshobject (vlax-create-object "wscript.shell"))))
)

;;----------------------------------------------------------------------;;

(defun count:tostring ( arg / dim )
    (cond
        (   (= 'int (type arg))
            (itoa arg)
        )
        (   (= 'real (type arg))
            (setq dim (getvar 'dimzin))
            (setvar 'dimzin 8)
            (setq arg (rtos arg 2 15))
            (setvar 'dimzin dim)
            arg
        )
        (   (vl-prin1-to-string arg))
    )
)
 
;;----------------------------------------------------------------------;;
 
(defun count:writecfg ( cfg lst / des )
    (if (setq des (open cfg "w"))
        (progn
            (foreach itm lst (write-line (count:tostring itm) des))
            (setq des (close des))
            t
        )
    )
)

;;----------------------------------------------------------------------;;

(defun count:readcfg ( cfg lst / des itm )
    (if
        (and
            (setq cfg (findfile cfg))
            (setq des (open cfg "r"))
        )
        (progn
            (foreach sym lst
                (if (setq itm (read-line des))
                    (set  sym (read itm))
                )
            )
            (setq des (close des))
            t
        )
    )
)

;;----------------------------------------------------------------------;;

(defun count:writedcl ( dcl / des )
    (cond
        (   (findfile dcl))
        (   (setq des (open dcl "w"))
            (foreach itm
               '(
                    "//--------------------=={ Count Dialog Definition }==-------------------//"
                    "//                                                                      //"
                    "//  Dialog definition file for use in conjunction with Count.lsp        //"
                    "//----------------------------------------------------------------------//"
                    "//  Author:  Lee Mac, Copyright � 2014  -  www.lee-mac.com              //"
                    "//----------------------------------------------------------------------//"
                    ""
                    "b15 : edit_box"
                    "{"
                    "    edit_width = 16;"
                    "    edit_limit = 1024;"
                    "    fixed_width = true;"
                    "    alignment = centered;"
                    "    horizontal_margin = none;"
                    "    vertical_margin = none;"
                    "}"
                    "b30 : edit_box"
                    "{"
                    "    edit_width = 52;"
                    "    edit_limit = 1024;"
                    "    fixed_width = true;"
                    "    alignment = centered;"
                    "    horizontal_margin = none;"
                    "    vertical_margin = none;"
                    "}"
                    "tog : toggle"
                    "{"
                    "    vertical_margin = none;"
                    "    horizontal_margin = 0.2;"
                    "}"
                    "rwo : row"
                    "{"
                    "    fixed_width = true;"
                    "    alignment = centered;"
                    "}"
                    "rrw : radio_row"
                    "{"
                    "    fixed_width = true;"
                    "    alignment = centered;"
                    "}"
                    "dia : dialog"
                    "{"
                    "    key = \"dcl\";"
                    "    spacer_1;"
                    "    : boxed_column"
                    "    {"
                    "        label = \"Output\";"
                    "        : rrw"
                    "        {"
                    "            : radio_button { key = \"tab\"; label = \"Table\"; }"
                    "            : radio_button { key = \"txt\"; label = \"Text File\"; }"
                    "            : radio_button { key = \"csv\"; label = \"CSV File\"; }"
                    "            : radio_button { key = \"com\"; label = \"Command line\"; }"
                    "        }"
                    "        spacer;"
                    "    }"
                    "    : boxed_column"
                    "    {"
                    "        label = \"Headings\";"
                    "        spacer_1;"
                    "        : rwo"
                    "        {"
                    "            : tog { key = \"tg1\"; }"
                    "            : b30 { key = \"ed1\"; }"
                    "            : spacer"
                    "            {"
                    "                fixed_width = true;"
                    "                vertical_margin = none;"
                    "                width = 2.5;"
                    "            }"
                    "        }"
                    "        : rwo"
                    "        {"
                    "            spacer;"
                    "            : tog { key = \"tg2\"; }"
                    "            : b15 { key = \"ed2\"; }"
                    "            : b15 { key = \"ed3\"; }"
                    "            : b15 { key = \"ed4\"; }"
                    "            : tog { key = \"tg3\"; }"
                    "            spacer;"
                    "        }"
                    "        spacer_1;"
                    "    }"
                    "    : row"
                    "    {"
                    "        : boxed_column"
                    "        {"
                    "            label = \"Sort By\";"
                    "            : rrw"
                    "            {"
                    "                : radio_button { key = \"blk\"; label = \"Block Name\"; }"
                    "                : radio_button { key = \"qty\"; label = \"Quantity\"; }"
                    "            }"
                    "            spacer;"
                    "        }"
                    "        : boxed_column"
                    "        {"
                    "            label = \"Sort Order\";"
                    "            : rrw"
                    "            {"
                    "                : radio_button { key = \"asc\"; label = \"Ascending\"; }"
                    "                : radio_button { key = \"des\"; label = \"Descending\"; }"
                    "            }"
                    "            spacer;"
                    "        }"
                    "    }"
                    "    spacer_1; ok_cancel;"
                    "}"
                    ""
                    "//----------------------------------------------------------------------//"
                    "//                             End of File                              //"
                    "//----------------------------------------------------------------------//"
                )
                (write-line itm des)
            )
            (setq des (close des))
            (while (not (findfile dcl))) ;; for slow HDDs
            dcl
        )
    )
)

;;----------------------------------------------------------------------;;
 
(defun count:writecsv ( lst csv / des sep )
    (if (setq des (open csv "w"))
        (progn
            (setq sep (cond ((vl-registry-read "HKEY_CURRENT_USER\\Control Panel\\International" "sList")) (",")))
            (foreach row lst (write-line (count:lst->csv row sep) des))
            (close des)
            t
        )
    )
)
 
;;----------------------------------------------------------------------;;
 
(defun count:lst->csv ( lst sep )
    (if (cdr lst)
        (strcat (count:csv-addquotes (car lst) sep) sep (count:lst->csv (cdr lst) sep))
        (count:csv-addquotes (car lst) sep)
    )
)

;;----------------------------------------------------------------------;;
 
(defun count:csv-addquotes ( str sep / pos )
    (cond
        (   (wcmatch str (strcat "*[`" sep "\"]*"))
            (setq pos 0)    
            (while (setq pos (vl-string-position 34 str pos))
                (setq str (vl-string-subst "\"\"" "\"" str pos)
                      pos (+ pos 2)
                )
            )
            (strcat "\"" str "\"")
        )
        (   str   )
    )
)
 
;;----------------------------------------------------------------------;;
 
(defun count:writetxt ( lst txt / des )
    (if (setq des (open txt "w"))
        (progn
            (foreach itm lst (write-line (count:lst->str itm "\t") des))
            (close des)
            t
        )
    )
)
 
;;----------------------------------------------------------------------;;
 
(defun count:lst->str ( lst del )
    (if (cdr lst)
        (strcat (car lst) del (count:lst->str (cdr lst) del))
        (car lst)
    )
)

;;----------------------------------------------------------------------;;

(defun count:padbetween ( s1 s2 ch ln )
    (
        (lambda ( a b c )
            (repeat (- ln (length b) (length c)) (setq c (cons a c)))
            (vl-list->string (append b c))
        )
        (ascii ch)
        (vl-string->list s1)
        (vl-string->list s2)
    )
)

;;----------------------------------------------------------------------;;

(defun count:setblocktablerecord ( obj row col blk )
    (eval
        (list 'defun 'count:setblocktablerecord '( obj row col blk )
            (cons
                (if (vlax-method-applicable-p obj 'setblocktablerecordid32)
                    'vla-setblocktablerecordid32
                    'vla-setblocktablerecordid
                )
                (list
                    'obj 'row 'col
                    (list 'count:objectid (list 'vla-item (vla-get-blocks (count:acdoc)) 'blk))
                    ':vlax-true
                )
            )
        )
    )
    (count:setblocktablerecord obj row col blk)
)

;;----------------------------------------------------------------------;;

(defun count:objectid ( obj )
    (eval
        (list 'defun 'count:objectid '( obj )
            (cond
                (   (not (wcmatch (getenv "PROCESSOR_ARCHITECTURE") "*64*"))
                   '(vla-get-objectid obj)
                )
                (   (= 'subr (type vla-get-objectid32))
                   '(vla-get-objectid32 obj)
                )
                (   (list 'vla-getobjectidstring (vla-get-utility (count:acdoc)) 'obj ':vlax-false))
            )
        )
    )
    (count:objectid obj)
)

;;----------------------------------------------------------------------;;

(defun count:assoc++ ( key lst / itm )
    (if (setq itm (assoc key lst))
        (subst (cons key (1+ (cdr itm))) itm lst)
        (cons  (cons key 1) lst)
    )
)

;;----------------------------------------------------------------------;;

(defun count:effectivename ( ent / blk rep )
    (if (wcmatch (setq blk (cdr (assoc 2 (entget ent)))) "`**")
        (if
            (and
                (setq rep
                    (cdadr
                        (assoc -3
                            (entget
                                (cdr
                                    (assoc 330
                                        (entget
                                            (tblobjname "block" blk)
                                        )
                                    )
                                )
                               '("AcDbBlockRepBTag")
                            )
                        )
                    )
                )
                (setq rep (handent (cdr (assoc 1005 rep))))
            )
            (setq blk (cdr (assoc 2 (entget rep))))
        )
    )
    blk
)

;;----------------------------------------------------------------------;;

(defun count:startundo ( doc )
    (count:endundo doc)
    (vla-startundomark doc)
)

;;----------------------------------------------------------------------;;

(defun count:endundo ( doc )
    (while (= 8 (logand 8 (getvar 'undoctl)))
        (vla-endundomark doc)
    )
)

;;----------------------------------------------------------------------;;

(defun count:acdoc nil
    (eval (list 'defun 'count:acdoc 'nil (vla-get-activedocument (vlax-get-acad-object))))
    (count:acdoc)
)

;;----------------------------------------------------------------------;;

(vl-load-com)
(princ
    (strcat
        "\n:: Count.lsp | Version "
        (vl-string-translate "-" "." count:version)
        " | \\U+00A9 Lee Mac "
        (menucmd "m=$(edtime,0,yyyy)")
        " www.lee-mac.com ::"
        "\n:: \"TA:blk-count\" - Filtered Count | \"blkcount\" - Original Count ::"
        "\n:: \"blkcountsettings\" - Output Settings ::"
    )
)
(princ)

;;----------------------------------------------------------------------;;
;;                             End of File                              ;;
;;----------------------------------------------------------------------;;
