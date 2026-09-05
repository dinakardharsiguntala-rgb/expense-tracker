import Foundation
import IdentityLookup

/// Native Apple SMS Filter Extension that processes incoming bank messages in the background
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {

    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        let response = ILMessageFilterQueryResponse()

        // Extract incoming SMS message text
        guard let messageBody = queryRequest.messageBody, !messageBody.isEmpty else {
            response.action = .none
            completion(response)
            return
        }

        // Run our intelligent On-Device Bank SMS Parser
        let result = BankSMSParser.parse(message: messageBody)

        if result.isValidTransaction {
            // 1. Automatically save transaction into shared App Group database
            SharedExpenseDatabase.shared.saveAutoParsedTransaction(from: result)

            // 2. Classify as Transactional for iOS Messages app
            response.action = .allow
            if #available(iOS 14.0, *) {
                response.subAction = .transactional
            }
        } else {
            response.action = .none
        }

        completion(response)
    }
}

