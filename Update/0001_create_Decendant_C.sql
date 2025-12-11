/*******************************************************************************************************************************
**                                                                                                                            **
**                                                MVD_RP1_Map : Decendant_C.sql                                               **
**                                                                                                                            **
*******************************************************************************************************************************
**                            Copyright (c) 2023-2025 Metaversal Corporation. All rights reserved.                            **
*******************************************************************************************************************************/

DROP FUNCTION IF EXISTS Decendant_C;
DELIMITER $$

CREATE FUNCTION Decendant_C
(
   Ancestor_wClass       SMALLINT,
   Ancestor_twObjectIx   BIGINT,
   Descendant_wClass     SMALLINT,
   Descendant_twObjectIx BIGINT
)
RETURNS INT
DETERMINISTIC
BEGIN
   DECLARE nCount INT;

   WITH RECURSIVE Tree AS
   (
      SELECT
         oa.ObjectHead_Parent_wClass,
         oa.ObjectHead_Parent_twObjectIx,
         oa.ObjectHead_Self_wClass,
         oa.ObjectHead_Self_twObjectIx
      FROM RMCObject AS oa
      WHERE oa.ObjectHead_Self_wClass     = Descendant_wClass
        AND oa.ObjectHead_Self_twObjectIx = Descendant_twObjectIx

      UNION ALL

      SELECT
         ob.ObjectHead_Parent_wClass,
         ob.ObjectHead_Parent_twObjectIx,
         ob.ObjectHead_Self_wClass,
         ob.ObjectHead_Self_twObjectIx
      FROM RMCObject AS ob
      JOIN Tree AS t
        ON t.ObjectHead_Parent_wClass     = ob.ObjectHead_Self_wClass
       AND t.ObjectHead_Parent_twObjectIx = ob.ObjectHead_Self_twObjectIx
   )

   SELECT COUNT(*) INTO nCount
     FROM Tree
    WHERE ObjectHead_Self_wClass     = Ancestor_wClass
      AND ObjectHead_Self_twObjectIx = Ancestor_twObjectIx;

   RETURN nCount;
END$$

DELIMITER ;

-- =========================================================
-- 3) STAMP THIS MIGRATION IN db_update
-- =========================================================

INSERT INTO db_update (script_name, checksum, comment)
SELECT '0001_create_Decendant_C.sql', NULL, 'Create Decendant_C.sql'
WHERE NOT EXISTS (
    SELECT 1
      FROM db_update
     WHERE script_name = '0001_create_Decendant_C.sql'
);
