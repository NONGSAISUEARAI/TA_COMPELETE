(defun Get-Drive-Hardware-Serial ( / locator service drives partitions logical letter serial model result)
  (vl-load-com)
  (setq result '()) 

  (setq locator (vlax-create-object "WbemScripting.SWbemLocator"))
  (setq service (vlax-invoke locator 'ConnectServer "." "root\\cimv2"))

  (setq drives (vlax-invoke service 'ExecQuery "SELECT * FROM Win32_DiskDrive"))

  ;; วนทุก drive
    (vlax-for dev drives
      (setq serial (vlax-get dev 'PNPDeviceID))
      (setq model  (vlax-get dev 'Model))

      ;; map partitions → logical disks (drive letters)
      (setq partitions
            (vlax-invoke service 'ExecQuery
              (strcat "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='"
                      (vlax-get dev 'DeviceID)
                      "'} WHERE AssocClass = Win32_DiskDriveToDiskPartition")))

      (vlax-for part partitions
        (setq logical
              (vlax-invoke service 'ExecQuery
                (strcat "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='"
                        (vlax-get part 'DeviceID)
                        "'} WHERE AssocClass = Win32_LogicalDiskToPartition")))
        (vlax-for ld logical
          (setq letter (vlax-get ld 'DeviceID))
          ;; เพิ่มข้อมูลลง list
          (setq result (cons (list model serial letter) result))
        )
      )
    )

  ;; ปล่อย COM objects
    (vlax-release-object service)
    (vlax-release-object locator)

  ;; คืนค่า list (กลับลำดับให้เหมือน query)
  (reverse result)
  
)
(defun TA:serial_number_finder ( all_target_drive_list_ drive_list_val_ )
  ;presetting
    ; (setq all_drive_list_ (Get-Drive-Hardware-Serial))
    ; (setq drive_list_val_ (list 
    ;                         (strcat "*" "8&17206EBA&0&000000" "*")
    ;                         (strcat "*" "4&11742CA2&0&070000" "*")
    ;                         (strcat "*" "5&1ED003EB&0&000000" "*")
    ;                       )
    ; )
  ;
  ;preloop_and_while
    (setq all_drive_list_i 0)
    (setq checker_ nil)
    (while (and 
             (= (type drive_list_val_) 'list)
             (= (type all_drive_list_) 'list)
             (< all_drive_list_i (length all_drive_list_))
             (= checker_ nil)
           )
      (setq all_drive_list_val_ (nth  all_drive_list_i all_drive_list_))
      (setq checker_ (TA:wcmatch_list drive_list_val_ all_drive_list_val_ T ))
      (setq all_drive_list_i (+ all_drive_list_i 1))
    )
  ;
  (if (/= checker_ nil)
    (progn
      T
    )
    nil
  )
)
(defun TA:wcmatch_list (filter_string_list_ list_data_ strcase_val)
  ;Note By Code_Developer
  ;This command is designed to work exclusively with a list name & array.
  ;The pripicle of the codework will read list name & array then filter target value that filter_string parameter indicate.
  ;Fully command must have sub-functions with names starting with TA: or LM:
  ;
  ;Example how argument work
    ; (setq filter_string_list_ (list 
    ;                             "*text_that _you_need*"
    ;                             "50"
    ;                             "45" 50 48 69
    ;                             "*re*"
    ;                             "*ai*"
    ;                           )
    ; )
    ; (setq list_data_ (list "50" "45" "A" "TRE" "TEXT" "ikwai na sonteen isud e heer" 48 55 69 50))
    ; (setq strcase_val nil)
  ;
  ;1st condition
  (cond
    ((= strcase_val nil)
      (progn
        (setq filter_string_list_ (mapcar 
                                    '(lambda (x) 
                                        (if 
                                          (and (= (type x) 'str) 
                                              (/= (atof x) 'real)
                                          ) 
                                          (progn 
                                            (strcase x T)
                                          ) 
                                          ""
                                        ;  (if (testexpr)
                                        ;   (progn
                                        ;     (thenexpr)
                                        ;   )
                                        ;  )
                                        )
                                      )
                                    filter_string_list_
                                  )
        )
        (setq list_data_ (mapcar 
                                    '(lambda (x) 
                                        (if 
                                          (and 
                                            (= (type x) 'str)
                                            (/= (atof x) 'real)
                                          ) 
                                          (progn 
                                            
                                            (strcase x T)
                                          ) 
                                          ""
                                        ;  (if (testexpr)
                                        ;   (progn
                                        ;     (thenexpr)
                                        ;   )
                                        ;  )
                                        )
                                      )
                                    list_data_
                                  )
        )
      )
    )
    ; ((= strcase_val T)
    ;   (progn
    ;     (setq filter_string_list_ (mapcar 
    ;                                 '(lambda (x) 
    ;                                    (if 
    ;                                      (and (= (type x) 'str) 
    ;                                           (/= (atof x) 'real)
    ;                                      ) 
    ;                                      (progn 
    ;                                        (strcase x T)
    ;                                      ) 
    ;                                      ""
    ;                                     ;  (if (testexpr)
    ;                                     ;   (progn
    ;                                     ;     (thenexpr)
    ;                                     ;   )
    ;                                     ;  )
    ;                                    )
    ;                                  )
    ;                                 filter_string_list_
    ;                               )
    ;     )
    ;     (setq list_data_ (mapcar 
    ;                                 '(lambda (x) 
    ;                                    (if 
    ;                                      (and  
    ;                                           (/= (atof x) 'real)
    ;                                      ) 
    ;                                      (progn 
    ;                                        (strcase x T)
    ;                                      ) 
    ;                                      ""
    ;                                     ;  (if (testexpr)
    ;                                     ;   (progn
    ;                                     ;     (thenexpr)
    ;                                     ;   )
    ;                                     ;  )
    ;                                    )
    ;                                  )
    ;                                 list_data_
    ;                               )
    ;     )
    ;   )
    ; )
  )
  (setq filter_result_ (vl-remove-if-not 
                        '(lambda (x) 
                            (apply 'or 
                                    (mapcar 
                                      '(lambda (p) (wcmatch x p))
                                      filter_string_list_
                                    )
                            )
                          )
                        list_data_
                      )
  )
  (setq filter_result_ (reverse filter_result_))
  ;
)
(TA:serial_number_finder 
  (Get-Drive-Hardware-Serial)
  (list 
    (strcat "*" "5&1ED003EB&0&000000" "*")
    (strcat "*" "AAasdasdAAAAAAA" "*")
    (strcat "*" "asadasdasdadasda" "*")
  )
)