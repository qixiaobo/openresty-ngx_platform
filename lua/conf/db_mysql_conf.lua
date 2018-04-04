
local _M={}

_M.mysql_master = {
	host = "139.196.180.249",
        port = 3306,
        database = "weixinshu",
        user = "root",
        password = "zhengsu@2014",
	max_packet_size = 1024 * 1024 
}


_M.mysql_master_ankao = {
	host = "222.185.56.218",
        port = 3306,
        database = "ankao",
        user = "admin",
        password = "zhengsu@2014",
		max_packet_size = 1024 * 1024 
}

_M.mysql_master_local = {
	host = "192.168.1.24",
        port = 3306,
        database = "ZengsuTestDB",
        user = "root",
        password = "Zhengsu@2014",
		max_packet_size = 1024 * 1024 
}

_M.mysql_master_local_xuniji = {
        host = "192.168.2.24",
        port = 3306,
        database = "ZengsuTestDB",
        user = "root",
        password = "Zhengsu@2014",
                max_packet_size = 1024 * 1024 
}


_M.redis_master_main={
        host = "127.0.0.1",
        port = 6379,
        --database = "ZengsuTestDB",
        user = "root",
        password = "Zhengsu@2014",
                max_packet_size = 1024 * 1024 
}
return _M