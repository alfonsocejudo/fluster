/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'base_cluster.dart';

class PointCluster extends BaseCluster {
  PointCluster({
    double? x,
    double? y,
    int? zoom,
    int? index,
    String? markerId,
    Function? callbackFunction,
    String? title,
  }) {
    this.x = x;
    this.y = y;
    this.zoom = zoom;
    this.index = index;
    this.markerId = markerId;

    parentId = -1;
    isCluster = false;

    this.callbackFunction = callbackFunction;
    this.title = title;
  }
}
