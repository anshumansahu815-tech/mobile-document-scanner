import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_cropper/image_cropper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScanPro AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A11CB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
      ),
      home: const ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<File> images = [];

  Future<void> scanImage() async {
    try {
      List<String>? pictures = await CunningDocumentScanner.getPictures(isGalleryImportAllowed: true);

      if (pictures == null || pictures.isEmpty) return;

      for (String picPath in pictures) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: picPath,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Adjust Document ✂️',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            images.add(File(croppedFile.path));
          });
        }
      }
    } catch (e) {
      print("Error scanning document: $e");
    }
  }

  void deleteImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  String applyPrivacyShield(String text) {
    String safeText = text;
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    safeText = safeText.replaceAll(emailRegex, '📧 [EMAIL HIDDEN] ⬛⬛⬛');
    final phoneRegex = RegExp(r'(\+91[\-\s]?)?[6789]\d{9}');
    safeText = safeText.replaceAll(phoneRegex, '📱 [PHONE HIDDEN] ⬛⬛⬛');
    final aadhaarRegex = RegExp(r'\d{4}[\s\-]?\d{4}[\s\-]?\d{4}');
    safeText = safeText.replaceAll(aadhaarRegex, '🪪 [ID HIDDEN] ⬛⬛⬛');
    return safeText;
  }

  Future<void> extractText(File imageFile, {bool usePrivacy = false}) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    String extracted = recognizedText.text;
    String displayText = usePrivacy ? applyPrivacyShield(extracted) : extracted;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: usePrivacy ? Colors.green.withOpacity(0.1) : const Color(0xFF6A11CB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  usePrivacy ? Icons.security : Icons.text_snippet,
                  color: usePrivacy ? Colors.green : const Color(0xFF6A11CB)
              ),
            ),
            const SizedBox(width: 12),
            Text(
                usePrivacy ? "Secured Text" : "Extracted Text",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ],
        ),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              displayText.isEmpty ? "No readable text found 😅" : displayText,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ),
        ),
        actions: [
          if (extracted.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8008),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.g_translate, size: 18),
              label: const Text("Translate 🇮🇳", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                translateToHindi(displayText);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> translateToHindi(String originalText) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFFF8008)),
            SizedBox(height: 20),
            Text("AI is translating... ✨\n(First time takes a few seconds)", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.hindi,
    );

    try {
      final translatedText = await translator.translateText(originalText);
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Text("🇮🇳 "),
              Text("Hindi Translation", style: TextStyle(color: Color(0xFFFF8008), fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Text(
                translatedText,
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Awesome! 😎", style: TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      print("Translation Error: $e");
    } finally {
      translator.close();
    }
  }

  String generateSmartName(String text) {
    if (text.isEmpty) return "Scanned_Document";
    List<String> lines = text.split('\n');
    String name = lines.take(2).join(" ");
    name = name.replaceAll(RegExp(r'[^\w\s]'), '');
    name = name.trim().replaceAll(' ', '_');
    if (name.length > 30) name = name.substring(0, 30);
    return name.isEmpty ? "Scanned_Document" : name;
  }

  Future<String> getDocumentName() async {
    if (images.isEmpty) return "Scanned_Document";
    final inputImage = InputImage.fromFile(images.first);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return generateSmartName(recognizedText.text);
  }

  Future<String?> getManualName() async {
    TextEditingController controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Enter file name", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: "My_Document",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
              )
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<String> askFileName() async {
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Save PDF 📄", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("How would you like to name your file?", style: TextStyle(color: Colors.black54)),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, "MANUAL"),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Manual"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2575FC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, "AI"),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text("Auto AI"),
          ),
        ],
      ),
    ) ?? "AI";
  }

  Future<void> createPDF() async {
    if (images.isEmpty) return;

    String choice = await askFileName();
    String fileName;

    if (choice == "MANUAL") {
      String? manual = await getManualName();
      fileName = (manual == null || manual.isEmpty) ? "Scanned_Document" : manual.replaceAll(' ', '_');
    } else {
      fileName = await getDocumentName();
    }

    final pdf = pw.Document();
    for (var imgFile in images) {
      final img = pw.MemoryImage(imgFile.readAsBytesSync());
      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(img))));
    }

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$fileName.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: "Here is your scanned document 📄");
  }

  void _showAdobeStyleMenu(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
              ]
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                const SizedBox(width: 16),
                _bottomActionItem(Icons.text_snippet, "Extract Text", () {
                  Navigator.pop(context);
                  extractText(images[index], usePrivacy: false);
                }),
                _bottomActionItem(Icons.security, "Privacy Shield", () {
                  Navigator.pop(context);
                  extractText(images[index], usePrivacy: true);
                }, iconColor: Colors.greenAccent),
                _bottomActionItem(Icons.crop_rotate, "Re-Crop", () async {
                  Navigator.pop(context);
                  final croppedFile = await ImageCropper().cropImage(
                    sourcePath: images[index].path,
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: 'Re-Adjust Document ✂️',
                        toolbarColor: Colors.black,
                        toolbarWidgetColor: Colors.white,
                      ),
                    ],
                  );
                  if (croppedFile != null) {
                    setState(() {
                      images[index] = File(croppedFile.path);
                    });
                  }
                }),
                _bottomActionItem(Icons.share, "Share Page", () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(images[index].path)], text: "Scanned via ScanPro AI");
                }),
                _bottomActionItem(Icons.delete_outline, "Delete", () {
                  Navigator.pop(context);
                  deleteImage(index);
                }, isDanger: true),
                const SizedBox(width: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomActionItem(IconData icon, String label, VoidCallback onTap, {bool isDanger = false, Color? iconColor}) {
    Color finalIconColor = isDanger ? Colors.redAccent : (iconColor ?? Colors.white);
    Color finalBgColor = isDanger ? Colors.red.withOpacity(0.15) : (iconColor != null ? iconColor.withOpacity(0.1) : Colors.white.withOpacity(0.1));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: finalBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: finalIconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: finalIconColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("ScanPro AI ✨", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white, size: 26),
            tooltip: "Save as PDF",
            onPressed: images.isEmpty ? null : createPDF,
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2575FC).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: scanImage,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
          label: const Text("New Scan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: images.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2575FC).withOpacity(0.05),
              ),
              child: const Icon(Icons.document_scanner_outlined, size: 80, color: Color(0xFF2575FC)),
            ),
            const SizedBox(height: 24),
            const Text("No Documents Yet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            Text("Tap 'New Scan' to digitize your papers\nwith the power of AI.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[500], height: 1.5)),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: GridView.builder(
          itemCount: images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () => _showAdobeStyleMenu(index),
                      child: Image.file(
                        images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => deleteImage(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text("Page ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}