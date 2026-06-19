import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Services/theme_manager.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Speech to text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // API State
  String _geminiApiKey = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _initSpeech();
    
    // Welcome message
    _messages.add(ChatMessage(
      text: "Halo! Saya SmartDrop AI Assistant. Ada yang bisa saya bantu terkait transaksi COD, Safe Zones, pelacakan penjual, atau penggunaan aplikasi SmartDrop?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load saved API key from env asset
  Future<void> _loadApiKey() async {
    try {
      final envContent = await rootBundle.loadString('assets/public/.env');
      final lines = envContent.split('\n');
      String loadedKey = '';
      for (var line in lines) {
        if (line.contains('GEMINI_API_KEY=')) {
          loadedKey = line.split('GEMINI_API_KEY=')[1].trim();
          break;
        }
      }
      setState(() {
        _geminiApiKey = loadedKey;
      });
    } catch (e) {
      debugPrint('Error loading .env asset: $e');
    }
  }

  // Init speech to text
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  // Toggle listening
  void _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      if (!_speechEnabled) {
        _initSpeech();
      }
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  // Scroll to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Generate mock fallback response
  String _generateMockResponse(String userQuery) {
    final query = userQuery.toLowerCase();
    
    if (query.contains('safe zone') || query.contains('safezone') || query.contains('titik aman') || query.contains('lokasi aman') || query.contains('kumpul')) {
      return "Safe Zones (Titik Kumpul Aman) adalah lokasi-lokasi publik strategis seperti pos satpam, minimarket, stasiun, atau kantor polisi yang kami rekomendasikan untuk titik temu COD Anda guna memastikan keselamatan bertransaksi.";
    } else if (query.contains('cod') || query.contains('cash on delivery') || query.contains('bayar') || query.contains('tunai') || query.contains('alamat')) {
      return "Dengan SmartDrop, saat bertransaksi COD (Cash on Delivery), alamat pembeli dan penjual akan tersimpan untuk melacak titik pengiriman. Kami menyarankan Anda selalu memeriksa kecocokan barang secara detail sebelum menyerahkan pembayaran tunai kepada penjual.";
    } else if (query.contains('ping') || query.contains('nudge') || query.contains('hubungi') || query.contains('darurat')) {
      return "Fitur 'Quick Nudge' atau tombol 'Ping!' memungkinkan Anda mengirimkan getaran dan notifikasi darurat cepat langsung ke penjual jika mereka lambat merespons pesan Anda selama proses pengiriman.";
    } else if (query.contains('lacak') || query.contains('track') || query.contains('lokasi') || query.contains('peta')) {
      return "Anda dapat memantau pergerakan penjual secara real-time pada peta interaktif di halaman tracking pesanan setelah penjual mengaktifkan status pengantaran.";
    } else if (query.contains('jarak') || query.contains('geofence') || query.contains('tiba') || query.contains('radius')) {
      return "Sistem kami menggunakan Geofencing (validasi jarak 50 meter). Penjual hanya dapat menekan tombol 'Tiba di Lokasi' jika koordinat GPS mereka berada dalam radius 50 meter dari pin lokasi pertemuan Anda.";
    } else if (query.contains('halo') || query.contains('hi') || query.contains('pagi') || query.contains('siang') || query.contains('sore') || query.contains('malam')) {
      return "Halo! Ada yang bisa saya bantu mengenai aplikasi SmartDrop hari ini? Anda bisa menanyakan tentang COD aman, Safe Zones, cara tracking pesanan, atau fitur lainnya.";
    }
    
    return "Terima kasih atas pertanyaan Anda. Untuk bantuan lebih spesifik terkait hal tersebut, silakan hubungi pusat bantuan kami atau setel Gemini API Key Anda pada tombol pengaturan di kanan atas untuk mengaktifkan AI chatbot yang lebih pintar dan responsif!";
  }

  // Send message
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isGenerating = true;
    });
    _scrollToBottom();

    // Call API or mock
    if (_geminiApiKey.trim().isNotEmpty) {
      try {
        final response = await _callGeminiApi(text);
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isGenerating = false;
          });
          _scrollToBottom();
        }
      } catch (e) {
        debugPrint('Gemini API Error: $e');
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: "Maaf, terjadi kesalahan saat menghubungi asisten AI (Error: ${e.toString()}). Silakan coba lagi atau periksa konfigurasi API Key Anda.",
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isGenerating = false;
          });
          _scrollToBottom();
        }
      }
    } else {
      // Mock Response delay
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _generateMockResponse(text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    }
  }

  // Gemini API Caller
  Future<String> _callGeminiApi(String userPrompt) async {
    final systemInstructionText = 
      "You are a helpful, professional, and friendly Customer Service AI Assistant for 'SmartDrop', an advanced secure Cash on Delivery (COD) transaction app. "
      "SmartDrop features include: drop pin COD location, public strategic 'Safe Zones' for meetings, real-time live GPS tracking of sellers, ETA info, internal in-app chat, and 'Quick Nudge' (Ping!). "
      "Geofencing: Sellers must be within a 50-meter radius of the buyer's drop pin to mark 'Arrived at Location'. "
      "COD Security advice: Always meet in Safe Zones, inspect goods before paying cash. "
      "Reply in Indonesian (Bahasa Indonesia) politely, concisely, and formatting with bullet points or clear structures if needed.";

    // FIX 1: Gunakan jalur v1beta agar mendukung system_instruction dan model gemini-2.5-flash yang tersedia di key ini
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey'
    );

    final chatContents = []; 
    
    for (var msg in _messages) {
      chatContents.add({
        "role": msg.isUser ? "user" : "model",
        "parts": [
          {"text": msg.text}
        ]
      });
    }
    
    chatContents.add({
      "role": "user",
      "parts": [
        {"text": userPrompt}
      ]
    });

    // FIX 2: Google AI REST API (v1 dan v1beta) WAJIB menggunakan snake_case (system_instruction)
    final requestBody = {
      "system_instruction": {
        "parts": [
          {"text": systemInstructionText}
        ]
      },
      "contents": chatContents,
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 800,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text.toString().trim();
    } else {
      debugPrint('HTTP Error Code: ${response.statusCode}');
      debugPrint('Error Body: ${response.body}');
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error']['message'] ?? 'Failed generating content');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, theme, _) {
        final bgColor = theme.bgColor;
        final textColor = theme.textColor;
        final cardColor = theme.cardColor;
        final accentColor = theme.accentColor;
        final subTextColor = theme.subTextColor;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'CS SmartDrop AI',
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isGenerating ? Colors.amber : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isGenerating
                          ? 'Sedang berpikir...'
                          : (_geminiApiKey.isEmpty ? 'Mode Simulasi' : 'Online'),
                      style: TextStyle(
                        color: subTextColor,
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.delete_sweep_outlined, color: textColor, size: 20),
                tooltip: 'Hapus Chat',
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _messages.add(ChatMessage(
                      text: "Halo! Saya SmartDrop AI Assistant. Ada yang bisa saya bantu terkait transaksi COD, Safe Zones, pelacakan penjual, atau penggunaan aplikasi SmartDrop?",
                      isUser: false,
                      timestamp: DateTime.now(),
                    ));
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Message List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message, theme);
                  },
                ),
              ),

              // Listening / Wave Indicator
              if (_isListening)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: accentColor.withOpacity(0.05),
                  child: Row(
                    children: [
                      Icon(Icons.mic, color: accentColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _textController.text.isEmpty
                              ? 'Mendengarkan...'
                              : _textController.text,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Beautiful pulsing circles
                      _buildPulsingIndicator(accentColor),
                    ],
                  ),
                ),

              // Bottom Input Bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: BorderSide(color: subTextColor.withOpacity(0.1), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Voice Record Button
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? accentColor.withOpacity(0.2)
                                : cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening ? accentColor : subTextColor.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? accentColor : textColor.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text input field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: subTextColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontSize: 13),
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Tulis pesan Anda...',
                              hintStyle: TextStyle(
                                color: subTextColor.withOpacity(0.5),
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send Button
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, AppTheme theme) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final accentColor = theme.accentColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textColor;
    final subTextColor = theme.subTextColor;

    final bubbleBgColor = isUser ? accentColor : cardColor;
    final bubbleTextColor = isUser ? Colors.white : textColor;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleBgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: subTextColor.withOpacity(0.15),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: bubbleTextColor,
                fontFamily: 'Montserrat',
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isUser ? Colors.white70 : subTextColor.withOpacity(0.6),
                  fontFamily: 'Montserrat',
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildPulsingIndicator(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
