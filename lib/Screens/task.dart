import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  String task = '';

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  Future<void> addTask() async {
    if (user != null) {
      await _firestore.collection('tasks').add({
        'task': task,
        'completed': false,
        'userId': user!.uid,
      });
    }
  }

  Future<void> updateTask(DocumentSnapshot doc, bool completed) async {
    await _firestore.collection('tasks').doc(doc.id).update({'completed': !completed});
  }

  Future<void> deleteTask(DocumentSnapshot doc) async {
    await _firestore.collection('tasks').doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => task = value,
              decoration: const InputDecoration(labelText: 'New Task'),
            ),
          ),
          ElevatedButton(onPressed: addTask, child: const Text('Add Task')),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('tasks').where('userId', isEqualTo: user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task['task']),
                      leading: Checkbox(
                        value: task['completed'],
                        onChanged: (value) => updateTask(task, task['completed']),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteTask(task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
