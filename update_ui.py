import re

path = "app/lib/screens/update_profile_picture_screen.dart"
with open(path, "r") as f:
    code = f.read()

# Replace the Take Photo row with Remove Photo
code = code.replace(
    """                  _OptionRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take Photo',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),""",
    """                  if (AmsGlobals.loggedInUser?.profilePictureUrl != null && AmsGlobals.loggedInUser!.profilePictureUrl!.isNotEmpty) ...[
                    _OptionRow(
                      icon: Icons.delete_outline,
                      label: 'Remove Photo',
                      onTap: () async {
                        final updatedUser = await AmsGlobals.sessionService.removeProfilePicture(AmsGlobals.loggedInUser!.id);
                        if (updatedUser != null) {
                          AmsGlobals.loggedInUser = updatedUser;
                          if (mounted) {
                            VesitToast.show(context: context, title: 'Profile picture removed successfully!', type: ToastType.success);
                            Navigator.of(context).maybePop(true);
                          }
                        } else {
                          if (mounted) {
                            VesitToast.show(context: context, title: 'Failed to remove photo', type: ToastType.info);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],"""
)

with open(path, "w") as f:
    f.write(code)

print("Updated UI in update_profile_picture_screen.dart")
