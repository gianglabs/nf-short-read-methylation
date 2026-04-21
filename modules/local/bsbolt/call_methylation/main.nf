process BSBOLT_CALL_METHYLATION {
    tag "${meta.id}"
    label 'process_medium'
    container "docker.io/nttg8100/bsbolt:1.6.0"

    input:
    tuple val(meta), path(bam), path(bai)
    path db

    output:
    tuple val(meta), path("*.CGmap.gz"), emit: cgmap, optional: true
    tuple val(meta), path("*.bedGraph"), emit: bedgraph, optional: true
    tuple val(meta), path("*.txt"), emit: text, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Output Options
    def text_output = task.ext.text ? '-text' : ''
    def bedgraph_output = task.ext.bedgraph ? '-BG' : ''
    def cpg_only = task.ext.cpg_only ? '-CG' : ''

    // Algorithm Options
    def remove_ccgg = task.ext.remove_ccgg ? '-remove-ccgg' : ''
    def verbose = task.ext.verbose ? '-verbose' : ''
    def ignore_overlap = task.ext.ignore_overlap != null ? (task.ext.ignore_overlap ? '-ignore-ov' : '') : '-ignore-ov'
    def max_depth = task.ext.max_depth ? "-max ${task.ext.max_depth}" : ''
    def min_depth = task.ext.min_depth ? "-min ${task.ext.min_depth}" : ''
    def base_quality = task.ext.base_quality ? "-BQ ${task.ext.base_quality}" : ''
    def mapping_quality = task.ext.mapping_quality ? "-MQ ${task.ext.mapping_quality}" : ''
    def ignore_orphans = task.ext.ignore_orphans ? '-IO' : ''

    """
    bsbolt CallMethylation \\
        -I ${bam} \\
        -DB ${db} \\
        -O ${prefix} \\
        -t ${task.cpus} \\
        ${text_output} \\
        ${bedgraph_output} \\
        ${cpg_only} \\
        ${remove_ccgg} \\
        ${verbose} \\
        ${ignore_overlap} \\
        ${max_depth} \\
        ${min_depth} \\
        ${base_quality} \\
        ${mapping_quality} \\
        ${ignore_orphans} \\
        ${args}

    # Create versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: \$(bsbolt --version 2>&1 | grep -oP 'BSBolt v\\K[0-9.]+')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def text_output = task.ext.text ?: false
    def bedgraph_output = task.ext.bedgraph ?: false

    """
    # Create stub output files
    touch ${prefix}.cgmap
    ${bedgraph_output ? "touch ${prefix}.bedGraph" : ''}
    ${text_output ? "touch ${prefix}.txt" : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: 1.6.0
    END_VERSIONS
    """
}
