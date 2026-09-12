import re

filepath = 'lib/widgets/vesit_widgets.dart'
with open(filepath, 'r') as f:
    lines = f.readlines()

def replace_between(start_str, end_str, new_str, lines):
    in_block = False
    new_lines = []
    i = 0
    while i < len(lines):
        if start_str in lines[i]:
            new_lines.append(lines[i])
            i += 1
            while i < len(lines) and end_str not in lines[i]:
                i += 1
            new_lines.append(new_str)
            new_lines.append(lines[i])
        else:
            new_lines.append(lines[i])
        i += 1
    return new_lines

# Fix VesitTextField
for i, line in enumerate(lines):
    if "filled: true," in line and "fillColor: context.colors.vesitGray.withOpacity(0.3)," in lines[i+1]:
        # This is a match for the decoration block.
        pass

# It's safer to just read the whole file and string replace the specific chunks
with open(filepath, 'r') as f:
    content = f.read()

# Replace for VesitTextField
old_field = """            filled: true,
            fillColor: context.colors.vesitGray.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colors.vesitPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),"""

new_field = """            filled: true,
            fillColor: context.colors.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.primary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.error, width: 1)),"""

content = content.replace(old_field, new_field)

# Replace for VesitDropdown
old_dropdown_color = "dropdownColor: context.colors.vesitWhite,"
new_dropdown_color = "dropdownColor: context.colors.surfaceContainerHigh,"
content = content.replace(old_dropdown_color, new_dropdown_color)

old_dropdown_dec = """            filled: true,
            fillColor: context.colors.vesitGray.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.colors.vesitPrimary, width: 2)),"""

new_dropdown_dec = """            filled: true,
            fillColor: context.colors.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.primary, width: 2)),"""

content = content.replace(old_dropdown_dec, new_dropdown_dec)

with open(filepath, 'w') as f:
    f.write(content)
