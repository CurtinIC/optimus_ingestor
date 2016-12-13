import base_service
import utils


class ExtractSample(base_service.BaseService):

    inst = None

    def __init__(self):
        ExtractSample.inst = self
        super(ExtractSample, self).__init__()

        #The pretty name of the service
        self.pretty_name = "Extract Student Sample"
        #Whether the service is enabled
        self.enabled = False
        #Whether to run more than once
        self.loop = False
        #The amount of time to sleep in seconds
        self.sleep_time = 60

        self.mongo_db = None
        self.mongo_dbname = ""

        self.sample_size = 100
        self.pass_ratio = 0.5

        self.initialize()

    pass

    def setup(self):
        """
        Set initial variables before the run loop starts
        """
        pass

    def run(self):
        """
        Runs every X seconds, the main run loop
        """
        last_run = self.find_last_run_ingest("ExtractSample")
        last_timefinder = self.find_last_run_ingest("TimeFinder")
        last_iptocountry = self.find_last_run_ingest("IpToCountry")
        if self.finished_ingestion("TimeFinder") and last_run < last_timefinder and self.finished_ingestion("IpToCountry") and last_run < last_iptocountry:

            ### add a step to remove existing sample tables ###
            #self.remove_exist_tables()

            ### add a step to remove existing sample collections ###
            #self.remove_exist_collections()

            self.save_run_ingest()
            utils.log("Subset completed")

            pass


def get_files(path):
    """
    Returns a list of files that the service will ingest
    :param path: The path of the files
    :return: An array of file paths
    """
    print path
    required_files = []
    return required_files


def name():
    """
    Returns the name of the service class
    """
    return "ExtractSample"


def service():
    """
    Returns an instance of the service
    """
    return ExtractSample()
