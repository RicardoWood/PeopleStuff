-- ***************************************************************
-- Program Name: 	RemoveUserRoles.sql
-- Developer Name: 	RAW
-- Date: 		19/09/2015
-- ***************************************************************
-- Program Description:
-- Remove roles from users' profiles
-- 
-- ***************************************************************
------------------------------------------------------------------
SET SERVEROUTPUT ON UNLIMITED

SPOOL RemoveUserRoles.log

------------------------------------------------------------------
DECLARE

-- C1_USERS returns the users and roles that need removing
CURSOR C1_USERS IS 
SELECT 
 RU.ROLEUSER
,RU.ROLENAME 
FROM PSROLEUSER RU
WHERE RU.ROLENAME NOT IN (SELECT RD.ROLENAME FROM PSROLEDEFN RD) -- Roles that do not exist
ORDER BY 
 RU.ROLEUSER
,RU.ROLENAME
;

------------------------------------------------------------------
R1_USERS C1_USERS%ROWTYPE;

N        INTEGER := 0;
------------------------------------------------------------------
BEGIN

DBMS_OUTPUT.PUT_LINE ('User profile clean-up. Remove non-existent roles.’);

OPEN C1_USERS;
LOOP
    FETCH C1_USERS INTO R1_USERS;
    EXIT WHEN C1_USERS%NOTFOUND;
    

          DBMS_OUTPUT.PUT_LINE('User: ' ||R1_USERS.ROLEUSER || '. Removing Role: '||R1_USERS.ROLENAME);
          N :=N+1;

          -- Remove the row from PSROLEUSER
          DELETE FROM PSROLEUSER WHERE ROLENAME = R1_USERS.ROLENAME AND ROLEUSER = R1_USERS.ROLEUSER;

          -- Update PSVERSION 
          UPDATE PSVERSION SET VERSION = VERSION+1 WHERE OBJECTTYPENAME = 'UPM';
          UPDATE PSLOCK SET VERSION =VERSION+1 WHERE OBJECTTYPENAME ='UPM';
          UPDATE PSOPRDEFN SET VERSION=(SELECT VERSION FROM PSVERSION WHERE OBJECTTYPENAME = 'UPM'),LASTUPDDTTM=SYSDATE WHERE OPRID = R1_USERS.ROLEUSER;
          UPDATE PSVERSION SET VERSION = VERSION + 1 WHERE OBJECTTYPENAME = 'SYS';
	
          COMMIT;

END LOOP;

CLOSE C1_USERS;

DBMS_OUTPUT.PUT_LINE('Number of rows deleted: ' || N);
END;
/

SPOOL OFF

