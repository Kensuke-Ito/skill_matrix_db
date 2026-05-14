CREATE OR REPLACE FUNCTION CSG."GET_PARTNER_SYAIN" (
     sequence IN number /* 連番値(1~25974(=Z999))の値をとるものとする */
) RETURN VARCHAR2 AS
 WORDS VARCHAR2(26) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
 header VARCHAR2(10);
 quotient number(2); /* 商 */
 remainder number(3); /* 剰余 */
BEGIN
  quotient := trunc((sequence-1) / 999);
  header := substr(Words,(quotient + 1),1);

  remainder := mod(sequence-1,999);

  RETURN 'U' || header || LPAD(remainder+1,3,'0'); /* UxXXXの文字列を返却 */
END GET_PARTNER_SYAIN;
/
