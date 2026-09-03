import re

# 1. Fix generate_report_screen.dart
path1 = "app/lib/screens/generate_report_screen.dart"
with open(path1, "r") as f:
    code1 = f.read()

# Replace the messy token URL logic back to normal
code1 = re.sub(
    r"final prefs = await SharedPreferences\.getInstance\(\);.*?final url = '\$baseUrl/api/report/excel/\\\$\{\widget\.session\.id\}\?token=\\\$token';",
    "final url = '$baseUrl/api/report/excel/${widget.session.id}';",
    code1,
    flags=re.DOTALL
)

# Replace the web download logic
web_logic1 = """
      if (kIsWeb) {
        // Web download logic with Blob to hide token
        final response = await httpClient.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final blob = html.Blob([response.bodyBytes]);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: blobUrl)
            ..setAttribute("download", 'Report_${widget.session.courseCode}.xlsx')
            ..click();
          html.Url.revokeObjectUrl(blobUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report downloaded successfully')),
            );
          }
        } else {
          throw Exception('Failed to download from server');
        }
      } else {
"""
code1 = re.sub(
    r"if \(kIsWeb\) \{.*?\}\s*else\s*\{",
    web_logic1,
    code1,
    flags=re.DOTALL
)

with open(path1, "w") as f:
    f.write(code1)

# 2. Fix report_timeline_screen.dart
path2 = "app/lib/screens/report_timeline_screen.dart"
with open(path2, "r") as f:
    code2 = f.read()

# Replace the messy token URL logic back to normal
code2 = re.sub(
    r"final prefs = await SharedPreferences\.getInstance\(\);.*?final url = '\$baseUrl/api/report/bulk-excel\?facultyId=\$facultyId&subject=\$subject&batchTarget=\$batchTarget&startDate=\$start&endDate=\$end&token=\\\$token';",
    "final url = '$baseUrl/api/report/bulk-excel?facultyId=$facultyId&subject=$subject&batchTarget=$batchTarget&startDate=$start&endDate=$end';",
    code2,
    flags=re.DOTALL
)

# Replace the web download logic
web_logic2 = """
      if (kIsWeb) {
        // Web download logic with Blob to hide token
        final response = await httpClient.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final blob = html.Blob([response.bodyBytes]);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: blobUrl)
            ..setAttribute("download", 'BulkReport_${widget.subject}.xlsx')
            ..click();
          html.Url.revokeObjectUrl(blobUrl);
          
          if (mounted) {
            VesitToast.show(
              context: context,
              title: 'Success',
              description: 'Report downloaded successfully',
              type: ToastType.success,
            );
          }
        } else {
          throw Exception('Failed to download from server');
        }
      } else {
"""
code2 = re.sub(
    r"if \(kIsWeb\) \{.*?\}\s*else\s*\{",
    web_logic2,
    code2,
    flags=re.DOTALL
)

with open(path2, "w") as f:
    f.write(code2)

print("Fixed download logic!")
