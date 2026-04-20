# Nextflow Short-Read Methylation

This repository implements a comprehensive Nextflow pipeline for bisulfite sequencing and TAPS (Transposase-Assisted Pyridoxylamine Sequencing) short-read methylation analysis. The pipeline supports both traditional Bismark-based T→C methylation conversion and modern RASTAIR-based C→T conversion (TAPS), with integrated quality control and comprehensive methylation calling.

## Pipeline Architecture

![Nextflow Short-Read Methylation Pipeline](docs/gianglabs-pipeline-nf-short-read-methylation.drawio.png)

## Primary Use Case

**Primary support**: **Illumina short-read bisulfite sequencing (RRBS, WGBS) and TAPS data with GRCh38 (hg38) alignment**

The pipeline is optimized for the following workflow:

- **Input**: Illumina short-read FASTQ files or pre-aligned BAM/CRAM files
- **Quality Filtering**: FASTP for read-level trimming and quality filtering
- **Alignment**: 
  - **Bismark mode** (default): Bismark + Bowtie2 alignment with T→C bisulfite conversion
  - **RASTAIR/TAPS mode**: BWA-MEM2 alignment with C→T bisulfite conversion
- **Deduplication**: Removal of PCR duplicates (Bismark deduplication or GATK MarkDuplicates)
- **Methylation Calling**:
  - **Bismark pathway**: Bismark methylation extraction with per-cytosine calls
  - **RASTAIR pathway**: M-bias calculation, trimming, and RASTAIR methylation calling
- **Quality Metrics**:
  - M-bias analysis and plots
  - Methylation coverage reports
  - Cytosine context summary (CpG, CHG, CHH)
- **Output**: BedGraph files, methylation calls, coverage reports, and MethylKit-formatted results

### Configuration for Primary Use Case

```bash
# Default configuration uses:
# - Bismark as methylation caller (or rastair with taps=true)
# - GRCh38/hg38 reference genome via --genome parameter
# - FASTP quality filtering
# - Automatic deduplication
# - Per-cytosine methylation reports

pixi run nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  -profile docker,bismark \
  -resume
```

## Quick Start

### 1. Prepare a Samplesheet

Create a CSV samplesheet with your input. The pipeline supports three input modes.

**Required Columns** (all modes):

- `sample`: Sample identifier
- `lane`: Sequencing lane (optional, defaults to L001)

#### Mode A: FASTQ Input (Full Pipeline)

```csv
sample,lane,fastq_1,fastq_2
sample1,L001,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,L001,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
sample2,L002,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
sample3,L001,/path/to/sample3_R1.fastq.gz,
```

Single-end reads can be provided by leaving `fastq_2` empty. Multiple lanes for the same sample will be automatically merged.

#### Mode B: BAM Input (Skip Alignment)

```csv
sample,lane,bam,bai
sample1,L001,/path/to/sample1.bam,/path/to/sample1.bam.bai
sample2,L001,/path/to/sample2.bam,/path/to/sample2.bam.bai
```

#### Mode C: CRAM Input (Skip Alignment + Auto-Convert)

```csv
sample,lane,cram,crai
sample1,L001,/path/to/sample1.cram,/path/to/sample1.cram.crai
sample2,L001,/path/to/sample2.cram,/path/to/sample2.cram.crai
```

**CRAM Benefits**:

- **Compressed input**: CRAM files are ~4x smaller than BAM (78% compression)
- **Faster pipeline**: Skip alignment step when re-running methylation calling
- **Automatic conversion**: CRAM→BAM conversion integrated into pipeline
- **Supported for both pathways**: Bismark and RASTAIR/TAPS

### 2. Run the Pipeline

#### Standard Run (FASTQ Input with Bismark)

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  -profile docker,bismark \
  -resume
```

#### RASTAIR/TAPS Pipeline

```bash
# Run with RASTAIR methylation calling (TAPS pathway)
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --taps true \
  --index_bwa2_reference true \
  -profile docker,rastair \
  -resume
```

#### Advanced Options

```bash
# Generate per-cytosine methylation reports (Bismark only)
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --cytosine_report true \
  -profile docker,bismark \
  -resume

# Skip deduplication
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --skip_deduplication true \
  -profile docker,bismark \
  -resume

# Custom reference genome (alternative to --genome)
nextflow run main.nf \
  --input samplesheet.csv \
  --reference /path/to/reference.fa \
  --reference_index /path/to/reference.fa.fai \
  --reference_dict /path/to/reference.dict \
  -profile docker,bismark \
  -resume

# Use pre-built Bismark index
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --bismark_index /path/to/bismark_index \
  -profile docker,bismark \
  -resume

# RASTAIR with custom trim parameters
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --taps true \
  --trim_OT 10 \
  --trim_OB 10 \
  -profile docker,rastair \
  -resume
