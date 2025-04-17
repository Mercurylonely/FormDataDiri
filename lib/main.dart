import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Person {
  int id;
  String name;
  String nim;
  String faculty;
  String major;
  String address;
  String phone;
  String photoBase64;

  Person({
    required this.id,
    required this.name,
    required this.nim,
    required this.faculty,
    required this.major,
    required this.address,
    required this.phone,
    required this.photoBase64,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        name: json['name'],
        nim: json['nim'],
        faculty: json['faculty'],
        major: json['major'],
        address: json['address'],
        phone: json['phone'],
        photoBase64: json['photoBase64'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nim': nim,
        'faculty': faculty,
        'major': major,
        'address': address,
        'phone': phone,
        'photoBase64': photoBase64,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Diri App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const ListPage(),
        '/form': (_) => const FormPage(),
      },
    );
  }
}

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Person> persons = [];

  @override
  void initState() {
    super.initState();
    loadPersons();
  }

  Future<void> loadPersons() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('persons');
    if (data != null) {
      final List list = jsonDecode(data);
      persons = list.map((e) => Person.fromJson(e)).toList();
      setState(() {});
    }
  }

  Future<void> savePersons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persons', jsonEncode(persons.map((p) => p.toJson()).toList()));
  }

  void deletePerson(int index) {
    persons.removeAt(index);
    _reassignIds();
    savePersons();
    setState(() {});
  }

  void _reassignIds() {
    for (int i = 0; i < persons.length; i++) {
      persons[i].id = i + 1;
    }
  }

  void _sortAndReassign() {
    persons.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _reassignIds();
    savePersons();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Data Diri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'Sort A-Z',
            onPressed: _sortAndReassign,
          ),
        ],
      ),
      body: persons.isEmpty
          ? const Center(child: Text('Belum ada data'))
          : ListView.builder(
              itemCount: persons.length,
              itemBuilder: (context, index) {
                final p = persons[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: p.photoBase64.isEmpty
                        ? const Icon(Icons.person)
                        : CircleAvatar(
                            backgroundImage: MemoryImage(base64Decode(p.photoBase64)),
                          ),
                    title: Text('${p.id}. ${p.name}'),
                    subtitle: Text('NIM: ${p.nim}\nFakultas: ${p.faculty} - ${p.major}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FormPage(person: p)),
                            );
                            await loadPersons();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deletePerson(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/form');
          await loadPersons();
        },
        tooltip: 'Tambah Data',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FormPage extends StatefulWidget {
  final Person? person;

  const FormPage({Key? key, this.person}) : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _nimCtrl;
  late TextEditingController _facultyCtrl;
  late TextEditingController _majorCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  String _photoBase64 = '';

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _nameCtrl = TextEditingController(text: p?.name);
    _nimCtrl = TextEditingController(text: p?.nim);
    _facultyCtrl = TextEditingController(text: p?.faculty);
    _majorCtrl = TextEditingController(text: p?.major);
    _addressCtrl = TextEditingController(text: p?.address);
    _phoneCtrl = TextEditingController(text: p?.phone);
    _photoBase64 = p?.photoBase64 ?? '';
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> savePerson() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('persons');
    final list = data != null
        ? (jsonDecode(data) as List).map((e) => Person.fromJson(e)).toList()
        : <Person>[];

    if (widget.person != null) {
      // Edit existing
      list.removeWhere((e) => e.id == widget.person!.id);
    }

    final newPerson = Person(
      id: list.length + 1,
      name: _nameCtrl.text.trim(),
      nim: _nimCtrl.text.trim(),
      faculty: _facultyCtrl.text.trim(),
      major: _majorCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      photoBase64: _photoBase64,
    );
    list.add(newPerson);

    // Sort & reassign IDs
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (int i = 0; i < list.length; i++) {
      list[i].id = i + 1;
    }

    await prefs.setString('persons', jsonEncode(list.map((e) => e.toJson()).toList()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person == null ? 'Tambah Data' : 'Edit Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: pickPhoto,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _photoBase64.isEmpty
                      ? null
                      : MemoryImage(base64Decode(_photoBase64)),
                  child: _photoBase64.isEmpty
                      ? const Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildTextField(_nameCtrl, 'Nama'),
              ..._buildTextField(_nimCtrl, 'NIM', keyboard: TextInputType.number),
              ..._buildTextField(_facultyCtrl, 'Fakultas'),
              ..._buildTextField(_majorCtrl, 'Prodi'),
              ..._buildTextField(_addressCtrl, 'Alamat'),
              ..._buildTextField(_phoneCtrl, 'Nomor HP', keyboard: TextInputType.phone),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) savePerson();
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTextField(TextEditingController ctrl, String label, {TextInputType keyboard = TextInputType.text}) {
    return [
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? 'Field tidak boleh kosong' : null,
      ),
      const SizedBox(height: 16),
    ];
  }
}

/*
Dependencies:
  shared_preferences: ^2.0.15
  image_picker: ^0.8.5+3
*/
