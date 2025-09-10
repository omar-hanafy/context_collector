# ConvertObject Utility Documentation

## Core Conversion Pattern

All conversions follow pattern: `to{Type}` (throws) and `tryTo{Type}` (returns null on failure)

Supported types: String, num, int, double, BigInt, bool, DateTime, Uri, Map<K,V>, Set<T>, List<T>

## Universal Parameters

```dart
object          // Input to convert
mapKey         // Extract from Map before conversion
listIndex      // Extract from List before conversion  
defaultValue   // Return if null/failed (varies by method)
converter      // Custom conversion function
```

## Type-Specific Parameters

Numbers (num/int/double):
```dart
format  // Number format pattern
locale  // Locale for formatting
```

DateTime:
```dart
format            // Date format pattern
locale            // Locale for formatting
autoDetectFormat  // Auto-detect format from string
useCurrentLocale  // Use system locale
utc              // Parse as UTC
```

Collections (Map/Set/List):
```dart
keyConverter      // Convert map keys (Map only)
valueConverter    // Convert map values (Map only)
elementConverter  // Convert elements (Set/List)
```

## Static Methods

```dart
// String conversions
ConvertObject.toString1(obj, mapKey: 'name', defaultValue: 'Unknown')
ConvertObject.tryToString(obj, listIndex: 0)

// Numeric conversions
ConvertObject.toNum('123.45', format: '#,##0.00')
ConvertObject.toInt(obj, mapKey: 'count', defaultValue: 0)
ConvertObject.toDouble(['45.67'], listIndex: 0)
ConvertObject.toBigInt('123456789012345678901234567890')

// Boolean conversion
ConvertObject.toBool('yes')  // true for: true, 'true', 'yes', num > 0

// DateTime conversion
ConvertObject.toDateTime('2024-01-15', format: 'yyyy-MM-dd')
ConvertObject.toDateTime(obj, autoDetectFormat: true)

// Uri conversion
ConvertObject.toUri('https://example.com')
ConvertObject.toUri('+1234567890')  // Detects phone numbers

// Collection conversions
ConvertObject.toMap<String, int>(jsonString)
ConvertObject.toList<User>(data, elementConverter: (e) => User.fromJson(e))
ConvertObject.toSet<String>(['a', 'b', 'a'])  // {'a', 'b'}
```

## Extension Methods

### Iterable Extensions

```dart
// Direct access by index
list.getString(0)
list.getInt(1, format: '#,###')
list.getDateTime(2, format: 'MM/dd/yyyy')
list.getMap<String, dynamic>(3)

// Try variants with fallback indexes
list.tryGetString(0, altIndexes: [1, 2], defaultValue: 'N/A')
list.tryGetNum(5, altIndexes: [4, 3])
```

### Map Extensions

```dart
// Direct access by key
map.getString('name', altKeys: ['fullName', 'displayName'])
map.getInt('age', defaultValue: 0)
map.getList<String>('tags')

// Nested extraction
map.getString('user', innerKey: 'email')
map.getInt('data', innerListIndex: 0)

// Parse to object
map.parse('user', (json) => User.fromJson(json))
```

### Collection Type Conversion

```dart
// Convert collection element types
dynamicList.convertTo<int>()     // List<dynamic> → List<int>
dynamicSet.convertTo<String>()    // Set<dynamic> → Set<String>
```

## Global Functions

Direct conversions without class prefix:

```dart
toString1(obj), tryToString(obj)
toNum(obj), tryToNum(obj)
toInt(obj), tryToInt(obj)
toBigInt(obj), tryToBigInt(obj)
toDouble(obj), tryToDouble(obj)
toBool(obj), tryToBool(obj)
toDateTime(obj), tryToDateTime(obj)
toUri(obj), tryToUri(obj)
toMap<K,V>(obj), tryToMap<K,V>(obj)
toSet<T>(obj), tryToSet<T>(obj)
toList<T>(obj), tryToList<T>(obj)

// Generic type conversion
toType<T>(obj)     // Throws on failure
tryToType<T>(obj)  // Returns null on failure
```

## Nested Data Extraction

Extract from complex structures in single call:

```dart
// From List<Map>
data.getString(0, innerKey: 'username')

// From Map<String, List>
response.getInt('scores', innerListIndex: 0)

// From Map with alternative keys
config.tryGetBool('enabled', altKeys: ['isEnabled', 'active'])
```

## Error Handling

Methods prefixed with `to` throw ParsingException on:
- Null input (unless defaultValue provided)
- Type conversion failure
- Invalid format

Methods prefixed with `tryTo`:
- Return null on any failure
- Never throw exceptions
- Log errors internally

extension LetExtension<T> on T {
  /// Executes [block] with `this` as its argument and returns the result.
  ///
  /// Think of it as a lightweight map/transform that works on any object.
  R let<R>(R Function(T it) block) => block(this);
}

extension LetExtensionNullable<T> on T? {
  /// If `this` is non-null, calls [block] with the non-null value and returns
  /// its result; otherwise returns `null`.
  R? let<R>(R Function(T it) block) => this == null ? null : block(this as T);
}

## Common Patterns

```dart
// API response parsing
final userId = response.tryGetInt('user_id') ?? response.tryGetInt('userId') ?? 0;

// Safe nested access
final email = data.tryGetString('user', innerKey: 'contact', innerListIndex: 0, defaultValue: 'no-email');

// Batch conversion with validation
final prices = data.getList<num>('prices').map((p) => p.toDouble()).toList();

// Format-aware parsing
final amount = data.getDouble('amount', format: '#,###.00', locale: 'en_US');

// Multi-source extraction
final name = user.tryGetString('name', altKeys: ['fullName', 'displayName']) ?? 'Guest';
```

## Dependencies

Requires: dart_helper_utils package for string extensions (toNum, tryToNum, etc.)
