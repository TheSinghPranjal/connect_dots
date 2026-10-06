/// Gameplay color identity. Never use Flutter Color as the gameplay ID.
enum ColorId {
  red,
  blue,
  green,
  yellow,
  orange,
  purple,
  cyan,
  pink;

  static ColorId? tryParse(String value) {
    for (final c in ColorId.values) {
      if (c.name == value) return c;
    }
    return null;
  }

  String get assistSymbol {
    switch (this) {
      case ColorId.red:
        return '●';
      case ColorId.blue:
        return '◆';
      case ColorId.green:
        return '▲';
      case ColorId.yellow:
        return '★';
      case ColorId.orange:
        return '■';
      case ColorId.purple:
        return '✚';
      case ColorId.cyan:
        return '⬡';
      case ColorId.pink:
        return '♥';
    }
  }
}
