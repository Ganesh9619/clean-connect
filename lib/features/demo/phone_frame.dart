import 'package:flutter/material.dart';

const _screenSize = Size(390, 844);
const _bezel = 12.0;
const _statusBarHeight = 44.0;
const _homeIndicatorHeight = 20.0;

/// Draws [child] inside an iPhone-sized frame and scales it to the space
/// available. The child sees a 390x844 screen with status bar insets.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final outer = MediaQuery.of(context);
    const insets = EdgeInsets.only(
      top: _statusBarHeight,
      bottom: _homeIndicatorHeight,
    );
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: _screenSize.width + _bezel * 2,
        height: _screenSize.height + _bezel * 2,
        padding: const EdgeInsets.all(_bezel),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(56),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(44),
          child: MediaQuery(
            data: outer.copyWith(
              size: _screenSize,
              padding: insets,
              viewPadding: insets,
              viewInsets: EdgeInsets.zero,
            ),
            child: Stack(
              children: [
                Positioned.fill(child: child),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _statusBarHeight,
                  child: IgnorePointer(child: _StatusBar()),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 130,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(3),
                        ),
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

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Text('9:41', style: style),
          const Spacer(),
          Container(
            width: 110,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Spacer(),
          const Icon(Icons.signal_cellular_alt_rounded, size: 17),
          const SizedBox(width: 4),
          const Icon(Icons.wifi_rounded, size: 17),
          const SizedBox(width: 4),
          const Icon(Icons.battery_full_rounded, size: 19),
        ],
      ),
    );
  }
}
