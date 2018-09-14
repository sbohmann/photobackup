import Foundation

func dateToMillisecondTimestamp(_ date: Date?) -> Int64? {
    if let date = date {
        return dateToMillisecondTimestamp(date)
    } else {
        return nil
    }
}

func dateToMillisecondTimestamp(_ date: Date) -> Int64? {
    return Int64(date.timeIntervalSince1970 * 1000.0)
}

func millisecondTimestampToDate(_ timestamp: Int64) -> Date {
    return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
}
