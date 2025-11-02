/// Test for session timeout issue after ~1 minute
/// This script repeatedly controls a device over an extended period
/// to reproduce the session loss issue

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:tinytuya/tinytuya.dart';

Future<void> main() async {
  print('═══════════════════════════════════════════════════════════════');
  print('Session Timeout Test - v3.5 Device');
  print('═══════════════════════════════════════════════════════════════');
  print('This test will:');
  print('1. Control the device every 10 seconds for 3 minutes');
  print('2. Monitor for session loss or connection failures');
  print('3. Test if the session expires after ~1 minute');
  print('═══════════════════════════════════════════════════════════════\n');

  // Load device configuration
  final configFile = File('example/devices.json');
  if (!configFile.existsSync()) {
    print('Error: devices.json not found');
    exit(1);
  }

  final config = jsonDecode(await configFile.readAsString());
  final devices = config['devices'] as List;

  // Find v3.5 device
  final v35Device = devices.firstWhere(
    (d) => d['version'] == 3.5,
    orElse: () => null,
  );

  if (v35Device == null) {
    print('Error: No v3.5 device found in config');
    exit(1);
  }

  print('Testing with device: ${v35Device['name']}');
  print('IP: ${v35Device['ip']}');
  print('Version: ${v35Device['version']}');
  print('Device ID: ${v35Device['device_id']}');
  print('');

  // Create device instance
  final device = Device(
    deviceId: v35Device['device_id'],
    address: v35Device['ip'],
    localKey: v35Device['local_key'],
    version: v35Device['version'],
  );

  var operationCount = 0;
  var successCount = 0;
  var failureCount = 0;
  final startTime = DateTime.now();

  try {
    print('Starting test...');
    print('Press Ctrl+C to stop early\n');

    // Test 1: Initial connection and status
    operationCount++;
    print('─────────────────────────────────────────────────────────────');
    print('Test 1: Initial connection and status query');
    print('─────────────────────────────────────────────────────────────');
    try {
      print('Calling device.status()...');
      final statusResult = await device.status();

      if (statusResult['success'] == true) {
        print('✓ Status query successful');
        print('  DPS: ${statusResult['dps']}');
        successCount++;
      } else {
        print('✗ Status query failed: ${statusResult['error'] ?? statusResult}');
        failureCount++;
      }
    } catch (e, stackTrace) {
      print('✗ Exception during status query: $e');
      print('Stack trace: $stackTrace');
      failureCount++;
    }

    // Test 2: Wait 1 minute idle, then try again
    print('\n─────────────────────────────────────────────────────────────');
    print('Test 2: Idle for 1 minute, then query status');
    print('─────────────────────────────────────────────────────────────');
    print('Waiting 1 minute (60 seconds) with idle connection...');
    await Future.delayed(const Duration(seconds: 60));

    operationCount++;
    print('1 minute elapsed. Attempting status query...');
    try {
      print('Calling device.status()...');
      final statusResult = await device.status();

      if (statusResult['success'] == true) {
        print('✓ Status query successful after 1 minute idle');
        print('  DPS: ${statusResult['dps']}');
        successCount++;
      } else {
        print('✗ Status query failed after 1 minute idle: ${statusResult['error'] ?? statusResult}');
        failureCount++;
      }
    } catch (e, stackTrace) {
      print('✗ Exception during status query after 1 minute idle: $e');
      print('Stack trace: $stackTrace');
      failureCount++;
    }

    // Test 3: Turn device on
    operationCount++;
    print('\nAttempting to turn device ON...');
    try {
      print('Calling device.turnOn()...');
      final result = await device.turnOn();

      if (result['success'] == true) {
        print('✓ Turn ON successful');
        successCount++;
      } else {
        print('✗ Turn ON failed: ${result['error'] ?? result}');
        failureCount++;
      }
    } catch (e, stackTrace) {
      print('✗ Exception during turn ON: $e');
      print('Stack trace: $stackTrace');
      failureCount++;
    }

    // Test 4: Wait 2 minutes idle, then try again
    print('\n─────────────────────────────────────────────────────────────');
    print('Test 4: Idle for 2 minutes, then query status');
    print('─────────────────────────────────────────────────────────────');
    print('Waiting 2 minutes (120 seconds) with idle connection...');
    await Future.delayed(const Duration(seconds: 120));

    operationCount++;
    print('2 minutes elapsed. Attempting status query...');
    try {
      print('Calling device.status()...');
      final statusResult = await device.status();

      if (statusResult['success'] == true) {
        print('✓ Status query successful after 2 minutes idle');
        print('  DPS: ${statusResult['dps']}');
        successCount++;
      } else {
        print('✗ Status query failed after 2 minutes idle: ${statusResult['error'] ?? statusResult}');
        failureCount++;
      }
    } catch (e, stackTrace) {
      print('✗ Exception during status query after 2 minutes idle: $e');
      print('Stack trace: $stackTrace');
      failureCount++;
    }

    // Test 5: Turn device off
    operationCount++;
    print('\nAttempting to turn device OFF...');
    try {
      print('Calling device.turnOff()...');
      final result = await device.turnOff();

      if (result['success'] == true) {
        print('✓ Turn OFF successful');
        successCount++;
      } else {
        print('✗ Turn OFF failed: ${result['error'] ?? result}');
        failureCount++;
      }
    } catch (e, stackTrace) {
      print('✗ Exception during turn OFF: $e');
      print('Stack trace: $stackTrace');
      failureCount++;
    }

  } finally {
    print('\n═══════════════════════════════════════════════════════════════');
    print('Test Complete');
    print('═══════════════════════════════════════════════════════════════');
    print('Total operations: $operationCount');
    print('Successful: $successCount');
    print('Failed: $failureCount');
    print('Success rate: ${(successCount * 100 / operationCount).toStringAsFixed(1)}%');
    print('Total duration: ${DateTime.now().difference(startTime).inSeconds}s');
    print('═══════════════════════════════════════════════════════════════\n');

    // Close device connection
    device.close();
    print('Device connection closed');
  }
}
