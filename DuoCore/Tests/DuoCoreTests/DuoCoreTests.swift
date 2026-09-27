import Foundation
import Testing
@testable import DuoCore

let tokyo: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return c
}()

func at(_ day: Int, _ h: Int, _ m: Int = 0) -> Date {
    tokyo.date(from: DateComponents(year: 2026, month: 9, day: day, hour: h, minute: m))!
}

@Suite struct SlotTests {
    @Test func 組み合わせは左右の順も区別して6通り_同じものは並べない() {
        #expect(SlotPair.all.count == 6)
        #expect(SlotPair.all.allSatisfy { $0.left != $0.right })
        #expect(Set(SlotPair.all).count == 6)
    }

    @Test func URLから戻せる() {
        for s in Slot.allCases { #expect(Slot(url: s.url) == s) }
        #expect(Slot(url: URL(string: "other://steps")!) == nil)
        #expect(Slot(url: URL(string: "splitproto://nope")!) == nil)
    }
}

@Suite struct BatteryTests {
    @Test func 読めない値はハイフン() {
        #expect(BatteryReading(raw: -1, charging: false).percentText == "--")
        #expect(BatteryReading(raw: 0.83, charging: false).percentText == "83%")
        #expect(BatteryReading(raw: 1, charging: true).percentText == "100%")
    }

    @Test func 少ないのは10パーセント以下で充電中は除く() {
        #expect(BatteryReading(level: 0.10, charging: false).isLow)
        #expect(!BatteryReading(level: 0.11, charging: false).isLow)
        #expect(!BatteryReading(level: 0.05, charging: true).isLow)
        #expect(!BatteryReading(level: nil, charging: false).isLow)
    }
}

@Suite struct StepsTests {
    @Test func 三桁区切り() {
        #expect(StepsText.format(8432) == "8,432")
        #expect(StepsText.format(12345) == "12,345")
        #expect(StepsText.format(0) == "0")
        #expect(StepsText.format(nil) == "--")
    }

    @Test func ヘルスケアと歩数計を合わせる_4_168() {
        #expect(StepCombiner.steps(healthTotal: 5000, watchSince: 120, watchToday: 4900) == 5120)
        // 読みのずれで Watch 単独を下回ったら Watch 単独を下限に
        #expect(StepCombiner.steps(healthTotal: 4000, watchSince: 0, watchToday: 4100) == 4100)
        #expect(StepCombiner.steps(healthTotal: nil, watchSince: nil, watchToday: 3000) == 3000)
        #expect(StepCombiner.steps(healthTotal: 2000, watchSince: nil, watchToday: nil) == 2000)
        #expect(StepCombiner.steps(healthTotal: nil, watchSince: nil, watchToday: nil) == nil)
    }
}

@Suite struct NextEventTests {
    let events = [
        CalEvent(title: "朝会", start: at(27, 9), end: at(27, 9, 30)),
        CalEvent(title: "誕生日", start: at(27, 0), end: at(28, 0), isAllDay: true),
        CalEvent(title: "打ち合わせ", start: at(27, 14, 30), end: at(27, 15, 30)),
        CalEvent(title: "歯医者", start: at(28, 10), end: at(28, 11)),
    ]

    @Test func 次に始まる予定を出す_終日は出さない() {
        let d = NextEvent.display(events, now: at(27, 12), calendar: tokyo)
        #expect(d == NextEventDisplay(when: "14:30", title: "打ち合わせ", inProgress: false))
    }

    @Test func 進行中は終わりの時刻() {
        let d = NextEvent.display(events, now: at(27, 9, 10), calendar: tokyo)
        #expect(d == NextEventDisplay(when: "〜9:30", title: "朝会", inProgress: true))
    }

    @Test func 明日の予定には明日と付ける() {
        let d = NextEvent.display(events, now: at(27, 20), calendar: tokyo)
        #expect(d.when == "明日 10:00")
        #expect(d.title == "歯医者")
    }

    @Test func 終わった予定と36時間より先は出さない() {
        #expect(NextEvent.display(events, now: at(28, 12), calendar: tokyo).title == "予定なし")
        let far = [CalEvent(title: "旅行", start: at(30, 9), end: at(30, 10))]
        #expect(NextEvent.pick(far, now: at(27, 12)) == nil)
    }

    @Test func 終わった瞬間に次へ移る() {
        #expect(NextEvent.display(events, now: at(27, 9, 30), calendar: tokyo).title == "打ち合わせ")
    }

    @Test func 無題の予定() {
        let e = [CalEvent(title: "", start: at(27, 13), end: at(27, 14))]
        #expect(NextEvent.display(e, now: at(27, 12), calendar: tokyo).title == "（無題）")
    }

    @Test func 切り替わる時刻は始まり_終わり_日付の変わり目() {
        let dates = NextEvent.changeDates(events, now: at(27, 12), until: at(28, 12), calendar: tokyo)
        #expect(dates == [at(27, 14, 30), at(27, 15, 30), at(28, 0), at(28, 10), at(28, 11)])
    }
}
