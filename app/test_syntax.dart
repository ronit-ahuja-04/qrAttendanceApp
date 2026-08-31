import 'package:flutter/material.dart';
Widget test() {
  return Column(
    children: [
      Text('Smart Seminar Setup'),
      SizedBox(height: 16),
      Padding(padding: EdgeInsets.only(bottom: 16), child: Container(child: Text("Test"))),
      Padding(padding: EdgeInsets.only(bottom: 16), child: Container(child: Text("Test"))),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () { },
          icon: Icon(Icons.add_circle, color: Colors.blue),
          label: Text('Add Division', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ),
      if (true) ...[
        SizedBox(height: 8),
      ],
    ],
  );
}
