/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'base_cluster.dart';

class Cluster extends BaseCluster {
  Cluster({
    double? x,
    double? y,
    int? id,
    int? pointsSize,
    String? childMarkerId,
    Function? callbackFunction,
    String? title,
  }) {
    this.x = x;
    this.y = y;
    this.id = id;
    this.pointsSize = pointsSize;
    this.childMarkerId = childMarkerId;

    isCluster = true;
    zoom = 24; // Max value.
    parentId = -1;

    this.callbackFunction = callbackFunction;
    this.title = title;
  }
}
