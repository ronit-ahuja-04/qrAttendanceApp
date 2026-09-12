import re

filepath = 'lib/screens/notifications_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Replace hardcoded Title color Color(0xFF1E1E1E) with context.colors.onSurface
content = content.replace("color: Color(0xFF1E1E1E),", "color: context.colors.onSurface,")

# Replace n.tag.isNotEmpty with n.tag.trim().isNotEmpty to prevent blank pills
content = content.replace("if (n.tag.isNotEmpty)", "if (n.tag.trim().isNotEmpty)")

# Add a helper function for Semantic Colors
helper_func = """
  Color _getSemanticColor(BuildContext context, String name) {
    switch (name) {
      case 'primaryContainer': return context.colors.primaryContainer;
      case 'onPrimaryContainer': return context.colors.onPrimaryContainer;
      case 'errorContainer': return context.colors.errorContainer;
      case 'onErrorContainer': return context.colors.onErrorContainer;
      case 'secondaryContainer': return context.colors.secondaryContainer;
      case 'onSecondaryContainer': return context.colors.onSecondaryContainer;
      case 'surfaceContainerHigh': return context.colors.surfaceContainerHighest;
      case 'onSurfaceVariant': return context.colors.onSurfaceVariant;
      default: return context.colors.primaryContainer;
    }
  }
"""
# Since _NotifCard is a StatelessWidget, we can just put this inside it or globally. 
# We'll put it globally. 
content = content.replace("class _NotifCard extends StatelessWidget {", helper_func + "\nclass _NotifCard extends StatelessWidget {")

# Then in _NotifCard build, use the helper
content = content.replace("color: n.tagColor,", "color: n.tagColor, // We'll ignore the hardcoded tagColor")
content = content.replace(
    "color: n.tagColor, // We'll ignore the hardcoded tagColor",
    "color: context.colors.primaryContainer, // Fallback"
)
content = content.replace("color: n.onTagColor,", "color: context.colors.onPrimaryContainer,")

with open(filepath, 'w') as f:
    f.write(content)
