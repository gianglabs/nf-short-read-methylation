process BSBOLT_AGGREGATE_MATRIX {
    tag "all"
    label 'process_medium'
    container "docker.io/nttg8100/bsbolt:1.6.0"

    input:
    path(cgmap_files)

    output:
    path("*.txt"), emit: matrix
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    // Output Options
    def cgonly = task.ext.cgonly ? '-CG' : ''
    def count_matrix = task.ext.count_matrix ? '-count' : ''
    def verbose = task.ext.verbose ? '-verbose' : ''
    
    // Algorithm Options
    def min_coverage = task.ext.min_coverage ? "-min-coverage ${task.ext.min_coverage}" : ''
    def min_sample = task.ext.min_sample ? "-min-sample ${task.ext.min_sample}" : ''
    
    // Build the file list argument
    def file_arg = cgmap_files.collect { it.toString() }.join(',')
    
    // Build sample labels argument if provided
    def sample_labels_arg = task.ext.sample_labels ? "-S ${task.ext.sample_labels}" : ''

    """
    bsbolt AggregateMatrix \\
        -F ${file_arg} \\
        -O aggregated_matrix.txt \\
        -t ${task.cpus}  \\
        ${cgonly} \\
        ${count_matrix} \\
        ${verbose} \\
        ${min_coverage} \\
        ${min_sample} \\
        ${sample_labels_arg} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: \$(bsbolt --version 2>&1 | grep -oP 'BSBolt v\\K[0-9.]+')
    END_VERSIONS
    """

    stub:
    """
    touch aggregated_matrix.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: 1.6.0
    END_VERSIONS
    """
}
