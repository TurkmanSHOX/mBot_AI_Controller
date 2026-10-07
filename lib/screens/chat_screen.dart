import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/mbot_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Boshlang'ich xabar
    _messages.add(
      ChatMessage(
        id: "1",
        text: "Salom! Men sizning aqlli mBot robotingizman. Menga buyruq bering yoki biror narsa so'rang!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

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

  Future<void> _sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      isVoice: isVoice,
    );

    setState(() {
      _messages.add(userMsg);
    });
    _textController.clear();
    _scrollToBottom();

    final ai = Provider.of<AiService>(context, listen: false);
    final mbot = Provider.of<MBotService>(context, listen: false);
    final tts = Provider.of<TtsService>(context, listen: false);

    // AI tahlili
    final response = await ai.processUserInput(
      userText: text,
      currentSensors: mbot.sensorData,
    );

    final aiMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: response.speechReply,
      isUser: false,
      timestamp: DateTime.now(),
      executedCommand: response.command,
    );

    setState(() {
      _messages.add(aiMsg);
    });
    _scrollToBottom();

    // Ovoz chiqarib aytish
    await tts.speak(response.speechReply);

    // mBot'da harakatni amalga oshirish
    if (response.command != null) {
      await mbot.executeCommand(response.command!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = Provider.of<SpeechService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text("AI Ovozli Suhbat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Xabarlar ro'yxati
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Tinglash ko'rsatkichi
          if (speech.isListening)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.redAccent.withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      speech.lastWords.isEmpty ? "Tinglanmoqda..." : speech.lastWords,
                      style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),

          // Matn va Ovoz kiritish paneli
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Mikrofon tugmasi
                  IconButton(
                    icon: Icon(
                      speech.isListening ? Icons.mic : Icons.mic_none,
                      color: speech.isListening ? Colors.redAccent : const Color(0xFF6366F1),
                    ),
                    onPressed: () {
                      if (speech.isListening) {
                        speech.stopListening();
                      } else {
                        speech.startListening(
                          onResultText: (text) => _sendMessage(text, isVoice: true),
                        );
                      }
                    },
                  ),
                  // Matn kiritish
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Buyruq yoki savol yozing...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (val) => _sendMessage(val),
                    ),
                  ),
                  // Yuborish tugmasi
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF6366F1)),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
