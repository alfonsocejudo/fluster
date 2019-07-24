/*
 * Created by Alfonso Cejudo, Wednesday, July 24th 2019.
 */

import 'package:fluster/fluster.dart';
import 'package:fluster/src/base_cluster.dart';
import 'package:fluster/src/clusterable.dart';

main() {
  const currentZoom = 10;

  List<MapMarker> markers = [
    MapMarker(markerId: '1', latitude: 40.736291, longitude: -73.990243),
    MapMarker(markerId: '2', latitude: 40.731349, longitude: -73.997723),
    MapMarker(markerId: '3', latitude: 40.670274, longitude: -73.964054),
    MapMarker(markerId: '4', latitude: 38.889974, longitude: -77.019908),
  ];

  Fluster<MapMarker> fluster = Fluster<MapMarker>(
      minZoom: 0,
      maxZoom: 20,
      radius: 150,
      extent: 2048,
      nodeSize: 64,
      points: markers,
      createCluster: (BaseCluster cluster, double longitude, double latitude) {
        return MapMarker(
            markerId: cluster.id.toString(),
            latitude: latitude,
            longitude: longitude);
      });

  List<MapMarker> clusters =
      fluster.clusters([-180, -85, 180, 85], currentZoom);

  print('Number of clusters at zoom $currentZoom: ${clusters.length}');
}

class MapMarker extends Clusterable {
  String markerId;
  double latitude;
  double longitude;

  MapMarker({this.markerId, this.latitude, this.longitude});
}
