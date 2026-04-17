process SAMTOOLS_CAT {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/samtools:1.18--h50ea8bc_1'

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path("*_cat.bam"), emit: bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    if (bams instanceof List && bams.size() > 1) {
        """
        samtools cat \
            ${args} \
            -o ${prefix}_cat.bam \
            ${bams.join(' ')}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(samtools --version | head -1 | sed 's/samtools //')
        END_VERSIONS
        """
    }
    else {
        """
        ln -s ${bams[0]} ${prefix}_cat.bam

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(samtools --version | head -1 | sed 's/samtools //')
        END_VERSIONS
        """
    }
}
