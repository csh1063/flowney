import APIClient
import ComposableArchitecture
import CoreLocation
import DesignSystem
import Models
import SwiftUI

struct AddItemFormView: View {
    @Bindable var store: StoreOf<AddItemFeature>
    @State private var isCurrencyManagementPresented = false
    @State private var isMapPickerPresented = false
    @State private var tripCurrencies: [String] = []

    private var showsDetailFields: Bool {
        store.editingOriginalItem != nil || store.resolvedLat != nil
    }

    var body: some View {
        Form {
            Section {
                FlowneySegmentedControl(
                    selection: Binding(
                        get: { store.mode },
                        set: { store.send(.modeChanged($0)) }
                    ),
                    options: AddItemFeature.Mode.allCases,
                    label: \.displayName
                )
            }

            if store.mode == .manual {
                Section("위치") {
                    if store.resolvedLat != nil {
                        if !store.address.isEmpty {
                            Text(store.address)
                                .font(FlowneyFont.caption)
                                .foregroundStyle(FlowneyTheme.textSecondary)
                        }
                        Button("위치 다시 찾기") { isMapPickerPresented = true }
                    } else {
                        Button("지도에서 위치 찾기") { isMapPickerPresented = true }
                    }
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
                                    .foregroundStyle(FlowneyTheme.textSecondary)
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
                            .font(FlowneyFont.caption)
                            .foregroundStyle(FlowneyTheme.error)
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
                            .font(FlowneyFont.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    } else {
                        ForEach(store.dedupedReuseCandidates) { candidate in
                            Button {
                                store.send(.reuseCandidateTapped(candidate))
                            } label: {
                                HStack {
                                    Text(candidate.itemType.icon)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.name)
                                            .foregroundStyle(FlowneyTheme.textPrimary)
                                        if let address = candidate.address {
                                            Text(address)
                                                .font(FlowneyFont.caption)
                                                .foregroundStyle(FlowneyTheme.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if isSelectedReuseCandidate(candidate) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(FlowneyTheme.success)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if showsDetailFields {
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
                            .foregroundStyle(FlowneyTheme.error)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FlowneyTheme.background)
        .scrollDismissesKeyboard(.immediately)
        .onAppear { tripCurrencies = TripCurrencyStore.read(tripID: store.tripID) }
        .onChange(of: store.savedItem) { _, savedItem in
            guard savedItem != nil, !store.costAmountText.isEmpty else { return }
            let currency = store.costCurrency
            guard currency.uppercased() != "KRW" else { return }
            guard !tripCurrencies.contains(where: { $0.uppercased() == currency.uppercased() }) else { return }
            tripCurrencies.append(currency)
            TripCurrencyStore.save(tripID: store.tripID, currencies: tripCurrencies)
        }
        .fullScreenCover(isPresented: $isMapPickerPresented) {
            MapLocationPickerView(
                initialCoordinate: mapPickerInitialCoordinate,
                onConfirm: { place in
                    store.send(.mapLocationPicked(place))
                    isMapPickerPresented = false
                }
            )
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
        .flowneyLifecycleLog(category: .addItem)
    }

    private var mapPickerInitialCoordinate: CLLocationCoordinate2D? {
        if let lat = store.resolvedLat, let lng = store.resolvedLng {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        if let lastCamera = LastMapCameraStore.read() {
            return CLLocationCoordinate2D(latitude: lastCamera.lat, longitude: lastCamera.lng)
        }
        return nil
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
