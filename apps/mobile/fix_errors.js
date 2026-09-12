const fs = require('fs');

// 1. Fix api_services.dart
let apiContent = fs.readFileSync('lib/ams/api_services.dart', 'utf8');

const approveCode = `  Future<bool> approveProxySession(String sessionId) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/api/sessions/$sessionId/approve'));
      return response.statusCode == 200;
    } catch (e) {
      print('APPROVE SESSION ERROR: $e');
      return false;
    }
  }

  Future<bool> declineProxySession(String sessionId) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/api/sessions/$sessionId/decline'));
      return response.statusCode == 200;
    } catch (e) {
      print('DECLINE SESSION ERROR: $e');
      return false;
    }
  }`;

// Remove from old place
apiContent = apiContent.replace(approveCode, '');

// Add to ApiSessionService
apiContent = apiContent.replace('  Future<List<Map<String, dynamic>>> getVerificationList(String sessionId) async {', approveCode + '\n\n  Future<List<Map<String, dynamic>>> getVerificationList(String sessionId) async {');

fs.writeFileSync('lib/ams/api_services.dart', apiContent);

// 2. Fix proxy_approvals_screen.dart
let proxyContent = fs.readFileSync('lib/screens/proxy_approvals_screen.dart', 'utf8');
// Fix DateFormat import
proxyContent = proxyContent.replace(`import 'package:intl/intl.dart';`, `import 'package:intl/intl.dart';\nimport '../ams/api_services.dart';`);

// Fix margin -> padding
proxyContent = proxyContent.replace(`margin: const EdgeInsets.only(bottom: 16),`, `padding: const EdgeInsets.only(bottom: 16),`);

// Fix ApiSessionService instantiation (it's in AmsGlobals.sessionService usually)
proxyContent = proxyContent.replace(`ApiSessionService().approveProxySession`, `AmsGlobals.sessionService.approveProxySession`);
proxyContent = proxyContent.replace(`ApiSessionService().declineProxySession`, `AmsGlobals.sessionService.declineProxySession`);

fs.writeFileSync('lib/screens/proxy_approvals_screen.dart', proxyContent);

console.log("Fixes applied");
