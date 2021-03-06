import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quantum_map/StaffMap.dart';
import 'BeaconScanner.dart';

class StaffMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: GoogleMapSimple(),
    );
  }
}

class GoogleMapSimple extends StatefulWidget {
  @override
  State<GoogleMapSimple> createState() => GoogleMapSimpleState();
}

class GoogleMapSimpleState extends State<GoogleMapSimple> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _Nice = CameraPosition(
    target: LatLng(43.6915029, 7.294096),
    zoom: 13,
  );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Stack(children: <Widget>[
        GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: _Nice,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
        Positioned(
            top: 350,
            left: 90,
            right: 90,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.lightBlue,
              icon: Icon(Icons.arrow_forward_ios),
              label: new Text("Deployment",
                  style: new TextStyle(fontFamily: 'Broadwell')),
              onPressed: () {
                _startDepolyment();
              },
            )),
        Positioned(
            top: 250,
            left: 40,
            right: 40,
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Input Your Project ID',
                border: OutlineInputBorder(),
              ),
            )),
        Positioned(
          top: 100,
          left: 100,
          right: 100,
          child: GestureDetector(
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Beacons()),
                );
              },
              child: Image.asset(
                'images/ibeacon.png',
                width: 100,
                height: 100,
              )),
        )
      ]),
    );
  }

  Future<void> _startDepolyment() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StaffMap()),
    );
  }
}
