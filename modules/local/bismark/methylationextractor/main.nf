process BISMARK_METHYLATIONEXTRACTOR {
    tag "${meta.id}"
    label 'process_high'

    container 'community.wave.seqera.io/library/bismark:0.25.1--1f50935de5d79c47'

    input:
    tuple val(meta), path(bam)
    path(index)

    output:
    tuple val(meta), path("*.bedGraph.gz"), emit: bedgraph
    tuple val(meta), path("*.txt.gz"), emit: methylation_calls
    tuple val(meta), path("*.cov.gz"), emit: coverage
    tuple val(meta), path("*_splitting_report.txt"), emit: report
    tuple val(meta), path("*.M-bias.txt"), emit: mbias
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    if (!args.contains('--multicore') && task.cpus >= 6) {
        args += " --multicore ${(task.cpus / 3) as int}"
    }
    if (!args.contains('--buffer_size') && task.memory?.giga > 6) {
        args += " --buffer_size ${task.memory.giga - 2}G"
    }

    def seqtype = meta.single_end ? '-s' : '-p'
    """
    bismark_methylation_extractor \\
        ${bam} \\
        --bedGraph \\
        --counts \\
        --gzip \\
        --report \\
        ${seqtype} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo | gzip > ${prefix}.bedGraph.gz
    echo | gzip > ${prefix}.txt.gz
    echo | gzip > ${prefix}.cov.gz
    touch ${prefix}_splitting_report.txt
    touch ${prefix}.M-bias.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """
}
