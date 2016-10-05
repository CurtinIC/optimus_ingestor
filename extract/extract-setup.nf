#!/usr/bin/env nextflow

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
