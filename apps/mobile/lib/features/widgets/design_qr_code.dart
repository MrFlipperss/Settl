import 'package:flutter/material.dart';

import '../mock_data.dart';

/// Renders the 21x21 QR matrix from [qrCells] in the foreground colour on a
/// padded background.
class DesignQrCode extends StatelessWidget {
  const DesignQrCode({super.key, this.cellSize = 7, this.padding = 12});

  final double cellSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in qrCells)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final cell in row)
                  Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: cell == 1 ? Colors.black : Colors.transparent,
                      borderRadius: cell == 1
                          ? BorderRadius.circular(1)
                          : BorderRadius.zero,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
