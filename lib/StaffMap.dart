import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class Line {
  Offset p1;
  Offset p2;

  Line(Offset p1, Offset p2) {
    this.p1 = p1;
    this.p2 = p2;
  }
}

class Position {
  int top;
  int left;

  Position(int top, int left) {
    this.top = top;
    this.left = left;
  }
}

class StaffMap extends StatefulWidget {
  @override
  _StaffMapState createState() => new _StaffMapState();
}

class _StaffMapState extends State<StaffMap>
    with SingleTickerProviderStateMixin {
  //AnimationController controller;
  final lines = <Line>[];
  final points = <Offset>[];
  final positions = <Position>[];
  bool checkingState = false;
  String region = 'O+101';
  Offset current = Offset(-100, -100);
  StreamSubscription<RangingResult> _streamRanging;
  final _regionBeacons = <Region, List<Beacon>>{};
  final _beacons = <Beacon>[];
  final _beaconsCollector = HashMap<String, double>();
  final _beaconsList = <String>[];
  bool logging = false;
  _StaffMapState();
  StreamSubscription<double> _streamDoubleRanging;
  double _direction;
  double pi = 3.1415926;
  double shaking = 0.2;
  bool shakeState = false;
  int shakeStopCount = 0;
  String currentBeaconID = '';

  @override
  void initState() {
    super.initState();
    initMap();
    initBeacon();
    positions.add(new Position(0, 0));
    positions.add(new Position(0, 100));
    positions.add(new Position(0, 200));
    positions.add(new Position(80, 0));
    positions.add(new Position(80, 100));
    positions.add(new Position(80, 200));
    positions.add(new Position(160, 0));
    positions.add(new Position(160, 100));
    positions.add(new Position(160, 200));
    positions.add(new Position(240, 200));
    _beaconsList.add("E4:F5:46:61:6F:7A131343");
    _beaconsList.add("C3:A7:10:53:3F:BB147935");
    _beaconsList.add("D0:5F:5B:74:8E:B21256");
    _beaconsList.add("D2:2A:96:01:1A:C1149434");
    _beaconsList.add("F1:80:31:49:9A:5E124218");

    _streamDoubleRanging = FlutterCompass.events.listen((double direction) {
      setState(() {
        _direction = direction;
      });
    });
  }

  updatePosition() async {}

  initMap() async {
    lines.add(Line(Offset(0.0, 0.0), Offset(290.0, 0)));
    lines.add(Line(Offset(290.0, 0.0), Offset(290.0, 330.0)));
    lines.add(Line(Offset(290.0, 330.0), Offset(180.0, 330.0)));
    lines.add(Line(Offset(180.0, 320.0), Offset(180.0, 330.0)));
    lines.add(Line(Offset(290.0, 230.0), Offset(180.0, 230.0)));
    lines.add(Line(Offset(180.0, 220.0), Offset(180.0, 260.0)));

    lines.add(Line(Offset(0.0, 0.0), Offset(0.0, 230.0)));
    lines.add(Line(Offset(0.0, 230.0), Offset(130.0, 230.0)));
    lines.add(Line(Offset(130.0, 220.0), Offset(130.0, 330.0)));
  }

  @override
  void dispose() {
    if (_streamRanging != null) {
      _streamRanging.cancel();
    }
    if (_streamDoubleRanging != null) {
      _streamDoubleRanging.cancel();
    }
    super.dispose();
  }

  Future<File> _getLocalFile() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    return new File('$dir/points.txt');
  }

  void saveFingerprintToFiles() async {
    String fg = "";

    _beaconsList.forEach((key) {
      fg += _beaconsCollector[key].toString() + ",";
    });
    fg += '\n';
    await (await _getLocalFile()).writeAsString(fg);
    print(fg);
    _beaconsCollector.clear();
  }

  initBeacon() async {
    try {
      await flutterBeacon.initializeScanning;
      print('Beacon scanner initialized');
    } on PlatformException catch (e) {
      print(e);
    }

    final regions = <Region>[];

    if (Platform.isIOS) {
      regions.add(Region(
          identifier: 'com.bluecats.BlueCats',
          proximityUUID: '61687109-905F-4436-91F8-E602F514C96D'));
    } else {
      regions.add(Region(identifier: 'com.aprilbrother'));
    }

    _streamRanging = flutterBeacon.ranging(regions).listen((result) {
      if (logging) {
        if (result != null && mounted) {
          _regionBeacons[result.region] = result.beacons;
          _beacons.clear();
          _regionBeacons.values.forEach((list) {
            _beacons.addAll(list);
          });
          _beacons.sort(_compareParameters);
          _beacons.forEach((beacon) {
            _beaconsCollector[beacon.macAddress +
                beacon.major.toString() +
                beacon.minor.toString()] = beacon.accuracy * 100;
          });
          if (_beaconsCollector.length == 5) {
            saveFingerprintToFiles();
            setState(() {
              logging = false;
            });
          }
        }
      }
    });
  }

  int _compareParameters(Beacon a, Beacon b) {
    int compare = a.proximityUUID.compareTo(b.proximityUUID);

    if (compare == 0) {
      compare = a.major.compareTo(b.major);
    }

    if (compare == 0) {
      compare = a.minor.compareTo(b.minor);
    }

    return compare;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        //appBar: new AppBar(title: new Text(region)),
        body: new Builder(
            builder: (context) => new GestureDetector(
                child: new Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('images/mapBg.jpg'),
                            fit: BoxFit.fill)),
                    child: new Stack(children: <Widget>[
                      Positioned(
                          top: 190,
                          right: 35,
                          child: FloatingActionButton.extended(
                            backgroundColor: Colors.brown[600],
                            icon: Icon(Icons.check),
                            label: new Text("Terminer",
                                style: new TextStyle(fontFamily: 'Broadwell')),
                            onPressed: () {},
                          )),
                      Positioned(
                          top: 250,
                          left: 35,
                          right: 35,
                          child: new Stack(
                            children: <Widget>[
                              Image.asset('images/classroom.jpg'),
                              CustomPaint(
                                  willChange: true,
                                  child: new Container(),
                                  foregroundPainter:
                                      new MapPainter(lines, points)),
                              Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 0,
                                  left: 100,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 0,
                                  left: 200,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 80,
                                  left: 0,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 80,
                                  left: 100,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 80,
                                  left: 200,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 160,
                                  left: 0,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 160,
                                  left: 100,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 160,
                                  left: 200,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 240,
                                  left: 200,
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: new SizedBox(
                                      width: 90.0,
                                      height: 70.0,
                                      child: RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            logging = true;
                                          }); // Add your onPressed code here!
                                        },
                                      ),
                                    ),
                                  )),
                            ],
                          )),
                      Positioned(
                          top: 180,
                          left: 35,
                          child: new Text(
                            region,
                            style: new TextStyle(
                                fontSize: 21.0,
                                color: Colors.grey[350],
                                fontFamily: 'Broadwell'),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                            textAlign: TextAlign.left,
                          )),
                      Positioned(
                          top: 100,
                          left: 35,
                          right: 35,
                          child: new Text(
                            'Ubiquarium',
                            style: new TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 41.0,
                                color: Colors.grey[350],
                                fontFamily: 'Broadwell'),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.left,
                          )),
                      Positioned(
                          top: current.dy - 27.5,
                          left: current.dx - 27.5,
                          child: Transform.rotate(
                              angle: ((_direction ?? 0) * (pi / 180)),
                              child: new Image.asset('images/Point.png'))),
                      //-->TODO!!! Buttons below are very Bad practices, just for demo !!!! Never forget to come back and change them
                    ])))));
  }

  void showAlertDialog(BuildContext context, String message) {
    NavigatorState navigator =
        context.rootAncestorStateOfType(const TypeMatcher<NavigatorState>());
    debugPrint("navigator is null?" + (navigator == null).toString());
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              shape: new RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
              title: new Text("UNE ERREUR",
                  style:
                      new TextStyle(fontSize: 20.0, fontFamily: 'Broadwell')),
              content: new Text(message,
                  style:
                      new TextStyle(fontSize: 16.0, fontFamily: 'Broadwell')),
            ));
  }
}

class MapPainter extends CustomPainter {
  final lines;
  final points;

  MapPainter(this.lines, this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.black
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 0.5);
    for (Line line in lines) canvas.drawLine(line.p1, line.p2, paint);
    for (Offset point in points) canvas.drawCircle(point, 10, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
