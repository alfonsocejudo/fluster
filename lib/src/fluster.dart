/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'dart:math' as math;

import 'base_cluster.dart';
import 'cluster.dart';
import 'clusterable.dart';
import 'kd_bush.dart';
import 'point_cluster.dart';

/// The List to be clustered must contain objects that conform to Clusterable.
class Fluster<T extends Clusterable> {
  /// Any zoom value below minZoom will not generate clusters.
  final int minZoom;

  /// Any zoom value above maxZoom will not generate clusters.
  final int maxZoom;

  /// Cluster radius in pixels.
  final int radius;

  /// Adjust the extent by powers of 2 (e.g. 512. 1024, ... max 8192) to get the
  /// desired distance between markers where they start to cluster.
  final int extent;

  /// The size of the KD-tree leaf node, which affects performance.
  final int nodeSize;

  /// The List to be clustered.
  final List<T> _points;

  /// Store the clusters for each zoom level.
  final List<KDBush> _trees;

  /// A callback to generate clusters of the given input type.
  final T Function(BaseCluster, double, double) _createCluster;

  Fluster(
      {this.minZoom,
      this.maxZoom,
      this.radius,
      this.extent,
      this.nodeSize,
      points,
      createCluster})
      : _points = points,
        _trees = List(maxZoom + 2),
        _createCluster = createCluster {
    List<BaseCluster> clusters = List();

    for (int i = 0; i < _points.length; i++) {
      if (_points[i].latitude == null || _points[i].longitude == null) {
        continue;
      }

      clusters.add(_createPointCluster(_points[i], i));
    }

    _trees[maxZoom + 1] = KDBush(points: clusters, nodeSize: nodeSize);

    for (int z = maxZoom; z >= minZoom; z--) {
      clusters = _buildClusters(clusters, z);

      _trees[z] = KDBush(points: clusters, nodeSize: nodeSize);
    }
  }

  /// Returns a list of clusters that reside within the bounding box, where
  /// bbox = [southwestLng, southwestLat, northeastLng, northeastLat].
  ///
  /// The list is comprised of the original points passed into the constructor
  /// or clusters of points (and perhaps other clusters) produced by
  /// createCluster().
  List<T> clusters(List<double> bbox, int zoom) {
    double minLng = ((bbox[0] + 180) % 360 + 360) % 360 - 180;
    double minLat = math.max(-90, math.min(90, bbox[1]));
    double maxLng =
        bbox[2] == 180 ? 180 : ((bbox[2] + 180) % 360 + 360) % 360 - 180;
    double maxLat = math.max(-90, math.min(90, bbox[3]));

    if (bbox[2] - bbox[0] >= 360) {
      minLng = -180;
      maxLng = 180;
    } else if (minLng > maxLng) {
      List<T> easternHemisphere = clusters([minLng, minLat, 180, maxLat], zoom);
      List<T> westernHemisphere =
          clusters([-180, minLat, maxLng, maxLat], zoom);

      easternHemisphere.addAll(westernHemisphere);

      return easternHemisphere;
    }

    KDBush tree = _trees[_limitZoom(zoom)];
    List<int> ids =
        tree.range(_lngX(minLng), _latY(maxLat), _lngX(maxLng), _latY(minLat));

    List<T> result = List();

    for (int id in ids) {
      BaseCluster c = tree.points[id];

      result.add((c.pointsSize != null && c.pointsSize > 0)
          ? _createCluster(c, _xLng(c.x), _yLat(c.y))
          : _points[c.index]);
    }

    return result;
  }

  /// Returns a list of clusters that are children of the given cluster.
  ///
  /// The list is comprised of the original points passed into the constructor
  /// or clusters of points (and perhaps other clusters) produced by
  /// createCluster().
  List<T> children(int clusterId) {
    if (clusterId == null) {
      return null;
    }

    int originId = clusterId >> 5;
    int originZoom = clusterId % 32;

    KDBush index = _trees[originZoom];
    if (index == null) {
      return null;
    }

    BaseCluster origin = index.points[originId];
    if (origin == null) {
      return null;
    }

    double r = radius / (extent * math.pow(2, originZoom - 1));
    List<int> ids = index.within(origin.x, origin.y, r);

    List<T> children = List();
    for (int id in ids) {
      BaseCluster c = index.points[id];

      if (c.parentId == clusterId) {
        children.add((c.pointsSize != null && c.pointsSize > 0)
            ? _createCluster(c, _xLng(c.x), _yLat(c.y))
            : _points[c.index]);
      }
    }

    return children;
  }

  /// Returns a list of standalone points (not clusters) that are children of
  /// the given cluster.
  List<T> points(int clusterId) {
    List<T> points = List();

    _extractClusterPoints(clusterId, points);

    return points;
  }

  /// Find the children that are individual media points, not other clusters.
  void _extractClusterPoints(int clusterId, List<T> points) {
    List<T> childList = children(clusterId);

    if (childList == null || childList.isEmpty) {
      return;
    } else {
      for (T child in childList) {
        if (child.isCluster != null && child.isCluster) {
          _extractClusterPoints(child.clusterId, points);
        } else {
          points.add(child);
        }
      }
    }
  }

  PointCluster _createPointCluster(T feature, int id) {
    double x = _lngX(feature.longitude);
    double y = _latY(feature.latitude);

    return PointCluster(
        x: x, y: y, zoom: 24, index: id, markerId: feature.markerId);
  }

  List<BaseCluster> _buildClusters(List<BaseCluster> points, int zoom) {
    List<BaseCluster> clusters = List();

    double r = radius / (extent * math.pow(2, zoom));

    for (int i = 0; i < points.length; i++) {
      BaseCluster p = points[i];

      if (p.zoom <= zoom) {
        continue;
      }
      p.zoom = zoom;

      KDBush tree = _trees[zoom + 1];
      List<int> neighborIds = tree.within(p.x, p.y, r);

      int pointsSize = p.pointsSize ?? 1;
      double wx = p.x * pointsSize;
      double wy = p.y * pointsSize;

      String childMarkerId =
          p.childMarkerId != null ? p.childMarkerId : p.markerId;

      int id = (i << 5) + (zoom + 1);

      for (int neighborId in neighborIds) {
        BaseCluster b = tree.points[neighborId];

        if (b.zoom <= zoom) {
          continue;
        }
        b.zoom = zoom;

        int pointsSize2 = b.pointsSize ?? 1;
        wx += b.x * pointsSize2;
        wy += b.y * pointsSize2;

        pointsSize += pointsSize2;
        b.parentId = id;
      }

      if (pointsSize == 1) {
        clusters.add(p);
      } else {
        p.parentId = id;
        clusters.add(Cluster(
            x: wx / pointsSize,
            y: wy / pointsSize,
            id: id,
            pointsSize: pointsSize,
            childMarkerId: childMarkerId));
      }
    }

    return clusters;
  }

  double _lngX(double lng) {
    return lng / 360 + 0.5;
  }

  double _latY(double lat) {
    double sin = math.sin(lat * math.pi / 180);
    double y = 0.5 - 0.25 * math.log((1 + sin) / (1 - sin)) / math.pi;

    return y < 0 ? 0 : y > 1 ? 1 : y;
  }

  double _xLng(double x) {
    return (x - 0.5) * 360;
  }

  double _yLat(double y) {
    double y2 = (180 - y * 360) * math.pi / 180;

    return 360 * math.atan(math.exp(y2)) / math.pi - 90;
  }

  int _limitZoom(int z) {
    return math.max(minZoom, math.min(z, maxZoom + 1));
  }
}
