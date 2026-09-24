//
//  StatisticsTextsEnum.swift
//  Statistics
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum StatisticsTextsEnum {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    private static func localized(_ value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(value, bundle: .atURL(Bundle.module.bundleURL))
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("statistics_screen_title")
    public static let emptyState = resource("statistics_empty_state")

    // MARK: Filter
    public static let statisticsFilterDay = resource("statistics_filter_day")
    public static let statisticsFilterWeek = resource("statistics_filter_week")
    public static let statisticsFilterMonth = resource("statistics_filter_month")
    public static let statisticsFilterYear = resource("statistics_filter_year")

    // MARK: Habits List
    public static let habitsHeader = resource("statistics_habits_header")

    // MARK: Day Chart
    public static let dayChartSummary = resource("statistics_day_chart_summary")

    // MARK: Week Chart
    public static let weekChartWeeklyMark = resource("statistics_week_chart_weekly_mark")
    public static let weekChartSummary = resource("statistics_week_chart_summary")

    // MARK: Month Chart
    public static let monthChartSummary = resource("statistics_month_chart_summary")

    public static func monthChartWeekMark(_ number: Int) -> LocalizedStringResource {
        localized("statistics_month_chart_week_mark \(number)")
    }

    // MARK: Year Chart
    public static let yearChartSummary = resource("statistics_year_chart_summary")
}
