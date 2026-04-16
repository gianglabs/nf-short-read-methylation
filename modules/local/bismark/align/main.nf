process BISMARK_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/bismark:0.25.1--1f50935de5d79c47'

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(fasta, stageAs: 'tmp/*')
    tuple val(meta3), path(index)

    output:
    tuple val(meta), path("*bam")       , emit: bam
    tuple val(meta), path("*report.txt"), emit: report
    tuple val(meta), path("*fq.gz")     , emit: unmapped, optional: true
    tuple val("${task.process}"), val("bismark"), eval('bismark --version | grep Version | sed -e "s/Bismark Version: v//" | xargs'), topic: versions, emit: versions_bismark

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    if(task.ext.prefix){
        args += " --prefix ${task.ext.prefix}"
    }
    def fastq = meta.single_end ? reads : "-1 ${reads[0]} -2 ${reads[1]}"

    if(!args.contains('--multicore') && task.cpus){
        def ccore = 1
        def cpu_per_multicore = 3
        def mem_per_multicore = (13.GB).toBytes()
        if(args.contains('--non_directional')){
            cpu_per_multicore = 5
            mem_per_multicore = (18.GB).toBytes()
        }

        ccore = ((task.cpus as int) / cpu_per_multicore) as int

        try {
            def tmem = (task.memory as MemoryUnit).toBytes()
            def mcore = (tmem / mem_per_multicore) as int
            ccore = Math.min(ccore, mcore)
        } catch (all) {
            log.warn "Not able to define bismark align multicore based on available memory"
        }
        if(ccore > 1){
            args += " --multicore ${ccore}"
        }
    }
    """
    bismark \\
        ${fastq} \\
        --genome ${index} \\
        --bam \\
        ${args}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    touch ${prefix}.report.txt
    """
}
