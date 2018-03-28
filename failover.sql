--主体 zhu  --A
--镜像 cong --B

--主体server:  GSHC-WANGJX
--1定义证书密码 master key
USE MASTER
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Zhu_pwd'

--2定义证书，他的加密密码是step1  ——【备份到镜像DB，就是个门】
CREATE CERTIFICATE Zhu_cert 
		WITH SUBJECT = 'zhu cert',  EXPIRY_DATE='3/27/2020'
--tips 确认证书是否created
SELECT * FROM SYS.certificates;

--3利用 上面创建的证书 为服务器实例 创建镜像端点6022
 CREATE ENDPOINT Zhu_FOR_mirror_Endpoint
 STATE=STARTED
 AS TCP(
	 LISTENER_PORT = 6022
	 ,LISTENER_IP = ALL
 )
 FOR DATABASE_MIRRORING(
	AUTHENTICATION = CERTIFICATE Zhu_cert   -- step2 证书名
	, ENCRYPTION =  REQUIRED ALGORITHM AES
	,ROLE = PARTNER
 )
 --tips 一个实例 只有一个data_mirroring 端口
 select * from sys.endpoints 
 select * from sys.database_mirroring_endpoints 
 -- drop endpoint 镜像


--4备份Zhu_cert证书,并且拷贝到镜像Server
--即：主服务器上保证存在 镜像上创建的证书；镜像服务器上 存在 主服务器上创建的证书； 
BACKUP CERTIFICATE Zhu_cert
TO FILE = 'G:\数据库备份\zhu_cert.cer'

--5 在各自的实例(服务器)上 为 对方实例(服务器) 分别创建一个登陆名 
--创建一个登录名
CREATE LOGIN FOR_B_login WITH PASSWORD = 'FOR_B_233'
--创建一个使用上面创建的 "登录名" 的"用户 "
CREATE USER FOR_B_user FOR LOGIN FOR_B_login;


--6登录名[主体server上的FOR_B_login]和证书[后来copy过来的cong cert]绑定
CREATE CERTIFICATE FOR_B_login_Cert
	AUTHORIZATION FOR_B_user   --STEP 5创建的user
		FROM FILE = 'G:\SQL\cong_cert.cer'  --非常意外的不识中文路径

--7给主server上镜像端口 一个登录名，并给这个登录名connect权限
GRANT CONNECT ON ENDPOINT::Zhu_FOR_mirror_Endpoint
TO  FOR_B_login;   --登录名
GO

--8设置partner伙伴.顺序：1 镜像 2主体 
--在主体server实例上，设置 镜像server实例
ALTER DATABASE mydb
	SET PARTNER = 'TCP://10.58.8.53:5022'; --主体server实例


--******测试是否镜像成功
--1安全模式 ，可手动切换
ALTER DATABASE mydb SET SAFETY FULL; 

--2切换到高性能模式，将事务安全性设置为off.
ALTER DATABASE mydb
	SET PARTNER SAFETY OFF;


-------------------------------------------------------------------------------------------
--主体 zhu  --A
--镜像 cong --B

--镜像server:  GSHC-WANGJX\WANGJX27
--1定义证书密码 master key
USE MASTER
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Cong_pwd'

--2定义证书，他的加密密码是step1  ——【备份到镜像DB，就是个门】
CREATE CERTIFICATE Cong_cert 
		WITH SUBJECT = 'cong cert',  EXPIRY_DATE='3/27/2020'
--tips 确认证书是否created
SELECT * FROM SYS.certificates;

--3利用 上面创建的证书 为服务器实例 创建镜像端点5022
 CREATE ENDPOINT Cong_FOR_Master_Endpoint
 STATE=STARTED
 AS TCP(
	 LISTENER_PORT = 5022
	 ,LISTENER_IP = ALL
 )
 FOR DATABASE_MIRRORING(
	AUTHENTICATION = CERTIFICATE Cong_cert   -- step2 证书名
	, ENCRYPTION =  REQUIRED ALGORITHM AES
	,ROLE = PARTNER
 )


--4备份Cong_cert证书,并且拷贝到主体Server 
BACKUP CERTIFICATE Cong_cert
TO FILE = 'G:\数据库备份\cong_cert.cer'

--5 在各自的实例(服务器)上 为 对方实例(服务器) 分别创建一个登陆名 
--创建一个登录名
CREATE LOGIN FOR_A_login WITH PASSWORD = 'FOR_A_233'
--创建一个使用上面创建的 "登录名" 的"用户 "
CREATE USER FOR_A_user FOR LOGIN FOR_A_login;

--6登录名[镜像server上的FOR_A_login]和证书[后来copy过来的 zhu cert]绑定
CREATE CERTIFICATE FOR_A_login_Cert
	AUTHORIZATION FOR_A_user
		FROM FILE ='G:\SQL\zhu_cert.cer'  

--7
GRANT CONNECT ON ENDPOINT :: Cong_FOR_Master_Endpoint
TO FOR_A_login


--8设置partner伙伴.顺序：1 镜像 2主体 
--在镜像server实例上，设置 主体server实例
ALTER DATABASE mydb
	SET PARTNER = 'TCP://GSHC-WANGJX:6022'; --主体server实例


--******测试是否镜像成功
 
--2切换到高性能模式，将事务安全性设置为off.
ALTER DATABASE mydb
	SET PARTNER SAFETY OFF;

--在镜像机上执行强制切换(当主服务器数据宕机时) 
ALTER DATABASE mydb 
SET PARTNER FORCE_SERVICE_ALLOW_DATA_LOSS

--主体server 恢复，服务重新起来。重新设定镜像
--镜像server执行 WANGJX27
ALTER DATABASE mydb SET PARTNER RESUME 
--
ALTER DATABASE mydb SET PARTNER FAILOVER


--安全模式 切换主备
------------------------删除数据库镜像 
ALTER DATABASE mydb SET PARTNER OFF 
-----------暂停数据库镜像会话 
ALTER DATABASE mydb SET PARTNER SUSPEND 
-----恢复数据库镜像会话 
ALTER DATABASE mydb SET PARTNER RESUME 
ALTER DATABASE mydb SET PARTNER SUSPEND 
-----关闭见证服务器 
ALTER DATABASE mydb SET WITNESS OFF 