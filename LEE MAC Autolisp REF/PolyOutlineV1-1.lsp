;; Polyline Outline
;; Example Calling Functions (these may be customised to suit your requirements):

;; Single Selection

(defun c:PolyOutline ( / e s )
    (if (setq e (ssget "_+.:E:S:L" '((0 . "LWPOLYLINE") (-4 . "<NOT") (-4 . "<>") (42 . 0.0) (-4 . "NOT>"))))
        (progn
            (LM:PolyOutline (setq e (ssname e 0)))
            (initget "Yes No")
            (if (/= "No" (getkword "\nDelete Original? [Yes/No] <Yes>: ")) (entdel e))
        )
    )
    (princ)
)

;; Multiple Selection

(defun c:mPolyOutline ( / d i s )
    (if (setq s (ssget "_:L" '((0 . "LWPOLYLINE") (-4 . "<NOT") (-4 . "<>") (42 . 0.0) (-4 . "NOT>"))))
        (progn
            (initget "Yes No")
            (setq d (/= "No" (getkword "\nDelete Original? [Yes/No] <Yes>: ")))
            (repaeat (setq i (sslength s))
                (LM:PolyOutline (setq e (ssname s (setq i (1- i)))))
                (if d (entdel e))
            )
        )
    )
    (princ)
)
(defun c:mREVCOutline ( / d i s ) ;TA EDIT
    ;presetting
      (setq arclength 1)
    ;
    (if (setq s_ (ssget "_:L" '((0 . "LWPOLYLINE") (-4 . "<NOT") (-4 . "<>") (42 . 0.0) (-4 . "NOT>"))))
        (progn
            ; (initget "Yes No")
            ; (setq d (/= "No" (getkword "\nDelete Original? [Yes/No] <Yes>: ")))
            ;preloop_and_while
              (setq s_i 0)
              (while (< s_i (sslength s_))
                
                
                (setq e_obj_ (vlax-ename->vla-object (ssname s_ s_i)))
                (vla-put-constantwidth e_obj_ 2)
                ( LM:PolyOutline (ssname s_ s_i))
                (vla-put-layer e_obj_ "000 - SYMBOL CON_COMMENT_ASBUILT_WALL_DEF_SUB")
                (vla-put-color e_obj_ 256)
                (vla-put-constantwidth e_obj_ 0)
                ;new_blk_entlast object
                  (setq new_polyline_ename (entlast)) 
                  (command "revcloud" "a" arclength arclength "O" new_polyline_ename "" )
                  (setq new_polyline_ename (entlast))
                  (vlax-ename->vla-object new_polyline_ename)
                  (vla-put-layer (vlax-ename->vla-object new_polyline_ename) "000 - SYMBOL CON_COMMENT_ASBUILT_WALL_MAIN_COLOR_1")
                  (vla-put-color (vlax-ename->vla-object new_polyline_ename) 256)
                    

                ;
                (setq s_i (+ s_i 1))
              )
            ;
        )
    )
    (princ)
)

;;------------------=={ LWPolyline Outline }==----------------;;
;;                                                            ;;
;;  Creates an LWPolyline surrounding the boundary of an      ;;
;;  LWPolyline with varying widths. Currently restricted to   ;;
;;  LWPolyline vertices with zero bulge.                      ;;
;;------------------------------------------------------------;;
;;  Author: Lee Mac, Copyright © 2011 - www.lee-mac.com       ;;
;;------------------------------------------------------------;;
;;  Arguments:                                                ;;
;;  ent - Entity name of LWPolyline                           ;;
;;------------------------------------------------------------;;
;;  Returns:  List of Entity name(s) of outline LWPolyline(s) ;;
;;------------------------------------------------------------;;

(defun LM:PolyOutline ( ent / _vertices lst )

    (defun _vertices ( e )
        (if (setq e (member (assoc 10 e) e))
            (cons
                (list
                    (cdr (assoc 10 e))
                    (cdr (assoc 40 e))
                    (cdr (assoc 41 e))
                )
                (_vertices (cdr e))
            )
        )
    )

    (setq
        ent (entget ent)
        lst (_vertices ent)
        lst (apply 'mapcar
                (cons
                    (function
                        (lambda ( a b )
                            (
                                (lambda ( c )
                                    (mapcar
                                        (function
                                            (lambda ( d )
                                                (mapcar
                                                    (function
                                                        (lambda ( e f )
                                                            (mapcar 'd (car e)
                                                                (mapcar
                                                                    (function
                                                                        (lambda ( g ) (* g (/ f 2.0)))
                                                                    )
                                                                    c
                                                                )
                                                            )
                                                        )
                                                    )
                                                    (list a b) (cdr a)
                                                )
                                            )
                                        )
                                        (list + -)
                                    )
                                )
                                (
                                    (lambda ( v / n )
                                        (setq v (list (- (cadr v)) (car v) 0.0)
                                              n (distance '(0. 0.) v)
                                        )
                                        (if (equal 0.0 n 1e-14)
                                            (list  0.0 0.0 0.0)
                                            (mapcar '/ v (list n n n))
                                        )
                                    )
                                    (mapcar '- (car a) (car b))
                                )
                            )
                        )
                    )
                    (if (= 1 (logand 1 (cdr (assoc 70 ent))))
                        (list
                            (cons (last lst) lst)
                            (append lst (list (car lst)))
                        )
                        (list lst (cdr lst))
                    )
                )
            )
        lst (
                (lambda ( a )
                    (if (zerop (logand 1 (cdr (assoc 70 ent))))
                        (append
                            (list (mapcar 'car  (car  lst)))
                            a
                            (list (mapcar 'cadr (last lst)))
                        )
                        a
                    )
                )
                (apply 'append
                    (mapcar
                        (function
                            (lambda ( a b / c )
                                (if
                                    (setq c
                                        (apply 'append
                                            (mapcar
                                                (function
                                                    (lambda ( d e / f )
                                                        (if (setq f (inters (car d) (cadr d) (car e) (cadr e) nil))
                                                            (list f)
                                                        )
                                                    )
                                                )
                                                a b
                                            )
                                        )
                                    )
                                    (list c)
                                )
                            )
                        )
                        lst (cdr lst)
                    )
                )
            )
    )
    (mapcar
        (function
            (lambda ( a )
                (entmakex
                    (append
                        (subst (cons 43 0.0) (assoc 43 ent)
                            (subst (cons 70 (logior 1 (cdr (assoc 70 ent)))) (assoc 70 ent)
                                (subst (cons 90 (length a)) (assoc 90 ent)
                                    (reverse (member (assoc 39 ent) (reverse ent)))
                                )
                            )
                        )
                        (mapcar '(lambda ( p ) (cons 10 p)) a) (list (assoc 210 ent))
                    )
                )
            )
        )
        (
            (lambda ( a b )
                (if (zerop (logand 1 (cdr (assoc 70 ent))))
                    (list
                        (append
                            (if (equal (car a) (last b) 1e-8)
                                (setq a (cdr a))
                                a
                            )
                            (if (equal (car b) (last a) 1e-8)
                                (setq b (cdr b))
                                b
                            )
                        )
                    )
                    (list a b)
                )
            )
            (mapcar 'car lst) (reverse (mapcar 'cadr lst))
        )
    )
)

(princ)

(defun C:Make_polyline_MKPLoutline_PLDEP ( / )
    (_startundo doc)
    ;selection_set_for_fillter_blk_name
      (if  ;pre_select_ssget_or_post_select_ssget
        (=
          (setq ss_pre_filter_set_xx_ (ssget "i"
                                            (list
                                              (cons 0 "LWPOLYLINE") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
          nil
        )
        (progn
          (setq ss_pre_filter_set_xx_ (ssget
                                            (list
                                              (cons 0 "LWPOLYLINE") ;type of object
                                              ; (cons 8 "000 - GRID")   ;kind of layer
                                              ; (cons 2 "000-GRID_LINE_DYN")       ;kind of nameblock
                                              ; (cons 62 1)           ;kind of color call sign with color code index
                                            )
                                      )
          )
        )
        (sslength ss_pre_filter_set_xx_)
      )
    ;
    (setq distance_depth (cond ( (getreal (strcat "\nspecify distance_depth <" (rtos (setq distance_depth (cond (distance_depth) (10) ) ) ) "> : " ) ) ) (distance_depth) ) )
    (initget "Yes No")
    (setq d (/= "No" (getkword "\nDelete Original? [Yes/No] <Yes>: ")))
    ;preloop_and_while
      (setq ss_pre_filter_set_xx_i 0)
      (while (< ss_pre_filter_set_xx_i (sslength ss_pre_filter_set_xx_))
        (setq ss_pre_filter_set_xx_ename_ (ssname ss_pre_filter_set_xx_ ss_pre_filter_set_xx_i))
        (setq ss_pre_filter_set_xx_obj_ (vlax-ename->vla-object  ss_pre_filter_set_xx_ename_))
        (setq ss_pre_filter_set_xx_obj_layer_ (vla-get-layer  ss_pre_filter_set_xx_obj_))
        (if ( = (vla-get-objectname ss_pre_filter_set_xx_obj_) "AcDbPolyline" )
          (progn
            (vla-put-constantwidth ss_pre_filter_set_xx_obj_ distance_depth)
            (LM:PolyOutline ss_pre_filter_set_xx_ename_)
            ;new_blk_entlast object
              (setq new_PL_ename (entlast))
              (setq new_PL_obj (vlax-ename->vla-object new_PL_ename))
              (vla-put-layer new_PL_obj ss_pre_filter_set_xx_obj_layer_)
              (vla-put-color new_PL_obj 256)
            ;
            
            (if (= d T)
              (progn
                (entdel ss_pre_filter_set_xx_ename_)
              )
              (vla-put-constantwidth ss_pre_filter_set_xx_obj_ 0)
            )
          )
        )
        (setq ss_pre_filter_set_xx_i (+ ss_pre_filter_set_xx_i 1))
      )
    ;
    (_endUndo doc)
)