```

For test mode with sample data:

```bash
nextflow run main.nf -profile docker,test,bismark -resume
```

### 3. View Results

Output files will be generated in the `results/` directory.

#### Bismark Pipeline Results:

```
results/
├── fastp/                           # Quality control reports
│   ├── *.html
│   └── *.json
├── bismark/
│   ├── alignments/                  # Aligned BAM files
│   ├── deduplicated/                # Deduplicated BAM files
│   │   ├── *.deduplicated.bam
│   │   └── *.deduplication_report.txt
│   ├── methylation_calls/
│   │   ├── bedGraph/                # BedGraph files for visualization
│   │   ├── methylation_calls/       # Raw methylation calls
│   │   ├── methylation_coverage/    # Per-cytosine reports
│   │   ├── mbias/                   # M-bias plots and data
│   │   └── splitting_report/
│   └── reports/                     # QC and summary reports
└── pipeline_info/                   # Execution logs
```

#### RASTAIR/TAPS Pipeline Results:

```
results/
├── fastp/                           # Quality control reports
├── gatk/
│   └── deduplicated/                # Deduplicated BAM files
├── rastair/
│   ├── mbias/                       # M-bias calculation results
│   ├── mbiasparser/                 # M-bias plots and trim parameters
│   ├── call/                        # Methylation calls
│   └── methylkit/                   # MethylKit format files
└── pipeline_info/                   # Execution logs
```

#### Key Output Files:

**Methylation Calls:**
- `*.bedGraph.gz` - BedGraph format (compatible with IGV, UCSC, etc.)
- `*.cov.gz` - Methylation coverage with read counts
- `*.methylkit.txt.gz` - MethylKit format for R analysis

**Quality Metrics:**
- `*.mbias.txt` - M-bias analysis by read position
- `*.deduplication_report.txt` - Deduplication statistics
- `*_fastqc.html` - Read quality reports

## Pipeline Modes

### Bismark Mode (Default)

Traditional bisulfite sequencing analysis with T→C conversion:

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  -profile docker,bismark
```

**Workflow:**
1. FASTP quality filtering and trimming
2. Bismark genome preparation (index building)
3. Bismark alignment with Bowtie2
4. Deduplication (Bismark deduplication)
5. Methylation extraction (cytosine-level calls)
6. Per-cytosine reports (optional)

**Output:** BedGraph, coverage files, methylation calls

### RASTAIR/TAPS Mode

Modern TAPS-based methylation analysis with C→T conversion:

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --taps true \
  --index_bwa2_reference true \
  -profile docker,rastair
```

**Workflow:**
1. FASTP quality filtering and trimming
2. BWA-MEM2 genome indexing and alignment
3. Deduplication (GATK MarkDuplicates)
4. M-bias calculation and optimization
5. RASTAIR methylation calling with trim parameters
6. MethylKit format conversion

**Output:** M-bias plots, methylation calls, MethylKit files

## Production Usage

For production runs, always specify the `--genome` parameter to ensure consistent reference genome usage:

```bash
# Production Bismark run
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  -profile docker,bismark \
  -resume

# Production RASTAIR run
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --taps true \
  --index_bwa2_reference true \
  -profile docker,rastair \
  -resume
```

### Supported Genomes

The pipeline supports the following reference genomes via the `--genome` parameter:

| Genome | Description | Provider |
|--------|-------------|----------|
| `GRCh38` | Human reference genome build 38 (hg38) | GATK/iGenomes |
| `test` | Small test genome for pipeline validation | nf-core |

### Alternative: Custom Reference Genomes

If using a genome not in the standard list, provide explicit reference paths instead:

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --reference /path/to/reference.fa \
  --reference_index /path/to/reference.fa.fai \
  --reference_dict /path/to/reference.dict \
  -profile docker,bismark \
  -resume
```

## Key Features

- **Multiple Input Formats**: FASTQ (full pipeline), BAM, and CRAM (skip alignment, auto-convert)
- **Two Methylation Pathways**: 
  - **Bismark**: Traditional T→C bisulfite conversion with Bowtie2 alignment
  - **RASTAIR/TAPS**: Modern C→T bisulfite conversion with BWA-MEM2 alignment
- **Flexible Alignment Options**: Bismark+Bowtie2 or BWA-MEM2 with automatic index building
- **Quality Control**: FASTP trimming, M-bias analysis, and comprehensive QC reports
- **Methylation Calling**: Per-cytosine calls with context-specific reporting (CpG, CHG, CHH)
- **Deduplication**: Automatic PCR duplicate removal (Bismark or GATK MarkDuplicates)
- **Multi-lane Support**: Automatic merging of multiple sequencing lanes per sample
- **Output Formats**: BedGraph, coverage files, MethylKit format, M-bias plots
- **CRAM Support**: Built-in CRAM→BAM conversion for efficient re-calling
- **Flexible Configuration**: Container support (Docker/Singularity), multiple profiles
- **Comprehensive Testing**: Full test suite with nf-test snapshots

## Configuration Parameters

### Essential Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `input` | null | Path to samplesheet CSV |
| `outdir` | "results" | Output directory |
| `genome` | "GRCh38" | Reference genome (test/GRCh38) |
| `reference` | null | Custom reference FASTA path |
| `reference_index` | null | Reference FAI index |
| `reference_dict` | null | Reference dictionary file |

### Pipeline Selection

