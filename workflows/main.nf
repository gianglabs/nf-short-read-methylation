// Include subworkflows
// QC raw reads
include { FASTP_TRIM } from '../modules/local/fastp/trim/main'
include { SAMTOOLS_FAIDX } from '../modules/local/samtools/faidx/main'

// Alignment
include { BISMARK_ALIGNMENT } from '../subworkflows/local/alignment/bismark/main'

// Methylation calling
include { BISMARK_METHYLATION_CALLING } from '../subworkflows/local/methylation_calling/bismark/main'

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
     - Subworkflows              : ${params.taps ? "RASTAIR" : "BISMARK"}
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
    def reference_path = params.reference.toString().endsWith('.gz')
        ? params.reference.toString().replaceAll(/\.gz$/, '')
        : params.reference
    ref_fasta = channel.fromPath(reference_path, checkIfExists: true).collect()

    //
    // Detect input mode and branch accordingly
    // FASTQ mode: run full pipeline (alignment + preprocessing + variant calling)
    // BAM/CRAM mode: skip alignment and optional preprocessing, go directly to variant calling
    //
    input_branched = input_ch.branch { row ->
        fastq: row[1] instanceof List && row[1][0].toString().endsWith('.fastq.gz')
    }

    //
    // SUBWORKFLOW: BISMARK - FASTQ ONLY
    // Includes: BISMARK alignment, deduplication, methylation extraction
    //

    FASTP_TRIM(
        input_branched.fastq
    )
    ch_trimmed_reads = FASTP_TRIM.out.reads
    ch_versions = ch_versions.mix(FASTP_TRIM.out.versions)

    if (params.taps) {
        log.info("Not support yet")
    }
    else {
        // the input data with traditional transformation of methylation T-> C
        BISMARK_ALIGNMENT(
            ch_trimmed_reads,
            ref_fasta,
            params.bismark_index ? channel.fromPath(params.bismark_index, checkIfExists: true) : null,
        )

        BISMARK_ALIGNMENT.out.versions.ifEmpty(channel.empty()).set { bismark_alignment_versions }
        ch_versions = ch_versions.mix(bismark_alignment_versions)

        BISMARK_METHYLATION_CALLING(
            BISMARK_ALIGNMENT.out.bam_name,
            BISMARK_ALIGNMENT.out.alignment_reports,
            BISMARK_ALIGNMENT.out.bam_raw,
            ref_fasta,
            BISMARK_ALIGNMENT.out.bismark_index,
            params.cytosine_report,
        )

        BISMARK_METHYLATION_CALLING.out.versions.ifEmpty(channel.empty()).set { bismark_versions }
        ch_versions = ch_versions.mix(bismark_versions)
    }
}
