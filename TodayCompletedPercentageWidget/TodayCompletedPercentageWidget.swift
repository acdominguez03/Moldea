//
//  TodayCompletedPercentageWidget.swift
//  TodayCompletedPercentageWidget
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import WidgetKit
import SwiftUI
import Core

struct Provider: TimelineProvider {
    let getTodayProgressUseCase: any GetTodayProgressUseCase = DefaultGetTodayProgressUseCase()
    
    typealias Entry = TodayProgressEntry
    
    func placeholder(in context: Context) -> TodayProgressEntry {
        Entry(date: Date(), percentage: 1)
    }
    
    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (TodayProgressEntry) -> Void
    ) {
        completion(Entry(date: Date(), percentage: 1))
    }
    
    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<TodayProgressEntry>) -> Void
    ) {
        Task {
            let percentage = try? await getTodayProgressUseCase.execute()
            
            completion(
                Timeline(
                    entries: [TodayProgressEntry(
                        date: Date(),
                        percentage: percentage ?? 0
                    )],
                    policy:
                            .after(
                                Calendar.current
                                    .date(
                                        byAdding: .minute,
                                        value: 10,
                                        to: .now
                                    )!
                            )
                )
            )
        }
    }
}

struct TodayProgressEntry: TimelineEntry {
    let date: Date
    let percentage: Double
}

struct TodayCompletedPercentageWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Gauge(
                value: entry.percentage
            ) {
                Text("Hábitos completados")
            } currentValueLabel: {
                Text(entry.percentage, format: .percent.precision(.fractionLength(0)))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
    }
}

struct TodayCompletedPercentageWidget: Widget {
    let kind: String = "TodayCompletedPercentageWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(),
            content: { entry in
                TodayCompletedPercentageWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
        )
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .systemSmall) {
    TodayCompletedPercentageWidget()
} timeline: {
    TodayProgressEntry(date: .now, percentage: 1 )
}
