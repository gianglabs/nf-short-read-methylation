process BSBOLT_INDEX {
    tag "${fasta}"
    label 'process_high'
    container "docker.io/nttg8100/bsbolt:1.6.0"

    input:
    path fasta

    output:
    path "bsbolt_index/", emit: index
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    # Pre-create the output directory with proper permissions
    mkdir -p bsbolt_index
    chmod 777 bsbolt_index
    
    # Set environment for pixi
    export PATH="/root/.pixi/bin:/root/.pixi/envs/default/bin:\${PATH}"
    
    # Build bsbolt index command
    bsbolt Index \\
        -G ${fasta} \\
        -DB bsbolt_index \\
        ${args}

    # Fix final permissions
    chmod -R 777 bsbolt_index || true
    
    # Create versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: \$(bsbolt --version 2>&1 | grep -oP 'BSBolt v\\K[0-9.]+')
    END_VERSIONS
    """

    stub:
    """
    # Create output directory structure
    mkdir -p bsbolt_index
    
    # Create stub index files
    touch bsbolt_index/genome.fa.amb
    touch bsbolt_index/genome.fa.ann
    touch bsbolt_index/genome.fa.bwt
    touch bsbolt_index/genome.fa.pac
    touch bsbolt_index/genome.fa.sa
    touch bsbolt_index/bsbolt_config.json
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: 1.3.8
    END_VERSIONS
    """
}
