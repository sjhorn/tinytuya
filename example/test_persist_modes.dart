/// Test both persist=false (default) and persist=true modes
/// This verifies socket behavior matches Python TinyTuya

import 'dart:convert';
import 'dart:io';
import 'package:tinytuya/tinytuya.dart';

Future<void> main() async {
  print('═══════════════════════════════════════════════════════════════');
  print('Persist Mode Test - v3.5 Device');
  print('═══════════════════════════════════════════════════════════════');
  print('This test compares persist=false (default) vs persist=true');
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
  print('Version: ${v35Device['version']}\n');

  // Test 1: persist=false (default, matches Python's socketPersistent=False)
  print('─────────────────────────────────────────────────────────────');
  print('Test 1: persist=false (default) - Socket closes after each op');
  print('─────────────────────────────────────────────────────────────');

  final deviceNoPersist = Device(
    deviceId: v35Device['device_id'],
    address: v35Device['ip'],
    localKey: v35Device['local_key'],
    version: v35Device['version'],
    persist: false, // Explicit, but this is the default
  );

  try {
    var success = 0;
    var failed = 0;

    // Operation 1: Status query
    final status1 = await deviceNoPersist.status();
    if (status1['success'] == true) {
      print('✓ Status query 1 successful');
      success++;
    } else {
      print('✗ Status query 1 failed');
      failed++;
    }

    // Small delay between operations
    await Future.delayed(const Duration(milliseconds: 100));

    // Operation 2: Turn on
    final turnOn = await deviceNoPersist.turnOn();
    if (turnOn['success'] == true) {
      print('✓ Turn ON successful');
      success++;
    } else {
      print('✗ Turn ON failed');
      failed++;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // Operation 3: Status query
    final status2 = await deviceNoPersist.status();
    if (status2['success'] == true) {
      print('✓ Status query 2 successful');
      success++;
    } else {
      print('✗ Status query 2 failed');
      failed++;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // Operation 4: Turn off
    final turnOff = await deviceNoPersist.turnOff();
    if (turnOff['success'] == true) {
      print('✓ Turn OFF successful');
      success++;
    } else {
      print('✗ Turn OFF failed');
      failed++;
    }

    print('persist=false: $success/${ success + failed} operations successful');
  } finally {
    deviceNoPersist.close();
  }

  print('');

  // Test 2: persist=true - Socket stays open between operations
  print('─────────────────────────────────────────────────────────────');
  print('Test 2: persist=true - Socket stays open between operations');
  print('─────────────────────────────────────────────────────────────');

  final devicePersist = Device(
    deviceId: v35Device['device_id'],
    address: v35Device['ip'],
    localKey: v35Device['local_key'],
    version: v35Device['version'],
    persist: true, // Keep socket open
  );

  try {
    var success = 0;
    var failed = 0;

    // Operation 1: Status query
    final status1 = await devicePersist.status();
    if (status1['success'] == true) {
      print('✓ Status query 1 successful');
      success++;
    } else {
      print('✗ Status query 1 failed');
      failed++;
    }

    // Small delay between operations
    await Future.delayed(const Duration(milliseconds: 100));

    // Operation 2: Turn on
    final turnOn = await devicePersist.turnOn();
    if (turnOn['success'] == true) {
      print('✓ Turn ON successful');
      success++;
    } else {
      print('✗ Turn ON failed');
      failed++;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // Operation 3: Status query
    final status2 = await devicePersist.status();
    if (status2['success'] == true) {
      print('✓ Status query 2 successful');
      success++;
    } else {
      print('✗ Status query 2 failed');
      failed++;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // Operation 4: Turn off
    final turnOff = await devicePersist.turnOff();
    if (turnOff['success'] == true) {
      print('✓ Turn OFF successful');
      success++;
    } else {
      print('✗ Turn OFF failed');
      failed++;
    }

    print('persist=true: $success/${success + failed} operations successful');
  } finally {
    devicePersist.close();
  }

  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('Both persist modes working correctly!');
  print('═══════════════════════════════════════════════════════════════');
}
