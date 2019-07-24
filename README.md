Fluster = Flutter + Cluster

A geospatial point clustering library for Dart (Flutter not actually required).
Essentially a Dart port of [supercluster](https://github.com/mapbox/supercluster).

![Image](fluster.gif?raw=true)

## Usage

### Implement Clusterable

Fluster will cluster a List of objects that conform to the Clusterable abstract
class, which includes necessary information such as latitude and longitude.

```dart
class MapMarker extends Clusterable {
  String markerId;
  double latitude;
  double longitude;

  MapMarker({this.markerId, this.latitude, this.longitude});
}
```

### Set up Fluster

Create a Fluster instance once you have a set of points you'd like to cluster:

```dart
List<MapMarker> markers = getMarkers();

Fluster<MapMarker> fluster = Fluster<MapMarker>(
      minZoom: 0,
      maxZoom: 20,
      radius: 150,
      extent: 2048,
      nodeSize: 64,
      points: markers,
      createCluster: (BaseCluster cluster, double longitude, double latitude) {
        return MapMarker(
            markerId: cluster.id.toString(),
            latitude: latitude,
            longitude: longitude);
      });
```

Parameters:

```dart
/// Any zoom value below minZoom will not generate clusters.
int minZoom;

/// Any zoom value above maxZoom will not generate clusters.
int maxZoom;

/// Cluster radius in pixels.
int radius;

/// Adjust the extent by powers of 2 (e.g. 512. 1024, ... max 8192) to get the
/// desired distance between markers where they start to cluster.
int extent;

/// The size of the KD-tree leaf node, which affects performance.
int nodeSize;

/// The List to be clustered.
List<T> points;

/// A callback to generate clusters of the given input type.
T Function(BaseCluster, double, double) createCluster;
```

### Get the clusters

You can then get the clusters for a given bounding box and zoom value, where the
bounding box = [southwestLng, southwestLat, northeastLng, northeastLat]:

```dart
List<MapMarker> clusters = fluster.clusters([-180, -85, 180, 85], _currentZoom);
```

### Get the cluster points

You can also get all the points inside a cluster, given the cluster id:

```dart
List<MapMarker> points = fluster.points(clusterId);
```


