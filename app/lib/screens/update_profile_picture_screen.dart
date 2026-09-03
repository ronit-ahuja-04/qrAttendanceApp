import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../ams/globals.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import '../widgets/vesit_toast.dart';

/// Update Profile Picture
class UpdateProfilePictureScreen extends StatefulWidget {
  const UpdateProfilePictureScreen({super.key});

  @override
  State<UpdateProfilePictureScreen> createState() => _UpdateProfilePictureScreenState();
}

class _UpdateProfilePictureScreenState extends State<UpdateProfilePictureScreen> {
  XFile? _selectedFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
      if (picked != null) {
        setState(() => _selectedFile = picked);
      }
    } catch (e) {
      VesitToast.show(context: context, title: 'Failed to pick image: $e', type: ToastType.info);
    }
  }

  Future<void> _saveProfilePicture() async {
    if (_selectedFile == null) return;
    final user = AmsGlobals.loggedInUser;
    if (user == null) return;

    setState(() => _isUploading = true);
    try {
      final updatedUser = await AmsGlobals.sessionService.uploadProfilePicture(user.id, _selectedFile!);
      if (updatedUser != null) {
        AmsGlobals.loggedInUser = updatedUser;
        if (mounted) {
          VesitToast.show(context: context, title: 'Profile picture updated successfully!', type: ToastType.info);
          Navigator.of(context).maybePop(true);
        }
      } else {
        throw 'Failed to update profile picture';
      }
    } catch (e) {
      if (mounted) {
        VesitToast.show(context: context, title: 'Error: $e', type: ToastType.info);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  _DropWell(
                    file: _selectedFile,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(height: 24),
                  _OptionRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take Photo',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 12),
                  _OptionRow(
                    icon: Icons.image_outlined,
                    label: 'Upload from Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(height: 24),
                  const _RequirementsCard(),
                ],
              ),
            ),
            _Footer(
              isUploading: _isUploading,
              hasFile: _selectedFile != null,
              onSave: _saveProfilePicture,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: context.colors.vesitPrimary),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Update Profile Picture',
                  style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.vesitPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.colors.vesitPrimary.withOpacity(0.3)),
                  ),
                  child: Text(
                    'TACTILE INTERFACE V1.0',
                    style: context.textStyles.vesitLabelSm.copyWith(letterSpacing: 1.5, fontSize: 9, color: context.colors.vesitPrimary),
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
  const _DropWell({required this.file, required this.onTap});

  final XFile? file;
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
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: context.colors.vesitWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: file == null
                          ? Icon(Icons.photo_camera, color: context.colors.vesitPrimary, size: 48)
                          : ClipOval(
                              child: kIsWeb
                                  ? Image.network(file!.path, width: 128, height: 128, fit: BoxFit.cover)
                                  : Image.file(File(file!.path), width: 128, height: 128, fit: BoxFit.cover),
                            ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: file == null ? context.colors.vesitPrimary : Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: (file == null ? context.colors.vesitPrimary : Color(0xFF2E7D32)).withOpacity(0.8), blurRadius: 12),
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
                    file == null ? 'Drag and drop or tap options below to upload a new profile photo' : 'Previewing your new profile picture',
                    textAlign: TextAlign.center,
                    style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600, height: 1.5),
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
      painter: _DashedRectPainter(color: context.colors.outlineVariant),
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

class _OptionRow extends StatefulWidget {
  const _OptionRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHovering ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.colors.vesitWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovering ? [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))
          ] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (h) => setState(() => _isHovering = h),
            onHighlightChanged: (h) => setState(() => _isHovering = h),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.vesitPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: context.colors.vesitPrimary),
                  ),
                  const SizedBox(width: 16),
                  Text(widget.label, style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitTextHeading, fontSize: 15)),
                ],
              ),
            ),
          ),
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
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IMAGE REQUIREMENTS', style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitPrimary)),
          const SizedBox(height: 4),
          Text(
            'Maximum file size: 5MB. Format: JPG, PNG, or GIF. Faces must be clearly visible for automated attendance check.',
            style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.isUploading, required this.hasFile, required this.onSave, required this.onCancel});

  final bool isUploading;
  final bool hasFile;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          if (isUploading)
            const Center(child: CircularProgressIndicator())
          else
            PushableButton(
              label: 'Save Profile Picture',
              icon: Icons.check_circle,
              onPressed: () {
                if (hasFile) onSave();
              },
            ),
          const SizedBox(height: 8),
          if (!isUploading)
            TextButton(
              onPressed: onCancel,
              child: Text('CANCEL', style: context.textStyles.vesitLabelBold.copyWith(color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }
}
