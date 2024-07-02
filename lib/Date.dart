import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeDisplay extends StatefulWidget {
  const DateTimeDisplay({Key? key}) : super(key: key);

  @override
  _DateTimeDisplayState createState() => _DateTimeDisplayState();
}

class _DateTimeDisplayState extends State<DateTimeDisplay> {
  String _dateTimeString = '';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _startTimer();
  }

  void _startTimer() {
    // Update the time every second
    Future.delayed(Duration(seconds: 1), () {
      _updateDateTime();
      _startTimer();
    });
  }

  void _updateDateTime() {
    setState(() {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      _dateTimeString = formatter.format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/Tanggal.png',
          height: 50,
          width: 50,
        ),
        const SizedBox(height: 10),
        Text(
          '$_dateTimeString', // Tampilkan waktu di bawah gambar
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
