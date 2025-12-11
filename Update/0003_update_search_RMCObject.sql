DROP PROCEDURE IF EXISTS search_RMCObject;
DELIMITER $$

CREATE PROCEDURE search_RMCObject
(
   IN    sIPAddress                   VARCHAR (16),
   IN    twRPersonaIx                 BIGINT,
   IN    twRMCObjectIx                BIGINT,
   IN    dX                           DOUBLE,
   IN    dY                           DOUBLE,
   IN    dZ                           DOUBLE,
   IN    sText                        VARCHAR (48)
)
BEGIN
       DECLARE MVO_RMCOBJECT_TYPE_SATELLITE              INT DEFAULT 15;

       DECLARE bError  INT;
       DECLARE bCommit INT DEFAULT 0;
       DECLARE nError  INT DEFAULT 0;

       DECLARE bType   TINYINT UNSIGNED;
       DECLARE dRange  DOUBLE;
       DECLARE nCount  INT DEFAULT 0;

            -- Create the temp Error table
        CREATE TEMPORARY TABLE Error
               (
                  nOrder                        INT             NOT NULL AUTO_INCREMENT PRIMARY KEY,
                  dwError                       INT             NOT NULL,
                  sError                        VARCHAR (255)   NOT NULL
               );

        SELECT Type_bType INTO bType
          FROM RMCObject
         WHERE ObjectHead_Self_twObjectIx = twRMCObjectIx;

            IF bType IS NULL
          THEN
               SET bError = 1;
        END IF ;

            IF bError = 0
          THEN
                 SET sText = TRIM (IFNULL (sText, ''));

                  IF sText <> ''
                THEN
                      CREATE TEMPORARY TABLE Result
                                      (
                                         nOrder                          INT         AUTO_INCREMENT PRIMARY KEY,
                                         ObjectHead_Self_twObjectIx      BIGINT,
                                         dFactor                         DOUBLE,
                                         dDistance                       DOUBLE
                                      );

                       INSERT INTO Result
                            (
                              ObjectHead_Self_twObjectIx, 
                              dFactor,
                              dDistance
                            )
                       SELECT 
                              o.ObjectHead_Self_twObjectIx, 
                              POW(4.0, o.Type_bType - 7) AS dFactor, 
                              -1 AS dDistance
                         FROM RMCObject AS o
                        WHERE o.Name_wsRMCObjectId LIKE CONCAT(sText, '%')
                          AND o.Type_bType BETWEEN bType + 1 AND MVO_RMCOBJECT_TYPE_SATELLITE
                     ORDER BY POW(4.0, o.Type_bType - 7) * (-1) DESC, o.Name_wsRMCObjectId
                        LIMIT 10;

                       SELECT o.ObjectHead_Parent_wClass     AS ObjectHead_wClass_Parent,
                              o.ObjectHead_Parent_twObjectIx AS ObjectHead_twParentIx,
                              o.ObjectHead_Self_wClass       AS ObjectHead_wClass_Object,
                              o.ObjectHead_Self_twObjectIx   AS ObjectHead_twObjectIx,
                              o.ObjectHead_wFlags,
                              o.ObjectHead_twEventIz,
                              o.Name_wsRMCObjectId,
                              o.Type_bType,
                              o.Type_bSubtype,
                              o.Type_bFiction,
                              r.dFactor,
                              r.dDistance
                         FROM RMCObject AS o
                         JOIN Result    AS r ON r.ObjectHead_Self_twObjectIx = o.ObjectHead_Self_twObjectIx
                     ORDER BY r.nOrder;

                       WITH RECURSIVE Tree AS
                              (
                                SELECT oa.ObjectHead_Parent_wClass,
                                       oa.ObjectHead_Parent_twObjectIx,
                                       oa.ObjectHead_Self_wClass,
                                       oa.ObjectHead_Self_twObjectIx,
                                       r.nOrder,
                                       0                               AS nAncestor
                                  FROM RMCObject AS oa
                                  JOIN Result    AS r  ON r.ObjectHead_Self_twObjectIx = oa.ObjectHead_Self_twObjectIx
 
                                 UNION ALL
 
                                SELECT ob.ObjectHead_Parent_wClass,
                                       ob.ObjectHead_Parent_twObjectIx,
                                       ob.ObjectHead_Self_wClass,
                                       ob.ObjectHead_Self_twObjectIx,
                                       x.nOrder,
                                       x.nAncestor + 1                 AS nAncestor
                                  FROM RMCObject AS ob
                                  JOIN Tree      AS x  ON x.ObjectHead_Parent_twObjectIx = ob.ObjectHead_Self_twObjectIx
                                                      AND x.ObjectHead_Parent_wClass     = ob.ObjectHead_Self_wClass
                              )
                       SELECT o.ObjectHead_Parent_wClass     AS ObjectHead_wClass_Parent,
                              o.ObjectHead_Parent_twObjectIx AS ObjectHead_twParentIx,
                              o.ObjectHead_Self_wClass       AS ObjectHead_wClass_Object,
                              o.ObjectHead_Self_twObjectIx   AS ObjectHead_twObjectIx,
                              o.ObjectHead_wFlags,
                              o.ObjectHead_twEventIz,
                              o.Name_wsRMCObjectId,
                              o.Type_bType,
                              o.Type_bSubtype,
                              o.Type_bFiction,
                              x.nAncestor
                         FROM RMCObject AS o
                         JOIN Tree      AS x ON x.ObjectHead_Self_twObjectIx = o.ObjectHead_Self_twObjectIx
                        WHERE x.nAncestor > 0
                     ORDER BY x.nOrder,
                              x.nAncestor;

                       DROP TEMPORARY TABLE Result;
                 ELSE
                       SELECT NULL AS Unused LIMIT 0;
                       SELECT NULL AS Unused LIMIT 0;
             END IF ;

                 SET bCommit = 1;
          ELSE 
                CALL call_Error (1, 'twRMCObjectIx is invalid', nError);
        END IF ;

            IF bCommit = 0
          THEN
                 SELECT dwError, sError FROM Error;
        END IF ;

        DROP TEMPORARY TABLE Error;

        SET nError = bCommit - bError - 1;
END$$
DELIMITER ;


-- =========================================================
-- 3) STAMP THIS MIGRATION IN db_migrations
-- =========================================================

INSERT INTO db_migrations (script_name, checksum, comment)
SELECT '0003_update_search_RMCObject.sql', NULL, 'Update Search RMCObject'
WHERE NOT EXISTS (
    SELECT 1
      FROM db_migrations
     WHERE script_name = '0003_update_search_RMCObject.sql'
);
