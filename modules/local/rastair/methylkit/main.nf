process RASTAIR_METHYLKIT {
    tag "${meta.id}"
    label 'process_low'

    container 'community.wave.seqera.io/library/rastair:0.8.2--bf70eeab4121509c'

    input:
    tuple val(meta), path(rastair_call_txt)

    output:
    tuple val(meta), path("*methylkit.txt.gz"), emit: methylkit
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cat ${rastair_call_txt} | rastair_call_to_methylkit.sh | gzip -c > ${prefix}.rastair_methylkit.txt.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rastair: \$(rastair --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.methylkit.txt.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rastair: \$(rastair --version 2>&1 || echo "stub")
    END_VERSIONS
    """
}
