include { BSBOLT_CALL_METHYLATION } from '../../../../modules/local/bsbolt/call_methylation/main'
include { BSBOLT_AGGREGATE_MATRIX } from '../../../../modules/local/bsbolt/aggregate_matrix/main'

workflow BSBOLT_METHYLATION_CALLING {
    take:
    ch_bam // channel: [ val(meta), path(bam), path(bai) ]
    ch_bsbolt_db // channel: path to bsbolt database/index

    main:
    ch_versions = channel.empty()

    BSBOLT_CALL_METHYLATION(
        ch_bam,
        ch_bsbolt_db
    )
    ch_versions = ch_versions.mix(BSBOLT_CALL_METHYLATION.out.versions)

    // Collect all CGmap files for aggregation across all samples
    ch_cgmap_collected = BSBOLT_CALL_METHYLATION.out.cgmap
        .map { meta, cgmap -> cgmap }
        .collect()

    // Create a metadata object for the aggregate matrix

    BSBOLT_AGGREGATE_MATRIX(
        ch_cgmap_collected
    )
    ch_versions = ch_versions.mix(BSBOLT_AGGREGATE_MATRIX.out.versions)

    emit:
    cgmap = BSBOLT_CALL_METHYLATION.out.cgmap
    bedgraph = BSBOLT_CALL_METHYLATION.out.bedgraph
    text = BSBOLT_CALL_METHYLATION.out.text
    matrix = BSBOLT_AGGREGATE_MATRIX.out.matrix
    versions = ch_versions
}

