process CAT_FASTQ {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/samtools:1.18--h50ea8bc_1'

    input:
    tuple val(meta), val(read_end), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: fastq
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def end_suffix = read_end ? "_${read_end}" : ''
    def output_name = "${prefix}${end_suffix}_cat.fastq.gz"
    if (reads instanceof List && reads.size() > 1) {
        """
        zcat -f ${reads.join(' ')} | gzip -c > ${output_name}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            gzip: \$(gzip --version 2>&1 | head -1 | sed 's/gzip //')
        END_VERSIONS
        """
    }
    else {
        """
        cp -L ${reads[0]} ${output_name}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            gzip: \$(gzip --version 2>&1 | head -1 | sed 's/gzip //')
        END_VERSIONS
        """
    }
}
