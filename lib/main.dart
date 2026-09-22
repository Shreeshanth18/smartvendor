import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart'; 

void main() {
  runApp(const VendorSuperApp());
}

class VendorSuperApp extends StatelessWidget {
  const VendorSuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vendor Mate',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.blueGrey[50],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- VARIABLES ---
  int totalMoney = 0;
  List<String> history = [];
  
  bool isQrVisible = false;
  bool isIdVisible = false;
  String? qrImagePath;
  String? idImagePath;
  
  final TextEditingController _amountController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initTts();
  }

  // --- VOICE SETUP ---
  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-IN"); 
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  // --- LOGIC ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalMoney = prefs.getInt('money') ?? 0;
      history = prefs.getStringList('history') ?? [];
      qrImagePath = prefs.getString('qrPath');
      idImagePath = prefs.getString('idPath');
    });
  }

  Future<void> _handleTransaction(bool isIncome) async {
    if (_amountController.text.isEmpty) return;

    int enteredAmount = int.tryParse(_amountController.text) ?? 0;
    
    String time = "${DateTime.now().hour}:${DateTime.now().minute}";
    String type = isIncome ? "Sale" : "Expense";
    String newEntry = "$type: ₹$enteredAmount  @ $time";

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (isIncome) {
        totalMoney += enteredAmount;
        _speak("Added $enteredAmount Rupees");
      } else {
        totalMoney -= enteredAmount;
        _speak("Spent $enteredAmount Rupees");
      }
      history.insert(0, newEntry); 
      _amountController.clear();
    });
    
    await prefs.setInt('money', totalMoney);
    await prefs.setStringList('history', history);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _resetDay() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalMoney = 0;
      history.clear();
      _amountController.clear();
    });
    await prefs.setInt('money', 0);
    await prefs.setStringList('history', []);
    _speak("New Day Started");
  }

  Future<void> _pickImage(bool isQr) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (isQr) qrImagePath = image.path;
        else idImagePath = image.path;
      });
      await prefs.setString(isQr ? 'qrPath' : 'idPath', image.path);
    }
  }

  Future<void> _openWeather() async {
    final Uri url = Uri.parse('https://www.google.com/search?q=weather+today');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       debugPrint("Could not launch weather");
    }
  }

  Future<void> _sendReceipt() async {
    String message = "Namaste! Receipt from Vendor Mate. Total Amount: ₹$totalMoney. Thank you!";
    final Uri url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       debugPrint("Could not launch WhatsApp");
    }
  }

  Future<void> makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Vendor Mate', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Transaction & Safety App', style: TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _resetDay, icon: const Icon(Icons.delete_forever), tooltip: "Reset Day")
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // === TOP ROW: WEATHER & WHATSAPP ===
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openWeather,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue[100], foregroundColor: Colors.blue[900]),
                    icon: const Icon(Icons.cloud),
                    label: const Text("Weather", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendReceipt,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100], foregroundColor: Colors.green[900]),
                    icon: const Icon(Icons.share),
                    label: const Text("Send Bill", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),

            // === CALCULATOR ===
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("Today's Balance / आज की कमाई", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text("₹ $totalMoney", style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Enter Amount (₹)",
                        filled: true, fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton.icon(onPressed: () => _handleTransaction(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), icon: const Icon(Icons.add, color: Colors.white), label: const Text("Sale", style: TextStyle(color: Colors.white)))),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton.icon(onPressed: () => _handleTransaction(false), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]), icon: const Icon(Icons.remove, color: Colors.white), label: const Text("Spent", style: TextStyle(color: Colors.white)))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // === TRANSACTION HISTORY ===
            const Text("   History / पुराना हिसाब", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              height: 150,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: history.isEmpty 
                ? const Center(child: Text("No transactions yet."))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          history[index].contains("Sale") ? Icons.arrow_upward : Icons.arrow_downward,
                          color: history[index].contains("Sale") ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        title: Text(history[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
            ),

            const SizedBox(height: 20),

            // === DIGITAL VAULT ===
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () { setState(() { isQrVisible = !isQrVisible; isIdVisible = false; }); },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                      child: const Column(children: [Icon(Icons.qr_code_2, color: Colors.orange, size: 30), Text("QR Code", style: TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () { setState(() { isIdVisible = !isIdVisible; isQrVisible = false; }); },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.purple.withOpacity(0.3))),
                      child: const Column(children: [Icon(Icons.badge, color: Colors.purple, size: 30), Text("ID Card", style: TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  ),
                ),
              ],
            ),
            
            if (isQrVisible || isIdVisible) ...[
              const SizedBox(height: 15),
              Card(child: Padding(padding: const EdgeInsets.all(10.0), child: Column(children: [
                Text(isQrVisible ? "Scan to Pay" : "Vendor License / ID", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                (isQrVisible ? qrImagePath : idImagePath) == null
                    ? ElevatedButton.icon(onPressed: () => _pickImage(isQrVisible), icon: const Icon(Icons.upload), label: const Text("Upload Photo"))
                    : Column(children: [Image.file(File(isQrVisible ? qrImagePath! : idImagePath!), height: 250), TextButton(onPressed: () => _pickImage(isQrVisible), child: const Text("Change Photo"))]),
              ]))),
            ],

            const SizedBox(height: 20),
            const Text("   Help Center / मदद केंद्र", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // === HELP GRID (NOW WITH FIRE) ===
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildHelpButton("Ambulance", "108", Icons.medical_services, Colors.red[700]!),
                _buildHelpButton("Police", "100", Icons.local_police, Colors.indigo),
                
                // NEW: Fire Button
                _buildHelpButton("Fire", "101", Icons.fire_extinguisher, Colors.deepOrange),
                
                _buildHelpButton("BBMP", "1533", Icons.location_city, Colors.green[700]!),
                _buildHelpButton("Women", "1091", Icons.woman, Colors.pink),
                _buildHelpButton("Child", "1098", Icons.child_care, Colors.amber[800]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpButton(String title, String number, IconData icon, Color color) {
    return ElevatedButton(
      onPressed: () => makeCall(number),
      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.zero),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 20), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(number, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
    );
  }
}