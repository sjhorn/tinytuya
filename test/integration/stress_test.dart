/// Stress test for tinytuya_dart package
///
/// Tests rapid consecutive operations on v3.3, v3.4, and v3.5 devices
/// to verify the package-level fixes for stream cleanup and operation locking.
///
/// This test validates that we've achieved Python-level reliability.

import 'dart:io';
import 'package:tinytuya/tinytuya.dart';

/// Device configuration
class TestDevice {
  final String name;
  final String deviceId;
  final String localKey;
  final String ip;
  final double version;

  TestDevice({
    required this.name,
    required this.deviceId,
    required this.localKey,
    required this.ip,
    required this.version,
  });
}

/// Test result tracker
class TestResult {
  final String operation;
  final bool success;
  final Duration duration;
  final String? error;

  TestResult({
    required this.operation,
    required this.success,
    required this.duration,
    this.error,
  });
}

/// Stress test a single device with rapid consecutive operations
Future<List<TestResult>> stressTestDevice(TestDevice config, int cycles) async {
  print('\n${'=' * 80}');
  print('STRESS TEST: ${config.name}');
  print('${'=' * 80}');
  print('Device ID: ${config.deviceId}');
  print('IP: ${config.ip}');
  print('Version: ${config.version}');
  print('Test cycles: $cycles (${cycles * 2} total operations)');
  print('');

  final results = <TestResult>[];
  var successCount = 0;
  var failureCount = 0;

  final device = Device(
    deviceId: config.deviceId,
    address: config.ip,
    localKey: config.localKey,
    version: config.version,
  );

  try {
    print('Starting stress test at ${DateTime.now()}...\n');

    for (var i = 1; i <= cycles; i++) {
      print('Cycle $i/$cycles:');

      // Turn ON
      final onStart = DateTime.now();
      try {
        final result = await device.turnOn();
        final onDuration = DateTime.now().difference(onStart);

        if (result['success'] == true) {
          print('  ✓ ON  - ${onDuration.inMilliseconds}ms');
          results.add(TestResult(
            operation: 'Cycle $i - ON',
            success: true,
            duration: onDuration,
          ));
          successCount++;
        } else {
          print('  ✗ ON  - FAILED: $result');
          results.add(TestResult(
            operation: 'Cycle $i - ON',
            success: false,
            duration: onDuration,
            error: result.toString(),
          ));
          failureCount++;
        }
      } catch (e) {
        final onDuration = DateTime.now().difference(onStart);
        print('  ✗ ON  - ERROR: $e');
        results.add(TestResult(
          operation: 'Cycle $i - ON',
          success: false,
          duration: onDuration,
          error: e.toString(),
        ));
        failureCount++;
      }

      // Small delay between ON and OFF (but no delay between cycles)
      await Future.delayed(const Duration(milliseconds: 100));

      // Turn OFF
      final offStart = DateTime.now();
      try {
        final result = await device.turnOff();
        final offDuration = DateTime.now().difference(offStart);

        if (result['success'] == true) {
          print('  ✓ OFF - ${offDuration.inMilliseconds}ms');
          results.add(TestResult(
            operation: 'Cycle $i - OFF',
            success: true,
            duration: offDuration,
          ));
          successCount++;
        } else {
          print('  ✗ OFF - FAILED: $result');
          results.add(TestResult(
            operation: 'Cycle $i - OFF',
            success: false,
            duration: offDuration,
            error: result.toString(),
          ));
          failureCount++;
        }
      } catch (e) {
        final offDuration = DateTime.now().difference(offStart);
        print('  ✗ OFF - ERROR: $e');
        results.add(TestResult(
          operation: 'Cycle $i - OFF',
          success: false,
          duration: offDuration,
          error: e.toString(),
        ));
        failureCount++;
      }

      // NO delay between cycles - this is the stress test!
      // We want to test rapid consecutive operations
    }

    print('\n${'─' * 80}');
    print('TEST SUMMARY FOR ${config.name}');
    print('${'─' * 80}');
    print('Total operations: ${results.length}');
    print('Successful: $successCount (${(successCount / results.length * 100).toStringAsFixed(1)}%)');
    print('Failed: $failureCount (${(failureCount / results.length * 100).toStringAsFixed(1)}%)');

    // Calculate timing statistics
    final successfulResults = results.where((r) => r.success).toList();
    if (successfulResults.isNotEmpty) {
      final durations = successfulResults.map((r) => r.duration.inMilliseconds).toList();
      durations.sort();

      final avg = durations.reduce((a, b) => a + b) / durations.length;
      final min = durations.first;
      final max = durations.last;
      final median = durations[durations.length ~/ 2];

      print('\nTiming Statistics (successful operations):');
      print('  Average: ${avg.toStringAsFixed(1)}ms');
      print('  Median:  ${median}ms');
      print('  Min:     ${min}ms');
      print('  Max:     ${max}ms');
    }

    // Show failures if any
    if (failureCount > 0) {
      print('\nFailed Operations:');
      for (final result in results.where((r) => !r.success)) {
        print('  ✗ ${result.operation}: ${result.error}');
      }
    }

    print('${'=' * 80}\n');
  } finally {
    device.close();
  }

  return results;
}

