Optimus Ingestor (Curtin fork)
==============================
This is a fork of the UQx optimus ingestor (https://github.com/UQ-UQx/optimus_ingestor).

The optimus ingestor is a daemon which runs a series of services for ingesting the edX data package.
Each service scans a data directory for specific data and saves its file reference.  Later, the service ingests it into either a MySQL or MongoDB
database.  These scans are run and repeated regularly.  The daemon also provides a REST API to
read the current state of the ingestion.  

The ingested databases are designed to work in conjunction with the UQx-API application: https://github.com/UQ-UQx/uqx_api


Requirements
------------
- Python 2.7
- MySQL with local-infile enabled (see http://dev.mysql.com/doc/refman/5.1/en/server-system-variables.html#sysvar_local_infile)
- MongoDB
- For the iptocountry service, the GeoLite2-Country.mmdb and GeoLite2-City.mmdb libs (available from http://dev.maxmind.com/geoip/geoip2/geolite2/)

The files extracted from the edX research package should be organised in the following manner
```
/[DATA_PATH]
    /clickstream_logs
        /latest (symlink to events)
        /events
            /...
    /database_state
        /latest (symlink to 2014-01-07)
        /2014-01-01
            /...
        /2014-01-07
            /...
```

The ingestor will look at these latest symlinked directories.  To create symlink directories, you can do (e.g. for clickstream):
```
ln -s /[DATA_PATH]/clickstream_logs/events /[DATA_PATH]/clickstream_logs/latest
```

For database_state, do similar, but point to the latest database_state.  When a new package comes in, you can just point the symlink to the newest database_state archive.
If the optional [data extractor](extract/README.md) is used, the latest symlink for database_state should be updated automatically.


Installation
------------
[BASE_PATH] is the path where you want the injestor installed (such as /var/ingestor)

Clone the repository
```bash
git clone https://github.com/CurtinIC/optimus_ingestor.git [BASE_PATH]
```
Install the GeoLite2-Country.mmdb and GeoLite2-City.mmdb libs
```bash
cp GeoLite2-Country.mmdb [BASE_PATH]/services/iptocountry/lib/
cp GeoLite2-City.mmdb [BASE_PATH]/services/iptocountry/lib/
```
Install pip requirements
```bash
sudo apt-get install libxml2-dev libxslt1-dev python-dev libsasl2-dev libldap2-dev
sudo pip install -r requirements.txt
```
Set injestor configuration
```bash
cp [BASE_PATH]/config.example.py [BASE_PATH]/config.py
vim [BASE_PATH]/config.py
[[EDIT THE VALUES]]
```
Edit the default course (note this is not used directly by the ingestor)
```bash
vim [BASE_PATH]/courses.py
[[EDIT 'EDX_DEFAULT_COURSE']]
```
Some services make use of the EXPORT_PATH that is defined in config.py, which needs to be created before running the ingestor
```bash
mkdir -p [EXPORT_PATH]
```
If the SERVER_URL specified in config.py is not None, then the generated course structure data (inside the www directory of the ingestor) will need to be available
via a web endpoint called datasources. The API application will also need this for some endpoints.  This can just be a symlink from your htdocs or web server folder:
```
ln -s [BASE_PATH]/www [HTDOCS_PATH]/datasources
```
To use this symlink with selinux you will need to grant permission explicitly
```
sudo chcon -R -t httpd_sys_content_t /yourpath/tosymlink/www
```
Run injestor
```bash
/etc/init.d/ingestor
(or) [BASE_PATH]/ingestor.py
```


Deployment
----------
If you wish to deploy the ingestor to a server, you can use the supplied fab (http://www.fabfile.org/) script (but only after config.py has been set).
This takes care of cloning the git repository to the target server.
```
fab deploy
```


Extraction Example
------------------
The optimus ingestor does not deal with the initial extraction of data from the edX s3 repository.  However, an example script (based on the UQx extraction process)
can be found in extract_data.example.sh.

A Nextflow [data extractor](extract/README.md) is also available for decrypting and extracting downloaded data packages.


Architecture
------------
The architecture of the Optimus Ingestor is a service-based application which has two aspects.  Firstly, the Ingestor calls each service and provides them
with an array of files from the exported edX data.  Each service replies with which files they are interested in, and the references to these files are stored 
in a MySQL database.  The service then is run and looks for uningested files in the database, and ingests them through the run() method.  Services can check the
queue of uningested data for other services, to establish when a service should be run (data dependencies).  

The flow of the data is as follows:
![Optimus Ingestor](/README_ARCHITECTURE_IMAGE.png?raw=true "Optimus Ingestor")


Service Logic
-------------
The service logic is as follows:
 - Clickstream - Ingests clicks into MongoDB (no requirements)
 - Database State - Updates the SQL tables from the SQL dumps (no requirements)
 - Discussion Forums - Ingests discussion forum tables into MongoDB (no requirements)
 - Course Structure - Uses the XML files in the research guide to generate a nested JSON structure describing each course (no requirements)
 - IP To Country - Updates Mongo records with Country attributes where IP is present (requires complete clickstream)
 - Time Finder - Updates Mongo records with Date object attributes where a date string is present (requires complete clickstream)
 - Person Course - Generates and exports Person Course SQL table (requires complete IP to country, time finder, and database state)
 - Email CRM - Generates and exports Email CRM SQL table (requires complete person course and database state)


Running Tests
-------------
Currently the project is at an early stage and does not have reliable tests created.


License
-------
This project is licensed under the terms of the MIT license.


How to Contribute
-----------------
Currently the injestor project is at a very early stage and unlikely to accept pull requests
in a timely fashion as the structure may change without notice.
However feel free to open issues that you run into and we can look at them ASAP.


Contact
-------
The best contact point, apart from opening github issues or comments, is to contact [Simon Huband](http://oasisapps.curtin.edu.au/staff/profile/view/Simon.Huband).