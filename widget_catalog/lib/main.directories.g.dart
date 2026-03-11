// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widget_catalog/app/add_client_view.widgetbook.dart'
    as _widget_catalog_app_add_client_view_widgetbook;
import 'package:widget_catalog/app/auth_screens.widgetbook.dart'
    as _widget_catalog_app_auth_screens_widgetbook;
import 'package:widget_catalog/app/chat_view.widgetbook.dart'
    as _widget_catalog_app_chat_view_widgetbook;
import 'package:widget_catalog/app/confirm_slider.widgetbook.dart'
    as _widget_catalog_app_confirm_slider_widgetbook;
import 'package:widget_catalog/app/customer_detail_view.widgetbook.dart'
    as _widget_catalog_app_customer_detail_view_widgetbook;
import 'package:widget_catalog/app/embedded_client_card.widgetbook.dart'
    as _widget_catalog_app_embedded_client_card_widgetbook;
import 'package:widget_catalog/app/engagement_timeline.widgetbook.dart'
    as _widget_catalog_app_engagement_timeline_widgetbook;
import 'package:widget_catalog/app/pending_review_list.widgetbook.dart'
    as _widget_catalog_app_pending_review_list_widgetbook;
import 'package:widget_catalog/app/settings_view.widgetbook.dart'
    as _widget_catalog_app_settings_view_widgetbook;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'screens',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'AddClientView',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widget_catalog_app_add_client_view_widgetbook
                .buildAddClientViewUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'CustomerDetailView',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Full View',
            builder: _widget_catalog_app_customer_detail_view_widgetbook
                .buildCustomerDetailViewUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'With Proposed Updates',
            builder: _widget_catalog_app_customer_detail_view_widgetbook
                .buildCustomerDetailViewWithProposedUpdatesUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'LoginScreen',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Login Screen',
            builder: _widget_catalog_app_auth_screens_widgetbook
                .buildLoginScreenUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'RegisterScreen',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Register Screen',
            builder: _widget_catalog_app_auth_screens_widgetbook
                .buildRegisterScreenUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'SettingsView',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widget_catalog_app_settings_view_widgetbook
                .buildSettingsViewUseCase,
          ),
        ],
      ),
    ],
  ),
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
        name: 'EngagementTimeline',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widget_catalog_app_engagement_timeline_widgetbook
                .buildEngagementTimelineUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'KeyValueChatView',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widget_catalog_app_chat_view_widgetbook
                .buildKeyValueChatViewUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'With Preview',
            builder: _widget_catalog_app_chat_view_widgetbook
                .buildKeyValueChatViewWithPreviewUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'PendingReviewList',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widget_catalog_app_pending_review_list_widgetbook
                .buildPendingReviewListUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'ai',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'EmbeddedClientCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _widget_catalog_app_embedded_client_card_widgetbook
                    .buildEmbeddedClientCardUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Minimal',
                builder: _widget_catalog_app_embedded_client_card_widgetbook
                    .buildMinimalEmbeddedClientCardUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
