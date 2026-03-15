/// Example usage of StorageService
///
/// This file demonstrates how to use the StorageService in your app.
/// You can delete this file after understanding the usage.

import 'storage_service.dart';

class StorageServiceExample {
  // Example 1: Initialize and use StorageService
  Future<void> example1_BasicUsage() async {
    // Get instance (singleton pattern - only one instance exists)
    StorageService storage = await StorageService.getInstance();

    // Save a string
    await storage.setString("myKey", "myValue");

    // Get a string
    String? value = storage.getString("myKey");
    print("Value: $value"); // Output: Value: myValue
  }

  // Example 2: User Management
  Future<void> example2_UserManagement() async {
    StorageService storage = await StorageService.getInstance();

    // Save a new user
    bool saved = await storage.saveUser(
      username: "john_doe",
      password: "password123",
      role: "doctor",
      speciality: "Cardiology",
    );

    if (saved) {
      print("User saved successfully!");
    }

    // Sign in and fetch the user profile from Firestore
    final profile = await storage.signIn("john_doe", "password123");
    if (profile != null) {
      print("User found: ${profile['username']}");
      print("Role: ${profile['role']}");
      print("Speciality: ${profile['speciality']}");
    }
  }

  // Example 3: Login Session Management
  Future<void> example3_LoginSession() async {
    StorageService storage = await StorageService.getInstance();

    // Sign in (this also establishes the Firebase Auth session)
    await storage.signIn("john_doe", "password123");

    // Check if user is logged in
    bool isLoggedIn = storage.isLoggedIn();
    print("Is logged in: $isLoggedIn");

    // Get current user profile
    final profile = await storage.getCurrentUserProfile();
    if (profile != null) {
      print("Logged in user: ${profile['username']}");
      print("Role: ${profile['role']}");
      print("Speciality: ${profile['speciality']}");
    }

    // Clear session (logout)
    await storage.clearSession();
  }

  // Example 4: Different Data Types
  Future<void> example4_DifferentDataTypes() async {
    StorageService storage = await StorageService.getInstance();

    // Demonstrate basic type storage
    await storage.setString('test_name', 'John Doe');
    await storage.setInt('test_age', 30);
    await storage.setBool('is_active', true);
    await storage.setDouble('price', 99.99);
    await storage.setStringList('tags', ['flutter', 'dart', 'storage']);
  }

  // Example 5: Appointments Management
  Future<void> example5_Appointments() async {
    StorageService storage = await StorageService.getInstance();

    // Save appointments
    List<Map<String, String>> appointments = [
      {"name": "Patient 1", "time": "10:00 AM", "diagnosis": "Fever"},
      {"name": "Patient 2", "time": "11:00 AM", "diagnosis": "Cold"},
    ];

    await storage.saveAppointments(appointments);

    // Get appointments
    List<Map<String, String>> savedAppointments = storage.getAppointments();
    print("Total appointments: ${savedAppointments.length}");
  }

  // Example 6: Medicines Management
  Future<void> example6_Medicines() async {
    StorageService storage = await StorageService.getInstance();

    // Save medicines
    List<Map<String, String>> medicines = [
      {"id": "1", "title": "Aspirin", "available": "true", "count": "45"},
      {"id": "2", "title": "Paracetamol", "available": "true", "count": "30"},
    ];

    await storage.saveMedicines(medicines);

    // Get medicines
    List<Map<String, String>> savedMedicines = storage.getMedicines();
    print("Total medicines: ${savedMedicines.length}");
  }

  // Example 7: Utility Methods
  // Example 8: Error Handling
  Future<void> example8_ErrorHandling() async {
    try {
      StorageService storage = await StorageService.getInstance();

      bool saved = await storage.setString("key", "value");
      if (!saved) {
        print("Failed to save data");
      }

      String? value = storage.getString("key");
      if (value == null) {
        print("No value found for key");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