/// Main stress test runner
void main() async {
  print('╔════════════════════════════════════════════════════════════════════════════╗');
  print('║                    TinyTuya Dart - Stress Test Suite                      ║');
  print('║                                                                            ║');
  print('║  Testing rapid consecutive operations to validate package-level fixes     ║');
  print('║  Target: Zero failures, matching Python implementation reliability        ║');
  print('╚════════════════════════════════════════════════════════════════════════════╝');
  print('');

  // Define test devices
  // TODO: Replace with your actual device credentials or load from devices.json
  final devices = [
    TestDevice(
      name: 'Device v3.3',
      deviceId: 'YOUR_DEVICE_ID_HERE',
      localKey: 'YOUR_LOCAL_KEY_HERE',
      ip: '192.168.1.100',
      version: 3.3,
    ),
    TestDevice(
      name: 'Device v3.4',
      deviceId: 'YOUR_DEVICE_ID_HERE',
      localKey: 'YOUR_LOCAL_KEY_HERE',
      ip: '192.168.1.101',
      version: 3.4,
    ),
    TestDevice(
      name: 'Device v3.5',
      deviceId: 'YOUR_DEVICE_ID_HERE',
      localKey: 'YOUR_LOCAL_KEY_HERE',
      ip: '192.168.1.102',
      version: 3.5,
    ),
  ];

  // Test configuration
  const cyclesPerDevice = 20; // 20 ON/OFF cycles = 40 total operations per device

  print('Test Configuration:');
  print('  Devices: ${devices.length}');
  print('  Cycles per device: $cyclesPerDevice');
  print('  Total operations per device: ${cyclesPerDevice * 2}');
  print('  Total operations across all devices: ${devices.length * cyclesPerDevice * 2}');
  print('');

  print('Press ENTER to start the stress test...');
  stdin.readLineSync();
  print('');

  // Track overall results
  final allResults = <String, List<TestResult>>{};
  final startTime = DateTime.now();

  // Test each device
  for (final device in devices) {
    final results = await stressTestDevice(device, cyclesPerDevice);
    allResults[device.name] = results;

    // Small pause between devices
    await Future.delayed(const Duration(seconds: 2));
  }

  final totalDuration = DateTime.now().difference(startTime);

  // Print overall summary
  print('\n');
  print('╔════════════════════════════════════════════════════════════════════════════╗');
  print('║                        OVERALL TEST SUMMARY                                ║');
  print('╚════════════════════════════════════════════════════════════════════════════╝');
  print('');
  print('Total test duration: ${totalDuration.inSeconds} seconds');
  print('');

  var totalOps = 0;
  var totalSuccess = 0;
  var totalFailures = 0;

  for (final entry in allResults.entries) {
    final deviceName = entry.key;
    final results = entry.value;
    final successes = results.where((r) => r.success).length;
    final failures = results.where((r) => !r.success).length;

    totalOps += results.length;
    totalSuccess += successes;
    totalFailures += failures;

    final successRate = (successes / results.length * 100).toStringAsFixed(1);
    final status = failures == 0 ? '✓' : '✗';

    print('$status $deviceName:');
    print('    Total: ${results.length} ops');
    print('    Success: $successes ($successRate%)');
    print('    Failures: $failures');
    print('');
  }

  print('${'─' * 80}');
  print('GRAND TOTAL:');
  print('  Operations: $totalOps');
  print('  Successful: $totalSuccess (${(totalSuccess / totalOps * 100).toStringAsFixed(1)}%)');
  print('  Failed: $totalFailures (${(totalFailures / totalOps * 100).toStringAsFixed(1)}%)');
  print('');

  if (totalFailures == 0) {
    print('🎉 SUCCESS! All operations completed without errors!');
    print('   Package reliability matches Python implementation.');
  } else {
    print('⚠️  WARNING: $totalFailures failures detected.');
    print('   Further investigation needed.');
  }

  print('╔════════════════════════════════════════════════════════════════════════════╗');
  print('║                           Test Complete                                   ║');
  print('╚════════════════════════════════════════════════════════════════════════════╝');
}
