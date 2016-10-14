#!/usr/bin/env nextflow

/*
 * Nextflow script that is responsible for ensuring the necessary folder structure (for publishing files and storing
 * md5 sums) is in place, if it isn't already. All operations are conducted on the local machine. This exists as a
 * Nextflow script (rather than a raw bash script) as it simplifies sharing the configuration settings wit extract.nf.
 *
 * See the 'README.md' for further information, including installation, configuration, and execution details. In
 * particular, note that this file should not be executed directly, nor should it need to be modified.
 */

process mkdir {
    script:
    """
    echo 'mkdir'
    mkdir -p '${params.publishedCourseDataFolder}'
    mkdir -p '${params.publishedEventEdXFolder}'
    mkdir -p '${params.publishedEventEdgeFolder}'
    mkdir -p '${params.md5Folder}'
    """
}
