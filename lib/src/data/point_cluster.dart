import 'base_cluster.dart';

class PointCluster extends BaseCluster {
  PointCluster({
    double? x,
    double? y,
    int? zoom,
    int? index,
    String? markerId,
  }) {
    this.x = x;
    this.y = y;
    this.zoom = zoom;
    this.index = index;
    this.markerId = markerId;

    this.parentId = -1;
    this.isCluster = false;
  }
}
