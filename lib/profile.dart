// import "package:cloud_firestore/cloud_firestore.dart";
// import "package:firebase_auth/firebase_auth.dart";
// import "package:flutter/material.dart";

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Profile')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             StreamBuilder<DocumentSnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(user?.uid)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || !snapshot.data!.exists) {
//                   return const Text('Name: N/A',
//                       style: TextStyle(fontSize: 18));
//                 }
//                 final userData = snapshot.data!.data() as Map<String, dynamic>;
//                 final userName = userData['name'] ?? 'N/A';

//                 return Text('Name: $userName',
//                     style: const TextStyle(fontSize: 18));
//               },
//             ),
//             Text('Email: ${user?.email ?? 'N/A'}',
//                 style: const TextStyle(fontSize: 18)),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser ;
    _loadUserData(); // Corrected method name
  }

  void _loadUserData() async { // Corrected method name
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(_user!.uid).get();
      if (userDoc.exists) {
        _nameController.text = userDoc["name"];
        _emailController.text = userDoc["email"];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading user data: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection("users").doc(_user!.uid).update({
        "name": _nameController.text,
      });

      if (_passwordController.text.isNotEmpty) {
        await _user!.updatePassword(_passwordController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: "Email", hintText: _user?.email),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "New Password (leave empty to keep current)"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
      ),
    );
  }
}