import 'dart:math' as math;

import 'data/base_cluster.dart';
import 'data/cluster.dart';
import 'data/clusterable.dart';
import 'kd_bush.dart';
import 'data/point_cluster.dart';

class Fluster<T extends Clusterable> {
  final int minZoom;
  final int maxZoom;
  final int radius;
  final int extent;
  final int nodeSize;
  final List<T> _points;
  final List<KDBush?> _trees;
  final T Function(BaseCluster?, double?, double?) _createCluster;

  Fluster({
    required this.minZoom,
    required this.maxZoom,
    required this.radius,
    required this.extent,
    required this.nodeSize,
    points,
    createCluster,
  })  : _points = points,
        _trees = List.filled(maxZoom + 2, null),
        _createCluster = createCluster {
    List<BaseCluster> clusters = [];

    for (int i = 0; i < _points.length; i++) {
      if (_points[i].latitude == null || _points[i].longitude == null) {
        continue;
      }

      clusters.add(_createPointCluster(_points[i], i));
    }

    _trees[maxZoom + 1] = KDBush(
      points: clusters,
      nodeSize: nodeSize,
    );

    for (int z = maxZoom; z >= minZoom; z--) {
      clusters = _buildClusters(clusters, z);

      _trees[z] = KDBush(points: clusters, nodeSize: nodeSize);
    }
  }

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
      List<T> easternHemisphere = clusters(
        [minLng, minLat, 180, maxLat],
        zoom,
      );
      List<T> westernHemisphere = clusters(
        [-180, minLat, maxLng, maxLat],
        zoom,
      );

      easternHemisphere.addAll(westernHemisphere);
      return easternHemisphere;
    }

    KDBush? tree = _trees[_limitZoom(zoom)];
    List<int> ids = tree != null
        ? tree.range(
            _lngX(minLng),
            _latY(maxLat),
            _lngX(maxLng),
            _latY(minLat),
          )
        : [];

    List<T> result = [];

    for (int id in ids) {
      BaseCluster? cluster = tree?.points[id];

      result.add((cluster?.pointsSize != null && (cluster?.pointsSize ?? 0) > 0)
          ? _createCluster(
              cluster,
              _xLng(cluster?.x ?? 0.0),
              _yLat(cluster?.y ?? 0.0),
            )
          : _points[cluster?.index ?? -1]);
    }

    return result;
  }

  List<T>? children(int clusterId) {
    int originId = clusterId >> 5;
    int originZoom = clusterId % 32;

    KDBush? index = _trees[originZoom];
    if (index == null) {
      return null;
    }

    BaseCluster origin = index.points[originId];
    double r = radius / (extent * math.pow(2, originZoom - 1));
    List<int> ids = index.within(origin.x ?? 0.0, origin.y ?? 0.0, r);

    List<T> children = [];
    for (int id in ids) {
      BaseCluster cluster = index.points[id];

      if (cluster.parentId == clusterId) {
        children
            .add((cluster.pointsSize != null && (cluster.pointsSize ?? 0) > 0)
                ? _createCluster(
                    cluster,
                    _xLng(cluster.x ?? 0.0),
                    _yLat(cluster.y ?? 0.0),
                  )
                : _points[cluster.index ?? -1]);
      }
    }

    return children;
  }

  List<T> points(int clusterId) {
    List<T> points = [];
    _extractClusterPoints(clusterId, points);
    return points;
  }

  void _extractClusterPoints(int clusterId, List<T> points) {
    List<T>? childList = children(clusterId);

    if (childList == null || childList.isEmpty) {
      return;
    } else {
      for (T child in childList) {
        if (child.isCluster ?? false) {
          _extractClusterPoints(child.clusterId ?? -1, points);
        } else {
          points.add(child);
        }
      }
    }
  }

  PointCluster _createPointCluster(T feature, int id) => PointCluster(
        x: _lngX(feature.longitude ?? 0.0),
        y: _latY(feature.latitude ?? 0.0),
        zoom: 24,
        index: id,
        markerId: feature.markerId,
      );

  List<BaseCluster> _buildClusters(List<BaseCluster> points, int zoom) {
    List<BaseCluster> clusters = [];
    double r = radius / (extent * math.pow(2, zoom));

    for (int i = 0; i < points.length; i++) {
      BaseCluster p = points[i];
      if ((p.zoom ?? 0) <= zoom) {
        continue;
      }
      p.zoom = zoom;

      KDBush? tree = _trees[zoom + 1];
      List<int> neighborIds = tree != null
          ? tree.within(
              p.x ?? 0.0,
              p.y ?? 0.0,
              r,
            )
          : [];

      int pointsSize = p.pointsSize ?? 1;
      double wx = (p.x ?? 0.0) * pointsSize;
      double wy = (p.y ?? 0.0) * pointsSize;

      String? childMarkerId =
          p.childMarkerId != null ? p.childMarkerId : p.markerId;

      int id = (i << 5) + (zoom + 1);

      for (int neighborId in neighborIds) {
        BaseCluster? b = tree?.points[neighborId];
        if (b == null) {
          continue;
        }

        if ((b.zoom ?? -1) <= zoom) {
          continue;
        }
        b.zoom = zoom;

        int pointsSize2 = b.pointsSize ?? 1;
        wx += (b.x ?? 0.0) * pointsSize2;
        wy += (b.y ?? 0.0) * pointsSize2;

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

  double _lngX(double lng) => lng / 360 + 0.5;

  double _latY(double lat) {
    double sin = math.sin(lat * math.pi / 180);
    double y = 0.5 - 0.25 * math.log((1 + sin) / (1 - sin)) / math.pi;
    return y < 0
        ? 0
        : y > 1
            ? 1
            : y;
  }

  double _xLng(double x) => (x - 0.5) * 360;

  double _yLat(double y) {
    double y2 = (180 - y * 360) * math.pi / 180;
    return 360 * math.atan(math.exp(y2)) / math.pi - 90;
  }

  int _limitZoom(int z) => math.max(minZoom, math.min(z, maxZoom + 1));
}
