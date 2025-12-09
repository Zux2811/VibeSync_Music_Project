import 'package:logger/logger.dart';

// Configure a global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 1, // number of method calls to be displayed
    errorMethodCount: 5, // number of method calls if stacktrace is provided
    lineLength: 80, // width of the log print
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    printTime: false, // Should each log print contain a timestamp
  ),
);

