import requests
import zipfile
import io
from fastapi import HTTPException

class OrganismService:

    @staticmethod
    async def download_and_process_organism(filename: str):
        try:
            url = f"https://golem-dev.ncbr.muni.cz/datasets/{filename}"
            response = requests.get(url)

            if response.status_code != 200:
                raise HTTPException(status_code=404, detail="File not found")

            with zipfile.ZipFile(io.BytesIO(response.content)) as z:
                fasta_content = None
                for file_info in z.infolist():
                    if file_info.filename.endswith((".fasta", ".fa")):
                        with z.open(file_info) as fasta_file:
                            fasta_content = fasta_file.read().decode('utf-8')
                        break

                if not fasta_content:
                    raise HTTPException(status_code=400, detail="No .fasta file found in archive.")

            gene_count, errors = OrganismService._parse_fasta(fasta_content)
            return {"gene_count": gene_count, "errors": errors}

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")

    @staticmethod
    def _parse_fasta(content: str):
        gene_count = 0
        errors = []

        sequences = content.split('>')  # Split on FASTA header
        for seq in sequences[1:]:  # Skip the first part, which is empty
            lines = seq.strip().splitlines()
            if not lines:
                continue

            if gene_count < 3:
                print(lines)
            header = lines[0]  # First line is the header
            sequence = ''.join(lines[1:])  # Join the rest as the sequence

            # Basic validations
            if not sequence:
                errors.append(f"Empty sequence found for header: {header}")
                continue

            # if any(char not in 'ACGT' for char in sequence.upper()):
            #     errors.append(f"Invalid characters found in sequence for header: {header}")

            gene_count += 1  # Count the valid gene sequences
        return content.count('>'), errors
