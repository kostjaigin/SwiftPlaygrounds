import UIKit

extension NSRegularExpression {
    static func isMatch(forPattern pattern: String, in text: String) -> Bool {
        return (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))?.firstMatch(in: text, range: NSRange(location: 0, length: text.count)) != nil
    }
}
extension NSTextCheckingResult {
    func isEmpty(atRangeIndex index: Int) -> Bool {
        return range(at: index).length == 0
    }
    func string(from text: String, atRangeIndex index: Int) -> String {
        return (text as NSString).substring(with: range(at: index))
    }
}
extension String {
    func substring(from startIdx: Int, to endIdx: Int? = nil) -> String {
        if startIdx < 0 || (endIdx != nil && endIdx! < 0) {
            return ""
        }
        let start = index(startIndex, offsetBy: startIdx)
        let end = endIdx != nil ? index(startIndex, offsetBy: endIdx!) : endIndex
        return String(self[start..<end])
    }
}

extension Date {
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    func add(component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self)!
    }
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    var endOfDay: Date {
        return self.set(hour: 23, minute: 59, second: 59)
    }
    func getTimeIgnoreSecondsFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    static func daysBetween(start: Date, end: Date, ignoreHours: Bool) -> Int {
        let startDate = ignoreHours ? start.startOfDay : start
        let endDate = ignoreHours ? end.startOfDay : end
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!
    }
    static let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second, .weekday]
    private var dateComponents: DateComponents {
        return  Calendar.current.dateComponents(Date.components, from: self)
    }
    
    var year: Int { return dateComponents.year! }
    var month: Int    { return dateComponents.month! }
    var day: Int { return dateComponents.day! }
    var hour: Int { return dateComponents.hour! }
    var minute: Int    { return dateComponents.minute! }
    var second: Int    { return dateComponents.second! }
    
    var weekday: Int { return dateComponents.weekday! }
    
    func set(year: Int?=nil, month: Int?=nil, day: Int?=nil, hour: Int?=nil, minute: Int?=nil, second: Int?=nil, tz: String?=nil) -> Date {
        let timeZone = Calendar.current.timeZone
        let year = year ?? self.year
        let month = month ?? self.month
        let day = day ?? self.day
        let hour = hour ?? self.hour
        let minute = minute ?? self.minute
        let second = second ?? self.second
        let dateComponents = DateComponents(timeZone:timeZone, year:year, month:month, day:day, hour:hour, minute:minute, second:second)
        let date = Calendar.current.date(from: dateComponents)
        return date!
    }
}

/*
The returned result structure
It will be changed by found matches to the patterns
*/
public class ParsedResult {
    
    /* Catched Date Time */
    private var startDate: Date
    private var endDate: Date
    public var startChanged: Bool
    public var endChanged: Bool
    public var start: Date { return self.startDate}
    public var end: Date { return self.endDate }
    /* Collection of parts of the text catched with patterns */
    public var catchedParts: [String]?
    /* Start index of the catched text, ordering corresponding to catchedParts */
    public var indexes: [Int]?
    
    public init() {
        startDate = Date()
        endDate = Date()
        catchedParts = [String]()
        indexes = [Int]()
        startChanged = false
        endChanged = false
    }
    
    public func setStartDate(value: Date) {
        self.startChanged = true
        self.startDate = value
    }
    public func setEndDate(value: Date) {
        self.endChanged = true
        self.endDate = value
    }
    
}

public class DateTimeParser {
    /* override this property */
    public var pattern: String { return "" }
    /* override this method */
    public func extract(text: String, match: NSTextCheckingResult, refResult: ParsedResult) {}
    
    public init() {}
    
    public func matchTextAndIndex(from text: String, andMatchResult matchResult: NSTextCheckingResult) -> (matchText: String, index: Int) {
        // let index1Length = matchResult.range(at: 1).length
        let matchText = matchResult.string(from: text, atRangeIndex: 0) //.substring(from: index1Length)
        let index = matchResult.range(at: 0).location //+ index1Length
        return (matchText, index)
        // do not delete commented parts
    }
    
}

