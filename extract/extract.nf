#!/usr/bin/env nextflow

/*
 * Nextflow script that is responsible for finding and watching for new raw edX data package data files, which it also
 * unpacks, decrypts, and publishes. All operations are conducted on the local machine. See the 'README.md' for further
 * information, including installation, configuration, and execution details. In particular, note that this file should
 * not be executed directly, nor should it need to be modified.
 */

// helper method to check if a file name corresponds to an edx-event file for the configured institution
boolean isEdXEvent(String str) { return str.startsWith(params.institution + "-edx-events-") }

// helper method to check if a file name corresponds to an edge-event file for the configured institution
boolean isEdgeEvent(String str) { return str.startsWith(params.institution + "-edge-events-") }

/*
 * We maintain a global sequence number cache (of file name to number), which we increment by one every time Nextflow
 * notifies us of a found, new, or modified file matching our search pattern. This is used to prevent us from kicking
 * off multiple concurrent extraction pipelines for the same file, which would otherwise happen when a file is being
 * downloaded, where Nextflow will emit an event for multiple changes to the file (as it is in the process of being
 * downloaded).
 *
 * The fundamental problem is that in the absence of additional information, this script cannot know when a file has
 * been fully downloaded. The adopted solution is to permit multiple attempts to extract a file (allowing for
 * failures), limited only by whether or not an md5 has changed (a relatively fast check), and by using this cache to
 * avoid pointlessly kicking off the pipeline for each and every update event emitted by Nextflow.
 */
sequenceMap = new HashMap()
int getAndIncrementSequence(String str) {
    println "getAndIncrementSequence(" + str + ") = " + (sequenceMap[str] = (sequenceMap[str] ?: 0) + 1);
    return sequenceMap[str];
}

/*
 * The pending channel is populated by Nextflow for all raw event log and course data files that exist at startup, and
 * as new such files are created or modified, for the configured institution and paths. Entries are tuples of the
 * following:
 *   - input: the path to the raw event log or raw course data file
 *   - output name: the expected extracted name of the raw event log or course data folder
 *   - output folder: the folder to which the extracted event log or course data folder is to be moved on success
 *   - md5: the path to the md5 file to check for changes and create/update on deciding that the extraction pipeline
 *     should be kicked off
 *   - sequence: the sequence number for this input
 */
watchPattern = params.institution + '-{*.zip,edx-events-*.log.gz.gpg,edge-events-*.log.gz.gpg}'
pending = Channel.create()
    .mix(Channel.watchPath(params.rawCourseDataFolder + '/' + watchPattern, 'create,modify'))
    .mix(Channel.watchPath(params.rawEventEdXFolder + '/' + watchPattern, 'create,modify'))
    .mix(Channel.watchPath(params.rawEventEdgeFolder + '/' + watchPattern, 'create,modify'))
    .mix(Channel.fromPath(params.rawCourseDataFolder + '/' + watchPattern))
    .mix(Channel.fromPath(params.rawEventEdXFolder + '/' + watchPattern))
    .mix(Channel.fromPath(params.rawEventEdgeFolder + '/' + watchPattern))
    .map { input -> tuple(
        input.toString(),
        input.name.replaceFirst(/.gz.gpg\z/,"").replaceFirst(/.zip\z/,""),
        isEdXEvent(input.name) ? params.publishedEventEdXFolder : ( isEdgeEvent(input.name) ? params.publishedEventEdgeFolder : params.publishedCourseDataFolder ),
        params.md5Folder + '/' + input.name + ".md5",
        getAndIncrementSequence(input.toString())
    ) }

/*
 * The queued channel is populated for raw data files that are to be extracted, as specified by tuples of:
 *   - input: the path to the raw event log or raw course data file
 *   - output name: the expected extracted name of the raw event log or course data folder
 *   - output folder: the folder to which the extracted event log or course data folder is to be moved on success
 */
queued = Channel.create()

/*
 * The queuedEventLog and queuedCourseData channels are populated from the queued channel for event logs and course data
 * respectively.
 */
queuedEventLog = Channel.create()
queuedCourseData = Channel.create()
queued.choice(queuedEventLog, queuedCourseData) { a -> a[0].endsWith(".log.gz.gpg") ? 0 : 1 }

/*
 * md5Check acts as the gatekeeper that determines whether or not the extraction pipeline should be kicked off for any
 * raw event log of course data file appearing on the pending channel.
 */
process md5Check {
    input:
    set val(input), val(outputName), val(outputFolder), val(md5), val(sequence) from pending

    output:
    set val(input), val(outputName), val(outputFolder) into queued

    when:
    println "md5Check(when) ${input}:${outputName}:${outputFolder}:${md5}:${sequence}:${sequenceMap[input]}"
    if (sequence == sequenceMap[input]) {
        // we are the latest in the sequence for this input, so check for a changed (or missing) md5 sum
        def process = ["sh", "-c", "md5sum --check '${md5}'"].execute()
        process.waitFor()
        return process.exitValue() != 0
    } else {
        // not the latest in the sequence for this input, so don't do anything
        return false
    }

    script:
    // if we get here, then generate a new md5 sum before outputting to the queued channel
    """
    echo 'md5Check(script) ${input}:${outputName}:${outputFolder}:${md5}:${sequence}'
    md5sum '${input}' > '${md5}'
    """
}

/*
 * extractEventLog will decrypt, extract, and publish any raw EdX or Edge event log that appears on the queuedEventLog
 * channel. It ignores errors, as failure is possible (e.g., file is mid-download).
 */
process extractEventLog {
    errorStrategy 'ignore'

    input:
    set val(input), val(outputName), val(outputFolder) from queuedEventLog

    script:
    """
    echo 'extractEventLog ${input}:${outputName}:${outputFolder}'
    gpg --passphrase-file '${params.passphrasePath}' --batch --yes --decrypt '${input}' | gunzip > '${outputName}'
    mv -f '${outputName}' '${outputFolder}/${outputName}'
    """
}

/*
 * extractCourseData will unzip, recursively decrypt, recursively un-tar, and publish any raw course data file that
 * appears on the queuedCourseData channel. It ignores errors, as failure is possible (e.g., file is mid-download).
 * When appropriate, the "latest" symbolic link is also updated.
 */
process extractCourseData {
    errorStrategy 'ignore'

    input:
    set val(input), val(outputName), val(outputFolder) from queuedCourseData

    script:
    """
    echo 'extractCourseData ${input}:${outputName}:${outputFolder}'
    unzip '${input}'
    find '${outputName}' -name '*.gpg' -exec sh -c 'gpg --passphrase-file "${params.passphrasePath}" --batch --yes --output "\${1%.*}" --decrypt "\$1" ; rm "\$1"' sh {} \\;
    find '${outputName}' -name '*.tar.gz' -exec sh -c 'tar -xzf "\$1" -C "${outputName}" ; rm "\$1"' sh {} \\;
    if [ -d '${outputFolder}/${outputName}' ]; then rm -r '${outputFolder}/${outputName}'; fi
    mv '${outputName}' '${outputFolder}/'
    published=\$(find '${outputFolder}' -mindepth 1 -maxdepth 1 -type d -name '${outputName}')
    latest=\$(find '${outputFolder}' -mindepth 1 -maxdepth 1 -type d -regextype sed -regex '.*/${params.institution}-[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}' | sort | tail -1)
    if [ "\$published" == "\$latest" ]; then ln -sfn "\$published" '${outputFolder}/latest'; fi
    """
}
