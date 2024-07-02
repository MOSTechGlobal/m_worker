part of 'theme_bloc.dart';

@immutable
sealed class ThemeEvent {}

final class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  ThemeChanged(this.themeMode);
}