public class EN_classicParser: DateTimeParser {
    private let PATTERN = "(\\W|^)(now|today|tonight|last\\s*night|(?:tomorrow|tmr|yesterday)\\s*|tomorrow|tmr|yesterday)(?=\\W|$)"

    
    override public var pattern: String { return PATTERN }
    /* expands referenced Result */
    override public func extract(text: String, match: NSTextCheckingResult, refResult: ParsedResult) {
        
        let (matchText, index) = matchTextAndIndex(from: text.lowercased(), andMatchResult: match)
        refResult.catchedParts?.append(matchText)
        refResult.indexes?.append(index)
        
        let lowercased = matchText.lowercased()
        
        if lowercased == "tonight" {
            refResult.setStartDate(value: refResult.start.set(year: nil, month: nil, day: nil, hour: 22, minute: 0, second: 0, tz: nil))
        } else if NSRegularExpression.isMatch(forPattern: "tomorrow|tmr", in: lowercased) {
            refResult.setStartDate(value: refResult.start.add(component: .day, value: 1))
            refResult.setStartDate(value: refResult.start.set(year: nil, month: nil, day: nil, hour: 12, minute: 0, second: 0, tz: nil))
        } else if NSRegularExpression.isMatch(forPattern: "yesterday", in: lowercased) {
            refResult.setStartDate(value: refResult.start.add(component: .day, value: -1))
            refResult.setStartDate(value: refResult.start.set(year: nil, month: nil, day: nil, hour: 12, minute: 0, second: 0, tz: nil))
        } else if NSRegularExpression.isMatch(forPattern: "last\\s*night", in: lowercased) {
            // TODO
        }
        /* For 'today' and now data is already initialized as start moment */
        
    }
}

public class EN_exactTimeParser: DateTimeParser {
    private let startPATTERN = "(^|\\s|T)" + // (GROUP1)
        "(?:(?:at|from)\\s*)?" + // optional at or from followed by whitespace, nl or tab
        "(\\d{1,2}|noon|midnight)" + // non-optional numeric digits (minimum 1, maximum 4 digits) or words noon and midnight (GROUP2)
        "(?:" + // non-capturing group (still no clue what that means)
        "(?:\\.|\\:|\\：|\\s)(\\d{1,2})" + // minutes (GROUP3)
        "(?:" +
        "(?:\\:|\\：)(\\d{2})" + // seconds (GROUP4)
        ")?" +
        ")?" +
        "(?:\\s*(A\\.M\\.|P\\.M\\.|AM?|PM?))?" + // AM/PM Group (GROUP5)
    "(?=\\W|$)"
    private let endPATTERN = "^\\s*" +
        "(\\-|\\–|\\~|\\〜|to|\\?)\\s*" + // first group
        "(\\d{1,2})" + //hours
        "(?:" +
        "(?:\\.|\\:|\\：|\\s)(\\d{1,2})" + // minutes
        "(?:" +
        "(?:\\.|\\:|\\：)(\\d{1,2})" + // seconds
        ")?" +
        ")?" +
        "(?:\\s*(A\\.M\\.|P\\.M\\.|AM?|PM?))?" + // ampm
    "(?=\\W|$)"
    
    private let hourGroup = 2
    private let minuteGroup = 3
    private let secondGroup = 4
    private let amPmHourGroup = 5

    override public var pattern: String { return startPATTERN }

