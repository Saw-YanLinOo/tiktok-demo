import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/room_config.dart';
import '../providers/room_provider.dart';
import 'host_view.dart';
import 'viewer_view.dart';

class LivePage extends ConsumerStatefulWidget {
  const LivePage({super.key, required this.role});

  final RoomRole role;

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage> {
  late final TextEditingController _roomCodeController;
  final _identityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isHost => widget.role == RoomRole.host;

  /// Generates a random 6-digit numeric room code (e.g. 847203).
  static String _generateRoomCode() {
    final rng = Random();
    return (rng.nextInt(900000) + 100000).toString(); // 100000–999999
  }

  @override
  void initState() {
    super.initState();
    _roomCodeController = TextEditingController(text: _generateRoomCode());
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    final config = RoomConfig(
      roomName: _roomCodeController.text.trim(),
      role: widget.role,
      identity: _identityController.text.trim(),
    );

    await ref.read(roomProvider.notifier).connect(config);
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);

    // Navigate to the right view once connected
    ref.listen<RoomState>(roomProvider, (prev, next) {
      if (next is RoomConnected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                next.config.isHost ? const HostView() : const ViewerView(),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isHost ? 'Go Live' : 'Join Live',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFFC0185A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isHost ? Icons.videocam : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Room Code — pre-filled with a random code, freely editable
                _FieldLabel('Room Code'),
                const SizedBox(height: 8),
                _TextField(
                  controller: _roomCodeController,
                  hint: 'e.g. 847-203',
                  suffix: IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.accent, size: 20),
                    tooltip: 'Generate new code',
                    onPressed: () => _roomCodeController.text = _generateRoomCode(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Room code required' : null,
                ),
                const SizedBox(height: 20),

                // Identity
                _FieldLabel('Your Name'),
                const SizedBox(height: 8),
                _TextField(
                  controller: _identityController,
                  hint: _isHost ? 'e.g. host-alice' : 'e.g. viewer-bob',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name required' : null,
                ),

                const Spacer(),

                // Error
                if (roomState is RoomError) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            roomState.message,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Connect button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: roomState is RoomConnecting ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: roomState is RoomConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isHost ? 'Start Streaming' : 'Join Stream',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.accent, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
