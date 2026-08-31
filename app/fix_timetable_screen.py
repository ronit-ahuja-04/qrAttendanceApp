import re

with open('lib/screens/student_timetable_screen.dart', 'r') as f:
    content = f.read()

# Fix end time color and font weight
content = content.replace(
    '''Text(formattedEnd, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),''',
    '''Text(formattedEnd, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),'''
)

# Fix pill for lecture and color scheme
# Currently: color: isLab ? Colors.orange : AppColors.vesitPrimary
# Let's change the border:
border_old = '''border: Border(left: BorderSide(color: isLab ? Colors.orange : AppColors.vesitPrimary, width: 6)),'''
border_new = '''border: Border(left: BorderSide(color: isLab ? AppColors.vesitOrange : AppColors.vesitPrimary, width: 6)),'''
content = content.replace(border_old, border_new)

# Pill styling: 
# Currently: decoration: BoxDecoration(color: isLab ? Colors.orange.shade100 : AppColors.primaryContainer, borderRadius: BorderRadius.circular(4)),
# And text: Text(type, style: TextStyle(fontSize: 10, color: isLab ? Colors.orange.shade800 : AppColors.vesitPrimary, fontWeight: FontWeight.bold)),
# Let's fix it so Lecture is light blue pill, Lab is light orange pill.
pill_old = '''Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: isLab ? Colors.orange.shade100 : AppColors.primaryContainer, borderRadius: BorderRadius.circular(4)),
                              child: Text(type, style: TextStyle(fontSize: 10, color: isLab ? Colors.orange.shade800 : AppColors.vesitPrimary, fontWeight: FontWeight.bold)),
                            ),'''
pill_new = '''Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: isLab ? AppColors.vesitOrange.withOpacity(0.15) : AppColors.vesitPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(type, style: TextStyle(fontSize: 11, color: isLab ? AppColors.vesitOrange : AppColors.vesitPrimary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),'''
content = content.replace(pill_old, pill_new)

with open('lib/screens/student_timetable_screen.dart', 'w') as f:
    f.write(content)
