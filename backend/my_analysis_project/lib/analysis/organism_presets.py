import re
from organism import Organism
from stage_and_color import StageAndColor

class OrganismPresets:
    """
    Presets for organisms.

    See Organism
    """

    # Mimic the `_arabidopsisStages` list from Dart
    _arabidopsis_stages = [
        StageAndColor("C_Tapetum", "#993300"),
        StageAndColor("C_EarlyPollen", "#B71C1C"),
        StageAndColor("C_UNM", "#FF6D6D"),
        StageAndColor("C_BCP", "#C80002"),
        StageAndColor("C_LatePollen", "#0D47A1"),
        StageAndColor("C_TCP", "#21C5FF"),
        StageAndColor("C_MPG", "#305496"),
        StageAndColor("C_SIV_PT", "#FF6600"),
        StageAndColor("C_Sperm_cell", "#FFC002"),
        StageAndColor("C_Leaves_35d", "#92D050"),
        StageAndColor("C_Seedlings_10d", "#C6E0B4"),
        StageAndColor("C_Egg_cell", "#607D8B"),

        StageAndColor("L_EarlyPollen", "#B71C1C", is_checked_by_default=False),
        StageAndColor("L_UNM", "#FF6D6D", is_checked_by_default=False),
        StageAndColor("L_BCP", "#C80002", is_checked_by_default=False),
        StageAndColor("L_LatePollen", "#0D47A1", is_checked_by_default=False),
        StageAndColor("L_TCP", "#21C5FF", is_checked_by_default=False),
        StageAndColor("L_MPG", "#305496", is_checked_by_default=False),

        StageAndColor("Egg cell_Julca", "orange", is_checked_by_default=False),
        StageAndColor("Embryo", "orchid", is_checked_by_default=False),
        StageAndColor("Endosperm", "purple", is_checked_by_default=False),

        StageAndColor("Tapetum", "#993300"),
        StageAndColor("EarlyPollen", "#B71C1C"),
        StageAndColor("UNM", "#FF6D6D"),
        StageAndColor("lerUNM", "#FF6D6D"),
        StageAndColor("BCP", "#C80002"),
        StageAndColor("lerBCP", "#C80002"),
        StageAndColor("LatePollen", "#0D47A1"),
        StageAndColor("TCP", "#21C5FF"),
        StageAndColor("lerTCP", "#21C5FF"),
        StageAndColor("MPG", "#305496"),
        StageAndColor("lerMPG", "#305496"),
        StageAndColor("SIV_PT", "#FF6600"),
        StageAndColor("Sperm", "#FFC002"),
        StageAndColor("Leaves", "#92D050"),
        StageAndColor("Seedlings", "#C6E0B4"),
        StageAndColor("Egg", "#607D8B"),
    ]

    # Now define the master list `k_organisms`.
    # We'll match the same structure from Dart.
    k_organisms = [
        Organism(
            public=True,
            name="Marchantia polymorpha",
            filename="Marchantia_polymorpha-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[
                StageAndColor("Antheridium", "#0085B4"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Thallus", "#548236"),
            ],
        ),
        Organism(
            name="Marchantia polymorpha",
            filename="Marchantia_polymorpha.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("Antheridium", "#0085B4"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Thallus", "#548236"),
            ],
        ),
        Organism(
            name="Physcomitrium patens",
            filename="Physcomitrium_patens.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("Antheridia_9DAI", "#21C5FF"),
                StageAndColor("Antheridia_11DAI", "#009ED6"),
                StageAndColor("Antheridia_14-15DAI_(mature)", "#009AD0"),
                StageAndColor("Sperm_cell_packages", "#FFDB69"),
                StageAndColor("Leaflets", "#548236"),
                StageAndColor("Archegonia (mature)", "orange"),
                StageAndColor("Sporophyte (9 DAF)", "teal"),
            ],
        ),
        Organism(
            public=True,
            name="Physcomitrium patens",
            filename="Physcomitrium_patens-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[
                StageAndColor("Antheridia_9DAI", "#21C5FF"),
                StageAndColor("Antheridia_11DAI", "#009ED6"),
                StageAndColor("Antheridia_14-15DAI_(mature)", "#0085B4"),
                StageAndColor("Sperm_cell_packages", "#FFDB69"),
                StageAndColor("Leaflets", "#548236"),
                StageAndColor("Archegonia (mature)", "orange"),
                StageAndColor("Sporophyte (9 DAF)", "teal"),
            ],
        ),
        Organism(
            name="Azolla filiculoides",
            filename="Azolla_filiculoides.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("Leaves", "#92D050"),
                StageAndColor("Spores", "#FFC002"),
            ],
            take_first_transcript_only=False,
        ),
        Organism(
            name="Azolla filiculoides",
            filename="Azolla_filiculoides-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[
                StageAndColor("Leaves", "#92D050"),
                StageAndColor("Spores", "#FFC002"),
            ],
            take_first_transcript_only=False,
        ),
        Organism(
            name="Ceratopteris richardii",
            filename="Ceratopteris_richardii.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("Gametophyte", "#2980B9"),
                StageAndColor("Male_gametophyte", "#5DADE2"),
                StageAndColor("Hermaphrodite_gametophyte", "#8E44AD"),
                StageAndColor("Sporophyte", "#229954"),
            ],
        ),
        Organism(
            public=True,
            name="Ceratopteris richardii",
            filename="Ceratopteris_richardii-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[
                StageAndColor("Gametophyte", "#2980B9"),
                StageAndColor("Male_gametophyte", "#5DADE2"),
                StageAndColor("Hermaphrodite_gametophyte", "#8E44AD"),
                StageAndColor("Sporophyte", "#229954"),
            ],
        ),
        Organism(
            public=True,
            name="Amborella trichopoda",
            filename="Amborella_trichopoda.fasta.zip",
            description="ATG",
            take_first_transcript_only=False,
            stages=[
                StageAndColor("UNM", "#FF6D6D"),
                StageAndColor("Pollen", "#0085B4"),
                StageAndColor("PT_bicellular", "#E9A5D2"),
                StageAndColor("PT_tricellular", "#77175C"),
                StageAndColor("Generative_cell", "#B48502"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Leaves", "#92D050"),
            ],
        ),
        Organism(
            public=True,
            name="Oryza sativa",
            filename="Oryza_sativa.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("TCP", "#21C5FF"),
                StageAndColor("Pollen", "#0085B4"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Leaves", "#92D050"),
            ],
        ),
        Organism(
            name="Zea mays",
            filename="Zea_mays.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("Microspore", "#FF6D6D"),
                # BCP missing
                StageAndColor("Pollen", "#0085B4"),
                StageAndColor("PT", "#E9A5D2"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Leaves", "#92D050"),
            ],
        ),
        Organism(
            public=True,
            name="Zea mays",
            filename="Zea_mays-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[
                StageAndColor("Microspore", "#FF6D6D"),
                # BCP missing
                StageAndColor("Pollen", "#0085B4"),
                StageAndColor("PT", "#E9A5D2"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Leaves", "#92D050"),
            ],
        ),
        Organism(
            name="Solanum lycopersicum",
            filename="Solanum_lycopersicum.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("Microspore", "#FF6D6D"),
                StageAndColor("Pollen", "#0085B4"),
                StageAndColor("Pollen_grain", "#305496"),
                StageAndColor("PT", "#E9A5D2"),
                StageAndColor("PT_1,5h", "#D75BAE"),
                StageAndColor("PT_3h", "#AC2A81"),
                StageAndColor("PT_9h", "#471234"),
                StageAndColor("Generative_cell", "#B48502"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Leaves", "#92D050"),
            ],
        ),
        Organism(
            public=True,
            name="Solanum lycopersicum",
            filename="Solanum_lycopersicum-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[
                StageAndColor("Microspore", "#FF6D6D"),
                StageAndColor("Pollen", "#0085B4"),
                StageAndColor("Pollen_grain", "#305496"),
                StageAndColor("PT", "#E9A5D2"),
                StageAndColor("PT_1,5h", "#D75BAE"),
                StageAndColor("PT_3h", "#AC2A81"),
                StageAndColor("PT_9h", "#471234"),
                StageAndColor("Generative_cell", "#B48502"),
                StageAndColor("Sperm_cell", "#FFC002"),
                StageAndColor("Leaves", "#92D050"),
            ],
        ),
        Organism(
            name="Hordeum vulgare",
            filename="Hordeum_vulgare.fasta.zip",
            description="ATG",
            stages=[
                StageAndColor("Embryo_8_DAP", "#6E2C00"),
                StageAndColor("Embryo_16_DAP", "#A04000"),
                StageAndColor("Embryo_24_DAP", "#D35400"),
                StageAndColor("Embryo_32_DAP", "#E59866"),
                StageAndColor("Endosperm_4_DAP", "#7D6608"),
                StageAndColor("Endosperm_8_DAP", "#9A7D0A"),
                StageAndColor("Endosperm_16_DAP", "#B7950B"),
                StageAndColor("Endosperm_24_DAP", "#F1C40F"),
                StageAndColor("Endosperm_32_DAP", "#F7DC6F"),
                StageAndColor("Seed_maternal_tissues_4_DAP", "#1B4F72"),
                StageAndColor("Seed_maternal_tissues_8_DAP", "#2874A6"),
                StageAndColor("Seed_maternal_tissues_16_DAP", "#3498DB"),
                StageAndColor("Seed_maternal_tissues_24_DAP", "#85C1E9"),
                StageAndColor("Leaf_non-infested_30_DAP", "#82E0AA"),
            ],
        ),
        Organism(
            public=True,
            name="Hordeum vulgare",
            filename="Hordeum_vulgare-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[
                StageAndColor("Embryo_8_DAP", "#6E2C00"),
                StageAndColor("Embryo_16_DAP", "#A04000"),
                StageAndColor("Embryo_24_DAP", "#D35400"),
                StageAndColor("Embryo_32_DAP", "#E59866"),
                StageAndColor("Endosperm_4_DAP", "#7D6608"),
                StageAndColor("Endosperm_8_DAP", "#9A7D0A"),
                StageAndColor("Endosperm_16_DAP", "#B7950B"),
                StageAndColor("Endosperm_24_DAP", "#F1C40F"),
                StageAndColor("Endosperm_32_DAP", "#F7DC6F"),
                StageAndColor("Seed_maternal_tissues_4_DAP", "#1B4F72"),
                StageAndColor("Seed_maternal_tissues_8_DAP", "#2874A6"),
                StageAndColor("Seed_maternal_tissues_16_DAP", "#3498DB"),
                StageAndColor("Seed_maternal_tissues_24_DAP", "#85C1E9"),
                StageAndColor("Leaf_non-infested_30_DAP", "#82E0AA"),
            ],
        ),
        Organism(
            name="Arabidopsis thaliana",
            filename="Arabidopsis_thaliana.fasta.zip",
            description="ATG only",
            stages=_arabidopsis_stages,
        ),
        Organism(
            public=True,
            name="Arabidopsis thaliana",
            filename="Arabidopsis_thaliana-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=_arabidopsis_stages,
        ),
        Organism(
            name="Arabidopsis thaliana",
            filename="Arabidopsis-variants.fasta.zip",
            description="TSS, ATG, all splicing variants",
            stages=_arabidopsis_stages,
        ),
        Organism(
            name="Arabidopsis thaliana",
            filename="Arabidopsis_thaliana_mitochondrion.fasta.zip",
            description="Mitochondrion dataset",
            stages=_arabidopsis_stages,
        ),
        Organism(
            name="Arabidopsis thaliana",
            filename="Arabidopsis_thaliana_chloroplast.fasta.zip",
            description="Chloroplast dataset",
            stages=_arabidopsis_stages,
        ),
        Organism(
            name="Arabidopsis thaliana",
            filename="Arabidopsis_thaliana_small_rna.fasta.zip",
            description="Small RNA dataset",
            stages=[],
        ),
        Organism(
            name="Allium cepa",
            filename="Allium_cepa.fasta.zip",
            description="ATG",
            stages=[],
        ),
        Organism(
            name="Silene vulgaris",
            filename="Silene_vulgaris.fasta.zip",
            description="ATG",
            stages=[],
        ),
        Organism(
            name="Silene vulgaris",
            filename="Silene_vulgaris-with-tss.fasta.zip",
            description="ATG, TSS",
            stages=[],
        ),
    ]

    @staticmethod
    def organism_by_filename(filename: str) -> "Organism":
        """
        Attempts to find an Organism in k_organisms whose filename starts with `filename`.
        If none is found, returns a new Organism with name based on the filename.
        """
        for org in OrganismPresets.k_organisms:
            if org.filename and org.filename.startswith(filename):
                return org

        # If not found, create a fallback organism
        match = re.match(r"([A-Za-z0-9_]+).*", filename)
        if match:
            fallback_name = match.group(1).replace("_", " ")
        else:
            fallback_name = "Unknown organism"

        return Organism(
            name=fallback_name,
            filename=filename,
        )
