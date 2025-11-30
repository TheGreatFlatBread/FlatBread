//
//  ChatWebSocketManager.swift
//  FlatBread
//
//  Created by hwan on 11/24/25.
//

import Foundation
import SocketIO

/// Socket.IO를 통한 실시간 채팅 메시지 수신
final class ChatWebSocketManager: NSObject, @unchecked Sendable {

    private let tokenCoordinator: TokenRefreshCoordinator = NetworkServiceFactory.shared.getTokenCoordinator()

override init() {
        super.init()
    }

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var currentRoomID: String?

    private var messageStream: AsyncStream<ChatMessageResponseDTO>?
    private var messageContinuation: AsyncStream<ChatMessageResponseDTO>.Continuation?

    private var connectionStream: AsyncStream<Bool>?
    private var connectionContinuation: AsyncStream<Bool>.Continuation?
    
    var messages: AsyncStream<ChatMessageResponseDTO> {
        if let stream = messageStream {
            return stream
        }
        let (stream, continuation) = AsyncStream.makeStream(of: ChatMessageResponseDTO.self)
        self.messageStream = stream
        self.messageContinuation = continuation
        return stream
    }

    var connectionStates: AsyncStream<Bool> {
        if let stream = connectionStream {
            return stream
        }
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        self.connectionStream = stream
        self.connectionContinuation = continuation
        return stream
    }

    func prepareNewConnection() {
        if socket != nil {
            disconnect()
        } else {
            resetStreams()
        }
    }

    func connect(roomID: String) {
        currentRoomID = roomID

        Task {
            let accessToken = await tokenCoordinator.getAccessToken()

            guard let url = URL(string: APIConfig.socketURL) else {
                return
            }

            let config: SocketIOClientConfiguration = [
                .log(false),
                .compress,
                .extraHeaders([
                    "Authorization": accessToken,
                    "SeSACKey": APIConfig.apikey,
                    "ProductId": APIConfig.productID
                ]),
                .reconnects(true),
                .reconnectAttempts(3),
                .reconnectWait(1),
                .reconnectWaitMax(16)
            ]

            manager = SocketManager(socketURL: url, config: config)
            socket = manager?.socket(forNamespace: "/chats-\(roomID)")

            setupEventHandlers()
            socket?.connect()
        }
    }

    private func resetStreams() {
        connectionStream = nil
        connectionContinuation = nil
        messageStream = nil
        messageContinuation = nil
    }

    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            self?.connectionContinuation?.yield(true)
        }

        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.connectionContinuation?.yield(false)
        }

        socket?.on(clientEvent: .reconnect) { [weak self] data, ack in
            self?.connectionContinuation?.yield(true)
        }

        socket?.on(clientEvent: .reconnectAttempt) { data, ack in
            if let attempt = data.first as? Int {
            }
        }

        socket?.on(clientEvent: .error) { data, ack in
        }

        socket?.on("chat") { [weak self] data, ack in
            guard let jsonObject = data.first,
                  let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject),
                  let messageDTO = try? JSONDecoder().decode(ChatMessageResponseDTO.self, from: jsonData) else {
                return
            }
            self?.messageContinuation?.yield(messageDTO)
        }
    }

    func disconnect() {
        guard socket != nil else { return }

        connectionContinuation?.yield(false)

        connectionContinuation?.finish()
        messageContinuation?.finish()

        socket?.disconnect()
        socket = nil
        manager = nil
        currentRoomID = nil

        connectionStream = nil
        connectionContinuation = nil
        messageStream = nil
        messageContinuation = nil
    }
}
