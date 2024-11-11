import requests
import zipfile
import io
from fastapi import HTTPException

async def download_and_unarchive(filename: str):
    try:
        # Download the file from the server
        url = f"https://golem-dev.ncbr.muni.cz/datasets/{filename}"
        response = requests.get(url)

        if response.status_code != 200:
            raise HTTPException(status_code=404, detail="File not found")

        # Decompress (unzip) the file
        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            fasta_content = None
            for file_info in z.infolist():
                # Extract only .fasta or .fa files
                if file_info.filename.endswith(".fasta") or file_info.filename.endswith(".fa"):
                    with z.open(file_info) as fasta_file:
                        fasta_content = fasta_file.read().decode('utf-8')
                    break

            if not fasta_content:
                raise HTTPException(status_code=400, detail="No .fasta file found in archive.")

        # Return the decompressed content
        return {
            "fasta_content": fasta_content
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")
