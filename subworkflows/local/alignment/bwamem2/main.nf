include { BWAMEM2_INDEX } from '../../../../modules/gianglabs/bwamem2/index/main'
include { BWAMEM2_MEM2 } from '../../../../modules/local/bwamem2/mem2/main'
include { SORT_MERGE_ALIGNMENT } from '../sort_merge/main'

workflow BWAMEM2_ALIGNMENT {
    take:
    reads_ch // channel: [ val(meta), [ path(read1), path(read2) ] ]
    ref_fasta // path: reference FASTA
    ref_fai // path: reference FAI
    ref_dict // path: reference dict
    bwa2_index // channel: Optional BWA index files
    index_bwa2_reference // channel: Optional BWA index files

    main:
    ch_versions = channel.empty()

    if (index_bwa2_reference) {
        BWAMEM2_INDEX(ref_fasta)
        ch_versions = ch_versions.mix(BWAMEM2_INDEX.out.versions)
        bwa2_index_ch = BWAMEM2_INDEX.out.index
    }
    else {
        bwa2_index_ch = channel.fromPath(bwa2_index)
    }

    ch_bwa_inputs = reads_ch
        .combine(ref_fasta)
        .combine(ref_fai)
        .combine(ref_dict)
        .multiMap { meta, reads, fasta, fai, dict ->
            reads: [meta, reads]
            fasta: fasta
            fai: fai
            dict: dict
        }

    BWAMEM2_MEM2(
        ch_bwa_inputs.reads,
        ch_bwa_inputs.fasta,
        ch_bwa_inputs.fai,
        ch_bwa_inputs.dict,
        bwa2_index_ch,
    )
    ch_versions = ch_versions.mix(BWAMEM2_MEM2.out.versions)

    SORT_MERGE_ALIGNMENT(
        BWAMEM2_MEM2.out.bam,
        ref_fasta,
    )

    emit:
    bam = SORT_MERGE_ALIGNMENT.out.bam
    bai = SORT_MERGE_ALIGNMENT.out.bai
    cram = SORT_MERGE_ALIGNMENT.out.cram
    crai = SORT_MERGE_ALIGNMENT.out.crai
    versions = ch_versions
}