    override public func extract(text: String, match: NSTextCheckingResult, refResult: ParsedResult) {
        
        var (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        refResult.catchedParts?.append(matchText)
        refResult.indexes?.append(index)
        var hour = 0
        var minute = 0
        var days = 0
        
        /* Hours */
        if (match.isEmpty(atRangeIndex: hourGroup) == false) {
            let hourText = match.string(from: text, atRangeIndex: hourGroup).lowercased()
            if hourText == "noon" {
                hour = 12
            } else if hourText == "midnight" {
                hour = 0
                days = 1
            } else {
                hour = Int(hourText)!
            }
        } else { return }
        
        /* Minutes */
        if match.isEmpty(atRangeIndex: minuteGroup) == false {
            minute = Int(match.string(from: text, atRangeIndex: minuteGroup))!
        }
        if minute>=60 || hour > 24 { return }

        /* AM PM Group */
        if match.isEmpty(atRangeIndex: amPmHourGroup) == false {
            if hour > 12 {
                return
            }
            
            let ampm = match.string(from: text, atRangeIndex: amPmHourGroup).first?.lowercased()
            if ampm == "a" { hour = (hour == 12) ? 0 : hour }
            if ampm == "p" { hour = hour != 12 ? hour+12 : hour }
        }
        
        // Assign start date to the result:
        let day = refResult.start.day + days
        refResult.setStartDate(value: refResult.start.set(year: nil, month: nil, day: day, hour: hour, minute: minute, second: 0, tz: nil))
        
        /* 'TO' part of input: */
        let regex = try? NSRegularExpression(pattern: endPATTERN, options: .caseInsensitive)
        let secondPartIdx = refResult.indexes!.last!+refResult.catchedParts!.last!.count
        let secondText = text.substring(from: secondPartIdx)
        guard let match = regex?.firstMatch(in: secondText, range: NSRange(location: 0, length: secondText.count)) else { return }
        
        (matchText, index) = matchTextAndIndex(from: secondText, andMatchResult: match)
        refResult.catchedParts!.append(matchText)
        /* index will not match, because we work only with the second part of the whole text */
        refResult.indexes!.append(secondPartIdx + index)
        
        if (refResult.endChanged == false) { refResult.setEndDate(value: refResult.start) }
        
        hour = Int(match.string(from: secondText, atRangeIndex: hourGroup))!
        minute = 0
        
        if match.isEmpty(atRangeIndex: minuteGroup) == false {
            minute = Int(match.string(from: secondText, atRangeIndex: minuteGroup))!
            if minute >= 60 || hour > 24 { return }
        }
        
        if match.isEmpty(atRangeIndex: amPmHourGroup) == false {
            
            if hour > 12 { return }
            
            let ampm = match.string(from: secondText, atRangeIndex: amPmHourGroup).first!.lowercased()
            if ampm == "a" { hour = (hour == 12) ? 0 : hour }
            if ampm == "p" { hour = hour != 12 ? hour+12 : hour }
        }
        
        var endDate = refResult.end.set(year: nil, month: nil, day: nil, hour: hour, minute: minute, second: 0, tz: nil)
        
        if (refResult.start > endDate) { endDate = endDate.add(component: .day, value: 1) }
        
        refResult.setEndDate(value: endDate)
    }
}

/*
Call different parsing patterns to refine the result
Return nil if parsing did not work out
Return refined ParsedResult entity
*/
public func main(text: String) -> ParsedResult? {
    
    var result = ParsedResult()
    
    if (text.isEmpty) { return nil }
    
    // TODO : for now only one parser available -> ENCasualDates
    // foreach pattern try it
    let parser = EN_classicParser()
    let parser1 = EN_exactTimeParser()
    var parsers = [DateTimeParser]()
    parsers.append(parser)
    parsers.append(parser1)
    
    for prsr in parsers {
        var regex = try? NSRegularExpression(pattern: prsr.pattern, options: .caseInsensitive)
        var match = regex?.firstMatch(in: text, range: NSRange(location: 0, length: text.count))
        if (match != nil) {
            // TODO pattern extract
            prsr.extract(text: text, match: match!, refResult: result)
        }
    }
    
    return result
}

/* Current test execution phase: */
let test_string = "I am going to the library tomorrow from 12 to 14:30"

var result = main(text: test_string)



