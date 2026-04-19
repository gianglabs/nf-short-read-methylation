process BISMARK_SUMMARY {
    label 'process_low'

    container 'community.wave.seqera.io/library/bismark:0.25.1--1f50935de5d79c47'

    input:
    val (align_report_name)
    val (bam)
    path(align_report)
    path(dedup_report)
    path(splitting_report)
    path(mbias)

    output:
    path ("*report.{html,txt}"), emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    touch ${align_report_name.join(' ')}
    bismark2summary ${bam.join(' ')}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch bismark_summary_report.txt
    touch bismark_summary_report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """
}
