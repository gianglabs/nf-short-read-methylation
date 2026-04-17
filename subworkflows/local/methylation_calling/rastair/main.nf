include { RASTAIR_MBIAS } from '../../../../modules/local/rastair/mbias/main'
include { RASTAIR_MBIASPARSER } from '../../../../modules/local/rastair/mbiasparser/main'
include { RASTAIR_CALL } from '../../../../modules/local/rastair/call/main'
include { RASTAIR_METHYLKIT } from '../../../../modules/local/rastair/methylkit/main'

workflow RASTAIR_METHYLATION_CALLING {
    take:
    ch_bam // channel: [ val(meta), path(bam) ]
    ch_bai // channel: [ val(meta), path(bai) ]
    ch_fasta // channel: [ val(meta), path(fa) ]
    ch_fasta_fai // channel: [ val(meta), path(fa.fai) ]

    main:
    ch_rastair_mbias = channel.empty()
    ch_rastair_call = channel.empty()
    ch_versions = channel.empty()

    RASTAIR_MBIAS(
        ch_bam,
        ch_bai,
        ch_fasta,
        ch_fasta_fai,
    )
    ch_rastair_mbias = RASTAIR_MBIAS.out.txt
    ch_versions = ch_versions.mix(RASTAIR_MBIAS.out.versions)

    RASTAIR_MBIASPARSER(
        ch_rastair_mbias
    )
    ch_rastair_mbiasparser = RASTAIR_MBIASPARSER.out.mbias_processed_str
    ch_versions = ch_versions.mix(RASTAIR_MBIASPARSER.out.versions)

    RASTAIR_CALL(
        ch_bam,
        ch_bai,
        ch_fasta,
        ch_fasta_fai,
        ch_rastair_mbiasparser.map { meta, nOT_clip, _nOB_clip -> [meta, nOT_clip] },
        ch_rastair_mbiasparser.map { meta, _nOT_clip, nOB_clip -> [meta, nOB_clip] },
    )
    ch_rastair_call = RASTAIR_CALL.out.txt
    ch_versions = ch_versions.mix(RASTAIR_CALL.out.versions)

    RASTAIR_METHYLKIT(
        ch_rastair_call
    )
    ch_methylkit = RASTAIR_METHYLKIT.out.methylkit
    ch_versions = ch_versions.mix(RASTAIR_METHYLKIT.out.versions)

    emit:
    mbias = ch_rastair_mbias
    call = ch_rastair_call
    methylkit = ch_methylkit
    versions = ch_versions
}
