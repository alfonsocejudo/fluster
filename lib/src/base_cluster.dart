/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

class BaseCluster {
  double? x;
  double? y;
  int? zoom;
  int? pointsSize;
  int? parentId;
  int? index;
  int? id;
  bool isCluster = false;

  /// For PointCluster instances that are standalone (i.e. not cluster) items.
  String? markerId;

  /// For clusters that wish to display one representation of its children.
  String? childMarkerId;

  /// Useful for handling tap on cluster
  Function? callbackFunction;

  /// Useful for assigning title on cluster
  String? title;
}
