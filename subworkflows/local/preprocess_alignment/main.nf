include { SAMTOOLS_SORT } from '../../../modules/gianglabs/samtools/sort/main'
include { SAMTOOLS_MERGE } from '../../../modules/gianglabs/samtools/merge/main'
include { GATKSPARK_MARKDUPLICATES } from '../../../modules/gianglabs/gatkspark/markduplicates/main'

workflow PREPROCESS_ALIGNMENT {
    take:
    ch_bam // channel: [ val(meta), path(bam) ]
    ch_fasta // path: reference FASTA

    main:
    ch_versions = channel.empty()

    SAMTOOLS_SORT(
        ch_bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions)

    SAMTOOLS_SORT.out.bam
        .map { meta, bam ->
            return [meta.sample, meta, bam]
        }
        .groupTuple()
        .map { _sample_id, metas, bams ->
            return [metas[0], bams]
        }
        .set { ch_bams_to_merge }

    SAMTOOLS_MERGE(
        ch_bams_to_merge,
        ch_fasta,
    )
    ch_versions = ch_versions.mix(SAMTOOLS_MERGE.out.versions)

    GATKSPARK_MARKDUPLICATES(
        SAMTOOLS_MERGE.out.bam
    )
    ch_versions = ch_versions.mix(GATKSPARK_MARKDUPLICATES.out.versions)

    emit:
    bam = GATKSPARK_MARKDUPLICATES.out.bam
    bai = GATKSPARK_MARKDUPLICATES.out.bai
    metrics = GATKSPARK_MARKDUPLICATES.out.metrics
    versions = ch_versions
}
