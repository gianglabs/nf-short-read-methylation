include { FASTP_TRIM } from '../../../modules/gianglabs/fastp/trim/main'
include { BISMARK_ALIGN } from '../../../modules/local/bismark/align/main'
include { BISMARK_DEDUPLICATE } from '../../../modules/local/bismark/deduplicate/main'
include { SAMTOOLS_SORT } from '../../../modules/local/samtools/sort/main'
include { SAMTOOLS_INDEX } from '../../../modules/local/samtools/index/main'
include { BISMARK_METHYLATIONEXTRACTOR } from '../../../modules/local/bismark/methylationextractor/main'
include { BISMARK_COVERAGE2CYTOSINE } from '../../../modules/local/bismark/coverage2cytosine/main'
include { BISMARK_REPORT } from '../../../modules/local/bismark/report/main'
include { BISMARK_SUMMARY } from '../../../modules/local/bismark/summary/main'
include { BISMARK_GENOMEPREPARATION } from '../../../modules/local/bismark/genomepreparation/main'

workflow BISMARK {
    take:
    ch_reads           // channel: [ val(meta), [ reads ] ]
    ch_fasta           // channel: [ path(fasta) ] or [ val(meta), path(fasta) ]
    ch_bismark_index   // channel: [ path(index) ] or empty
    skip_deduplication // boolean: whether to deduplicate alignments
    cytosine_report    // boolean: whether to run coverage2cytosine

    main:
    ch_alignments                 = channel.empty()
    ch_alignment_reports          = channel.empty()
    ch_methylation_bedgraph       = channel.empty()
    ch_methylation_calls          = channel.empty()
    ch_methylation_coverage       = channel.empty()
    ch_methylation_report         = channel.empty()
    ch_methylation_mbias          = channel.empty()
    ch_coverage2cytosine_coverage = channel.empty()
    ch_coverage2cytosine_report   = channel.empty()
    ch_coverage2cytosine_summary  = channel.empty()
    ch_bismark_report             = channel.empty()
    ch_bismark_summary            = channel.empty()
    ch_multiqc_files              = channel.empty()
    ch_versions                   = channel.empty()

    // Ensure fasta is a tuple channel with meta
    ch_fasta = ch_fasta.map { it instanceof Tuple ? it : [ [id: 'reference', sample: 'reference'], it ] }

    // Trim with fastp (replaces fastqc + trimgalore)
    FASTP_TRIM(
        ch_reads
    )
    ch_trimmed_reads = FASTP_TRIM.out.reads
    ch_versions      = ch_versions.mix(FASTP_TRIM.out.versions)

    // Build bismark index if not supplied
    if (ch_bismark_index) {
        ch_bismark_index = ch_bismark_index.map { it instanceof Tuple ? it : [ [id: 'bismark_index', sample: 'bismark_index'], it ] }
    } else {
        BISMARK_GENOMEPREPARATION(
            ch_fasta
        )
        ch_bismark_index = BISMARK_GENOMEPREPARATION.out.index
        ch_versions      = ch_versions.mix(BISMARK_GENOMEPREPARATION.out.versions)
    }

    // Broadcast reference/index to each sample
    ch_bismark_inputs = ch_trimmed_reads
        .combine(ch_fasta)
        .combine(ch_bismark_index)
        .multiMap { meta, reads, meta_fasta, fasta, meta_bismark, bismark_index ->
            reads: [ meta, reads ]
            fasta: [ meta_fasta, fasta ]
            bismark_index: [ meta_bismark, bismark_index ]
        }

    // Align with bismark
    BISMARK_ALIGN(
        ch_bismark_inputs.reads,
        ch_bismark_inputs.fasta,
        ch_bismark_inputs.bismark_index
    )
    ch_alignments        = BISMARK_ALIGN.out.bam
    ch_alignment_reports = BISMARK_ALIGN.out.report.map { meta, report -> [ meta, report, [] ] }
    ch_versions          = ch_versions.mix(BISMARK_ALIGN.out.versions_bismark)

    if (!skip_deduplication) {
        BISMARK_DEDUPLICATE(
            BISMARK_ALIGN.out.bam
        )
        ch_alignments        = BISMARK_DEDUPLICATE.out.bam
        ch_alignment_reports = BISMARK_ALIGN.out.report.join(BISMARK_DEDUPLICATE.out.report)
        ch_versions          = ch_versions.mix(BISMARK_DEDUPLICATE.out.versions)
    }

    // Sort + index
    SAMTOOLS_SORT(
        ch_alignments,
        [[:],[]],
        ''
    )

    SAMTOOLS_INDEX(
        SAMTOOLS_SORT.out.bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    // Methylation extraction
    BISMARK_METHYLATIONEXTRACTOR(
        ch_alignments,
        ch_bismark_inputs.bismark_index
    )
    ch_methylation_bedgraph = BISMARK_METHYLATIONEXTRACTOR.out.bedgraph
    ch_methylation_calls    = BISMARK_METHYLATIONEXTRACTOR.out.methylation_calls
    ch_methylation_coverage = BISMARK_METHYLATIONEXTRACTOR.out.coverage
    ch_methylation_report   = BISMARK_METHYLATIONEXTRACTOR.out.report
    ch_methylation_mbias    = BISMARK_METHYLATIONEXTRACTOR.out.mbias
    ch_versions             = ch_versions.mix(BISMARK_METHYLATIONEXTRACTOR.out.versions)

    // Coverage2cytosine
    if (cytosine_report) {
        BISMARK_COVERAGE2CYTOSINE(
            ch_methylation_coverage,
            ch_bismark_inputs.fasta,
            ch_bismark_inputs.bismark_index
        )
        ch_coverage2cytosine_coverage = BISMARK_COVERAGE2CYTOSINE.out.coverage
        ch_coverage2cytosine_report   = BISMARK_COVERAGE2CYTOSINE.out.report
        ch_coverage2cytosine_summary  = BISMARK_COVERAGE2CYTOSINE.out.summary
        ch_versions                   = ch_versions.mix(BISMARK_COVERAGE2CYTOSINE.out.versions)
    }

    // Reports
    ch_bismark_report = channel.empty()
    if (!params.skip_bismark_report) {
        BISMARK_REPORT(
            ch_alignment_reports
                .join(ch_methylation_report)
                .join(ch_methylation_mbias)
        )
        ch_bismark_report = BISMARK_REPORT.out.report
        ch_versions       = ch_versions.mix(BISMARK_REPORT.out.versions)
    }

    BISMARK_SUMMARY(
        BISMARK_ALIGN.out.bam.collect { _meta, bam -> bam.name },
        ch_alignment_reports.collect { _meta, align_report, _dedup_report -> align_report },
        ch_alignment_reports.collect { _meta, _align_report, dedup_report -> dedup_report }.ifEmpty([]),
        ch_methylation_report.collect { _meta, report -> report },
        ch_methylation_mbias.collect { _meta, mbias -> mbias }
    )
    ch_bismark_summary = BISMARK_SUMMARY.out.summary
    ch_versions        = ch_versions.mix(BISMARK_SUMMARY.out.versions)

    ch_multiqc_files = ch_bismark_summary
        .mix(ch_alignment_reports.collect { _meta, align_report, _dedup_report -> align_report })
        .mix(ch_alignment_reports.collect { _meta, _align_report, dedup_report -> dedup_report })
        .mix(ch_methylation_report.collect { _meta, report -> report })
        .mix(ch_methylation_mbias.collect { _meta, mbias -> mbias })
        .mix(ch_bismark_report.collect { _meta, report -> report }.ifEmpty([]))

    emit:
    bam                        = SAMTOOLS_SORT.out.bam
    bai                        = SAMTOOLS_INDEX.out.bai
    coverage2cytosine_coverage = ch_coverage2cytosine_coverage
    coverage2cytosine_report   = ch_coverage2cytosine_report
    coverage2cytosine_summary  = ch_coverage2cytosine_summary
    methylation_bedgraph       = ch_methylation_bedgraph
    methylation_calls          = ch_methylation_calls
    methylation_coverage       = ch_methylation_coverage
    methylation_report         = ch_methylation_report
    methylation_mbias          = ch_methylation_mbias
    bismark_report             = ch_bismark_report
    bismark_summary            = ch_bismark_summary
    multiqc                    = ch_multiqc_files
    versions                   = ch_versions
}
