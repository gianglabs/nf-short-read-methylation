process PICARD_CREATEREFERENCEDICT {
    tag "${fasta.baseName}"
    label 'process_low'
    container 'quay.io/biocontainers/picard:3.1.1--hdfd78af_0'

    input:
    path fasta

    output:
    path "*.dict", emit: dict
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    picard CreateSequenceDictionary \
        R=${fasta} \
        O=${fasta.baseName}.dict

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(picard CreateSequenceDictionary --version 2>&1 | head -1 | sed 's/.*Picard //')
    END_VERSIONS
    """
}
