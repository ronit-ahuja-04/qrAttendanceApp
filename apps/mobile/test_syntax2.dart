import 'package:flutter/material.dart';

Widget test(BuildContext context) {
  bool _isCombinedSeminar = true;
  String _year = '2023';
  String _seminarDivision = 'A';
  List<Map<String, String>> _seminarTargets = [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Smart Seminar Setup'),
      SizedBox(height: 16),
      Padding(padding: EdgeInsets.only(bottom: 16), child: Container()),
      Padding(padding: EdgeInsets.only(bottom: 16), child: Container()),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            
          },
          icon: Icon(Icons.add_circle,
              color: Colors.blue),
          label: Text('Add Division',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      if (_seminarTargets.isNotEmpty) ...[
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _seminarTargets
              .asMap()
              .entries
              .map((entry) {
            final int index = entry.key;
            final Map<String, String> target =
                entry.value;
            return Chip(
              label: Text(
                  '${target['year']} - ${target['division']}',
                  style: TextStyle(
                      fontSize: 12)),
              deleteIcon:
                  Icon(Icons.close, size: 16),
              onDeleted: () {
                
              },
              backgroundColor: Colors.blue,
              side: BorderSide.none,
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  filled: true,
                  fillColor: Colors.blue,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                child: Text('test'),
              ),
            ),
          ),
        ],
      )
    ]
  );
}
