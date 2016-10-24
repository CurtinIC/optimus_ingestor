"""
Common course info methods
"""
import config
import urllib2
import json


def load_course_info(json_file):
    """
    Loads the course information from JSON course structure file
    :param json_file: the name of the course structure file
    :return the course information
    """

    if config.SERVER_URL is None:
        courseuri = 'www/course_structure/' + json_file
        openfn = open
    else:
        courseuri = config.SERVER_URL + '/datasources/course_structure/' + json_file
        openfn = urllib2.urlopen

    print "ATTEMPTING TO LOAD " + courseuri
    try:
        courseinfofile = openfn(courseuri)
        if courseinfofile:
            return json.load(courseinfofile)
    except urllib2.HTTPError as e:
        print "Failed to load %s: %s" % (courseuri, e.message)
    except Exception as e:
        print "Failed to load %s" % courseuri

    return None
