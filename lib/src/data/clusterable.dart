abstract class Clusterable {
  double? latitude;
  double? longitude;
  bool? isCluster = false;
  int? clusterId;
  int? pointsSize;
  String? markerId;
  String? childMarkerId;

  Clusterable({
    this.latitude,
    this.longitude,
    this.isCluster,
    this.clusterId,
    this.pointsSize,
    this.markerId,
    this.childMarkerId,
  });
}
