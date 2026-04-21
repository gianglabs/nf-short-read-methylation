process BSBOLT_ALIGN {
    tag "${meta.id}"
    label 'process_high'
    container "docker.io/nttg8100/bsbolt:1.6.0"

    input:
    tuple val(meta), path(reads)
    path db

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.bai"), emit: bai, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Input/Output Options
    def f1 = reads[0]
    def f2 = reads.size() > 1 && reads[1] != null && reads[1].toString() != 'null' ? "-F2 ${reads[1]}" : ''
    def os_arg = task.ext.os ? '-OS' : ''
    def ot_arg = task.ext.ot ? "-OT ${task.ext.ot}" : '-OT 1'
    def read_group = task.ext.read_group ? "-R '${task.ext.read_group}'" : ''
    def header = task.ext.header ? "-H ${task.ext.header}" : ''
    def xa_arg = task.ext.xa ? "-XA ${task.ext.xa}" : ''
    def dr_arg = task.ext.dr ? "-DR ${task.ext.dr}" : ''
    def pairing = task.ext.smart_pairing ? '-p' : ''

    // Scoring Options
    def score_match = task.ext.score_match ? "-A ${task.ext.score_match}" : ''
    def score_mismatch = task.ext.score_mismatch ? "-B ${task.ext.score_mismatch}" : ''
    def indel_penalty = task.ext.indel_penalty ? "-INDEL ${task.ext.indel_penalty}" : ''
    def gap_ext = task.ext.gap_ext ? "-E ${task.ext.gap_ext}" : ''
    def clip_penalty = task.ext.clip_penalty ? "-L ${task.ext.clip_penalty}" : ''
    def unpaired_penalty = task.ext.unpaired_penalty ? "-U ${task.ext.unpaired_penalty}" : ''

    // Bisulfite Options
    def undirectional = task.ext.undirectional ? '-UN' : ''
    def ch_conversion = task.ext.ch_conversion ? "-CP ${task.ext.ch_conversion}" : ''
    def ch_sites = task.ext.ch_sites ? "-CT ${task.ext.ch_sites}" : ''
    def substitution_threshold = task.ext.substitution_threshold ? "-SP ${task.ext.substitution_threshold}" : ''

    // Algorithm Options
    def seed_length = task.ext.seed_length ? "-k ${task.ext.seed_length}" : ''
    def band_width = task.ext.band_width ? "-w ${task.ext.band_width}" : ''
    def diagonal_drop = task.ext.diagonal_drop ? "-d ${task.ext.diagonal_drop}" : ''
    def internal_seed = task.ext.internal_seed ? "-r ${task.ext.internal_seed}" : ''
    def seed_occ = task.ext.seed_occ ? "-y ${task.ext.seed_occ}" : ''
    def max_seed_occ = task.ext.max_seed_occ ? "-c ${task.ext.max_seed_occ}" : ''
    def chain_drop = task.ext.chain_drop ? "-D ${task.ext.chain_drop}" : ''
    def chain_min = task.ext.chain_min ? "-W ${task.ext.chain_min}" : ''
    def mate_rescue = task.ext.mate_rescue ? "-m ${task.ext.mate_rescue}" : ''
    def skip_mate_rescue = task.ext.skip_mate_rescue ? '-S' : ''
    def skip_pairing = task.ext.skip_pairing ? '-P' : ''
    def ignore_alt = task.ext.ignore_alt ? '-j' : ''
    def min_score = task.ext.min_score ? "-T ${task.ext.min_score}" : ''
    def mark_secondary = task.ext.mark_secondary ? '-M' : ''
    def insert_size = task.ext.insert_size ? "-I ${task.ext.insert_size}" : ''

    """
    export PATH="/root/.pixi/bin:/root/.pixi/envs/default/bin:\${PATH}"
    
    bsbolt Align \\
        -F1 ${f1} \\
        ${f2} \\
        -O ${prefix} \\
        -DB ${db} \\
        -t ${task.cpus}  \\
        ${os_arg} \\
        ${ot_arg} \\
        ${read_group} \\
        ${header} \\
        ${xa_arg} \\
        ${dr_arg} \\
        ${pairing} \\
        ${score_match} \\
        ${score_mismatch} \\
        ${indel_penalty} \\
        ${gap_ext} \\
        ${clip_penalty} \\
        ${unpaired_penalty} \\
        ${undirectional} \\
        ${ch_conversion} \\
        ${ch_sites} \\
        ${substitution_threshold} \\
        ${seed_length} \\
        ${band_width} \\
        ${diagonal_drop} \\
        ${internal_seed} \\
        ${seed_occ} \\
        ${max_seed_occ} \\
        ${chain_drop} \\
        ${chain_min} \\
        ${mate_rescue} \\
        ${skip_mate_rescue} \\
        ${skip_pairing} \\
        ${ignore_alt} \\
        ${min_score} \\
        ${mark_secondary} \\
        ${insert_size} \\
        ${args}

    # Create versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: \$(bsbolt --version 2>&1 | grep -oP 'BSBolt v\\K[0-9.]+')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Create stub BAM file
    touch ${prefix}.bam
    touch ${prefix}.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bsbolt: 1.6.0
    END_VERSIONS
    """
}