| Parameter | Default | Description |
|-----------|---------|-------------|
| `taps` | false | Use RASTAIR (true) or Bismark (false) |
| `bismark_index` | null | Pre-built Bismark index directory |
| `bwa2_index` | null | Pre-built BWA-MEM2 index directory |
| `index_bwa2_reference` | false | Build BWA-MEM2 index from reference |

### Processing Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `skip_deduplication` | false | Skip duplicate removal |
| `skip_bismark_report` | false | Skip Bismark report generation |
| `cytosine_report` | false | Generate per-cytosine reports (Bismark) |
| `fastp_length_required` | 20 | Minimum read length after trimming |

### RASTAIR-Specific Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `trim_OT` | null | Original top-strand nucleotides to trim |
| `trim_OB` | null | Original bottom-strand nucleotides to trim |
| `skip_rastair` | false | Skip RASTAIR methylation calling |

### Workflow Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `publish_dir_mode` | "symlink" | Output directory mode (symlink/copy/move) |

## Running Tests

The pipeline includes comprehensive tests for both Bismark and RASTAIR pathways:

```bash
# Run Bismark pipeline test
make test-bismark

# Run RASTAIR pipeline test
make test-rastair

# Run all tests
make test-e2e

# Update test snapshots after changes
make test-bismark-update-snapshot
make test-rastair-update-snapshot

# Lint Nextflow code
make lint

# Clean work directories and results
make clean
```

## Pipeline Requirements

### Nextflow

- **Version**: >=25.10.2
- **DSL**: DSL2 enabled

### Container System

- **Docker**: For containerized execution
- **Singularity**: Alternative container runtime

### Reference Genomes

The pipeline includes pre-configured references:

**GRCh38 (Human):**
- FASTA: `s3://ngi-igenomes/igenomes/Homo_sapiens/GATK/GRCh38/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta`
- FAI: `s3://ngi-igenomes/igenomes/Homo_sapiens/GATK/GRCh38/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta.fai`
- Dict: `s3://ngi-igenomes/igenomes/Homo_sapiens/GATK/GRCh38/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.dict`

**Test Genome:**
- Available via `-profile test` flag

### Tool Versions (via Containers)

| Tool | Version | Purpose |
|------|---------|---------|
| fastp | 1.1.0 | Read QC and trimming |
| Bismark | 0.25.1 | Bisulfite alignment & methylation extraction |
| BWA-MEM2 | Latest | High-speed sequence alignment |
| Samtools | 1.18 | BAM/SAM manipulation |
| Picard | 3.1.1 | SAM/BAM utilities |
| RASTAIR | 0.8.2 | TAPS-based methylation calling |

## Pipeline Components

### Modules

The pipeline uses modular components for:

- **Quality Control**: FASTP read trimming and filtering
- **Reference Preparation**: Indexing (Bismark, BWA-MEM2, FASTA)
- **Alignment**: Bismark (Bowtie2) or BWA-MEM2
- **Deduplication**: Bismark deduplication or GATK MarkDuplicates
- **Methylation Calling**: Bismark extraction or RASTAIR calling
- **Output Processing**: Coverage conversion, MethylKit formatting

### Subworkflows

The pipeline organizes complex workflows into subworkflows:

- **BISMARK_ALIGNMENT**: Index building → alignment → sorting/merging
- **BWAMEM2_ALIGNMENT**: Optional index → alignment → sorting/merging
- **BISMARK_METHYLATION_CALLING**: Extraction → coverage conversion → reporting
- **RASTAIR_METHYLATION_CALLING**: M-bias → trimming → calling → formatting

## Output Description

### Bismark Mode

**Alignment Results:**
- `bismark/alignments/*.bam` - Aligned BAM files
- `bismark/deduplicated/*.bam` - Deduplicated BAM files

**Methylation Results:**
- `bismark/methylation_calls/bedGraph/*.bedGraph.gz` - BedGraph format for visualization
- `bismark/methylation_calls/methylation_calls/*.txt.gz` - Raw methylation calls
- `bismark/methylation_calls/methylation_coverage/*.cov.gz` - Coverage with counts
- `bismark/methylation_calls/mbias/*.txt` - M-bias analysis by position

**Quality Reports:**
- `bismark/reports/*.txt` - Alignment and splitting reports
- `fastp/*.html` - Read quality reports

### RASTAIR/TAPS Mode

**Methylation Results:**
- `rastair/mbias/*.txt` - M-bias calculation results
- `rastair/mbiasparser/*.pdf` - M-bias visualization plots
- `rastair/call/*.txt` - Methylation site calls
- `rastair/methylkit/*.txt.gz` - MethylKit format for R

**Quality Reports:**
- `gatk/deduplicated/*.bam` - Deduplicated BAM files
- `fastp/*.html` - Read quality reports

## Support and Documentation

For additional information and advanced usage:

- See example samplesheet: `assets/samplesheet_fastq.csv`
- View pipeline diagram: `docs/gianglabs-pipeline-nf-short-read-methylation.drawio.png`
- Test data available in: `assets/input/`

## License

MIT ([LICENSE](LICENSE))
