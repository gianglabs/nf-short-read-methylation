process FASTP_TRIM {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/fastp:1.1.0--heae3180_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_trimmed_*.fastq.gz"), emit: reads
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.json"), emit: json
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.read_group}"
    def paired = reads.size() == 2
    def in2 = paired ? "--in2 ${reads[1]}" : ''
    def out2 = paired ? "--out2 ${prefix}_trimmed_2.fastq.gz" : ''
    def pe_adapter = paired ? "--detect_adapter_for_pe" : ''

    """
    # Adapter trimming, quality filtering, and QC with fastp
    fastp \\
        --thread ${task.cpus} \\
        --in1 ${reads[0]} \\
        ${in2} \\
        --out1 ${prefix}_trimmed_1.fastq.gz \\
        ${out2} \\
        --html ${prefix}_fastp.html \\
        --json ${prefix}_fastp.json \\
        --qualified_quality_phred 20 \\
        ${pe_adapter} \\
        ${args}
    
    # Create versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | grep -oP 'fastp \\K[0-9.]+')
    END_VERSIONS
    """
}
