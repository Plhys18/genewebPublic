from asgiref.sync import sync_to_async

from my_analysis_project.analysis.models import AnalysisHistory
from my_analysis_project.auth_app.models import UserColorPreference


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


@sync_to_async
def process_analysis_results(gene_model, user=None):
    stage_color_preferences = {}
    if user:
        preferences = UserColorPreference.objects.filter(
            user=user,
            preference_type='stage'
        )
        for pref in preferences:
            print(f"✅ DEBUG: User {user.username} has preference for {pref.name} with color {pref.color}")
            stage_color_preferences[pref.name] = pref.color

    filtered_results = []
    for analysis in gene_model.analyses:
        print(f"✅ DEBUG: Processing analysis {analysis.name}")

        # Extract the stage name from the analysis name (format: "Stage - Motif")
        stage_name = analysis.name.split(' - ')[0] if ' - ' in analysis.name else analysis.name

        # Check if we have a preference for this stage
        if user and stage_name in stage_color_preferences:
            color = stage_color_preferences[stage_name]
            print(f"✅ DEBUG: Found color preference for stage '{stage_name}': {color}")
            analysis.color = color
            analysis.distribution.color = color
        else:
            print(f"⚠️ DEBUG: No color preference found for stage '{stage_name}'")

        filtered_results.append(process_single_analysis(analysis))

    return filtered_results

@sync_to_async
def save_analysis_history(user, organism_name, filtered_results, motifs, stages, options):
    """
    Saves the analysis history to the database in a synchronous manner.
    """
    try:
        history = AnalysisHistory.objects.create(
            user=user,
            name=f"Analysis for {organism_name}",
            organism=organism_name,
            motifs=motifs,
            stages=stages,
            settings=options,
            filtered_results=filtered_results
        )
        print(f"✅ DEBUG: Successfully saved analysis history for {user.username}")
        return history
    except Exception as e:
        print(f"❌ ERROR saving analysis history: {str(e)}")
