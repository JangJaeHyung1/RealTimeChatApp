//
//  ConversationsModel.swift
//  Messenger
//
//  Created by jh on 2021/04/04.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
