from asgiref.sync import sync_to_async

from analysis.models import AnalysisHistory
from auth_app.models import UserColorPreference
from analysis.utils.file_utils import logger


def process_single_analysis(analysis):
    """Process a single analysis series into a serializable format."""
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


async def process_analysis_results(gene_model, user=None):
    """Process analysis results with proper async handling."""
    stage_color_preferences = {}

    if user:
        preferences = await get_user_preferences(user)
        for pref in preferences:
            logger.debug(
                f"User {
                    user.username} has preference for {
                    pref['name']} with color {
                    pref['color']}")
            stage_color_preferences[pref['name']] = pref['color']

    filtered_results = []
    for analysis in gene_model.analyses:
        logger.debug(f"Processing analysis {analysis.name}")

        stage_name = analysis.name.split(
            ' - ')[0] if ' - ' in analysis.name else analysis.name

        if user and stage_name in stage_color_preferences:
            color = stage_color_preferences[stage_name]
            logger.debug(
                f"Found color preference for stage '{stage_name}': {color}")
            analysis.color = color
            analysis.distribution.color = color
        else:
            logger.debug(f"No color preference found for stage '{stage_name}'")

        filtered_results.append(process_single_analysis(analysis))

    return filtered_results


async def get_user_preferences(user):
    """Get user preferences in a database-safe way."""

    @sync_to_async
    def _get_preferences():
        preferences = UserColorPreference.objects.filter(
            user=user,
            preference_type='stage'
        ).values('name', 'color')
        return list(preferences)

    return await _get_preferences()


async def save_analysis_history(
        user,
        organism_name,
        organism_filename,
        filtered_results,
        motifs,
        stages,
        options):
    """
    Saves the analysis history to the database in a safe async manner.
    """

    @sync_to_async
    def _save_history():
        if user:
            try:
                history = AnalysisHistory.objects.create(
                    user=user,
                    name=f"Analysis for {organism_name}",
                    organism=organism_name,
                    organism_filename=organism_filename,
                    motifs=motifs,
                    stages=stages,
                    settings=options,
                    filtered_results=filtered_results
                )
                logger.debug(
                    f"Successfully saved analysis history for {
                        user.username}")
                return history
            except Exception as e:
                logger.error(f"Error saving analysis history: {str(e)}")
                return None

    return await _save_history()
