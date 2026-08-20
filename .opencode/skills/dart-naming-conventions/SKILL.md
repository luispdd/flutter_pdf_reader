---
name: dart-naming-conventions
description: >
  Enforce Dart naming conventions, Effective Dart style, and Flutter best practices.
  Use when generating, refactoring, reviewing, or explaining Dart/Flutter code.
  Do not use for non-Dart languages.
---

# Dart Naming Conventions

Follow the [Effective Dart](https://dart.dev/effective-dart) style guide strictly. All generated Dart code must pass `dart analyze` with zero issues.

## Naming Rules

### Variables, parameters, functions, methods → `lowerCamelCase`
- Good: `userName`, `fetchData()`, `onPressed`, `itemCount`
- Bad: `user_name`, `UserName`, `fetch_data`, `itemcount`

### Classes, enums, typedefs, extensions → `PascalCase`
- Good: `UserProfile`, `HttpStatusCode`, `AuthState`
- Bad: `userProfile`, `user_profile`, `httpStatusCode`

### Libraries, packages, directories, file names → `lowercaseWithUnderscores`
- Good: `user_profile.dart`, `my_package`, `data_sources/`
- Bad: `userProfile.dart`, `my-package`, `dataSources/`

### Private members → prefix with `_`
- Good: `_internalCounter`, `_fetchSecret()`, `_cache`
- Bad: `internalCounter` (when intended to be library-private)

### Constants
- **Local / field constants**: `lowerCamelCase`
  - Good: `defaultTimeout`, `maxRetries`
- **Enum values**: `lowerCamelCase`
  - Good: `authState.loading`, `authState.success`
- **Legacy / symbolic constants only**: `SCREAMING_SNAKE_CASE`
  - Acceptable: `PI`, `HTTP_STATUS_OK` (avoid in new code)

### Getters and setters → name like fields, not methods
- Good: `bool get isEmpty`, `set name(String value)`
- Bad: `bool getEmpty()`, `setName(String value)`

### Type parameters → `PascalCase`, single letter or descriptive
- Good: `T`, `E`, `ItemType`
- Bad: `itemType`, `t`

## Code Generation Rules

1. **Prefer `final` over `var`** when the variable is not reassigned.
2. **Type-annotate public APIs**; omit redundant types on local variables with obvious initializers.
3. **Do NOT use `new`** or redundant `const`.
4. **Use initializing formals** (`this.name`) in constructors when possible.
5. **Prefer named parameters** for functions with many parameters or boolean flags.
6. **Use `const` constructors** for immutable data classes and widgets.
7. **Always use trailing commas** in multi-line parameter/argument lists for better formatting.
8. **After generating code, run `dart analyze`**. Fix all issues and repeat until clean.

## Flutter-Specific Rules

### Widgets
- StatelessWidget / StatefulWidget names: `PascalCase` ending with `Widget` or descriptive noun.
  - Good: `UserProfileCard`, `LoginButton`
  - Bad: `userProfileCard`, `Login`
- `BuildContext` parameter: always name it `context`.
- `Key?` parameter: always name it `key` and pass to `super(key: key)`.

### State classes
- Private state class for StatefulWidget: `_PascalCaseState`
  - Good: `class _UserProfileCardState extends State<UserProfileCard>`

### Callbacks
- VoidCallback variables: `on` + `PascalCase` action in `lowerCamelCase`
  - Good: `onPressed`, `onUserTap`, `onSubmit`
  - Bad: `on_press`, `OnPressed`, `onpress`

## Example: Complete Dart File

```dart
// user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserRepository {
  final String _baseUrl;
  static const defaultTimeout = Duration(seconds: 30);

  UserRepository({required String baseUrl}) : _baseUrl = baseUrl;

  Future<User> fetchUser(int userId) async {
    final requestUrl = '$_baseUrl/users/$userId';
    final response = await http
        .get(Uri.parse(requestUrl))
        .timeout(defaultTimeout);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(jsonBody);
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }
}

class User {
  final int id;
  final String userName;
  final String emailAddress;

  const User({
    required this.id,
    required this.userName,
    required this.emailAddress,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      userName: json['user_name'] as String,
      emailAddress: json['email_address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'email_address': emailAddress,
    };
  }
}
```

## Example: Flutter Widget

```dart
// user_profile_card.dart
import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final String displayName;
  final String avatarUrl;
  final VoidCallback? onEditPressed;

  const UserProfileCard({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl),
        ),
        title: Text(displayName),
        trailing: onEditPressed != null
            ? IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEditPressed,
              )
            : null,
      ),
    );
  }
}
```

## Anti-Patterns to Avoid

| Anti-Pattern | Correct |
|-------------|---------|
| `var user_name = 'John';` | `final userName = 'John';` |
| `class userProfile { }` | `class UserProfile { }` |
| `void FetchData() { }` | `void fetchData() { }` |
| `final Color bg_color;` | `final Color backgroundColor;` |
| `new User()` | `User()` |
| `const val MAX_COUNT = 100;` | `static const maxCount = 100;` |
| `setName(String value)` | `set name(String value)` |
| `on_press` | `onPressed` |
| `UserProfile.dart` | `user_profile.dart` |

## Workflow

1. Generate or edit Dart/Flutter code following the rules above.
2. Run `dart analyze` (or `flutter analyze`).
3. If issues are reported, fix them and run again until zero issues.
4. Prefer `dart fix --apply` for automatic style fixes when safe.
