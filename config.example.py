#SQL Server details
SQL_HOST = 'localhost'
SQL_PORT = 3306
SQL_USERNAME = 'root'
SQL_PASSWORD = ''
#Mongo Server details
MONGO_HOST = 'localhost'
#Fab - configuration for deploying to a remote server
FAB_HOSTS = []
FAB_GITHUB_URL = 'https://github.com/UQ-UQx/optimus_ingestor.git'
FAB_REMOTE_PATH = '/file/to/your/deployment/location'
#Ignored services
IGNORE_SERVICES = ['extract_sample', 'eventcount', 'daily_count']
#File output
DATA_PATHS = ['/data/']
EXPORT_PATH = '/Volumes/VMs/export'
MONGO_PATH = '/usr/local/bin/'
#Data share supports symlinking true/false
SYMLINK_ENABLED = False
#The server where the course information is found (set to None to instead load from local files)
SERVER_URL = 'http://dashboard.ceit.uq.edu.au'
CLICKSTREAM_PREFIX = 'uqx-edx-events-'
DBSTATE_PREFIX = 'UQx-'
#Set EMAILCRM_FULL_EXPORT to True to force the emailcrm export to be a full export, irrespective of any previous exports
EMAILCRM_FULL_EXPORT = True