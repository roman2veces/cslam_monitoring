import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ditredi/ditredi.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:roslibdart/roslibdart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late DiTreDiController controller;
  List<Point3D> points = [];
  Color color = Colors.black;

  // ROS variables
  late Ros ros;
  late Topic pointcloud;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();

    controller = DiTreDiController();

    // ROS config
    ros = Ros(url: 'ws://127.0.0.1:9090');
    pointcloud = Topic(
      ros: ros,
      name: '/kitti/velo/pointcloud',
      type: "sensor_msgs/msg/PointCloud2",
      reconnectOnClose: true,
      queueLength: 10,
      queueSize: 10,
    );
    ros.connect();
    Timer(const Duration(seconds: 3), () async {
      await pointcloud.subscribe(subscribeHandler);
    });
  }

  String msgReceived = '';
  Future<void> subscribeHandler(Map<String, dynamic> msg) async {
    final fields = msg["fields"];
    // print("Point: (${x}, ${y}, ${z})");

    final data = msg["data"] as String;
    int counter = 0;
    // final x = fields[0]["offset"];
    // final y = fields[1]["offset"];
    // final z = fields[2]["offset"];
    // final i = fields[3]["offset"];
    int x = 0;
    int y = 0;
    int z = 0;
    int opacity = 0;

    for (var i = 0; i < data.length; i++) {
      counter++;
      if (counter == 1) x = data[i].codeUnitAt(0);
      if (counter == 2) y = data[i].codeUnitAt(0);
      if (counter == 3) z = data[i].codeUnitAt(0);
      if (counter == 4) {
        opacity = data[i].codeUnitAt(0);
        counter = 0;
        points.add(
          Point3D(
            vector.Vector3(x.toDouble(), y.toDouble(), z.toDouble()),
            color: Colors.green,
            width: 2,
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: DiTreDiDraggable(
                controller: controller,
                child: DiTreDi(
                  figures: [
                    ...points,
                  ],
                  config: DiTreDiConfig(
                    defaultColorMesh: Colors.green,
                    defaultColorPoints: Colors.pink,
                    defaultPointWidth: 10,
                    // defaultLineWidth: 30,
                    supportZIndex: false,
                    perspective: true,
                  ),
                  controller: controller,
                ),
              ),
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          color = Colors.blue;
          setState(() {});
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
