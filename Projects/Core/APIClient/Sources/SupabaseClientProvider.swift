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
                    storage: Supabase.AuthClient.Configuration.defaultLocalStorage,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}
