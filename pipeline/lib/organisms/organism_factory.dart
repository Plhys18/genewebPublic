import 'package:pipeline/organisms/allium.dart';
import 'package:pipeline/organisms/amborella.dart';
import 'package:pipeline/organisms/arabidopsis.dart';
import 'package:pipeline/organisms/base_organism.dart';
import 'package:pipeline/organisms/ginkgo.dart';
import 'package:pipeline/organisms/marchantia.dart';
import 'package:pipeline/organisms/oryza.dart';
import 'package:pipeline/organisms/physcomitrium.dart';
import 'package:pipeline/organisms/silene.dart';
import 'package:pipeline/organisms/solanum.dart';
import 'package:pipeline/organisms/zea.dart';

class OrganismFactory {
  static BaseOrganism getOrganism(String organism) {
    switch (organism) {
      case 'Allium_cepa':
        return Allium();
      case 'Amborella_trichopoda':
        return Amborella();
      case 'Arabidopsis_small_rna':
        return ArabidopsisSmallRna();
      case 'Arabidopsis_thaliana':
      case 'Arabidopsis_thaliana_private':
        return ArabidopsisThaliana();
      case 'Arabidopsis_thaliana_chloroplast':
        return ArabidopsisChloroplast();
      case 'Arabidopsis_thaliana_mitochondrion':
        return ArabidopsisMitochondrion();
      case 'Ginkgo_biloba':
        return Ginkgo();
      case 'Marchantia_polymorpha':
        return Marchantia();
      case 'Oryza_sativa':
        return Oryza();
      case 'Physcomitrium_patens':
        return Physcomitrium();
      case 'Silene_vulgaris':
        return Silene();
      case 'Solanum_lycopersicum':
        return Solanum();
      case 'Zea_mays':
        return Zea();

      default:
        throw ArgumentError('Unknown organism: $organism');
    }
  }
}
