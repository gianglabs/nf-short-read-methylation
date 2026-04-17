process BISMARK_COVERAGE2CYTOSINE {
    tag "${meta.id}"
    label 'process_low'

    container 'community.wave.seqera.io/library/bismark:0.25.1--1f50935de5d79c47'

    input:
    tuple val(meta), path(coverage_file)
    tuple val(meta2), path(fasta, stageAs: 'tmp/*')
    tuple val(meta3), path(index)

    output:
    tuple val(meta), path("*.cov.gz"), emit: coverage, optional: true
    tuple val(meta), path("*report.txt.gz"), emit: report
    tuple val(meta), path("*cytosine_context_summary.txt"), emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    coverage2cytosine \\
        ${coverage_file} \\
        --genome ${index} \\
        --output ${prefix} \\
        --gzip \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo | gzip > ${prefix}.cov.gz
    echo | gzip > ${prefix}.report.txt.gz
    touch ${prefix}.cytosine_context_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """
}
