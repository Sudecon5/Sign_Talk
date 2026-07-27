import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'gloss_parser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SignTalkApp());
}

class SignTalkApp extends StatelessWidget {
  const SignTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Talk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SignTalkMobileScreen(),
    );
  }
}

class SignTalkMobileScreen extends StatefulWidget {
  const SignTalkMobileScreen({super.key});

  @override
  State<SignTalkMobileScreen> createState() => _SignTalkMobileScreenState();
}

class _SignTalkMobileScreenState extends State<SignTalkMobileScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _spokenText = "Tap the microphone below to start talking...";
  List<String> _currentKeywords = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// Initialize native mobile speech engine
  void _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (error) => debugPrint('STT Error: $error'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Failed to initialize native speech: $e");
    }
  }

  /// Toggle listening mode
  void _toggleListening() async {
    if (!_isListening) {
      if (!_speechAvailable) {
        _speechAvailable = await _speech.initialize();
      }

      if (_speechAvailable) {
        setState(() {
          _isListening = true;
          _spokenText = "Listening...";
        });

        await _speech.listen(
          onResult: (result) {
            setState(() {
              _spokenText = result.recognizedWords;
              // Extract sign keywords from live voice stream
              _currentKeywords = GlossParser.parseToKeywords(_spokenText);
            });
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
          ),
        );
      } else {
        setState(() {
          _spokenText = "Microphone access denied or unverified on device.";
        });
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Talk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TOP HALF: Mobile Live Caption Display
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? Colors.red : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening ? "RECORDING..." : "READY",
                          style: TextStyle(
                            color: _isListening
                                ? Colors.redAccent
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _spokenText,
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color:
                                _spokenText.startsWith("Tap") ||
                                    _spokenText.startsWith("Listening")
                                ? Colors.grey[400]
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (_currentKeywords.isNotEmpty) ...[
                      const Divider(color: Colors.white24, height: 20),
                      Text(
                        "Extracted Keywords:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentKeywords.join('  •  ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // BOTTOM HALF: Full Sentence ASL Viewport
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: _currentKeywords.isEmpty
                      // 1. Idle state when no speech is detected
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sign_language_rounded,
                              size: 56,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Sign Playback Viewport",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      // 2. Active state: Passes the full list of keywords for sentence translation
                      : _buildSignContent(_currentKeywords),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleListening,
        backgroundColor: _isListening ? Colors.redAccent : Colors.deepPurple,
        elevation: 6,
        icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 28),
        label: Text(
          _isListening ? "STOP LISTENING" : "START SPEAKING",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  /// Renders full sentences by iterating through all extracted keywords sequentially
  /// Modernized horizontal viewport with a clean, high-end card design
  Widget _buildSignContent(List<String> keywords) {
    if (keywords.isEmpty) {
      return const Center(
        child: Text(
          "No signs to display",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: keywords.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemBuilder: (context, index) {
        final word = keywords[index].toLowerCase();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 220,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.withValues(alpha: 0.15),
                Colors.grey[900]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Word Badge Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  word.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Hand Signs Row
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: word.split('').map((char) {
                        final isLetter = RegExp(r'[a-z]').hasMatch(char);
                        if (!isLetter) return const SizedBox(width: 6);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'alphabet/$char.jpg',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 60,
                                height: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  char.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.deepPurpleAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
