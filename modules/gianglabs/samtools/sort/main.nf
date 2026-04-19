process SAMTOOLS_SORT {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/samtools:1.17--hd87286a_2'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*_sorted.bam"), emit: bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = "${meta.read_group}"

    // Handle both single BAM file and list of BAM files
    if (bam instanceof List && bam.size() > 1) {
        """
        # Multiple BAM files: concatenate and sort
        samtools cat \\
            ${bam.join(' ')} \\
            | samtools sort \\
            -@ ${task.cpus} \\
            ${args} \\
            -o ${prefix}_sorted.bam \\
            -
        
        # Create versions file
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(samtools --version | head -1 | sed 's/samtools //')
        END_VERSIONS
        """
    } else {
        """
        # Single BAM file: sort directly
        samtools sort \\
            -@ ${task.cpus} \\
            ${args} \\
            -o ${prefix}_sorted.bam \\
            ${bam}
        
        # Create versions file
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(samtools --version | head -1 | sed 's/samtools //')
        END_VERSIONS
        """
    }
}
