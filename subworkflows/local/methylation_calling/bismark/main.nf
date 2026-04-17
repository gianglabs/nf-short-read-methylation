include { BISMARK_METHYLATIONEXTRACTOR } from '../../../../modules/local/bismark/methylationextractor/main'
include { BISMARK_COVERAGE2CYTOSINE } from '../../../../modules/local/bismark/coverage2cytosine/main'
include { BISMARK_REPORT } from '../../../../modules/local/bismark/report/main'
include { BISMARK_SUMMARY } from '../../../../modules/local/bismark/summary/main'


workflow BISMARK_METHYLATION_CALLING {
    take:
    ch_bam // channel: [ val(meta), path(bam) ]
    ch_alignment_reports // channel: [ val(meta), path(align_report), path(dedup_report) ]
    ch_bam_report // channel: [ val(meta), path(bam) ]
    ch_fasta // channel: [ path(fasta) ] or [ val(meta), path(fasta) ]
    ch_bismark_index // channel: [ path(index) ] or empty
    cytosine_report // boolean: whether to run coverage2cytosine

    main:
    ch_bismark_index_out = channel.empty()
    ch_methylation_bedgraph = channel.empty()
    ch_methylation_calls = channel.empty()
    ch_methylation_coverage = channel.empty()
    ch_methylation_report = channel.empty()
    ch_methylation_mbias = channel.empty()
    ch_coverage2cytosine_coverage = channel.empty()
    ch_coverage2cytosine_report = channel.empty()
    ch_coverage2cytosine_summary = channel.empty()
    ch_bismark_report = channel.empty()
    ch_bismark_summary = channel.empty()
    ch_multiqc_files = channel.empty()
    ch_versions = channel.empty()


    // Methylation extraction
    ch_bismark_index_out = ch_bismark_index.map { value ->
        if (value instanceof Tuple || value instanceof List) {
            return value
        }
        return [[id: 'bismark_index', sample: 'bismark_index'], value]
    }

    BISMARK_METHYLATIONEXTRACTOR(
        ch_bam,
        ch_bismark_index_out,
    )
    ch_methylation_bedgraph = BISMARK_METHYLATIONEXTRACTOR.out.bedgraph
    ch_methylation_calls = BISMARK_METHYLATIONEXTRACTOR.out.methylation_calls
    ch_methylation_coverage = BISMARK_METHYLATIONEXTRACTOR.out.coverage
    ch_methylation_report = BISMARK_METHYLATIONEXTRACTOR.out.report
    ch_methylation_mbias = BISMARK_METHYLATIONEXTRACTOR.out.mbias
    ch_versions = ch_versions.mix(BISMARK_METHYLATIONEXTRACTOR.out.versions)

    // Coverage2cytosine
    if (cytosine_report) {
        BISMARK_COVERAGE2CYTOSINE(
            ch_methylation_coverage,
            ch_fasta,
            ch_bismark_index_out,
        )
        ch_coverage2cytosine_coverage = BISMARK_COVERAGE2CYTOSINE.out.coverage
        ch_coverage2cytosine_report = BISMARK_COVERAGE2CYTOSINE.out.report
        ch_coverage2cytosine_summary = BISMARK_COVERAGE2CYTOSINE.out.summary
        ch_versions = ch_versions.mix(BISMARK_COVERAGE2CYTOSINE.out.versions)
    }

    // Reports
    ch_bismark_report = channel.empty()
    if (!params.skip_bismark_report) {
        BISMARK_REPORT(
            ch_alignment_reports.join(ch_methylation_report).join(ch_methylation_mbias)
        )
        ch_bismark_report = BISMARK_REPORT.out.report
        ch_versions = ch_versions.mix(BISMARK_REPORT.out.versions)
    }

    BISMARK_SUMMARY(
        ch_bam_report.collect { _meta, bam -> bam.name },
        ch_alignment_reports.collect { _meta, align_report, _dedup_report -> align_report },
        ch_alignment_reports.collect { _meta, _align_report, dedup_report -> dedup_report }.ifEmpty([]),
        ch_methylation_report.collect { _meta, report -> report },
        ch_methylation_mbias.collect { _meta, mbias -> mbias },
    )
    ch_bismark_summary = BISMARK_SUMMARY.out.summary
    ch_versions = ch_versions.mix(BISMARK_SUMMARY.out.versions)

    ch_multiqc_files = ch_bismark_summary
        .mix(ch_alignment_reports.collect { _meta, align_report, _dedup_report -> align_report })
        .mix(ch_alignment_reports.collect { _meta, _align_report, dedup_report -> dedup_report })
        .mix(ch_methylation_report.collect { _meta, report -> report })
        .mix(ch_methylation_mbias.collect { _meta, mbias -> mbias })
        .mix(ch_bismark_report.collect { _meta, report -> report }.ifEmpty([]))

    emit:
    bam = ch_bam
    coverage2cytosine_coverage = ch_coverage2cytosine_coverage
    coverage2cytosine_report = ch_coverage2cytosine_report
    coverage2cytosine_summary = ch_coverage2cytosine_summary
    methylation_bedgraph = ch_methylation_bedgraph
    methylation_calls = ch_methylation_calls
    methylation_coverage = ch_methylation_coverage
    methylation_report = ch_methylation_report
    methylation_mbias = ch_methylation_mbias
    bismark_report = ch_bismark_report
    bismark_summary = ch_bismark_summary
    multiqc = ch_multiqc_files
    versions = ch_versions
}
