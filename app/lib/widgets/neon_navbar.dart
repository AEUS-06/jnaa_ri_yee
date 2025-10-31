import 'package:flutter/material.dart';

class NeonNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const NeonNavbar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  State<NeonNavbar> createState() => _NeonNavbarState();
}

class _NeonNavbarState extends State<NeonNavbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.camera_alt_rounded,
    Icons.info_rounded,
  ];

  double _indicatorPosition = 0.0;
  bool _isDragging = false;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Inicializamos la posición del indicador según la página actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _indicatorPosition = widget.currentIndex.toDouble();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final glow = 8 + 6 * _controller.value;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            // Permite mover indicador con el dedo
            setState(() {
              _isDragging = true;
              final box = context.findRenderObject() as RenderBox;
              double dx = details.localPosition.dx.clamp(0, box.size.width);
              double segmentWidth = box.size.width / _icons.length;
              _indicatorPosition = dx / segmentWidth;
            });
          },
          onHorizontalDragEnd: (_) {
            // Al soltar, redondeamos al índice más cercano
            setState(() {
              _isDragging = false;
              final index = _indicatorPosition.round();
              _indicatorPosition = index.toDouble();
              widget.onItemSelected(index);
            });
          },
          child: Container(
            height: 70,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.6),
                  blurRadius: glow,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Indicador circular animado
                LayoutBuilder(builder: (context, constraints) {
                  double segmentWidth = constraints.maxWidth / _icons.length;
                  double left = segmentWidth * _indicatorPosition + segmentWidth/2 - 18;

                  return AnimatedPositioned(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: left,
                    top: 7,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.4),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.7),
                            blurRadius: glow,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  );
                }),
                // Iconos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_icons.length, (index) {
                    final isSelected = widget.currentIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _indicatorPosition = index.toDouble();
                        });
                        widget.onItemSelected(index);
                      },
                      child: Icon(
                        _icons[index],
                        color: isSelected
                            ? Colors.blueAccent
                            : Colors.blueAccent.withOpacity(0.5),
                        size: isSelected ? 30 : 26,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
