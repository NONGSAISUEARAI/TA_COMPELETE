;Dynamic Funcion
  ;; Get Dynamic Block Property Value  -  Lee Mac
    ;; Returns the value of a Dynamic Block property (if present)
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; prp - [str] Dynamic Block property name (case-insensitive)

    (defun LM:getdynpropvalue ( blk prp )
        (setq prp (strcase prp))
        (vl-some '(lambda ( x ) (if (= prp (strcase (vla-get-propertyname x))) (vlax-get x 'value)))
            (vlax-invoke blk 'getdynamicblockproperties)
        )
    )
  ;; Set Dynamic Block Property Value  -  Lee Mac
    ;; Modifies the value of a Dynamic Block property (if present)
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; prp - [str] Dynamic Block property name (case-insensitive)
    ;; val - [any] New value for property
    ;; Returns: [any] New value if successful, else nil

    (defun LM:setdynpropvalue ( blk prp val )
        (setq prp (strcase prp))
        (vl-some
          '(lambda ( x )
                (if (= prp (strcase (vla-get-propertyname x)))
                    (progn
                        (vla-put-value x (vlax-make-variant val (vlax-variant-type (vla-get-value x))))
                        (cond (val) (t))
                    )
                )
            )
            (vlax-invoke blk 'getdynamicblockproperties)
        )
    )
  ;; Get Dynamic Block Properties  -  Lee Mac
    ;; Returns an association list of Dynamic Block properties & values.
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; Returns: [lst] Association list of ((<prop> . <value>) ... )

    (defun LM:getdynprops ( blk )
        (mapcar '(lambda ( x ) (cons (vla-get-propertyname x) (vlax-get x 'value)))
            (vlax-invoke blk 'getdynamicblockproperties)
        )
    )
  ;; Set Dynamic Block Properties  -  Lee Mac
    ;; Modifies values of Dynamic Block properties using a supplied association list.
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; lst - [lst] Association list of ((<Property> . <Value>) ... )
    ;; Returns: nil

    (defun LM:setdynprops ( blk lst / itm )
        (setq lst (mapcar '(lambda ( x ) (cons (strcase (car x)) (cdr x))) lst))
        (foreach x (vlax-invoke blk 'getdynamicblockproperties)
            (if (setq itm (assoc (strcase (vla-get-propertyname x)) lst))
                (vla-put-value x (vlax-make-variant (cdr itm) (vlax-variant-type (vla-get-value x))))
            )
        )
    )
  ;; Get Dynamic Block Property Allowed Values  -  Lee Mac
    ;; Returns the allowed values for a specific Dynamic Block property.
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; prp - [str] Dynamic Block property name (case-insensitive)
    ;; Returns: [lst] List of allowed values for property, else nil if no restrictions

    (defun LM:getdynpropallowedvalues ( blk prp )
        (setq prp (strcase prp))
        (vl-some '(lambda ( x ) (if (= prp (strcase (vla-get-propertyname x))) (vlax-get x 'allowedvalues)))
            (vlax-invoke blk 'getdynamicblockproperties)
        )
    )
  ;; Toggle Dynamic Block Flip State  -  Lee Mac
    ;; Toggles the Flip parameter if present in a supplied Dynamic Block.
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; Return: [int] New Flip Parameter value

    (defun LM:toggleflipstate ( blk )
        (vl-some
          '(lambda ( prp / rtn )
                (if (equal '(0 1) (vlax-get prp 'allowedvalues))
                    (progn
                        (vla-put-value prp (vlax-make-variant (setq rtn (- 1 (vlax-get prp 'value))) vlax-vbinteger))
                        rtn
                    )
                )
            )
            (vlax-invoke blk 'getdynamicblockproperties)
        )
    )
  ;; Get Visibility Parameter Name  -  Lee Mac
    ;; Returns the name of the Visibility Parameter of a Dynamic Block (if present)
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; Returns: [str] Name of Visibility Parameter, else nil

    (defun LM:getvisibilityparametername ( blk / vis )  
        (if
            (and
                (vlax-property-available-p blk 'effectivename)
                (setq blk
                    (vla-item
                        (vla-get-blocks (vla-get-document blk))
                        (vla-get-effectivename blk)
                    )
                )
                (= :vlax-true (vla-get-isdynamicblock blk))
                (= :vlax-true (vla-get-hasextensiondictionary blk))
                (setq vis
                    (vl-some
                      '(lambda ( pair )
                            (if
                                (and
                                    (= 360 (car pair))
                                    (= "BLOCKVISIBILITYPARAMETER" (cdr (assoc 0 (entget (cdr pair)))))
                                )
                                (cdr pair)
                            )
                        )
                        (dictsearch
                            (vlax-vla-object->ename (vla-getextensiondictionary blk))
                            "ACAD_ENHANCEDBLOCK"
                        )
                    )
                )
            )
            (cdr (assoc 301 (entget vis)))
        )
    )
  ;; Get Dynamic Block Visibility State  -  Lee Mac
    ;; Returns the value of the Visibility Parameter of a Dynamic Block (if present)
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; Returns: [str] Value of Visibility Parameter, else nil

    (defun LM:getvisibilitystate ( blk / vis )
        (if (setq vis (LM:getvisibilityparametername blk))
            (LM:getdynpropvalue blk vis)
        )
    )
  ;; Set Dynamic Block Visibility State  -  Lee Mac
    ;; Sets the Visibility Parameter of a Dynamic Block (if present) to a specific value (if allowed)
    ;; blk - [vla] VLA Dynamic Block Reference object
    ;; val - [str] Visibility State Parameter value
    ;; Returns: [str] New value of Visibility Parameter, else nil

    (defun LM:SetVisibilityState ( blk val / vis )
        (if
            (and
                (setq vis (LM:getvisibilityparametername blk))
                (member (strcase val) (mapcar 'strcase (LM:getdynpropallowedvalues blk vis)))
            )
            (LM:setdynpropvalue blk vis val)
        )
    )
;
;Effective Block Name Funcition
  ;; Effective Block Name  -  Lee Mac
    ;; obj - [vla] VLA Block Reference object
        (defun LM:effectivename ( obj )
            (vlax-get-property obj
                (if (vlax-property-available-p obj 'effectivename)
                    'effectivename
                    'name
                )
            )
        )
  ;; Effective Block Name  -  Lee Mac
    ;; ent - [ent] Block Reference entity

    (defun LM:al-effectivename ( ent / blk rep )
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
;
;Attribute Function
  ;; Get Attribute Value  -  Lee Mac
    ;; Returns the value held by the specified tag within the supplied block, if present.
    ;; blk - [vla] VLA Block Reference Object
    ;; tag - [str] Attribute TagString
    ;; Returns: [str] Attribute value, else nil if tag is not found.

    (defun LM:vl-getattributevalue ( blk tag )
        (setq tag (strcase tag))
        (vl-some '(lambda ( att ) (if (= tag (strcase (vla-get-tagstring att))) (vla-get-textstring att))) (vlax-invoke blk 'getattributes))
    )
  ;; Set Attribute Value  -  Lee Mac
    ;; Sets the value of the first attribute with the given tag found within the block, if present.
    ;; blk - [vla] VLA Block Reference Object
    ;; tag - [str] Attribute TagString
    ;; val - [str] Attribute Value
    ;; Returns: [str] Attribute value if successful, else nil.

    (defun LM:vl-setattributevalue ( blk tag val )
        (setq tag (strcase tag))
        (vl-some
          '(lambda ( att )
                (if (= tag (strcase (vla-get-tagstring att)))
                    (progn (vla-put-textstring att val) val)
                )
            )
            (vlax-invoke blk 'getattributes)
        )
    )
  ;; Get Attribute Values  -  Lee Mac
    ;; Returns an association list of attributes present in the supplied block.
    ;; blk - [vla] VLA Block Reference Object
    ;; Returns: [lst] Association list of ((<tag> . <value>) ... )

    (defun LM:vl-getattributevalues ( blk )
        (mapcar '(lambda ( att ) (cons (vla-get-tagstring att) (vla-get-textstring att))) (vlax-invoke blk 'getattributes))
    )
  ;; Set Attribute Values  -  Lee Mac
    ;; Sets attributes with tags found in the association list to their associated values.
    ;; blk - [vla] VLA Block Reference Object
    ;; lst - [lst] Association list of ((<tag> . <value>) ... )
    ;; Returns: nil

    (defun LM:vl-setattributevalues ( blk lst / itm )
        (foreach att (vlax-invoke blk 'getattributes)
            (if (setq itm (assoc (vla-get-tagstring att) lst))
                (vla-put-textstring att (cdr itm))
            )
        )
    )
;

;Filter INSERT selection set by empty PANEL_COLOR attribute
;Reference sub-function: LM:vl-getattributevalue by Lee Mac
;Input  : selection_set_ [pickset]
;Return : new selection set containing INSERT objects whose
;         PANEL_COLOR attribute exists and is empty
  (defun TA:Filter_ss_empty_panel_color_
         (selection_set_
          /
          new_ss_
          selection_set_i_
          selection_set_ename_
          selection_set_obj_
          panel_color_value_
         )

    (vl-load-com)
    (setq new_ss_ (ssadd))

    (if selection_set_
      (progn
        (setq selection_set_i_ 0)

        (while (< selection_set_i_ (sslength selection_set_))
          (setq selection_set_ename_
                 (ssname selection_set_ selection_set_i_)
          )

          (if (= "INSERT"
                 (cdr (assoc 0 (entget selection_set_ename_)))
              )
            (progn
              (setq selection_set_obj_
                     (vlax-ename->vla-object selection_set_ename_)
              )

              (if (= :vlax-true
                     (vla-get-HasAttributes selection_set_obj_)
                  )
                (progn
                  (setq panel_color_value_
                         (LM:vl-getattributevalue
                           selection_set_obj_
                           "PANEL_COLOR"
                         )
                  )

                  ;nil means the PANEL_COLOR tag was not found.
                  ;Only an existing tag with an empty value is accepted.
                  (if (and (= 'STR (type panel_color_value_))
                           (= ""
                              (vl-string-trim
                                " \t\r\n"
                                panel_color_value_
                              )
                           )
                      )
                    (ssadd selection_set_ename_ new_ss_)
                  )
                )
              )
            )
          )

          (setq selection_set_i_ (1+ selection_set_i_))
        )
      )
    )

    new_ss_
  )


;Command: select INSERT objects and keep blocks whose PANEL_COLOR is empty
  (defun c:TA_PANEL_COLOR_EMPTY
         (/
          ss_pre_filter_set_xx_
          new_ss_
         )

    (vl-load-com)

    ;Use PICKFIRST selection first, otherwise prompt for a new selection.
    (if (not
          (setq ss_pre_filter_set_xx_
                 (ssget "_I" '((0 . "INSERT")))
          )
        )
      (setq ss_pre_filter_set_xx_
             (ssget '((0 . "INSERT")))
      )
    )

    (if ss_pre_filter_set_xx_
      (progn
        (setq new_ss_
               (TA:Filter_ss_empty_panel_color_
                 ss_pre_filter_set_xx_
               )
        )

        (if (> (sslength new_ss_) 0)
          (progn
            (sssetfirst nil new_ss_)
            (prompt
              (strcat
                "\nFound "
                (itoa (sslength new_ss_))
                " INSERT object(s) with empty PANEL_COLOR."
              )
            )
          )
          (prompt
            "\nNo INSERT object with an empty PANEL_COLOR was found."
          )
        )
      )
      (prompt "\nNo INSERT object was selected.")
    )

    (princ)
  )


;Run PANEL_NO attribute using PREFIX_SEQUENCE format
;Reference sub-function: LM:vl-setattributevalue by Lee Mac
;Input  : selection_set_ [pickset], prefix_ [str], start_number_ [int]
;Return : number of PANEL_NO attributes updated
  (defun TA:Run_panel_no_
         (selection_set_
          prefix_
          start_number_
          /
          selection_set_i_
          selection_set_ename_
          selection_set_obj_
          panel_no_value_
          updated_count_
         )

    (vl-load-com)
    (setq selection_set_i_ 0
          updated_count_   0
    )

    (if selection_set_
      (while (< selection_set_i_ (sslength selection_set_))
        (setq selection_set_ename_
               (ssname selection_set_ selection_set_i_)
        )

        (if (= "INSERT"
               (cdr (assoc 0 (entget selection_set_ename_)))
            )
          (progn
            (setq selection_set_obj_
                   (vlax-ename->vla-object selection_set_ename_)
                  panel_no_value_
                   (strcat
                     prefix_
                     "_"
                     (itoa (+ start_number_ updated_count_))
                   )
            )

            ;The sequence advances only when PANEL_NO exists and is updated.
            (if (LM:vl-setattributevalue
                  selection_set_obj_
                  "PANEL_NO"
                  panel_no_value_
                )
              (setq updated_count_ (1+ updated_count_))
            )
          )
        )

        (setq selection_set_i_ (1+ selection_set_i_))
      )
    )

    updated_count_
  )


;Command: assign PREFIX_SEQUENCE values to PANEL_NO attributes
  (defun c:TA_RUN_PANEL_NO
         (/
          ss_pre_filter_set_xx_
          prefix_
          start_number_
          updated_count_
         )

    (vl-load-com)

    ;Prefix must not be empty.
    (while (= ""
              (setq prefix_
                     (getstring T "\nSpecify PANEL_NO prefix: ")
              )
           )
      (prompt "\nPrefix cannot be empty.")
    )

    ;Require a positive starting sequence number.
    (initget 6)
    (setq start_number_
           (getint "\nSpecify starting sequence number: ")
    )

    (if start_number_
      (progn
        ;Use PICKFIRST selection first, otherwise prompt for INSERT objects.
        (if (not
              (setq ss_pre_filter_set_xx_
                     (ssget "_I" '((0 . "INSERT")))
              )
            )
          (setq ss_pre_filter_set_xx_
                 (ssget '((0 . "INSERT")))
          )
        )

        (if ss_pre_filter_set_xx_
          (progn
            (setq updated_count_
                   (TA:Run_panel_no_
                     ss_pre_filter_set_xx_
                     prefix_
                     start_number_
                   )
            )

            (command "_.REGEN")

            (prompt
              (strcat
                "\nUpdated PANEL_NO on "
                (itoa updated_count_)
                " block(s)."
              )
            )
          )
          (prompt "\nNo INSERT object was selected.")
        )
      )
    )

    (princ)
  )


;Set PANEL_ZONE attribute for selected INSERT objects
;Reference sub-function: LM:vl-setattributevalue by Lee Mac
;Input  : selection_set_ [pickset], panel_zone_value_ [str]
;Return : number of PANEL_ZONE attributes updated
  (defun TA:Set_panel_zone_
         (selection_set_
          panel_zone_value_
          /
          selection_set_i_
          selection_set_ename_
          selection_set_obj_
          updated_count_
         )

    (vl-load-com)
    (setq selection_set_i_ 0
          updated_count_   0
    )

    (if selection_set_
      (while (< selection_set_i_ (sslength selection_set_))
        (setq selection_set_ename_
               (ssname selection_set_ selection_set_i_)
        )

        (if (= "INSERT"
               (cdr (assoc 0 (entget selection_set_ename_)))
            )
          (progn
            (setq selection_set_obj_
                   (vlax-ename->vla-object selection_set_ename_)
            )

            (if (LM:vl-setattributevalue
                  selection_set_obj_
                  "PANEL_ZONE"
                  panel_zone_value_
                )
              (setq updated_count_ (1+ updated_count_))
            )
          )
        )

        (setq selection_set_i_ (1+ selection_set_i_))
      )
    )

    updated_count_
  )


;Command: assign one PANEL_ZONE value to selected INSERT objects
  (defun c:TA_SET_PANEL_ZONE
         (/
          ss_pre_filter_set_xx_
          panel_zone_prefix_
          panel_zone_suffix_
          panel_zone_value_
          updated_count_
         )

    (vl-load-com)

    ;Format: PP{prefix}_ZONE_{suffix}
    ;Example: prefix = 18, suffix = 2 -> PP18_ZONE_2
    (while (= ""
              (setq panel_zone_prefix_
                     (getstring T "\nSpecify PANEL_ZONE prefix <PP{prefix}>: ")
              )
           )
      (prompt "\nPANEL_ZONE prefix cannot be empty.")
    )

    (while (= ""
              (setq panel_zone_suffix_
                     (getstring T "\nSpecify PANEL_ZONE suffix <ZONE_{suffix}>: ")
              )
           )
      (prompt "\nPANEL_ZONE suffix cannot be empty.")
    )

    (setq panel_zone_value_
           (strcat
             "PP"
             panel_zone_prefix_
             "_ZONE_"
             panel_zone_suffix_
           )
    )

    ;Use PICKFIRST selection first, otherwise prompt for INSERT objects.
    (if (not
          (setq ss_pre_filter_set_xx_
                 (ssget "_I" '((0 . "INSERT")))
          )
        )
      (setq ss_pre_filter_set_xx_
             (ssget '((0 . "INSERT")))
      )
    )

    (if ss_pre_filter_set_xx_
      (progn
        (setq updated_count_
               (TA:Set_panel_zone_
                 ss_pre_filter_set_xx_
                 panel_zone_value_
               )
        )

        (command "_.REGEN")

        (prompt
          (strcat
            "\nUpdated PANEL_ZONE on "
            (itoa updated_count_)
            " block(s)."
          )
        )
      )
      (prompt "\nNo INSERT object was selected.")
    )

    (princ)
  )
