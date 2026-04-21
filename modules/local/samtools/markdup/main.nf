process SAMTOOLS_MARKDUP {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/samtools:1.18--h50ea8bc_1'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.dup.bam"), emit: bam
    tuple val(meta), path("*.dup.bam.bai"), emit: bai
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args_fixmate = task.ext.args_fixmate ?: '-p -m'
    def args_sort_threads = task.ext.args_sort_threads ?: '-@ 2'
    def args_markdup = task.ext.args_markdup ?: ''

    """
    # Sort by queryname for fixmate (input BAM is coordinate-sorted from aligner)
    samtools sort -@ ${task.cpus}  -n ${args_sort_threads} -o ${prefix}.qname.bam ${bam}

    # fixmates to prepare for duplicate removal, use -p to disable proper pair check
    samtools fixmate ${args_fixmate} ${prefix}.qname.bam ${prefix}.fixmates.bam

    # sort bam by coordinates for duplicate calling
    samtools sort -@ ${task.cpus}  ${args_sort_threads} -o ${prefix}.sorted.bam ${prefix}.fixmates.bam

    # remove duplicate reads
    samtools markdup ${args_markdup} ${prefix}.sorted.bam ${prefix}.dup.bam

    # index bam file for methylation calling
    samtools index ${prefix}.dup.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.dup.bam
    touch ${prefix}.dup.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: 1.18
    END_VERSIONS
    """
}
