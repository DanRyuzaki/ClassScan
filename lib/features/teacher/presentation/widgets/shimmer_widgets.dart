import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });
  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, U) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class ClassesShimmer extends StatelessWidget {
  const ClassesShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: 44, borderRadius: 10),
          const SizedBox(height: 20),
          ShimmerBox(width: double.infinity, height: 40, borderRadius: 6),
          const SizedBox(height: 8),
          ...List.generate(
            6,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShimmerBox(
                width: double.infinity,
                height: 56,
                borderRadius: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceShimmer extends StatelessWidget {
  const AttendanceShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 200, height: 44, borderRadius: 10),
              const SizedBox(width: 12),
              ShimmerBox(width: 160, height: 44, borderRadius: 10),
              const Spacer(),
              ShimmerBox(width: 100, height: 44, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 20),
          ShimmerBox(width: double.infinity, height: 40, borderRadius: 6),
          const SizedBox(height: 8),
          ...List.generate(
            7,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShimmerBox(
                width: double.infinity,
                height: 52,
                borderRadius: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsShimmer extends StatelessWidget {
  const SettingsShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 64, height: 64, borderRadius: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 180, height: 20, borderRadius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 240, height: 14, borderRadius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          ShimmerBox(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 52, borderRadius: 8),
          const SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 52, borderRadius: 8),
          const SizedBox(height: 24),
          ShimmerBox(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 52, borderRadius: 8),
        ],
      ),
    );
  }
}
