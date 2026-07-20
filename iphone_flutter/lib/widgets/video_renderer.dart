import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Widget personalizado para renderizar transmisiones de video WebRTC
/// con soporte para ajuste de pantalla, indicadores de carga y borde estilo cristal.
class RTCVideoRendererWidget extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final bool mirror;
  final RTCVideoViewObjectFit objectFit;
  final String placeholderText;

  const RTCVideoRendererWidget({
    super.key,
    required this.renderer,
    this.mirror = false,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    this.placeholderText = 'Esperando transmisión...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF5C8A).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ValueListenableBuilder<RTCVideoValue>(
          valueListenable: renderer,
          builder: (context, value, child) {
            if (renderer.srcObject != null) {
              return RTCVideoView(
                renderer,
                mirror: mirror,
                objectFit: objectFit,
              );
            }
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF5C8A),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    placeholderText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
