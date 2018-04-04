
--[[创建 多级联动 菜单记录表
DROP PROCEDURE IF EXISTS  MENU_PRO_CRE_PF;     
delimiter // 
create procedure MENU_PRO_CRE_PF(in _pkid BIGINT, in _depth INT)
BEGIN

	DECLARE done INT DEFAULT 0;   
 
	DECLARE b INT DEFAULT 0; 

	DECLARE cur1 CURSOR FOR SELECT t_menu_action.id_pk FROM t_menu_action where t_menu_action.parent_id_fk = _pkid;   

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1; 
	SET max_sp_recursion_depth=12; 
  
	INSERT INTO tmpLst VALUES (NULL,_pkid,_depth);    
   
  OPEN cur1;    

  FETCH cur1 INTO b;   

  WHILE done = 0 DO   

		  CALL MENU_PRO_CRE_PF(b,_depth+1);   

		  FETCH cur1 INTO b;   

  END WHILE;    

  CLOSE cur1;   
END//

DROP PROCEDURE IF EXISTS  _TEMP_SE_PK_FK;     
delimiter // 
create procedure _TEMP_SE_PK_FK(in _tName varchar(64),in _pkName varchar(64),in _funcName varchar(64),in _pkid BIGINT, in _depth INT)
BEGIN
-- 创建一个临时表,用于存储该信息记录
 DROP TEMPORARY TABLE IF EXISTS tmpLst;   
      CREATE TEMPORARY TABLE IF NOT EXISTS tmpLst    
       (tempIdPk INT PRIMARY KEY AUTO_INCREMENT,id INT,depth INT);      
	set @tName=_tName;
	set @pkName = _pkName;
	-- set @fkName = _fkName;
	set @depth = _depth; 
	-- call _TEMP_PRO_CRE_PK_FK(_pkid,_depth);
	set @exeSql1 = concat("call ",_funcName,'(',_pkid,',',_depth,'); '); 
	prepare sqlstr1 from @exeSql1;  
	EXECUTE sqlstr1;  
	deallocate prepare sqlstr1; 
	-- select * from tmpLst;
	-- select t_channel.* from _tName right JOIN tmpLst on t_channel.id=tmpLst.id where tmpLst.depth != 0;  
	set @exeSql = concat('SELECT ', _tName,'.* FROM ', _tName, ' right JOIN tmpLst on ', _tName, '.', _pkName ,' = tmpLst.id where tmpLst.depth != 0;'); 
	prepare sqlstr from @exeSql;  
	EXECUTE sqlstr;  
	deallocate prepare sqlstr; 
END//
]]

