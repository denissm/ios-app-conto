import Foundation

extension TransactionsListScene {
    struct Routing {
        let onDidSelectItemWithIdentifier: (Identifier, BalanceId) -> Void
        let showSendPayment: (_ balanceId: String?) -> Void
        let showCreateReedeem: (_ balanceId: String?) -> Void
        let showAcceptRedeem: () -> Void
        let showReceive: () -> Void
        let showShadow: () -> Void
        let hideShadow: () -> Void
    }
}
