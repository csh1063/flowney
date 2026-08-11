import Foundation

/// `travel_map.html`(참고 프로토타입)에 있던 실제 2026년 유럽 여행
/// (네덜란드 → 프랑스 → 스위스) 일정을 그대로 옮긴 더미 데이터.
/// Xcode 프리뷰와 개발 중 빈 상태 대신 보여줄 샘플로 쓴다.
public enum SampleTravelData {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Amsterdam") ?? .current
        return calendar
    }()

    private static func date(month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    public static let ownerId = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!

    public static let trip = Trip(
        id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!,
        ownerId: ownerId,
        name: "2026 유럽 여행 (네덜란드·프랑스·스위스)",
        startDate: date(month: 9, day: 19),
        endDate: date(month: 10, day: 7),
        status: .confirmed
    )

    public static let countries: [TripCountry] = [
        TripCountry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            tripId: trip.id,
            countryCode: "NL",
            color: "#c8452e",
            sortOrder: 0
        ),
        TripCountry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            tripId: trip.id,
            countryCode: "FR",
            color: "#1e3a5f",
            sortOrder: 1
        ),
        TripCountry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            tripId: trip.id,
            countryCode: "CH",
            color: "#b8202e",
            sortOrder: 2
        ),
    ]

    public static let day1 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
        tripId: trip.id,
        countryCode: "NL",
        dayDate: date(month: 9, day: 19),
        dayIndex: 1,
        label: "9/19"
    )

    public static let day2 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
        tripId: trip.id,
        countryCode: "NL",
        dayDate: date(month: 9, day: 20),
        dayIndex: 2,
        label: "9/20 (A 단독)"
    )

    public static let day3 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000203")!,
        tripId: trip.id,
        countryCode: "NL",
        dayDate: date(month: 9, day: 21),
        dayIndex: 3,
        label: "9/21 (잔세스칸스)"
    )

    public static let day4 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000204")!,
        tripId: trip.id,
        countryCode: "NL",
        dayDate: date(month: 9, day: 22),
        dayIndex: 4,
        label: "9/22 (반고흐)"
    )

    public static let day5 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000205")!,
        tripId: trip.id,
        countryCode: "NL",
        dayDate: date(month: 9, day: 23),
        dayIndex: 5,
        label: "9/23 (파리로)"
    )

    public static let day6 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000206")!,
        tripId: trip.id,
        countryCode: "FR",
        dayDate: date(month: 9, day: 24),
        dayIndex: 6,
        label: "9/24"
    )

    public static let day7 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000207")!,
        tripId: trip.id,
        countryCode: "FR",
        dayDate: date(month: 9, day: 25),
        dayIndex: 7,
        label: "9/25"
    )

    public static let day8 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000208")!,
        tripId: trip.id,
        countryCode: "FR",
        dayDate: date(month: 9, day: 26),
        dayIndex: 8,
        label: "9/26"
    )

    public static let day9 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000209")!,
        tripId: trip.id,
        countryCode: "FR",
        dayDate: date(month: 9, day: 27),
        dayIndex: 9,
        label: "9/27 (휴식)"
    )

    public static let day10 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000210")!,
        tripId: trip.id,
        countryCode: "FR",
        dayDate: date(month: 9, day: 28),
        dayIndex: 10,
        label: "9/28 (디즈니)"
    )

    public static let day11 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000211")!,
        tripId: trip.id,
        countryCode: "FR",
        dayDate: date(month: 9, day: 29),
        dayIndex: 11,
        label: "9/29"
    )

    public static let day12 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000212")!,
        tripId: trip.id,
        countryCode: "FR",
        dayDate: date(month: 9, day: 30),
        dayIndex: 12,
        label: "9/30 (스위스로)"
    )

    public static let day13 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000213")!,
        tripId: trip.id,
        countryCode: "CH",
        dayDate: date(month: 10, day: 1),
        dayIndex: 13,
        label: "10/1"
    )

    public static let day14 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000214")!,
        tripId: trip.id,
        countryCode: "CH",
        dayDate: date(month: 10, day: 2),
        dayIndex: 14,
        label: "10/2"
    )

    public static let day15 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000215")!,
        tripId: trip.id,
        countryCode: "CH",
        dayDate: date(month: 10, day: 3),
        dayIndex: 15,
        label: "10/3"
    )

    public static let day16 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000216")!,
        tripId: trip.id,
        countryCode: "CH",
        dayDate: date(month: 10, day: 4),
        dayIndex: 16,
        label: "10/4 (자유)"
    )

    public static let day17 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000217")!,
        tripId: trip.id,
        countryCode: "CH",
        dayDate: date(month: 10, day: 5),
        dayIndex: 17,
        label: "10/5"
    )

    public static let day18 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000218")!,
        tripId: trip.id,
        countryCode: "CH",
        dayDate: date(month: 10, day: 6),
        dayIndex: 18,
        label: "10/6"
    )

    public static let day19 = TripDay(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000219")!,
        tripId: trip.id,
        countryCode: "CH",
        dayDate: date(month: 10, day: 7),
        dayIndex: 19,
        label: "10/7 (출국)"
    )

    public static let days: [TripDay] = [day1, day2, day3, day4, day5, day6, day7, day8, day9, day10, day11, day12, day13, day14, day15, day16, day17, day18, day19]

    private static let day1Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day1.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "스히폴 공항",
            lat: 52.3105,
            lng: 4.7683
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day1.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 12,
            name: "슬로터데이크역",
            lat: 52.3888,
            lng: 4.8384
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day1.id,
            sortOrder: 2,
            itemType: .lodge,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "숙소 Hotel2Stay",
            lat: 52.3869,
            lng: 4.8395
        ),
    ]

    private static let day2Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 52.3869,
            lng: 4.8395
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .tram,
            plannedDurationMin: 15,
            name: "요르단 지구",
            lat: 52.3738,
            lng: 4.8825
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 2,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "Foodhallen",
            lat: 52.3671,
            lng: 4.8681
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "본델파크 서쪽입구",
            lat: 52.3573,
            lng: 4.8615
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "Blauwe Theehuis",
            lat: 52.3568,
            lng: 4.872
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "장미정원(Rosarium)",
            lat: 52.3563,
            lng: 4.8735
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "노천극장",
            lat: 52.3555,
            lng: 4.8756
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 7,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "본델파크 동쪽출구",
            lat: 52.3616,
            lng: 4.8823
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day2.id,
            sortOrder: 8,
            itemType: .lodge,
            arrivalMode: .tram,
            plannedDurationMin: 20,
            name: "숙소 복귀",
            lat: 52.3869,
            lng: 4.8395
        ),
    ]

    private static let day3Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 52.3869,
            lng: 4.8395
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 3,
            name: "슬로터데이크역",
            lat: 52.3888,
            lng: 4.8384
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 14,
            name: "Zaandijk Zaanse Schans역",
            lat: 52.4472,
            lng: 4.8195
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 13,
            name: "잔세스칸스 마을",
            lat: 52.4747,
            lng: 4.8172
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 3,
            name: "카타리나 후버 치즈농장",
            lat: 52.473447,
            lng: 4.8184268
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 18,
            name: "중앙역",
            lat: 52.3791,
            lng: 4.9003
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "시내 관광지",
            lat: 52.373,
            lng: 4.8926
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day3.id,
            sortOrder: 7,
            itemType: .lodge,
            arrivalMode: .tram,
            plannedDurationMin: 15,
            name: "숙소 복귀",
            lat: 52.3869,
            lng: 4.8395
        ),
    ]

    private static let day4Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 52.3869,
            lng: 4.8395
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .tram,
            plannedDurationMin: 15,
            name: "중앙역",
            lat: 52.3791,
            lng: 4.9003
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "스투시",
            lat: 52.375607,
            lng: 4.900723
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "기울어진집(담락)",
            lat: 52.3745,
            lng: 4.8977
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "담광장",
            lat: 52.3730701,
            lng: 4.8926473
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .tram,
            plannedDurationMin: 5,
            name: "반고흐미술관",
            lat: 52.3584,
            lng: 4.8811,
            costAmount: 50.00,
            costCurrency: "EUR",
            costAmountKRW: 84500,
            costCategory: .entrance,
            paymentStatus: .paid
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 2,
            name: "쇼핑가(미술관 인근)",
            lat: 52.3576,
            lng: 4.879
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day4.id,
            sortOrder: 7,
            itemType: .lodge,
            arrivalMode: .tram,
            plannedDurationMin: 15,
            name: "숙소 복귀",
            lat: 52.3869,
            lng: 4.8395
        ),
    ]

    private static let day5Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day5.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소 체크아웃",
            lat: 52.3869,
            lng: 4.8395
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day5.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .tram,
            plannedDurationMin: 15,
            name: "암스테르담 중앙역",
            lat: 52.3791,
            lng: 4.9003
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day5.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 200,
            name: "파리 북역",
            lat: 48.8809,
            lng: 2.3553
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day5.id,
            sortOrder: 3,
            itemType: .lodge,
            arrivalMode: .metro,
            plannedDurationMin: 10,
            name: "파리 숙소",
            lat: 48.8512671,
            lng: 2.3664701,
            costAmount: 1128.86,
            costCurrency: "EUR",
            costAmountKRW: 1907773,
            costCategory: .lodging,
            paymentStatus: .paid
        ),
    ]

    private static let day6Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "파리 숙소",
            lat: 48.8512671,
            lng: 2.3664701
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .metro,
            plannedDurationMin: 4,
            name: "샤틀레역",
            lat: 48.8583,
            lng: 2.347
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 2,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 3,
            name: "라 파리지엔느 레알",
            lat: 48.8608,
            lng: 2.3458
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "루브르 박물관",
            lat: 48.8606,
            lng: 2.3376,
            costAmount: 66.27,
            costCurrency: "EUR",
            costAmountKRW: 112000,
            costCategory: .entrance,
            paymentStatus: .paid
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 4,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "Le P'tit Bistrot",
            lat: 48.8577,
            lng: 2.3494
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "Bourse de Commerce",
            lat: 48.8628,
            lng: 2.3428
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "팔레루아얄",
            lat: 48.8637569,
            lng: 2.3371261
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 7,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 2,
            name: "메르시 2호점",
            lat: 48.864525,
            lng: 2.3360862
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 8,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "alpha",
            lat: 48.86324,
            lng: 2.3341187
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 9,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "뫼리스",
            lat: 48.86566,
            lng: 2.32784
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 10,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "콩코르드 광장",
            lat: 48.8656,
            lng: 2.3212
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day6.id,
            sortOrder: 11,
            itemType: .lodge,
            arrivalMode: .metro,
            plannedDurationMin: 10,
            name: "숙소 복귀",
            lat: 48.8512671,
            lng: 2.3664701
        ),
    ]

    private static let day7Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 48.8512671,
            lng: 2.3664701
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .metro,
            plannedDurationMin: 10,
            name: "오르세미술관",
            lat: 48.8599614,
            lng: 2.3265614,
            costAmount: 32.00,
            costCurrency: "EUR",
            costAmountKRW: 54080,
            costCategory: .entrance,
            paymentStatus: .paid
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 2,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 3,
            name: "Cinq-Mars",
            lat: 48.8586028,
            lng: 2.3269472
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "APC Surplus",
            lat: 48.8557279,
            lng: 2.3335114
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 4,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 3,
            name: "카페 드 플로르",
            lat: 48.8541588,
            lng: 2.3326046
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "TASCHEN Store",
            lat: 48.8538128,
            lng: 2.3380656
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "노트르담",
            lat: 48.8529682,
            lng: 2.3499021
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 7,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "La Parisienne",
            lat: 48.8499455,
            lng: 2.3497819
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day7.id,
            sortOrder: 8,
            itemType: .lodge,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "숙소 복귀",
            lat: 48.8512671,
            lng: 2.3664701
        ),
    ]

    private static let day8Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 48.8512671,
            lng: 2.3664701
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "앙팡시장",
            lat: 48.8627249,
            lng: 2.3622569
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "메르시",
            lat: 48.8607214,
            lng: 2.3668319
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 3,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "LULU 크레페",
            lat: 48.8629922,
            lng: 2.3620888
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .metro,
            plannedDurationMin: 15,
            name: "피갈역",
            lat: 48.8822,
            lng: 2.3317
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 3,
            name: "마미쉐(빵집)",
            lat: 48.8800888,
            lng: 2.3435419
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .bus,
            plannedDurationMin: 4,
            name: "몽마르뜨(사크레쾨르)",
            lat: 48.8861929,
            lng: 2.3430895
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 7,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "사랑해벽",
            lat: 48.884856,
            lng: 2.3385644
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 8,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 2,
            name: "물랭루즈",
            lat: 48.8841,
            lng: 2.3322
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 9,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "Peppe Pizzeria Martyrs",
            lat: 48.8810102,
            lng: 2.339982
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day8.id,
            sortOrder: 10,
            itemType: .lodge,
            arrivalMode: .metro,
            plannedDurationMin: 10,
            name: "숙소 복귀",
            lat: 48.8512671,
            lng: 2.3664701
        ),
    ]

    private static let day9Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 48.8512671,
            lng: 2.3664701
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "Marché Bastille",
            lat: 48.8548,
            lng: 2.3699
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "앙팡시장",
            lat: 48.8627249,
            lng: 2.3622569
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 3,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "BigLove",
            lat: 48.8620551,
            lng: 2.3636352
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .metro,
            plannedDurationMin: 5,
            name: "몽쥬약국",
            lat: 48.8426219,
            lng: 2.3519269
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 5,
            itemType: .meal,
            arrivalMode: .walk,
            plannedDurationMin: 3,
            name: "Au P'tit Grec",
            lat: 48.8427933,
            lng: 2.3495547
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "뤽상부르공원",
            lat: 48.8466144,
            lng: 2.3363309
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day9.id,
            sortOrder: 7,
            itemType: .lodge,
            arrivalMode: .metro,
            plannedDurationMin: 5,
            name: "숙소 복귀",
            lat: 48.8512671,
            lng: 2.3664701
        ),
    ]

    private static let day10Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day10.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 48.8512671,
            lng: 2.3664701
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day10.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 45,
            name: "마른라발레 셰시역",
            lat: 48.8677,
            lng: 2.783
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day10.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "디즈니랜드 파리",
            lat: 48.8673858,
            lng: 2.783593,
            costAmount: 121.96,
            costCurrency: "EUR",
            costAmountKRW: 206120,
            costCategory: .activity,
            paymentStatus: .paid
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day10.id,
            sortOrder: 3,
            itemType: .lodge,
            arrivalMode: .train,
            plannedDurationMin: 45,
            name: "숙소 복귀",
            lat: 48.8512671,
            lng: 2.3664701
        ),
    ]

    private static let day11Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day11.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "숙소",
            lat: 48.8512671,
            lng: 2.3664701
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day11.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .metro,
            plannedDurationMin: 20,
            name: "개선문",
            lat: 48.8738,
            lng: 2.295
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day11.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "샹젤리제",
            lat: 48.8729602,
            lng: 2.2978526
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day11.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .metro,
            plannedDurationMin: 15,
            name: "마르스광장",
            lat: 48.8556,
            lng: 2.2986
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day11.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 15,
            name: "트로카데로",
            lat: 48.8619502,
            lng: 2.288682
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day11.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "바토파리지앵 선착장",
            lat: 48.860385,
            lng: 2.293565
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day11.id,
            sortOrder: 6,
            itemType: .lodge,
            arrivalMode: .metro,
            plannedDurationMin: 15,
            name: "숙소 복귀",
            lat: 48.8512671,
            lng: 2.3664701
        ),
    ]

    private static let day12Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day12.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "파리 숙소 체크아웃",
            lat: 48.8512671,
            lng: 2.3664701
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day12.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 20,
            name: "파리 리옹역",
            lat: 48.8443,
            lng: 2.3744
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day12.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 180,
            name: "바젤 SBB",
            lat: 47.5476,
            lng: 7.5896
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day12.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 155,
            name: "인터라켄 오스트",
            lat: 46.6908,
            lng: 7.8666
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day12.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 35,
            name: "그린델발트역",
            lat: 46.62436,
            lng: 8.03331
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day12.id,
            sortOrder: 5,
            itemType: .lodge,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "그린델발트 숙소",
            lat: 46.6250089,
            lng: 8.0255361,
            costAmount: 1388.96,
            costCurrency: "EUR",
            costAmountKRW: 2569576,
            costCategory: .lodging,
            paymentStatus: .paid
        ),
    ]

    private static let day13Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day13.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "그린델발트 숙소",
            lat: 46.6250089,
            lng: 8.0255361
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day13.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "그린델발트역",
            lat: 46.62436,
            lng: 8.03331
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day13.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 35,
            name: "인터라켄",
            lat: 46.6908,
            lng: 7.8666
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day13.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .car,
            plannedDurationMin: 10,
            name: "행글라이딩 착륙(회매트공원)",
            lat: 46.6863,
            lng: 7.8489
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day13.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .funicular,
            plannedDurationMin: 15,
            name: "하더쿨룸",
            lat: 46.6976,
            lng: 7.8637
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day13.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 45,
            name: "그린델발트역 복귀",
            lat: 46.62436,
            lng: 8.03331
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day13.id,
            sortOrder: 6,
            itemType: .lodge,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "그린델발트 복귀",
            lat: 46.6250089,
            lng: 8.0255361
        ),
    ]

    private static let day14Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "그린델발트 숙소",
            lat: 46.6250089,
            lng: 8.0255361
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "First 계곡역",
            lat: 46.625125,
            lng: 8.0417791
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 25,
            name: "First",
            lat: 46.660556,
            lng: 8.053611,
            costAmount: 43.40,
            costCurrency: "EUR",
            costAmountKRW: 80290,
            costCategory: .activity,
            paymentStatus: .fixed
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 8,
            name: "Schreckfeld (First Flyer)",
            lat: 46.65849,
            lng: 8.065224
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 10,
            name: "Bort (트로티바이크 활동)",
            lat: 46.6353,
            lng: 8.0489
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 10,
            name: "First 계곡역 복귀",
            lat: 46.625125,
            lng: 8.0417791
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 25,
            name: "First 재상승",
            lat: 46.660556,
            lng: 8.053611
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 7,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 40,
            noRoute: true,
            name: "Bachalpsee",
            lat: 46.667762,
            lng: 8.023103
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 8,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 40,
            noRoute: true,
            name: "First 복귀",
            lat: 46.660556,
            lng: 8.053611
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 9,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 8,
            name: "Schreckfeld 하산경유",
            lat: 46.65849,
            lng: 8.065224
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 10,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 8,
            name: "Bort 하산경유",
            lat: 46.6353,
            lng: 8.0489
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 11,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 9,
            name: "First 계곡역 하산",
            lat: 46.625125,
            lng: 8.0417791
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day14.id,
            sortOrder: 12,
            itemType: .lodge,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "그린델발트 하산",
            lat: 46.6250089,
            lng: 8.0255361
        ),
    ]

    private static let day15Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "그린델발트 숙소",
            lat: 46.6250089,
            lng: 8.0255361
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "그린델발트 터미널",
            lat: 46.625508,
            lng: 8.017106
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 15,
            name: "아이거글레처",
            lat: 46.575375,
            lng: 7.975647
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 50,
            name: "융프라우요흐",
            lat: 46.5450199,
            lng: 7.9709441
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 50,
            name: "클라이네샤이덱",
            lat: 46.5861,
            lng: 7.9613
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 15,
            name: "웬겐",
            lat: 46.6058,
            lng: 7.9219
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 6,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 15,
            name: "라우터브루넨",
            lat: 46.598434,
            lng: 7.9080887
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 7,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 15,
            name: "웬겐 복귀",
            lat: 46.6058,
            lng: 7.9219
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 8,
            itemType: .sight,
            arrivalMode: .gondola,
            plannedDurationMin: 20,
            name: "멘리헨",
            lat: 46.6103,
            lng: 7.9298
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day15.id,
            sortOrder: 9,
            itemType: .lodge,
            arrivalMode: .gondola,
            plannedDurationMin: 20,
            name: "그린델발트 복귀",
            lat: 46.6250089,
            lng: 8.0255361
        ),
    ]

    private static let day16Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day16.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "그린델발트 숙소",
            lat: 46.6250089,
            lng: 8.0255361
        ),
    ]

    private static let day17Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day17.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "그린델발트 체크아웃",
            lat: 46.6250089,
            lng: 8.0255361
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day17.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 8,
            name: "그린델발트역",
            lat: 46.62436,
            lng: 8.03331
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day17.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 35,
            name: "인터라켄 오스트",
            lat: 46.6908,
            lng: 7.8666
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day17.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 120,
            name: "루체른",
            lat: 47.0502,
            lng: 8.3093
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day17.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 45,
            name: "취리히 HB",
            lat: 47.3782,
            lng: 8.5402
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day17.id,
            sortOrder: 5,
            itemType: .lodge,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "취리히 숙소",
            lat: 47.3740681,
            lng: 8.5298541,
            costAmount: 286.66,
            costCurrency: "EUR",
            costAmountKRW: 530321,
            costCategory: .lodging,
            paymentStatus: .paid
        ),
    ]

    private static let day18Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day18.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "취리히 숙소",
            lat: 47.3740681,
            lng: 8.5298541
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day18.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .tram,
            plannedDurationMin: 10,
            name: "취리히 디자인박물관",
            lat: 47.390136,
            lng: 8.51204
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day18.id,
            sortOrder: 2,
            itemType: .meal,
            arrivalMode: .tram,
            plannedDurationMin: 10,
            name: "Zeughauskeller",
            lat: 47.3704208,
            lng: 8.5399742
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day18.id,
            sortOrder: 3,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 2,
            name: "린덴호프",
            lat: 47.3721811,
            lng: 8.5413182
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day18.id,
            sortOrder: 4,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "프라우뮌스터",
            lat: 47.3697849,
            lng: 8.5408331,
            costAmount: 10.00,
            costCurrency: "EUR",
            costAmountKRW: 18500,
            costCategory: .activity,
            paymentStatus: .fixed
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day18.id,
            sortOrder: 5,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 5,
            name: "호수(뷔르클리플라츠)",
            lat: 47.3667,
            lng: 8.541
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day18.id,
            sortOrder: 6,
            itemType: .lodge,
            arrivalMode: .tram,
            plannedDurationMin: 4,
            name: "숙소 복귀",
            lat: 47.3740681,
            lng: 8.5298541
        ),
    ]

    private static let day19Items: [ItineraryItem] = [
        ItineraryItem(
            tripId: trip.id,
            dayId: day19.id,
            sortOrder: 0,
            itemType: .lodge,
            arrivalMode: .start,
            name: "취리히 숙소 체크아웃",
            lat: 47.3740681,
            lng: 8.5298541
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day19.id,
            sortOrder: 1,
            itemType: .sight,
            arrivalMode: .walk,
            plannedDurationMin: 10,
            name: "취리히 HB",
            lat: 47.3782,
            lng: 8.5402
        ),
        ItineraryItem(
            tripId: trip.id,
            dayId: day19.id,
            sortOrder: 2,
            itemType: .sight,
            arrivalMode: .train,
            plannedDurationMin: 10,
            name: "취리히 공항",
            lat: 47.4502,
            lng: 8.5616
        ),
    ]

    public static let items: [ItineraryItem] = day1Items + day2Items + day3Items + day4Items + day5Items + day6Items + day7Items + day8Items + day9Items + day10Items + day11Items + day12Items + day13Items + day14Items + day15Items + day16Items + day17Items + day18Items + day19Items

    /// `trip`/`countries`/`days`/`items`는 프리뷰용으로 ID가 고정돼 있어서, 실제 백엔드에
    /// 그대로 insert하면 두 번째부터는 매번 기본키 중복 에러가 난다. 실제로 서버에 심을
    /// 때는 이 함수로 매번 새 UUID를 발급받은 복사본을 만들어 쓴다.
    public static func makeSeed(ownerId: UUID) -> (trip: Trip, countries: [TripCountry], days: [TripDay], items: [ItineraryItem]) {
        let tripID = UUID()

        var dayIDMap: [UUID: UUID] = [:]
        for day in days {
            dayIDMap[day.id] = UUID()
        }

        var seededTrip = trip
        seededTrip.id = tripID
        seededTrip.ownerId = ownerId

        let seededCountries = countries.map { country -> TripCountry in
            var country = country
            country.id = UUID()
            country.tripId = tripID
            return country
        }

        let seededDays = days.map { day -> TripDay in
            var day = day
            day.id = dayIDMap[day.id]!
            day.tripId = tripID
            return day
        }

        let seededItems = items.map { item -> ItineraryItem in
            var item = item
            item.id = UUID()
            item.tripId = tripID
            item.dayId = dayIDMap[item.dayId]!
            return item
        }

        return (seededTrip, seededCountries, seededDays, seededItems)
    }
}
