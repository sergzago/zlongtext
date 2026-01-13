*&---------------------------------------------------------------------*
*& Report ZLONGTEXT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZLONGTEXT.

DATA:
  lt_text_lines TYPE STANDARD TABLE OF tline,
  ls_text_header TYPE thead,
  lt_text type c LENGTH 1000,
  lv_matnr type TDOBNAME,
  ls_ltext type zlongtexts,
  lv_lmatnr type i value 0,
  lv_lines type i value 0.

select t002~spras,t002t~sptxt from t002
  inner join t002t on t002t~SPRSL EQ t002~spras and t002t~spras eq 'R'
  where ( t002~spras GE '0' and t002~spras LE '9' ) or t002~spras in ('R','Z')
  into table @data(lt_t002).

select mara~matnr,makt~maktx from mara
  inner join makt on makt~matnr EQ mara~matnr and makt~spras EQ 'R'
  into table @data(lt_mara)
  "up to 1000 rows
  .

delete from zlongtexts.
if sy-subrc = 0.
  commit work.
else.
  rollback work.
endif.

loop at lt_mara ASSIGNING FIELD-SYMBOL(<ls_mara>).
 loop at lt_t002 assigning field-symbol(<ls_t002>).
  lv_matnr = |{ <ls_mara>-matnr }|.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      client   = sy-mandt
      id       = 'GRUN'          " Идентификатор текста (например, заголовок)
      language = <ls_t002>-spras " Язык текста
      name     = lv_matnr     " Номер объекта (например, заказа)
      object   = 'MATERIAL'          " Объект текста (например, заказ)
    IMPORTING
      header   = ls_text_header
    TABLES
      lines    = lt_text_lines
    EXCEPTIONS
      not_found = 4.
  if sy-subrc = 4.
    " WRITE: / |{ <ls_mara>-matnr } - нет длинного текста указаного языка |.
    CONTINUE.
  endif.
  if sy-subrc = 0.
    clear lt_text.
    " Вывод текста
    LOOP AT lt_text_lines ASSIGNING FIELD-SYMBOL(<fs_line>).
      lt_text = lt_text && | { <fs_line>-tdline }|.
    ENDLOOP.
    ls_ltext-mandt = sy-mandt.
    ls_ltext-matnr = <ls_mara>-matnr.
    ls_ltext-spras = <ls_t002>-spras.
    ls_ltext-sptxt = <ls_t002>-sptxt.
    shift ls_ltext-sptxt left deleting leading ' '.
    ls_ltext-zlongtxt = lt_text.
    insert zlongtexts from ls_ltext.
    if sy-subrc = 0.
      commit work.
      lv_lines = lv_lines + 1.
    else.
      rollback work.
    endif.
   "WRITE: / |{ <ls_mara>-matnr } { <ls_mara>-maktx } { <ls_t002>-sptxt } { lt_text } |.
  endif.
 endloop.
 lv_lmatnr = lv_lmatnr + 1.
endloop.
write: / |Добавлено { lv_lmatnr } материалов и { lv_lines } строк|.
