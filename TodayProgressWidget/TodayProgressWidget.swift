//
//  TodayProgressWidget.swift
//  TodayProgressWidget
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import WidgetKit
import SwiftUI
import Core

struct Provider: TimelineProvider {
    typealias Entry = TodayProgressEntry
    
    private let getTodayProgressUseCase: any GetTodayProgressUseCase = DefaultGetTodayProgressUseCase(
        store: UserDefaultsTodayProgressStore()
    )
    
    func placeholder(in context: Context) -> TodayProgressEntry {
        Entry(date: Date(), percentage: 1)
    }
    
    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (TodayProgressEntry) -> Void
    ) {
        completion(Entry(date: .now, percentage: getTodayProgressUseCase.execute(on: .now)))
    }
    
    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<TodayProgressEntry>) -> Void
    ) {
        let calendar = Calendar.current
        let now = Date.now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let midnight = calendar.startOfDay(for: tomorrow)
        
        let entries = [
            Entry(date: now, percentage: getTodayProgressUseCase.execute(on: now)),
            Entry(date: midnight, percentage: getTodayProgressUseCase.execute(on: midnight))
        ]
        
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }
}

struct TodayProgressEntry: TimelineEntry {
    let date: Date
    let percentage: Double
}

struct TodayProgressWidgetEntryView : View {
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

struct TodayProgressWidget: Widget {
    let kind: String = "TodayProgressWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(),
            content: { entry in
                TodayProgressWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
        )
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .systemSmall) {
    TodayProgressWidget()
} timeline: {
    TodayProgressEntry(date: .now, percentage: 1 )
}
