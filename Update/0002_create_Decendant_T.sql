
/*******************************************************************************************************************************
**                                                                                                                            **
**                                                MVD_RP1_Map : Decendant_T.sql                                               **
**                                                                                                                            **
********************************************************************************************************************************
**                            Copyright (c) 2023-2025 Metaversal Corporation. All rights reserved.                            **
*******************************************************************************************************************************/
DROP FUNCTION IF EXISTS dbo.Decendant_T;
DELIMITER $$


CREATE FUNCTION dbo.Decendant_T
(
   @Ancestor_wClass            SMALLINT,
   @Ancestor_twObjectIx        BIGINT,
   @Descendant_wClass          SMALLINT,
   @Descendant_twObjectIx      BIGINT
)
RETURNS INT
AS
BEGIN
      DECLARE @nCount INT

       ; WITH Tree AS
              (
                SELECT oa.ObjectHead_Parent_wClass,
                       oa.ObjectHead_Parent_twObjectIx,
                       oa.ObjectHead_Self_wClass,
                       oa.ObjectHead_Self_twObjectIx
                  FROM dbo.RMTObject AS oa
                 WHERE oa.ObjectHead_Self_wClass     = @Descendant_wClass
                   AND oa.ObjectHead_Self_twObjectIx = @Descendant_twObjectIx
                       
                 UNION ALL
      
                SELECT ob.ObjectHead_Parent_wClass,
                       ob.ObjectHead_Parent_twObjectIx,
                       ob.ObjectHead_Self_wClass,
                       ob.ObjectHead_Self_twObjectIx
                  FROM dbo.RMTObject AS ob
                  JOIN Tree          AS t  ON t.ObjectHead_Parent_wClass     = ob.ObjectHead_Self_wClass
                                          AND t.ObjectHead_Parent_twObjectIx = ob.ObjectHead_Self_twObjectIx
              )
       SELECT @nCount = COUNT (*)
         FROM Tree
        WHERE ObjectHead_Self_wClass     = @Ancestor_wClass
          AND ObjectHead_Self_twObjectIx = @Ancestor_twObjectIx

       RETURN @nCount
  END
GO

-- =========================================================
-- 3) STAMP THIS MIGRATION IN db_migrations
-- =========================================================

INSERT INTO db_migrations (script_name, checksum, comment)
SELECT '0002_create_Decendant_T.sql', NULL, 'Create Decendant_T'
WHERE NOT EXISTS (
    SELECT 1
      FROM db_migrations
     WHERE script_name = '0002_create_Decendant_T.sql'
);
