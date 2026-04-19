process BISMARK_GENOMEPREPARATION {
    tag "${fasta}"
    label 'process_high'

    container 'community.wave.seqera.io/library/bismark:0.25.1--1f50935de5d79c47'

    input:
    path(fasta)

    output:
    path("BismarkIndex"), emit: index
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def fasta_name = file(fasta).getName()
    def fasta_basename = fasta_name.endsWith('.gz') ? fasta_name.replaceAll(/\.gz$/, '') : fasta_name
    def unpack_cmd = fasta_name.endsWith('.gz')
        ? "gzip -dc ${fasta} > ${fasta_basename} && mkdir -p BismarkIndex && mv ${fasta_basename} BismarkIndex/"
        : "mkdir -p BismarkIndex && cp ${fasta} BismarkIndex/${fasta_basename}"
    """
    ${unpack_cmd}

    bismark_genome_preparation \\
        ${args} \\
        BismarkIndex

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """

    stub:
    """
    rm ${fasta}

    mkdir -p BismarkIndex/Bisulfite_Genome/CT_conversion
    touch BismarkIndex/Bisulfite_Genome/CT_conversion/BS_CT.1.bt2
    touch BismarkIndex/Bisulfite_Genome/CT_conversion/BS_CT.2.bt2
    touch BismarkIndex/Bisulfite_Genome/CT_conversion/BS_CT.3.bt2
    touch BismarkIndex/Bisulfite_Genome/CT_conversion/BS_CT.4.bt2
    touch BismarkIndex/Bisulfite_Genome/CT_conversion/BS_CT.rev.1.bt2
    touch BismarkIndex/Bisulfite_Genome/CT_conversion/BS_CT.rev.2.bt2
    touch BismarkIndex/Bisulfite_Genome/CT_conversion/genome_mfa.CT_conversion.fa

    mkdir -p BismarkIndex/Bisulfite_Genome/GA_conversion
    touch BismarkIndex/Bisulfite_Genome/GA_conversion/BS_GA.1.bt2
    touch BismarkIndex/Bisulfite_Genome/GA_conversion/BS_GA.2.bt2
    touch BismarkIndex/Bisulfite_Genome/GA_conversion/BS_GA.3.bt2
    touch BismarkIndex/Bisulfite_Genome/GA_conversion/BS_GA.4.bt2
    touch BismarkIndex/Bisulfite_Genome/GA_conversion/BS_GA.rev.1.bt2
    touch BismarkIndex/Bisulfite_Genome/GA_conversion/BS_GA.rev.2.bt2
    touch BismarkIndex/Bisulfite_Genome/GA_conversion/genome_mfa.GA_conversion.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """
}
