import 'base_cluster.dart';

class Cluster extends BaseCluster {
  Cluster({
    double? x,
    double? y,
    int? id,
    int? pointsSize,
    String? childMarkerId,
  }) {
    this.x = x;
    this.y = y;
    this.id = id;
    this.pointsSize = pointsSize;
    this.childMarkerId = childMarkerId;

    this.isCluster = true;
    this.zoom = 24;
    this.parentId = -1;
  }
}
