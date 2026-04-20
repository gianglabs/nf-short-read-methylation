include { BISMARK_METHYLATIONEXTRACTOR } from '../../../../modules/local/bismark/methylationextractor/main'
include { BISMARK_COVERAGE2CYTOSINE } from '../../../../modules/local/bismark/coverage2cytosine/main'
// include { BISMARK_REPORT } from '../../../../modules/local/bismark/report/main' // for multi lanes samples, it will be failed
include { BISMARK_SUMMARY as BISMARK_SUMMARY_SAMPLE } from '../../../../modules/local/bismark/summary/main'

workflow BISMARK_METHYLATION_CALLING {
    take:
    ch_bam // channel: [ val(meta), path(bam) ]
    ch_dedup_report // channel: [ val(meta), path(dedup_report) ]
    ch_fasta // channel: [ path(fasta) ] or [ val(meta), path(fasta) ]
    ch_bismark_index // channel: [ path(index) ] or empty

    main:
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
    ch_versions = channel.empty()

    BISMARK_METHYLATIONEXTRACTOR(
        ch_bam,
        ch_bismark_index,
    )
    ch_methylation_bedgraph = BISMARK_METHYLATIONEXTRACTOR.out.bedgraph
    ch_methylation_calls = BISMARK_METHYLATIONEXTRACTOR.out.methylation_calls
    ch_methylation_coverage = BISMARK_METHYLATIONEXTRACTOR.out.coverage
    ch_methylation_report = BISMARK_METHYLATIONEXTRACTOR.out.report
    ch_methylation_mbias = BISMARK_METHYLATIONEXTRACTOR.out.mbias
    ch_versions = ch_versions.mix(BISMARK_METHYLATIONEXTRACTOR.out.versions)

    // Coverage2cytosine
    BISMARK_COVERAGE2CYTOSINE(
        ch_methylation_coverage,
        ch_fasta,
        ch_bismark_index,
    )
    ch_coverage2cytosine_coverage = BISMARK_COVERAGE2CYTOSINE.out.coverage
    ch_coverage2cytosine_report = BISMARK_COVERAGE2CYTOSINE.out.report
    ch_coverage2cytosine_summary = BISMARK_COVERAGE2CYTOSINE.out.summary
    ch_versions = ch_versions.mix(BISMARK_COVERAGE2CYTOSINE.out.versions)

    // Summary 
    BISMARK_SUMMARY_SAMPLE(
        ch_bam.collect { meta, _bam -> meta.id + "_SE_report.txt" },
        ch_bam.collect { meta, _bam -> meta.id + ".bam" },
        [],
        ch_dedup_report.collect { _meta, dedup_report -> dedup_report },
        ch_methylation_report.collect { _meta, report -> report },
        ch_methylation_mbias.collect { _meta, mbias -> mbias },
    )
    ch_bismark_summary = BISMARK_SUMMARY_SAMPLE.out.summary
    ch_versions = ch_versions.mix(BISMARK_SUMMARY_SAMPLE.out.versions)

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
    versions = ch_versions
}
