import inspect
import os
import logging
import datetime
import config
import MySQLdb

basepath = os.path.dirname(__file__)

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
loggers = {}


def log(message):
    """
    Logs a message to screen and to the file
    :param message:
    """
    class_name = os.path.splitext(os.path.basename(inspect.stack()[1][1]))[0]
    if class_name not in loggers:
        log_file = basepath + '/logs/' + class_name + '.log'
        new_logger = logging.getLogger(class_name)
        new_log_handler = logging.FileHandler(log_file)
        new_logger.addHandler(new_log_handler)
        loggers[class_name] = new_logger
    the_log = loggers[class_name]
    the_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = the_time + ":" + " " + message
    the_log.info(log_message)


# get first child dir name of current
def get_subdir(a_dir):
    """
    Returns the path of the first child directory found in the main-path
    :param a_dir: The main path
    :rtype: string
    """
    for d in os.listdir(a_dir):
        p = os.path.join(a_dir, d)
        if os.path.isdir(p):
            return p


def connect_to_sql(sql_connect, db_name="", force_reconnect=False, create_db=True, charset=None):
    """
    Connect to SQL database or create the database and connect
    :param sql_connect: the variable to set
    :param db_name: the name of the database
    :param force_reconnect: force the database connection
    :param create_db: create the database
    :param charset: the charset
    :return the created SQL connection
    """
    if sql_connect is None or force_reconnect:
        try:
            sql_connect = MySQLdb.connect(host=config.SQL_HOST, port=config.SQL_PORT, user=config.SQL_USERNAME,
                                          passwd=config.SQL_PASSWORD, db=db_name, local_infile=1, charset=charset)
            return sql_connect
        except Exception, e:
            # Create the database
            if e[0] and create_db and db_name != "":
                if sql_connect is None:
                    sql_connect = MySQLdb.connect(host=config.SQL_HOST, port=config.SQL_PORT, user=config.SQL_USERNAME,
                                                  passwd=config.SQL_PASSWORD, local_infile=1, charset=charset)
                log("Creating database " + db_name)

                cur = sql_connect.cursor()
                cur.execute("CREATE DATABASE " + db_name)
                sql_connect.commit()
                sql_connect.select_db(db_name)
                return sql_connect
            else:
                log("Could not connect to MySQL: %s" % e)
                return None
    return None


def sql_conn_is_alive(sql_conn):
    """
    Check if the given SQL connection is alive
    :param sql_conn: the MySQLdb connection to check
    :return: True if the connection can be pinged, False otherwise
    """
    alive = False

    if sql_conn:
        try:
            sql_conn.ping(True)
            alive = True
        except MySQLdb.OperationalError:
            alive = False

    return alive
