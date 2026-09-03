import APIClient
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

struct AddItemFormView: View {
    @Bindable var store: StoreOf<AddItemFeature>
    @State private var isCurrencyManagementPresented = false
    @State private var tripCurrencies: [String] = []

    var body: some View {
        Form {
            Section {
                Picker(
                    "등록 방식",
                    selection: Binding(
                        get: { store.mode },
                        set: { store.send(.modeChanged($0)) }
                    )
                ) {
                    ForEach(AddItemFeature.Mode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if store.resolvedLat != nil {
                    Label("위치 확인됨 — 지도에 핀/경로가 표시돼요.", systemImage: "mappin.circle.fill")
                        .font(WaypinFont.caption)
                        .foregroundStyle(WaypinTheme.success)
                } else {
                    Label("위치 정보 없음 — 지도에 핀이나 경로가 안 나와요.", systemImage: "exclamationmark.triangle.fill")
                        .font(WaypinFont.caption)
                        .foregroundStyle(WaypinTheme.warning)
                }
            }

            if store.mode == .link {
                Section("구글맵 링크") {
                    HStack {
                        TextField("구글맵에서 공유한 링크 붙여넣기", text: $store.linkURLText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !store.linkURLText.isEmpty {
                            Button {
                                store.linkURLText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(WaypinTheme.textSecondary)
                            }
                            .buttonStyle(.borderless)
                        }
                        if store.isResolvingLink {
                            ProgressView()
                        } else {
                            Button("가져오기") { store.send(.resolveLinkButtonTapped) }
                                .disabled(store.linkURLText.isEmpty)
                        }
                    }
                    if let linkResolveErrorMessage = store.linkResolveErrorMessage {
                        Text(linkResolveErrorMessage)
                            .font(WaypinFont.caption)
                            .foregroundStyle(WaypinTheme.error)
                    }
                }
            }

            if store.mode == .reuse {
                Section("이 여행에 이미 추가된 장소") {
                    if store.isLoadingReuseCandidates {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if store.dedupedReuseCandidates.isEmpty {
                        Text("좌표가 있는 장소가 아직 없어요. 링크로 가져온 항목이 있어야 재사용할 수 있어요.")
                            .font(WaypinFont.caption)
                            .foregroundStyle(WaypinTheme.textSecondary)
                    } else {
                        ForEach(store.dedupedReuseCandidates) { candidate in
                            Button {
                                store.send(.reuseCandidateTapped(candidate))
                            } label: {
                                HStack {
                                    Text(candidate.itemType.icon)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.name)
                                            .foregroundStyle(WaypinTheme.textPrimary)
                                        if let address = candidate.address {
                                            Text(address)
                                                .font(WaypinFont.caption)
                                                .foregroundStyle(WaypinTheme.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if isSelectedReuseCandidate(candidate) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(WaypinTheme.success)
                                    }
                                }
                            }
                        }
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
                CostInputSection(
                    tripCurrencies: tripCurrencies,
                    costAmountText: $store.costAmountText,
                    costCurrency: $store.costCurrency,
                    costAmountKRWText: $store.costAmountKRWText,
                    costCategory: $store.costCategory,
                    paymentStatus: $store.paymentStatus,
                    onManageCurrenciesTapped: { isCurrencyManagementPresented = true }
                )
            }

            Section("메모") {
                TextField("메모", text: $store.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            if let errorMessage = store.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(WaypinTheme.error)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(WaypinTheme.background)
        .scrollDismissesKeyboard(.immediately)
        .onAppear { tripCurrencies = TripCurrencyStore.read(tripID: store.tripID) }
        .onChange(of: store.savedItem) { _, savedItem in
            guard let currency = savedItem?.costCurrency, currency.uppercased() != "KRW" else { return }
            guard !tripCurrencies.contains(where: { $0.uppercased() == currency.uppercased() }) else { return }
            tripCurrencies.append(currency)
            TripCurrencyStore.save(tripID: store.tripID, currencies: tripCurrencies)
        }
        .sheet(isPresented: $isCurrencyManagementPresented) {
            CurrencyManagementView(currentCurrencies: tripCurrencies) { finalCurrencies in
                TripCurrencyStore.save(tripID: store.tripID, currencies: finalCurrencies)
                tripCurrencies = finalCurrencies
                let stillValid = (["KRW"] + finalCurrencies).contains { $0.uppercased() == store.costCurrency.uppercased() }
                if !stillValid {
                    store.costCurrency = "KRW"
                }
            }
        }
    }

    private func isSelectedReuseCandidate(_ candidate: ItineraryItem) -> Bool {
        guard let resolvedLat = store.resolvedLat, let resolvedLng = store.resolvedLng else { return false }
        return candidate.lat == resolvedLat && candidate.lng == resolvedLng
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
