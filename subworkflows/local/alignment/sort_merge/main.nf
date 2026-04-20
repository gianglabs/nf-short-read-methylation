include { SAMTOOLS_SORT } from '../../../../modules/gianglabs/samtools/sort/main'
include { SAMTOOLS_MERGE } from '../../../../modules/gianglabs/samtools/merge/main'

workflow SORT_MERGE_ALIGNMENT {
    take:
    ch_bam // channel (mandatory): [ val(meta), [ path(reads) ] ]
    ref_fasta // path: reference FASTA

    main:
    ch_versions = channel.empty()

    // Group BAM files by sample ID (meta.id)
    // groupTuple() by default groups by the first element when it's a map
    // We need to extract meta.id for grouping
    SAMTOOLS_SORT(
        ch_bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions)

    ch_group_by_bam = SAMTOOLS_SORT.out.bam
        .map { meta, bam ->
            [meta.id, meta, bam]
        }
        .groupTuple(by: 0)
        .map { id, metas, bams ->
            def grouped_meta = metas[0]
            def flat_bams = bams.flatten()
            [grouped_meta, flat_bams]
        }


    SAMTOOLS_MERGE(
        ch_group_by_bam,
        ref_fasta,
    )
    ch_versions = ch_versions.mix(SAMTOOLS_MERGE.out.versions)

    emit:
    bam = SAMTOOLS_MERGE.out.bam
    bai = SAMTOOLS_MERGE.out.bai
    cram = SAMTOOLS_MERGE.out.cram
    crai = SAMTOOLS_MERGE.out.crai
    versions = ch_versions
}
