part of '../../../quran.dart';

class BannerStyle {
  ///[bannerImagePath] if you wanna add banner as image you can provide the path
  final String? bannerImagePath;

  ///[bannerImageWidth] if you wanna add the width for the banner image
  final double? bannerImageWidth;

  ///[bannerImageHeight] if you wanna add the height for the banner image
  final double? bannerImageHeight;

  ///[isImage] if you wanna add banner as svg you can set it to true
  final bool? isImage;

  ///[bannerSvgPath] if you wanna add banner as svg you can provide the path
  final String? bannerSvgPath;

  ///[bannerSvgWidth] if you wanna add the width for the banner svg
  final double? bannerSvgWidth;

  ///[bannerSvgHeight] if you wanna add the height for the banner svg
  final double? bannerSvgHeight;

  BannerStyle({
    this.isImage,
    this.bannerImagePath,
    this.bannerImageWidth,
    this.bannerImageHeight,
    this.bannerSvgPath,
    this.bannerSvgWidth,
    this.bannerSvgHeight,
  });
}
