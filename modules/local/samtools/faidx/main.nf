process SAMTOOLS_FAIDX {
    tag "${fasta.baseName}"
    label 'process_low'
    container 'quay.io/biocontainers/samtools:1.18--h50ea8bc_1'

    input:
    path fasta

    output:
    path "*.fai", emit: fai
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    samtools faidx ${fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """
}
