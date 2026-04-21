include { BSBOLT_INDEX } from '../../../../modules/local/bsbolt/index/main'
include { BSBOLT_ALIGN } from '../../../../modules/local/bsbolt/align/main'
include { SORT_MERGE_ALIGNMENT } from '../sort_merge/main'

workflow BSBOLT_ALIGNMENT {
    take:
    reads_ch // channel: [ val(meta), [ path(read1), path(read2) ] ]
    ref_fasta // path: reference FASTA
    index_bsbolt_reference // boolean: whether to create index
    bsbolt_index // channel: Optional bsbolt index files (if not creating)

    main:
    ch_versions = channel.empty()

    // Create or use existing bsbolt index
    if (index_bsbolt_reference) {
        BSBOLT_INDEX(
            ref_fasta
        )
        ch_versions = ch_versions.mix(BSBOLT_INDEX.out.versions)
        bsbolt_index_ch = BSBOLT_INDEX.out.index
    }
    else {
        bsbolt_index_ch = channel.fromPath(bsbolt_index).collect()
    }

    // Combine reads with index
    ch_bsbolt_inputs = reads_ch.combine(bsbolt_index_ch)

    // Align reads - split the combined channel back into separate inputs
    BSBOLT_ALIGN(
        ch_bsbolt_inputs.map { meta, reads, db -> [meta, reads] },
        ch_bsbolt_inputs.map { meta, reads, db -> db },
    )
    ch_versions = ch_versions.mix(BSBOLT_ALIGN.out.versions)

    // Sort and merge alignments
    SORT_MERGE_ALIGNMENT(
        BSBOLT_ALIGN.out.bam,
        ref_fasta,
    )
    ch_versions = ch_versions.mix(SORT_MERGE_ALIGNMENT.out.versions)

    emit:
    bam = SORT_MERGE_ALIGNMENT.out.bam
    bai = SORT_MERGE_ALIGNMENT.out.bai
    cram = SORT_MERGE_ALIGNMENT.out.cram
    crai = SORT_MERGE_ALIGNMENT.out.crai
    bsbolt_db = bsbolt_index_ch
    versions = ch_versions
}
