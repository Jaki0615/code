--���� zhu  --A
--���� cong --B

--����server:  GSHC-WANGJX
--1����֤������ master key
USE MASTER
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Zhu_pwd'

--2����֤�飬���ļ���������step1  ���������ݵ�����DB�����Ǹ��š�
CREATE CERTIFICATE Zhu_cert 
		WITH SUBJECT = 'zhu cert',  EXPIRY_DATE='3/27/2020'
--tips ȷ��֤���Ƿ�created
SELECT * FROM SYS.certificates;

--3���� ���洴����֤�� Ϊ������ʵ�� ��������˵�6022
 CREATE ENDPOINT Zhu_FOR_mirror_Endpoint
 STATE=STARTED
 AS TCP(
	 LISTENER_PORT = 6022
	 ,LISTENER_IP = ALL
 )
 FOR DATABASE_MIRRORING(
	AUTHENTICATION = CERTIFICATE Zhu_cert   -- step2 ֤����
	, ENCRYPTION =  REQUIRED ALGORITHM AES
	,ROLE = PARTNER
 )
 --tips һ��ʵ�� ֻ��һ��data_mirroring �˿�
 select * from sys.endpoints 
 select * from sys.database_mirroring_endpoints 
 -- drop endpoint ����


--4����Zhu_cert֤��,���ҿ���������Server
--�������������ϱ�֤���� �����ϴ�����֤�飻����������� ���� ���������ϴ�����֤�飻 
BACKUP CERTIFICATE Zhu_cert
TO FILE = 'G:\���ݿⱸ��\zhu_cert.cer'

--5 �ڸ��Ե�ʵ��(������)�� Ϊ �Է�ʵ��(������) �ֱ𴴽�һ����½�� 
--����һ����¼��
CREATE LOGIN FOR_B_login WITH PASSWORD = 'FOR_B_233'
--����һ��ʹ�����洴���� "��¼��" ��"�û� "
CREATE USER FOR_B_user FOR LOGIN FOR_B_login;


--6��¼��[����server�ϵ�FOR_B_login]��֤��[����copy������cong cert]��
CREATE CERTIFICATE FOR_B_login_Cert
	AUTHORIZATION FOR_B_user   --STEP 5������user
		FROM FILE = 'G:\SQL\cong_cert.cer'  --�ǳ�����Ĳ�ʶ����·��

--7����server�Ͼ���˿� һ����¼�������������¼��connectȨ��
GRANT CONNECT ON ENDPOINT::Zhu_FOR_mirror_Endpoint
TO  FOR_B_login;   --��¼��
GO

--8����partner���.˳��1 ���� 2���� 
--������serverʵ���ϣ����� ����serverʵ��
ALTER DATABASE mydb
	SET PARTNER = 'TCP://10.58.8.53:5022'; --����serverʵ��


--******�����Ƿ���ɹ�
--1��ȫģʽ �����ֶ��л�
ALTER DATABASE mydb SET SAFETY FULL; 

--2�л���������ģʽ��������ȫ������Ϊoff.
ALTER DATABASE mydb
	SET PARTNER SAFETY OFF;


-------------------------------------------------------------------------------------------
--���� zhu  --A
--���� cong --B

--����server:  GSHC-WANGJX\WANGJX27
--1����֤������ master key
USE MASTER
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Cong_pwd'

--2����֤�飬���ļ���������step1  ���������ݵ�����DB�����Ǹ��š�
CREATE CERTIFICATE Cong_cert 
		WITH SUBJECT = 'cong cert',  EXPIRY_DATE='3/27/2020'
--tips ȷ��֤���Ƿ�created
SELECT * FROM SYS.certificates;

--3���� ���洴����֤�� Ϊ������ʵ�� ��������˵�5022
 CREATE ENDPOINT Cong_FOR_Master_Endpoint
 STATE=STARTED
 AS TCP(
	 LISTENER_PORT = 5022
	 ,LISTENER_IP = ALL
 )
 FOR DATABASE_MIRRORING(
	AUTHENTICATION = CERTIFICATE Cong_cert   -- step2 ֤����
	, ENCRYPTION =  REQUIRED ALGORITHM AES
	,ROLE = PARTNER
 )


--4����Cong_cert֤��,���ҿ���������Server 
BACKUP CERTIFICATE Cong_cert
TO FILE = 'G:\���ݿⱸ��\cong_cert.cer'

--5 �ڸ��Ե�ʵ��(������)�� Ϊ �Է�ʵ��(������) �ֱ𴴽�һ����½�� 
--����һ����¼��
CREATE LOGIN FOR_A_login WITH PASSWORD = 'FOR_A_233'
--����һ��ʹ�����洴���� "��¼��" ��"�û� "
CREATE USER FOR_A_user FOR LOGIN FOR_A_login;

--6��¼��[����server�ϵ�FOR_A_login]��֤��[����copy������ zhu cert]��
CREATE CERTIFICATE FOR_A_login_Cert
	AUTHORIZATION FOR_A_user
		FROM FILE ='G:\SQL\zhu_cert.cer'  

--7
GRANT CONNECT ON ENDPOINT :: Cong_FOR_Master_Endpoint
TO FOR_A_login


--8����partner���.˳��1 ���� 2���� 
--�ھ���serverʵ���ϣ����� ����serverʵ��
ALTER DATABASE mydb
	SET PARTNER = 'TCP://GSHC-WANGJX:6022'; --����serverʵ��


--******�����Ƿ���ɹ�
 
--2�л���������ģʽ��������ȫ������Ϊoff.
ALTER DATABASE mydb
	SET PARTNER SAFETY OFF;

--�ھ������ִ��ǿ���л�(��������������崻�ʱ) 
ALTER DATABASE mydb 
SET PARTNER FORCE_SERVICE_ALLOW_DATA_LOSS

--����server �ָ����������������������趨����
--����serverִ�� WANGJX27
ALTER DATABASE mydb SET PARTNER RESUME 
--
ALTER DATABASE mydb SET PARTNER FAILOVER


--��ȫģʽ �л�����
------------------------ɾ�����ݿ⾵�� 
ALTER DATABASE mydb SET PARTNER OFF 
-----------��ͣ���ݿ⾵��Ự 
ALTER DATABASE mydb SET PARTNER SUSPEND 
-----�ָ����ݿ⾵��Ự 
ALTER DATABASE mydb SET PARTNER RESUME 
ALTER DATABASE mydb SET PARTNER SUSPEND 
-----�رռ�֤������ 
ALTER DATABASE mydb SET WITNESS OFF 