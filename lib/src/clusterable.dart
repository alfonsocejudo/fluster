/*
 * Created by Alfonso Cejudo, Wednesday, July 24th 2019.
 */

abstract class Clusterable {
  /// Either an individual data point's latitude or the center point latitude of
  /// a cluster's children.
  double? latitude;

  /// Either an individual data point's longitude or the center point longitude
  /// of a cluster's children.
  double? longitude;

  /// Denote that the instance is either a cluster or an individual data point.
  bool? isCluster = false;

  /// Unique id for use in cluster algorithm indexing.
  int? clusterId;

  /// If instance is a cluster, this is the number of child points it contains
  /// that are not themselves also clusters.
  int? pointsSize;

  /// Attach the unique id of the instance's corresponding map marker so that
  /// it can be used as a childMarkerId for clusters.
  String? markerId;

  /// Useful for representing a cluster by referencing one of its children.
  String? childMarkerId;

  /// Useful for handling tap on cluster
  Function? callbackFunction;

  /// Useful for assigning title on cluster
  String? title;

  Clusterable({
    this.latitude,
    this.longitude,
    this.isCluster,
    this.clusterId,
    this.pointsSize,
    this.markerId,
    this.childMarkerId,
    this.callbackFunction,
    this.title,
  });
}
