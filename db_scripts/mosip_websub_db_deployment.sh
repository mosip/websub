### -- ---------------------------------------------------------------------------------------------------------
### -- Script Name		: MOSIP ALL DB Artifacts deployment script
### -- Deploy Module 	: MOSIP WebSub Module
### -- Purpose    		: To deploy MOSIP WebSub Module Database DB Artifacts.       
### -- Create By   		: Sadanandegowda DM
### -- Created Date		: Oct-2020
### -- 
### -- Modified Date        Modified By         Comments / Remarks
### -- -----------------------------------------------------------------------------------------------------------

#! bin/bash
echo "`date` : You logged on to DB deplyment server as : `whoami`"
echo "`date` : MOSIP Database objects deployment started...."

echo "=============================================================================================================="
bash ./mosip_websub/mosip_websub_db_deploy.sh ./mosip_websub/mosip_websub_deploy.properties
echo "=============================================================================================================="

echo "`date` : MOSIP DB Deployment for websub module databases is completed, Please check the logs at respective logs directory for more information"
 
