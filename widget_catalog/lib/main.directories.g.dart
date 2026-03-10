// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widget_catalog/app/confirm_slider.widgetbook.dart'
    as _widget_catalog_app_confirm_slider_widgetbook;
import 'package:widget_catalog/dash/feedback_detail_sidebar.widgetbook.dart'
    as _widget_catalog_dash_feedback_detail_sidebar_widgetbook;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'widgets',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'ConfirmSlider',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Compact',
            builder: _widget_catalog_app_confirm_slider_widgetbook
                .buildCompactConfirmSliderUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widget_catalog_app_confirm_slider_widgetbook
                .buildConfirmSliderUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'FeedbackDetailSidebar',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widget_catalog_dash_feedback_detail_sidebar_widgetbook
                .buildFeedbackDetailSidebarUseCase,
          ),
        ],
      ),
    ],
  ),
];
