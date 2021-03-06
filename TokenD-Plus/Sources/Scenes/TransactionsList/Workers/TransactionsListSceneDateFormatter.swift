import Foundation
import AFDateHelper

extension TransactionsListScene {
    class DateFormatter: DateFormatterProtocol {
        
        private let userDefaults: UserDefaults = UserDefaults.standard
        
        private lazy var localeIdentifier: String = {
            let languageKey = self.userDefaults
                .value(forKey: LocalizationManager.languageKey) as? String ?? "en"
            return languageKey
        }()
        
        private lazy var titleDateFormatter: Foundation.DateFormatter = {
            let formatter = Foundation.DateFormatter()
            formatter.locale = Locale(identifier: self.localeIdentifier)
            formatter.dateFormat = "LLLL yyyy"
            return formatter
        }()
        private lazy var transactionDateFormatter: Foundation.DateFormatter = {
            let formatter = Foundation.DateFormatter()
            formatter.locale = Locale(identifier: self.localeIdentifier)
            formatter.dateFormat = "dd MMMM"
            return formatter
        }()
        private lazy var transactionDateFormatterForHours: Foundation.DateFormatter = {
            let formatter = Foundation.DateFormatter()
            formatter.locale = Locale(identifier: self.localeIdentifier)
            formatter.dateFormat = "HH:mm"
            return formatter
        }()
        private lazy var transactionDateFormatterForYears: Foundation.DateFormatter = {
            let formatter = Foundation.DateFormatter()
            formatter.locale = Locale(identifier: self.localeIdentifier)
            formatter.dateFormat = "dd MMMM, YYYY"
            return formatter
        }()
        
        func formatDateForTitle(_ date: Date) -> String {
            return self.titleDateFormatter.string(from: date)
        }
        
        func formatDateForTransaction(_ date: Date) -> String {
            if date.compare(.isToday) {
                return self.transactionDateFormatterForHours.string(from: date)
            } else if date.compare(.isYesterday) {
                let hours = self.transactionDateFormatterForHours.string(from: date)
                return Localized(
                    .yesterday_at,
                    replace: [
                        .yesterday_at_replace_hours: hours
                    ]
                )
            } else if date.compare(.isThisYear) {
                return self.transactionDateFormatter.string(from: date)
            } else {
                return self.transactionDateFormatterForYears.string(from: date)
            }
        }
    }
}
