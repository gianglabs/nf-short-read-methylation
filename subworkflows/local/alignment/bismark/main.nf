include { BISMARK_ALIGN } from '../../../../modules/local/bismark/align/main'
include { BISMARK_DEDUPLICATE } from '../../../../modules/local/bismark/deduplicate/main'
include { BISMARK_GENOMEPREPARATION } from '../../../../modules/local/bismark/genomepreparation/main'
include { BISMARK_SUMMARY as BISMARK_SUMMARY_ALIGNMENT } from '../../../../modules/local/bismark/summary/main'
include { SORT_MERGE_ALIGNMENT } from '../sort_merge/main'

workflow BISMARK_ALIGNMENT {
    take:
    ch_reads // channel: [ val(meta), [ reads ] ]
    ch_reference // channel: [ path(fasta) ] or [ val(meta), path(fasta) ]
    ch_bismark_index // channel: [ path(index) ] or empty

    main:
    ch_versions = channel.empty()

    // Build bismark index if not supplied
    if (ch_bismark_index) {
        ch_bismark_index = ch_bismark_index
    }
    else {
        BISMARK_GENOMEPREPARATION(
            ch_reference
        )
        ch_bismark_index = BISMARK_GENOMEPREPARATION.out.index
        ch_versions = ch_versions.mix(BISMARK_GENOMEPREPARATION.out.versions)
    }

    // Align with bismark
    BISMARK_ALIGN(
        ch_reads,
        ch_reference,
        BISMARK_GENOMEPREPARATION.out.index,
    )
    ch_versions = ch_versions.mix(BISMARK_ALIGN.out.versions_bismark)

    ch_bam = BISMARK_ALIGN.out.bam
    BISMARK_SUMMARY_ALIGNMENT(
        ch_bam.collect { meta, _bam -> meta.id + "_SE_report.txt" },
        ch_bam.collect { meta, _bam -> meta.id + ".bam" },
        BISMARK_ALIGN.out.report.collect { _meta, report -> report },
        [],
        [],
        [],
    )

    // Sort and merge using samtools
    SORT_MERGE_ALIGNMENT(BISMARK_ALIGN.out.bam, ch_reference)
    ch_versions = ch_versions.mix(SORT_MERGE_ALIGNMENT.out.versions)

    emit:
    bam = SORT_MERGE_ALIGNMENT.out.bam
    bam_raw = BISMARK_ALIGN.out.bam
    index = ch_bismark_index
    versions = ch_versions
}
