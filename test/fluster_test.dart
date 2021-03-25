/*
 * Created by Alfonso Cejudo, Wednesday, July 24th 2019.
 */

import 'package:test/test.dart';

import 'package:fluster/fluster.dart';
import 'package:fluster/src/clusterable.dart';

import 'common.dart';

void main() {
  group('Fluster API Tests', () {
    late Fluster fluster;

    setUp(() {
      fluster = Fluster(
          minZoom: 0,
          maxZoom: 20,
          radius: 150,
          extent: 2048,
          nodeSize: 0,
          points: <Clusterable>[],
          createCluster: (cluster, longitude, latitude) {
            return MockClusterable();
          });
    });

    test('Empty Set Test', () {
      expect(fluster.clusters([-180, -85, 180, 85], 2).length, 0);
    });
  });
}
