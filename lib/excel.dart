import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExcelHelper {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo? _androidInfo;

  Future<void> _initDeviceInfo() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      _androidInfo = info;
    }
  }

  Future<void> exportToExcel(BuildContext context, Map data) async {
    await _initDeviceInfo();
    int sdk = _androidInfo?.version.sdkInt ?? 0;

    // meminta izin penyimpanan
    if (sdk >= 33) {
      final PermissionStatus status = await Permission.manageExternalStorage.request();
      print("status: $status");

      // jika izin diberikan
      if (status == PermissionStatus.granted) {
        await _export(context, data);
      } else {
        // jika izin tidak diberikan
        print('Storage permission not granted');
        throw Exception('Storage permission not granted');
      }
    } else if (sdk >= 23) {
      final PermissionStatus status = await Permission.storage.request();

      // jika izin diberikan
      if (status == PermissionStatus.granted) {
        await _export(context, data);
      } else {
        // jika izin tidak diberikan
        print('Storage permission not granted');
        throw Exception('Storage permission not granted');
      }
    } else {
      // jika versi SDK Android tidak didukung
      print('Unsupported Android SDK version');
      throw Exception('Unsupported Android SDK version');
    }
  }

  Future<void> _export(BuildContext context, Map data) async {
    // ambil data ikan
    String largeFish = data['large_fish'];
    String veryLargeFish = data['very_large_fish'];

    // Dapatkan tanggal dan waktu saat ini
    String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // buat file excel
    var excel = Excel.createExcel();

    Sheet sheet = excel['Sheet1'];

    CellStyle cellStyle = CellStyle(bold: true);

    var cell1 = sheet.cell(CellIndex.indexByString("A1"));
    cell1.value = const TextCellValue("Ikan Berukuran Besar");
    cell1.cellStyle = cellStyle;

    var cell2 = sheet.cell(CellIndex.indexByString("B1"));
    cell2.value = const TextCellValue("Ikan Berukuran Sangat Besar");
    cell2.cellStyle = cellStyle;

    var cell3 = sheet.cell(CellIndex.indexByString("C1"));
    cell3.value = const TextCellValue("Tanggal dan Waktu");
    cell3.cellStyle = cellStyle;

    var cell4 = sheet.cell(CellIndex.indexByString("A2"));
    cell4.value = TextCellValue(largeFish);

    var cell5 = sheet.cell(CellIndex.indexByString("B2"));
    cell5.value = TextCellValue(veryLargeFish);

    var cell6 = sheet.cell(CellIndex.indexByString("C2"));
    cell6.value = TextCellValue(now);

    // Saving the file
    try {
      String? directory = await getAppDocsDir();
      Directory downloadDir = Directory('/storage/emulated/0/Download');
      String date = DateTime.now().toString().replaceAll(":", "-").replaceAll(" ", "_");
      String outputFile = "";
      if (Platform.isAndroid) {
        outputFile = "${downloadDir.path}/Data-Ikan-$date.xlsx";
      } else {
        outputFile = "$directory/Data-Ikan-$date.xlsx";
      }

      List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        File(join(outputFile))
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
      }
      print('File saved at $outputFile');

      // show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully exported to Excel!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export to Excel!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> getAppDocsDir() async {
    final appDocumentsDir = (await getExternalStorageDirectories(type: StorageDirectory.downloads))?.first;
    return appDocumentsDir?.path;
  }
}
