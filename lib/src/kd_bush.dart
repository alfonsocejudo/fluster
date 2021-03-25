import 'dart:collection';
import 'dart:math' as math;

import 'data/base_cluster.dart';

class KDBush {
  List<BaseCluster> points;
  int nodeSize;
  late List<int> ids;
  late List<double> coordinates;

  KDBush({
    required this.points,
    required this.nodeSize,
  }) {
    ids = List.filled(points.length, 0);
    coordinates = List.filled(points.length * 2, 0.0);

    for (int i = 0; i < points.length; i++) {
      ids[i] = i;
      coordinates[i * 2] = points[i].x ?? 0.0;
      coordinates[(i * 2) + 1] = points[i].y ?? 0.0;
    }

    _sortKD(
      ids: ids,
      coordinates: coordinates,
      nodeSize: nodeSize,
      left: 0,
      right: (ids.length - 1),
      axis: 0,
    );
  }

  _sortKD({
    required List<int> ids,
    required List<double> coordinates,
    required int nodeSize,
    required int left,
    required int right,
    required int axis,
  }) {
    if (right - left <= nodeSize) {
      return null;
    }

    int m = (left + right) >> 1;

    _select(
        ids: ids,
        coordinates: coordinates,
        k: m,
        left: left,
        right: right,
        axis: axis);

    _sortKD(
        ids: ids,
        coordinates: coordinates,
        nodeSize: nodeSize,
        left: left,
        right: m - 1,
        axis: 1 - axis);
    _sortKD(
        ids: ids,
        coordinates: coordinates,
        nodeSize: nodeSize,
        left: m + 1,
        right: right,
        axis: 1 - axis);
  }

  List<int> range(double minX, double minY, double maxX, double maxY) {
    Queue stack = Queue();
    stack.add(0);
    stack.add(ids.length - 1);
    stack.add(0);

    List<int> result = [];

    while (stack.isNotEmpty) {
      int axis = stack.removeLast();
      int right = stack.removeLast();
      int left = stack.removeLast();

      if (right - left <= nodeSize) {
        for (int i = left; i <= right; i++) {
          double x = coordinates[i * 2];
          double y = coordinates[i * 2 + 1];

          if (x >= minX && x <= maxX && y >= minY && y <= maxY) {
            result.add(ids[i]);
          }
        }

        continue;
      }

      int m = (left + right) >> 1;

      double x = coordinates[m * 2];
      double y = coordinates[m * 2 + 1];

      if (x >= minX && x <= maxX && y >= minY && y <= maxY) {
        result.add(ids[m]);
      }

      if (axis == 0 ? minX <= x : minY <= y) {
        stack.add(left);
        stack.add(m - 1);
        stack.add(1 - axis);
      }

      if (axis == 0 ? maxX >= x : maxY >= y) {
        stack.add(m + 1);
        stack.add(right);
        stack.add(1 - axis);
      }
    }

    return result;
  }

  List<int> within(double qx, double qy, double r) {
    Queue stack = Queue();
    stack.add(0);
    stack.add(ids.length - 1);
    stack.add(0);

    List<int> result = [];
    double r2 = r * r;

    while (stack.isNotEmpty) {
      int axis = stack.removeLast();
      int right = stack.removeLast();
      int left = stack.removeLast();

      if (right - left <= nodeSize) {
        for (int i = left; i <= right; i++) {
          final squared = _squaredDistance(
            coordinates[i * 2],
            coordinates[i * 2 + 1],
            qx,
            qy,
          );
          if (squared <= r2) {
            result.add(ids[i]);
          }
        }

        continue;
      }

      int m = (left + right) >> 1;

      double x = coordinates[m * 2];
      double y = coordinates[m * 2 + 1];

      if (_squaredDistance(x, y, qx, qx) <= r2) {
        result.add(ids[m]);
      }

      if (axis == 0 ? qx - r <= x : qy - r <= y) {
        stack.add(left);
        stack.add(m - 1);
        stack.add(1 - axis);
      }

      if (axis == 0 ? qx + r >= x : qy + r >= y) {
        stack.add(m + 1);
        stack.add(right);
        stack.add(1 - axis);
      }
    }

    return result;
  }

  void _select({
    required List<int> ids,
    required List<double> coordinates,
    required int k,
    required int left,
    required int right,
    required int axis,
  }) {
    while (right > left) {
      if (right - left > 600) {
        int n = right - left + 1;
        int m = k - left + 1;
        double z = math.log(n);
        double s = 0.5 * math.exp(2 * z / 3);
        double sd =
            0.5 * math.sqrt(z * s * (n - s) / n) * (m - n / 2 < 0 ? -1 : 1);
        int newLeft = (math.max(left, (k - m * s / n + sd).floor())).toInt();
        int newRight =
            (math.min(right, (k + (n - m) * s / n + sd).floor())).toInt();
        _select(
            ids: ids,
            coordinates: coordinates,
            k: k,
            left: newLeft,
            right: newRight,
            axis: axis);
      }

      double t = coordinates[k * 2 + axis];
      int i = left;
      int j = right;

      _swapItem(ids: ids, coordinates: coordinates, i: left, j: k);
      if (coordinates[right * 2 + axis] > t) {
        _swapItem(ids: ids, coordinates: coordinates, i: left, j: right);
      }

      while (i < j) {
        _swapItem(ids: ids, coordinates: coordinates, i: i, j: j);
        i++;
        j--;

        while (coordinates[i * 2 + axis] < t) {
          i++;
        }

        while (coordinates[j * 2 + axis] > t) {
          j--;
        }
      }

      if (coordinates[left * 2 + axis] == t) {
        _swapItem(ids: ids, coordinates: coordinates, i: left, j: j);
      } else {
        j++;
        _swapItem(ids: ids, coordinates: coordinates, i: j, j: right);
      }

      if (j <= k) {
        left = j + 1;
      }

      if (k <= j) {
        right = j - 1;
      }
    }
  }

  void _swapItem({
    required List<int> ids,
    required List<double> coordinates,
    required int i,
    required int j,
  }) {
    _swapInt(list: ids, i: i, j: j);
    _swapDouble(list: coordinates, i: i * 2, j: j * 2);
    _swapDouble(list: coordinates, i: (i * 2) + 1, j: (j * 2) + 1);
  }

  void _swapInt({
    required List<int> list,
    required int i,
    required int j,
  }) {
    int temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }

  void _swapDouble({
    required List<double> list,
    required int i,
    required int j,
  }) {
    double temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }

  double _squaredDistance(double ax, double ay, double bx, double by) {
    double dx = ax - bx;
    double dy = ay - by;

    return dx * dx + dy * dy;
  }
}
