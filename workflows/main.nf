// Include subworkflows
include { BISMARK } from '../subworkflows/local/bismark/main'

workflow SHORT_READ_METHYLATION {
    take:
    input_ch // channel: 

    main:
    ch_versions = channel.empty()

    // Automatically set reference resources from iGenomes if --igenomes_base and --genome are set
    if (params.genome && params.genomes.containsKey(params.genome)) {
        def igenome_ref = params.genomes[params.genome]
        if (igenome_ref) {
            if (igenome_ref.fasta) {
                params.reference = igenome_ref.fasta
            }
            if (igenome_ref.fasta_fai) {
                params.reference_index = igenome_ref.fasta_fai
            }
            if (igenome_ref.dict) {
                params.reference_dict = igenome_ref.dict
            }
            if (igenome_ref.bismark_index) {
                params.bismark_index = igenome_ref.bismark_index
            }
        }
    }

    log.info(
        """
    ==============================================================================================================================
    nf-short-read-methylation:
     - Nextflow Version
     - Workflow                  : SHORT_READ_METHYLATION
     - Subworkflows              : BISMARK
     - Loaded genomes set        : ${params.genome ? params.genome : 'None'}
     - Reference Genome          : ${params.reference}
     - Bismark Index             : ${params.bismark_index ?: 'None'}
     - Input Samplesheet         : ${params.input}
     - Output Directory          : ${params.outdir}
    ==============================================================================================================================
    """.stripIndent()
    )

    //
    // Prepare reference genome channels
    // Values from nextflow.config params block, override via CLI as needed
    ref_fasta = channel.fromPath(params.reference, checkIfExists: true)

    //
    // Detect input mode and branch accordingly
    // FASTQ mode: run full pipeline (alignment + preprocessing + variant calling)
    // BAM/CRAM mode: skip alignment and optional preprocessing, go directly to variant calling
    //
    input_branched = input_ch.branch {
        fastq: it[1] instanceof List && it[1][0].toString().endsWith('.fastq.gz')
    }

    //
    // SUBWORKFLOW: BISMARK - FASTQ ONLY
    // Includes: FASTP, BISMARK alignment, deduplication, methylation extraction
    //

    BISMARK(
        input_branched.fastq,
        ref_fasta,
        params.bismark_index ? channel.fromPath(params.bismark_index, checkIfExists: true) : null,
        params.skip_deduplication,
        params.cytosine_report
    )

    BISMARK.out.versions.ifEmpty(channel.empty()).set { bismark_versions }
    ch_versions = ch_versions.mix(bismark_versions)

}
