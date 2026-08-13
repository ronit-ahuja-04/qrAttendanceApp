import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';

/// Update Profile Picture — mirrors the Stitch export (code.html):
/// dashed drop-well with debossed camera icon + LED, Take Photo /
/// Upload from Gallery rows, requirements note, Save / Cancel footer.
class UpdateProfilePictureScreen extends StatelessWidget {
  const UpdateProfilePictureScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  _DropWell(onTap: () => _comingSoon(context, 'File picker')),
                  const SizedBox(height: 24),
                  _OptionRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take Photo',
                    onTap: () => _comingSoon(context, 'Take Photo'),
                  ),
                  const SizedBox(height: 12),
                  _OptionRow(
                    icon: Icons.image_outlined,
                    label: 'Upload from Gallery',
                    onTap: () => _comingSoon(context, 'Upload from Gallery'),
                  ),
                  const SizedBox(height: 24),
                  const _RequirementsCard(),
                ],
              ),
            ),
            _Footer(
              onSave: () => Navigator.of(context).maybePop(),
              onCancel: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Update Profile Picture',
                  style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Text(
                    'TACTILE INTERFACE V1.0',
                    style: AppTextStyles.labelSm.copyWith(letterSpacing: 1.5, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _DropWell extends StatelessWidget {
  const _DropWell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: DottedBorder(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.debossedWell,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.photo_camera, color: AppColors.primary, size: 48),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryContainer.withOpacity(0.8), blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Drag and drop or tap options below to upload a new profile photo',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
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

/// Dashed-border container standing in for the CSS `dashed-well` background.
class DottedBorder extends StatelessWidget {
  const DottedBorder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: AppColors.outlineVariant),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => oldDelegate.color != color;
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PushSurfaceButton(
      onPressed: onTap,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Text(label, style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: const [BoxShadow(color: AppColors.primaryContainer, offset: Offset(-4, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IMAGE REQUIREMENTS', style: AppTextStyles.labelBold.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(
            'Maximum file size: 5MB. Format: JPG, PNG, or GIF. Faces must be clearly visible for automated attendance check.',
            style: AppTextStyles.labelSm,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onSave, required this.onCancel});

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        children: [
          PushableButton(
            label: 'Save Profile Picture',
            icon: Icons.check_circle,
            onPressed: onSave,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCancel,
            child: Text('CANCEL', style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
