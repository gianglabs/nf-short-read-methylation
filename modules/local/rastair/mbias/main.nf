process RASTAIR_MBIAS {
    tag "${meta.id}"
    label 'process_medium'

    container 'community.wave.seqera.io/library/rastair:0.8.2--bf70eeab4121509c'

    input:
    tuple val(meta), path(bam)
    tuple val(meta2), path(bai)
    path fasta
    path fai

    output:
    tuple val(meta), path("*.rastair_mbias.txt"), emit: txt
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    rastair mbias \\
        --threads ${task.cpus} \\
        --fasta-file ${fasta} \\
        ${bam} > ${prefix}.rastair_mbias.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rastair: \$(rastair --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.rastair_mbias.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rastair: \$(rastair --version 2>&1 || echo "stub")
    END_VERSIONS
    """
}
