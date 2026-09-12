import re

path = "app/lib/ams/api_services.dart"
with open(path, "r") as f:
    code = f.read()

func = """
  Future<User?> removeProfilePicture(String userId) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/users/$userId/profile-picture'),
      );
      if (response.statusCode == 200) {
        if (AmsGlobals.loggedInUser != null) {
          AmsGlobals.loggedInUser = AmsGlobals.loggedInUser!.copyWith(
            profilePictureUrl: '',
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ams_user_session', jsonEncode(AmsGlobals.loggedInUser!.toJson()));
        }
        return AmsGlobals.loggedInUser;
      }
      return null;
    } catch (e) {
      print('Error removing profile picture: $e');
      return null;
    }
  }

  Future<User?> uploadProfilePicture"""

code = code.replace("  Future<User?> uploadProfilePicture", func)

with open(path, "w") as f:
    f.write(code)

print("Added removeProfilePicture to api_services.dart")
