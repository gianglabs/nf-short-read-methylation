include { BISMARK_ALIGN } from '../../../../modules/local/bismark/align/main'
include { BISMARK_DEDUPLICATE } from '../../../../modules/local/bismark/deduplicate/main'
include { BISMARK_GENOMEPREPARATION } from '../../../../modules/local/bismark/genomepreparation/main'

workflow BISMARK_ALIGNMENT {
    take:
    ch_reads // channel: [ val(meta), [ reads ] ]
    ch_fasta // channel: [ path(fasta) ] or [ val(meta), path(fasta) ]
    ch_bismark_index // channel: [ path(index) ] or empty

    main:
    ch_alignment_reports = channel.empty()
    ch_versions = channel.empty()

    // Ensure fasta is a tuple channel with meta
    ch_fasta = ch_fasta.map { value ->
        if (value instanceof Tuple) {
            return value
        }
        if (value instanceof List && value.size() == 2 && value[0] instanceof Map) {
            return value
        }
        return [[id: 'reference', sample: 'reference'], value]
    }

    // Build bismark index if not supplied
    if (ch_bismark_index) {
        ch_bismark_index = ch_bismark_index.map { value ->
            if (value instanceof Tuple) {
                return value
            }
            return [[id: 'bismark_index', sample: 'bismark_index'], value]
        }
    }
    else {
        BISMARK_GENOMEPREPARATION(
            ch_fasta
        )
        ch_bismark_index = BISMARK_GENOMEPREPARATION.out.index
        ch_versions = ch_versions.mix(BISMARK_GENOMEPREPARATION.out.versions)
    }

    // Broadcast reference/index to each sample
    ch_bismark_inputs = ch_reads
        .combine(ch_fasta)
        .combine(ch_bismark_index)
        .multiMap { meta, reads, meta_fasta, fasta, meta_bismark, bismark_index ->
            reads: [meta, reads]
            fasta: [meta_fasta, fasta]
            bismark_index: [meta_bismark, bismark_index]
        }

    // Align with bismark
    BISMARK_ALIGN(
        ch_bismark_inputs.reads,
        ch_bismark_inputs.fasta,
        ch_bismark_inputs.bismark_index,
    )
    ch_alignment_reports = BISMARK_ALIGN.out.report.map { meta, report -> [meta, report, []] }
    ch_versions = ch_versions.mix(BISMARK_ALIGN.out.versions_bismark)

    BISMARK_DEDUPLICATE(
        BISMARK_ALIGN.out.bam
    )

    ch_alignment_reports = BISMARK_ALIGN.out.report.join(BISMARK_DEDUPLICATE.out.report)
    ch_versions = ch_versions.mix(BISMARK_DEDUPLICATE.out.versions)

    emit:
    bam = BISMARK_DEDUPLICATE.out.bam
    bam_raw = BISMARK_ALIGN.out.bam
    bam_name = BISMARK_DEDUPLICATE.out.bam
    alignment_reports = ch_alignment_reports
    bismark_index = ch_bismark_index
    versions = ch_versions
}
