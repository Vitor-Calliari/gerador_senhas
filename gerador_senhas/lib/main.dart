import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

void main() {
  runApp(const PasswordGeneratorApp());
}

class PasswordGeneratorApp extends StatelessWidget {
  const PasswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de Senhas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PasswordGeneratorScreen(),
    );
  }
}

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _phraseController = TextEditingController();

  String _selectedHash = "MD5";
  double _length = 12;
  bool _useExtraEntropy = true;

  String _generatedPassword = "";

  void _generatePassword() {
    if (!_formKey.currentState!.validate()) return;

    final service = _serviceController.text;
    final phrase = _phraseController.text;
    final length = _length.toInt();

    // Seed básica
    final seed = "$service-$phrase";

    // Hash escolhido
    Digest digest;
    final bytes = utf8.encode(seed);
    switch (_selectedHash) {
      case "SHA-1":
        digest = sha1.convert(bytes);
        break;
      case "SHA-256":
        digest = sha256.convert(bytes);
        break;
      default:
        digest = md5.convert(bytes);
    }

    List<int> finalBytes = digest.bytes;
    if (_useExtraEntropy) {
      final rng = Random.secure();
      final extra = List<int>.generate(8, (_) => rng.nextInt(256));
      finalBytes = [...digest.bytes, ...extra];
    }

    String password = base64UrlEncode(finalBytes);

    password = password.substring(0, length);

    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[^a-zA-Z0-9]').hasMatch(password);

    if (!(hasUpper && hasNumber && hasSymbol)) {
      password += "!Aa1"; 
      password = password.substring(0, length);
    }

    setState(() {
      _generatedPassword = password;
    });
  }

  void _copyPassword() {
    if (_generatedPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Senha copiada para a área de transferência!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerador de Senhas")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _serviceController,
                decoration: const InputDecoration(labelText: "Serviço / Site"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Informe o serviço" : null,
              ),
              TextFormField(
                controller: _phraseController,
                decoration: const InputDecoration(labelText: "Frase-base"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Informe a frase-base" : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedHash,
                decoration: const InputDecoration(labelText: "Algoritmo Hash"),
                items: ["MD5", "SHA-1", "SHA-256"]
                    .map((algo) => DropdownMenuItem(
                          value: algo,
                          child: Text(algo),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHash = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text("Comprimento da senha: ${_length.toInt()}"),
              Slider(
                value: _length,
                min: 8,
                max: 32,
                divisions: 24,
                label: _length.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _length = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text("Adicionar entropia extra"),
                value: _useExtraEntropy,
                onChanged: (value) {
                  setState(() {
                    _useExtraEntropy = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generatePassword,
                child: const Text("Gerar Senha"),
              ),
              const SizedBox(height: 20),
              if (_generatedPassword.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      _generatedPassword,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyPassword,
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
