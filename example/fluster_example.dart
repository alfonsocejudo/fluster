/*
 * Created by Alfonso Cejudo, Wednesday, July 24th 2019.
 */

import 'package:fluster/fluster.dart';
import 'package:fluster/src/base_cluster.dart';
import 'package:fluster/src/clusterable.dart';

main() {
  const currentZoom = 10;

  List<MapMarker> markers = [
    MapMarker(
        locationName: 'One',
        markerId: '9000001',
        latitude: 40.736291,
        longitude: -73.990243),
    MapMarker(
        locationName: 'Two',
        markerId: '9000002',
        latitude: 40.731349,
        longitude: -73.997723),
    MapMarker(
        locationName: 'Three',
        markerId: '9000003',
        latitude: 40.670274,
        longitude: -73.964054),
    MapMarker(
        locationName: 'Four',
        markerId: '9000004',
        latitude: 38.889974,
        longitude: -77.019908),
  ];

  Fluster<MapMarker> fluster = Fluster<MapMarker>(
      minZoom: 0,
      maxZoom: 21,
      radius: 150,
      extent: 2048,
      nodeSize: 64,
      points: markers,
      createCluster: (BaseCluster cluster, double longitude, double latitude) =>
          MapMarker(
              locationName: null,
              latitude: latitude,
              longitude: longitude,
              isCluster: true,
              clusterId: cluster.id,
              pointsSize: cluster.pointsSize,
              markerId: cluster.id.toString(),
              childMarkerId: cluster.childMarkerId));

  List<MapMarker> clusters =
      fluster.clusters([-180, -85, 180, 85], currentZoom);

  print('Number of clusters at zoom $currentZoom: ${clusters.length}');
}

class MapMarker extends Clusterable {
  String? locationName;
  String? thumbnailSrc;

  MapMarker(
      {this.locationName,
      latitude,
      longitude,
      this.thumbnailSrc,
      isCluster = false,
      clusterId,
      pointsSize,
      markerId,
      childMarkerId})
      : super(
            latitude: latitude,
            longitude: longitude,
            isCluster: isCluster,
            clusterId: clusterId,
            pointsSize: pointsSize,
            markerId: markerId,
            childMarkerId: childMarkerId);
}
