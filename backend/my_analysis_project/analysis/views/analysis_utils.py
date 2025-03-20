from concurrent.futures import ThreadPoolExecutor

from my_analysis_project.auth_app.models import AnalysisHistory


def process_single_analysis(analysis):
    return {
        "name": analysis.name,
        "color": analysis.color,
        "stroke": analysis.stroke,
        "distribution": {
            "min": analysis.distribution.min,
            "max": analysis.distribution.max,
            "bucket_size": analysis.distribution.bucket_size,
            "name": analysis.distribution.name,
            "color": analysis.distribution.color,
            "align_marker": analysis.distribution.align_marker,
            "total_count": analysis.distribution.totalCount,
            "total_genes_count": analysis.distribution.totalGenesCount,
            "total_genes_with_motif_count": analysis.distribution.totalGenesWithMotifCount,
            "data_points": [
                {
                    "min": dp.min,
                    "max": dp.max,
                    "count": dp.count,
                    "percent": dp.percent,
                    "genes_count": dp.genesCount,
                    "genes_percent": dp.genes_percent
                }
                for dp in analysis.distribution.dataPoints
            ] if analysis.distribution.dataPoints else []
        },
    }


def process_analysis_results(gene_model):
    with ThreadPoolExecutor() as executor:
        filtered_results = list(executor.map(process_single_analysis, gene_model.analyses))

    return filtered_results

def save_analysis_history(user, organism_name, filtered_results):
    """
    Saves the analysis history to the database in a synchronous manner.
    """
    try:
        AnalysisHistory.objects.create(
            user=user,
            name=f"Analysis for {organism_name}",
            filtered_results=filtered_results
        )
        print(f"✅ DEBUG: Successfully saved analysis history for {user.username}")
    except Exception as e:
        print(f"❌ ERROR saving analysis history: {str(e)}")
