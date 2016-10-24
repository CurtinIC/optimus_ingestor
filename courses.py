EDX_DATABASES = {
    'default': {'dbname': 'api', 'mongoname': 'course-v1:CurtinX+TBOMx+2T2015', 'icon': 'fa-settings'},
    'personcourse': {'dbname': 'Person_Course', 'icon': 'fa-settings'},
    'Course_Event': {'dbname': 'Course_Event', 'icon': 'fa-settings'},
    'TBOMx_2T2015': {'dbname': 'CurtinX_TBOMx_2T2015', 'mongoname': 'course-v1:CurtinX+TBOMx+2T2015', 'discussiontable': 'CurtinX-TBOMx-2T2015-prod', 'icon': 'fa-heart', 'year': '2015'},
}

for DB in EDX_DATABASES:
    EDX_DATABASES[DB]['id'] = DB
