Data Extraction Pipeline
========================
This is an optional scripting component for unpacking and decrypting edX research data packages, including existing
files, in-transit files (being downloaded/copied), and background monitoring for new files. All operations are
conducted on the local machine, with the extracted files likewise stored on the local machine.

The folders that are scanned for new raw files, and to which extracted data is published, are configurable.


Requirements
------------
- Nextflow (see https://www.nextflow.io/)
- Linux (bash, GPG, other commands, etc)


Installation
------------
[BASE_PATH] is the path where the injestor has been installed (such as /var/ingestor), per the main Optimus Ingestor
installation instructions.

Install Nextflow (see https://www.nextflow.io/docs/latest/getstarted.html).
```bash
wget -qO- get.nextflow.io | bash
```

Set Nextflow script configuration.
```bash
cp [BASE_PATH]/extract/extract.example.config [BASE_PATH]/extract/extract.config
vim [BASE_PATH]/extract/extract.config
[[EDIT THE VALUES IN THE PARAMS GROUP]]
```

Configure the service script.
```bash
cp [BASE_PATH]/extract/extract.example.sh [BASE_PATH]/extract/extract.sh
vim [BASE_PATH]/extract/extract.sh
[[EDIT THE NXF_BIN AND EXTRACT_HOME VALUES]]
```

Run the service script setup command (if it doesn't already exist, creates the folder structure for published data).
Note that unlike when data files are published, the service setup command does *not* change folder permissions or
group (any changes need to be done manually).
```bash
[BASE_PATH]/extract/extract.sh setup
```


Execution
---------
To run the extraction pipeline, use the service script start command. This will continue running in the background,
even after logging off. The first run can be slow, depending on how many files need to be extracted and published.
Thereafter, each time the extraction pipeline is run, after an initial check (where it will re-examine md5 sums for all
raw files), it will generally remain idle.
```bash
[BASE_PATH]/extract/extract.sh start
```

To check if the extraction pipeline is still alive, use the service script status command.
```bash
[BASE_PATH]/extract/extract.sh status
```

To stop the extraction pipeline, use the service script stop command.
```bash
[BASE_PATH]/extract/extract.sh stop
```


Diagnostics
-----------
Standard output (stdout) from the extraction pipeline is redirected to [BASE_PATH]/extract/work/extract.nf.out.

The main Nextflow log file can be found at [BASE_PATH]/extract/work/.nextflow.log.

On stopping the extraction pipeline, a Nextflow timeline report (see https://www.nextflow.io/docs/latest/tracing.html#timeline-report)
is saved to [BASE_PATH]/extract/work/extract-timeline.html.


Logic Notes
-----------
When the extraction script is running, it will check for changes and monitor for new event log and course data files
(whether processed previously or not). On detecting new or changed files, a pipeline is kicked off to decrypt and
extract the files, and on success the new data is published to a nominated local folder. In the event of new data being
published, if the file/folder name indicates it is the latest such data (i.e., it has the most recent date), then a
"latest" symbolic link (in the same folder as the published data) is pointed to the published file/folder.

This component does not handle downloads, and the implementation makes no assumptions about whether or not raw files
are complete or not. What it does do is use md5 sums of the potentially incomplete raw files to determine if a raw file
has changed and therefore requires reprocessing. This permits the following behaviours:
- If a published file is deleted, the extraction pipeline will not reprocess and republish the deleted data unless both
  the md5 changes (e.g., by deleting the md5 file) *and* either the extraction pipeline is restarted or the
  corresponding raw file is touched. This can be used delete irrelevant published data, without having to move or
  delete raw files.
- If for some reason it is desirable to force a raw file to be reprocessed and republished, this can be achieved by
  deleting the corresponding md5 file *and* either restarting the extraction pipeline or touching the raw file.