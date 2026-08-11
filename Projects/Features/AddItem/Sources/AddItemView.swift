import ComposableArchitecture
import Models
import SwiftUI

public struct AddItemView: View {
    @Bindable var store: StoreOf<AddItemFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<AddItemFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("등록 방식", selection: $store.mode) {
                        ForEach(AddItemFeature.Mode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if store.mode == .link {
                    Section("구글맵 링크") {
                        HStack {
                            TextField("구글맵에서 공유한 링크 붙여넣기", text: $store.linkURLText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            if store.isResolvingLink {
                                ProgressView()
                            } else {
                                Button("가져오기") { store.send(.resolveLinkButtonTapped) }
                                    .disabled(store.linkURLText.isEmpty)
                            }
                        }
                        if store.resolvedLat != nil {
                            Label("장소를 찾았어요 — 아래 이름/주소를 확인해주세요.", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section("일정") {
                    TextField("이름 (예: 루브르 박물관, 점심 식사)", text: $store.name)

                    Picker("종류", selection: $store.itemType) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    // 세부 수단(지하철/트램/버스 등)은 "경로 탐색"이 실제 걷기 vs 대중교통
                    // 소요시간을 비교해서 자동으로 정해준다 — 여기서는 "차만큼은 확실히
                    // 차로 가야 한다"는 의도만 구분하면 되므로 3단계로 단순화했다. 걷기/대중교통을
                    // 골라도 검색이 더 빠른 쪽으로 바꿀 수 있다("차"만 검색이 안 건드리는 확정값).
                    Picker("이동수단", selection: transportBucketBinding) {
                        ForEach(TransportBucket.allCases, id: \.self) { bucket in
                            Text(bucket.label).tag(bucket)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("시간 지정", isOn: $store.hasStartTime)
                    if store.hasStartTime {
                        DatePicker("시작 시간", selection: $store.startTime, displayedComponents: .hourAndMinute)
                    }

                    TextField("주소/메모용 위치 (선택)", text: $store.address)
                }

                Section("비용") {
                    HStack {
                        TextField("금액", text: $store.costAmountText)
                            .keyboardType(.decimalPad)
                        TextField("통화", text: $store.costCurrency)
                            .frame(width: 60)
                    }

                    if store.costCurrency.uppercased() != "KRW" && !store.costAmountText.isEmpty {
                        TextField("원화 환산 금액 (선택 — 요금표 합계에 쓰여요)", text: $store.costAmountKRWText)
                            .keyboardType(.decimalPad)
                    }

                    Picker("카테고리", selection: $store.costCategory) {
                        Text("선택 안 함").tag(CostCategory?.none)
                        ForEach(CostCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(CostCategory?.some(category))
                        }
                    }

                    Picker("결제 상태", selection: $store.paymentStatus) {
                        Text("선택 안 함").tag(PaymentStatus?.none)
                        ForEach(PaymentStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(PaymentStatus?.some(status))
                        }
                    }
                }

                Section("메모") {
                    TextField("메모", text: $store.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage = store.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("일정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        store.send(.cancelButtonTapped)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if store.isSaving {
                        ProgressView()
                    } else {
                        Button("추가") { store.send(.saveButtonTapped) }
                    }
                }
            }
        }
    }

    private enum TransportBucket: String, CaseIterable {
        case walk, transit, car

        var label: String {
            switch self {
            case .walk: return "걷기"
            case .transit: return "대중교통"
            case .car: return "차"
            }
        }
    }

    // 걷기/대중교통은 백엔드에서 똑같이 "실제로 비교해서 더 빠른 쪽" 취급되므로 굳이
    // 세부 TransportMode로 구분해서 저장할 필요가 없다 — .walk만 미리 채워서 검색 전에도
    // 배지가 보이게 하고, 대중교통은 검색이 실제 수단(지하철/버스/트램)을 채워줄 때까지 비워둔다.
    private var transportBucketBinding: Binding<TransportBucket> {
        Binding(
            get: {
                switch store.arrivalMode {
                case .car: return .car
                case .walk: return .walk
                default: return .transit
                }
            },
            set: { newValue in
                let mode: TransportMode? = switch newValue {
                case .walk: .walk
                case .transit: nil
                case .car: .car
                }
                store.send(.binding(.set(\.arrivalMode, mode)))
            }
        )
    }
}
