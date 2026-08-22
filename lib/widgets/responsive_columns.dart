/// Column counts for preset / vent tile grids.
int responsiveTileColumns(double width) {
  if (width < 520) return 3;
  if (width < 760) return 4;
  if (width < 1024) return 5;
  if (width < 1280) return 6;
  if (width < 1600) return 7;
  return 8;
}

int responsivePresetColumns(double width, int itemCount) {
  final cols = responsiveTileColumns(width);
  return cols.clamp(3, itemCount);
}
