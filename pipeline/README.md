# GeneWeb Pipeline

A bioinformatics pipeline for processing genomic data in preparation for the GeneWeb platform. This tool processes FASTA, GFF, and TPM files for various organisms to generate standardized outputs for genomic analysis.

## Purpose

The pipeline performs several key functions:
- Validates genomic sequence data from FASTA files against gene features from GFF files
- Processes gene expression data (TPM) from multiple developmental stages
- Extracts promoter regions (customizable length) from genes
- Handles organism-specific genomic peculiarities through specialized adapters
- Performs thorough validation of input data and generates detailed error reports
- Creates standardized FASTA output files with validated gene sequences

## Input Requirements

The pipeline expects the following input structure:
- Source data organized in organism-specific directories (e.g., `source_data/Arabidopsis_thaliana/`)
- Each organism directory should contain:
  - One FASTA file (`.fa`, `.faa`, or `.fasta` extension)
  - One GFF file (`.gff` or `.gff3` extension)
  - Optionally, TPM files in a `TPM/` subdirectory

## Installation and Setup

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) version 3.0.0 or higher

### Steps to Set Up the Pipeline

1. Clone or download this repository:
   ```bash
   git clone <repository-url>
   cd pipeline
   ```

2. Install Dart dependencies:
   ```bash
   dart pub get
   ```

3. Create your data directory structure:
   ```bash
   mkdir -p source_data/<organism_name>/TPM
   ```

4. Place your source files in the created directories:
   - Place FASTA file (`.fa`, `.faa`, or `.fasta`) in `source_data/<organism_name>/`
   - Place GFF file (`.gff` or `.gff3`) in `source_data/<organism_name>/`
   - Place TPM files in `source_data/<organism_name>/TPM/`

5. Run the pipeline for a specific organism:
   ```bash
   dart run bin/pipeline.dart <organism_directory_name>
   ```

### Additional Setup Notes

- If you encounter file descriptor limits when processing large genomes, the `run.sh` script automatically sets `ulimit -n 10240` to increase the limit.
- For Windows users, you may need to use Dart commands directly instead of the shell script:
  ```
  dart run bin/pipeline.dart <organism_directory_name>
  ```
- To modify the pipeline for custom organisms, you'll need to add a new adapter in the `lib/organisms/` directory.

## Usage

### Basic Usage

Run the pipeline for a specific organism:

```bash
dart run bin/pipeline.dart <organism_directory_name>
```

For organisms that support TSS (Transcription Start Site) processing:

```bash
dart run bin/pipeline.dart <organism_directory_name> --with-tss
```

### Batch Processing

Process all supported organisms using the run script:

```bash
./run.sh
```

Or process a specific organism directory:

```bash
./run.sh source_data/Organism_name
```

## Output Files

The pipeline generates the following output files in the `output/` directory:
- `<organism>.fasta`: FASTA file containing validated gene sequences
- `<organism>.errors.csv`: CSV file listing validation errors
- `<organism>.validated-genes-tpm.csv`: CSV file with TPM data for validated genes
- `<organism>.info.txt`: Log file with processing information
- Zipped versions of the FASTA files for easier distribution

For organisms with TSS support, equivalent files with the `-with-tss` suffix are also generated.

## Adding New Development Stages

To add new developmental stages (defined via TPM data) to an existing organism:

1. Prepare your TPM data file with the following format:
   - Tab or comma-separated values
   - First column should contain gene identifiers that match those in the GFF file
   - Additional columns should contain expression values for each gene

2. Name your TPM file following the pattern: `<developmental_stage>.tpm` or `<developmental_stage>.csv`
   - Example: `seedling.tpm`, `adult_leaf.tpm`, `flower_development.csv`

3. Place the TPM file in the organism's TPM directory:
   ```bash
   source_data/<organism_name>/TPM/
   ```

4. Run the pipeline for the organism as usual:
   ```bash
   dart run bin/pipeline.dart <organism_directory_name>
   ```

The pipeline will automatically detect and process the new stage along with existing ones. The combined expression data will be included in the `<organism>.validated-genes-tpm.csv` output file.

Stage name is extracted from the TPM file name using `BaseOrganism.stageNameFromTpmFilePath()` method. Override this method in the organism adapter if the stage name is not correctly extracted.

## Supported Organisms

The pipeline includes specialized adapters for multiple organisms, including:
- Arabidopsis thaliana
- Azolla filiculoides
- Ceratopteris richardii
- Hordeum vulgare
- Marchantia polymorpha
- Physcomitrium patens
- Silene vulgaris
- Solanum lycopersicum
- Zea mays
- And many others

Each organism adapter handles species-specific genomic features and naming conventions.

## Requirements

- Dart SDK >=3.0.0 <4.0.0
- Dependencies:
  - collection: ^1.16.0
  - csv: ^5.0.1
  - string_splitter: ^1.0.0+1
