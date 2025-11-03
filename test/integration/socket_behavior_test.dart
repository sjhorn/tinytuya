/// Verify socket close/open behavior for persist modes
/// This explicitly checks that sockets are closed/opened as expected

import 'dart:convert';
import 'dart:io';
import 'package:tinytuya/tinytuya.dart';

Future<void> main() async {
  print('═══════════════════════════════════════════════════════════════');
  print('Socket Behavior Verification Test');
  print('═══════════════════════════════════════════════════════════════');
  print('This test verifies socket close/open behavior\n');

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
  print('IP: ${v35Device['ip']}\n');

  // Test 1: persist=false - Socket should close after each operation
  print('─────────────────────────────────────────────────────────────');
  print('Test 1: persist=false - Verify socket closes after each op');
  print('─────────────────────────────────────────────────────────────');

  final deviceNoPersist = Device(
    deviceId: v35Device['device_id'],
    address: v35Device['ip'],
    localKey: v35Device['local_key'],
    version: v35Device['version'],
    persist: false,
  );

  try {
    final socketState = (bool active) => active ? 'OPEN' : 'CLOSED';
    print('Initial state: Socket ${socketState(deviceNoPersist.isSocketActive)}');

    // Operation 1
    print('\nOperation 1: Calling status()...');
    await deviceNoPersist.status();
    print('After operation: Socket ${socketState(deviceNoPersist.isSocketActive)}');
    print('  ✓ Expected: CLOSED, Actual: ${socketState(deviceNoPersist.isSocketActive)}');

    // Wait a bit to show socket stays closed
    await Future.delayed(const Duration(seconds: 2));
    print('After 2s wait: Socket ${socketState(deviceNoPersist.isSocketActive)}');

    // Operation 2
    print('\nOperation 2: Calling turnOn()...');
    await deviceNoPersist.turnOn();
    print('After operation: Socket ${socketState(deviceNoPersist.isSocketActive)}');
    print('  ✓ Expected: CLOSED, Actual: ${socketState(deviceNoPersist.isSocketActive)}');

    // Verify socket is truly closed between operations
    if (deviceNoPersist.isSocketActive) {
      print('\n❌ FAIL: Socket should be CLOSED with persist=false');
    } else {
      print('\n✅ PASS: Socket correctly CLOSED after each operation');
    }
  } finally {
    deviceNoPersist.close();
  }

  print('');

  // Test 2: persist=true - Socket should stay open, then test timeout
  print('─────────────────────────────────────────────────────────────');
  print('Test 2: persist=true - Socket stays open, test timeout');
  print('─────────────────────────────────────────────────────────────');

  final devicePersist = Device(
    deviceId: v35Device['device_id'],
    address: v35Device['ip'],
    localKey: v35Device['local_key'],
    version: v35Device['version'],
    persist: true,
  );

  try {
    final socketState = (bool active) => active ? 'OPEN' : 'CLOSED';
    print('Initial state: Socket ${socketState(devicePersist.isSocketActive)}');

    // Operation 1
    print('\nOperation 1: Calling status()...');
    await devicePersist.status();
    print('After operation: Socket ${socketState(devicePersist.isSocketActive)}');
    print('  ✓ Expected: OPEN, Actual: ${socketState(devicePersist.isSocketActive)}');

    // Verify socket stays open
    await Future.delayed(const Duration(seconds: 2));
    print('After 2s wait: Socket ${socketState(devicePersist.isSocketActive)}');

    // Operation 2 - should reuse existing socket
    print('\nOperation 2: Calling turnOn()...');
    await devicePersist.turnOn();
    print('After operation: Socket ${socketState(devicePersist.isSocketActive)}');
    print('  ✓ Expected: OPEN, Actual: ${socketState(devicePersist.isSocketActive)}');

    if (!devicePersist.isSocketActive) {
      print('\n❌ FAIL: Socket should stay OPEN with persist=true');
    } else {
      print('\n✅ PASS: Socket correctly stays OPEN between operations');
    }

    // Test 3: Wait for timeout (90 seconds) then verify reconnection
    print('\n─────────────────────────────────────────────────────────────');
    print('Test 3: Idle timeout test - Wait 90s, then reconnect');
    print('─────────────────────────────────────────────────────────────');
    print('Waiting 90 seconds without any operations...');
    print('(Socket will timeout and automatic reconnection will handle it)');

    await Future.delayed(const Duration(seconds: 90));

    print('\n90 seconds elapsed. Attempting operation...');
    final result = await devicePersist.status();

    if (result['success'] == true) {
      print('✅ Status query successful after 90s idle');
      print('   Automatic reconnection worked correctly');
    } else {
      print('❌ Status query failed after 90s idle');
    }

  } finally {
    devicePersist.close();
  }

  print('\n═══════════════════════════════════════════════════════════════');
  print('Verification Complete');
  print('═══════════════════════════════════════════════════════════════');
}
