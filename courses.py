import os
import glob
import re

import config


EDX_DEFAULT_COURSE = {
    'id': 'default', 'dbname': 'api', 'mongoname': 'course-v1:CurtinX+TBOMx+2T2015', 'icon': 'fa-settings'
}


def get_all_courses():
    """
    Returns a dictionary that contains one distinct entry per course found in any of the configured data paths. Each entry
    is mapped to the dictionary representation of a CourseInfo object, and hence contains database information, ids, etc.
    :return: Dictionary of all courses, keyed on CourseInfo.id
    """
    courses = {
        'default': EDX_DEFAULT_COURSE,
        'personcourse': {'id': 'personcourse', 'dbname': 'Person_Course', 'icon': 'fa-settings'},
        'Course_Event': {'id': 'Course_Event', 'dbname': 'Course_Event', 'icon': 'fa-settings'},
    }

    for data_path in config.DATA_PATHS:
        for course_info in _list_courses(os.path.join(data_path, 'database_state', 'latest')):
            courses[course_info.id] = course_info.__dict__

    return courses


def _list_courses(path):
    """
    Returns a list of CourseInfo objects, one for each course folder found in the specified path
    :param path: The path to the folder containing the course data in which to find courses (usually database_state/latest)
    :return: List of CourseInfo objects for all found courses in the given path
    """
    return [_CourseInfo(path, name) for name in os.listdir(path) if os.path.isfile(os.path.join(path, name, 'course.xml'))]


class _CourseInfo(object):
    """
    Contains meta-information for a single course, such as database and mongodb names.
    """

    def __init__(self, path, full_name):
        """
        Construct a CourseInfo object given the path to the folder with the course data, and the full course name. For
        example, a full_name of 'CurtinX-ENV1x-2016_T3' would result in a CourseInfo of {'mongoname': 'course-v1:CurtinX+ENV1x+2016_T3',
        'dbname': 'CurtinX_ENV1x_2016_T3', 'discussiontable': 'CurtinX-ENV1x-2016_T3-edge', 'year': '2016',
        'id': 'ENV1x_2016_T3', 'icon': 'fa-heart'}, assuming that there is a '*prod-edge*' file for the course in the
        given path (if not, then the discussiontable suffix would be '-prod' instead).
        :param path: The path that contains the course data files (usually database_state/latest)
        :param full_name: The full course and run name, of the form {org}-{course}-{run}, where {run} is expected
            to contain either "Anytime" or a year of the form "20xx"
        """

        full_course_split = full_name.split('-')

        org = full_course_split[0]
        run = '-'.join(full_course_split[2:])
        course_run_underscore = '_'.join(full_course_split[1:])
        course_run_plus = '+'.join(full_course_split[1:])
        course_run_hyphen = '-'.join(full_course_split[1:])

        prod_edge = 'edge' if len(glob.glob(os.path.join(path, full_name + '*prod-edge*'))) > 0 else 'prod'
        year_search = re.search('20\d{2}', run)
        anytime_search = re.search('anytime', run, re.IGNORECASE)

        self.id = course_run_underscore
        self.dbname = org + '_' + course_run_underscore
        self.mongoname = 'course-v1:' + org + '+' + course_run_plus
        self.discussiontable = org + '-' + course_run_hyphen + '-' + prod_edge
        self.icon = 'fa-heart'
        self.year = anytime_search.group(0) if year_search is None else year_search.group(0)
