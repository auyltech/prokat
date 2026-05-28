import 'package:flutter/material.dart';

// Standalone bottom sheet component for displaying full vehicle specifications
class EquipmentDetailsSheet extends StatelessWidget {
  final String? name;
  final String? model;
  final String? plateNumber;
  final String? imageUrl;
  final List<String>? specifications; // Handles an array of specs for flexible display

  const EquipmentDetailsSheet({
    super.key,
    this.name,
    this.model,
    this.plateNumber,
    this.imageUrl,
    this.specifications,
  });

  // Helper method to trigger the bottom drawer cleanly from any context action
  static void show(
    BuildContext context, {
    required String? name,
    required String? model,
    required String? plateNumber,
    required String? imageUrl,
    List<String>? specifications,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EquipmentDetailsSheet(
        name: name,
        model: model,
        plateNumber: plateNumber,
        imageUrl: imageUrl,
        specifications: specifications,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Drag Handle indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Equipment Details",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Image Presentation Block
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[100],
                  child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 4. Data Specification Rows
          _buildSpecRow("Vehicle Name", name ?? "—"),
          const Divider(height: 16, thickness: 0.5),
          _buildSpecRow("Model Type", model ?? "—"),
          const Divider(height: 16, thickness: 0.5),
          _buildSpecRow("Plate Number", plateNumber ?? "—"),
          
          if (specifications != null && specifications!.isNotEmpty) ...[
            const Divider(height: 16, thickness: 0.5),
            _buildSpecRow(
              "Technical Specs", 
              specifications!.join(" • "),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
