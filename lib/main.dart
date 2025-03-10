import 'package:flutter/material.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CleverTapPlugin.setDebugLevel(1);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PermissionScreen(),
    );
  }
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin(); // ✅ Correct instantiation

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeCleverTapInbox();
  }

  void _initializeCleverTapInbox() {
    CleverTapPlugin.initializeInbox(); // ✅ Initialize Inbox
    _cleverTapPlugin.setCleverTapInboxDidInitializeHandler(inboxDidInitialize);
    _cleverTapPlugin.setCleverTapInboxMessagesDidUpdateHandler(inboxMessagesDidUpdate);
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
    ].request();

    if (statuses[Permission.notification]?.isGranted ?? false) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
      }
    }
  }

  void inboxDidInitialize() {
    setState(() {
      print("📥 CleverTap Inbox Initialized");
    });
  }

  void inboxMessagesDidUpdate() {
    setState(() {
      print("🔄 CleverTap Inbox Messages Updated");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Requesting Permissions..."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text("Grant Permissions"),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin(); // ✅ Instance created

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _identityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void onUserLogin() {
    var profile = {
      'Name': _nameController.text,
      'Identity': _identityController.text,
      'Email': _emailController.text,
      'Phone': _phoneController.text,
      'stuff': ["bags", "shoes"],
    };
    CleverTapPlugin.onUserLogin(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User logged in successfully!")),
    );
  }

  void updateUserProfile() {
    var profile = {
      'Name': _nameController.text,
      'Identity': _identityController.text,
      'Email': _emailController.text,
      'Phone': _phoneController.text,
      'DOB': CleverTapPlugin.getCleverTapDate(DateTime.parse('2012-04-22')),
      'props': 'property1',
      'stuff': ["bags", "shoes"],
    };
    CleverTapPlugin.profileSet(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
  }
//on click to push notification buttion this function is called.
  void openInbox() {
    CleverTapPlugin.initializeInbox(); // ✅ Ensure Inbox is initialized
    Future.delayed(Duration(seconds: 1), () {
      var styleConfig = {
        'noMessageTextColor': '#ff6600',
        'noMessageText': 'No messages yet!',
        'navBarTitle': 'App Inbox Message'
      };
      CleverTapPlugin.showInbox(styleConfig);
    });

    
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CleverTap User Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _identityController, decoration: const InputDecoration(labelText: "Identity")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onUserLogin, child: const Text("On User Login")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: updateUserProfile, child: const Text("Update Profile")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: openInbox, child: const Text("Open App Inbox")),
          ],
        ),
      ),
    );
  }
}

