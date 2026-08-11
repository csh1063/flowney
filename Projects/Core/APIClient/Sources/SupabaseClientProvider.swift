import Foundation
import Supabase

public enum SupabaseClientProvider {
    public static let shared: SupabaseClient = {
        guard
            let host = Bundle.main.object(forInfoDictionaryKey: "SupabaseHost") as? String,
            !host.isEmpty,
            let url = URL(string: "https://\(host)"),
            url.host(percentEncoded: false) != nil,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            !anonKey.isEmpty
        else {
            fatalError("Supabase 설정이 없습니다. Projects/App/Config.xcconfig를 확인하세요.")
        }
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    // 이 모듈에도 `AuthClient`(우리 TCA 클라이언트)가 있어서 이름이 겹치므로
                    // Supabase SDK의 AuthClient는 모듈 접두사로 명시해야 함.
                    storage: Supabase.AuthClient.Configuration.defaultLocalStorage,
                    // 새로 나온 옵션으로 미리 opt-in — 로컬에 저장된 세션을 즉시 그대로 emit하고,
                    // 유효한지는 우리가 직접 판단한다(AuthFeature에서 만료 여부 체크).
                    // 안 켜두면 "refresh 시도 후 초기 세션 emit"이라는 레거시 동작이라 매번
                    // 콘솔에 deprecation 경고가 뜨고, 초기 세션 emit 타이밍도 한 박자 늦어진다.
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}
