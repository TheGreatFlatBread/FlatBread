//
//  RefreshableView.swift
//  FlatBread
//
//  Created by hwan on 11/13/25.
//

import SwiftUI

struct RefreshableContainer<Content: View>: View {
    @Namespace private var namespace

    @State private var refreshable: Refreshable = .init()
    @State private var isRefreshing: Bool = false
    @State private var lastScrollOffset: CGFloat = 0
    private let reverse: Bool
    @ViewBuilder private var content: () -> Content
    @ViewBuilder private var indicator: () -> AnyView?
    private let onRefresh: (() -> Void)?

    @Binding var scrollPosition: String
    
    init(
        reverse: Bool = false,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder indicator: @escaping () -> AnyView? = { nil },
        onRefresh: (() -> Void)? = nil,
        scrollPosition: Binding<String>
    ) {
        self.reverse = reverse
        self.content = content
        self.indicator = indicator
        self.onRefresh = onRefresh
        self._scrollPosition = scrollPosition
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                content()
                    .rotationEffect(.degrees(reverse ? 180 : 0))
                    .scaleEffect(x: -1)
                    .background(
                        GeometryReader { geometry in
                            return Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: reverse
                                    ? -geometry.frame(in: .named(namespace)).maxY + refreshable.scrollViewHeight
                                    : geometry.frame(in: .named(namespace)).minY
                                )
                        }
                    )
                    .padding(.horizontal, 8)
            }
            .coordinateSpace(name: namespace)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollViewHeightKey.self, value: geometry.size.height)
                }
            )
            .onPreferenceChange(ScrollViewHeightKey.self) { height in
                Task {
                    await MainActor.run {
                        if reverse && height > 0 {
                            refreshable.scrollViewHeight = height
                        }
                    }
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let shouldUpdate = abs(offset - lastScrollOffset) > 1.0 || refreshable.state == .loading || offset == 0
                guard shouldUpdate else { return }
                lastScrollOffset = offset
                refreshable.updateStateOnlyLoading(for: offset)
                if refreshable.state == .loading && !isRefreshing {
                    isRefreshing = true
                    onRefresh?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        refreshable.reset()
                        isRefreshing = false
                    }
                }
            }
            .onChange(of: scrollPosition) { v1, v2 in
                guard v1 != v2 && !v2.isEmpty else { return }
                proxy.scrollTo(v2)
            }
            .overlay {
                VStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black)
                        .cornerRadius(15)
                        .opacity(refreshable.state.indicatorOpacity)
                        .offset(y: refreshable.scrollOffset * 0.3)
                        .animation(.linear, value: refreshable.state)
                        .padding(.top, 10)
                    Spacer()
                }
                .rotationEffect(.degrees(reverse ? 180 : 0))
                .scaleEffect(x: -1)
            }
            .rotationEffect(.degrees(reverse ? 180 : 0))
            .scaleEffect(x: -1)
        }
    }

}

fileprivate struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}

fileprivate struct ScrollViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}

fileprivate struct Refreshable {
    private let PENDING_THRESHOLD: CGFloat = 40
    private let READY_THRESHOLD: CGFloat = 90

    enum State {
        case none
        case pending
        case ready
        case loading

        var indicatorOpacity: CGFloat {
            switch self {
            case .none:
                return 0
            case .pending:
                return 0.2
            case .ready, .loading:
                return 1
            }
        }
    }

    private var previousScrollOffset: CGFloat = 0

    var scrollViewHeight: CGFloat = 0

    var scrollOffset: CGFloat = 0 {
        didSet {
            previousScrollOffset = oldValue
        }
    }

    var differentialOffset: CGFloat {
        scrollOffset - previousScrollOffset
    }

    var state: State = .none
    
    mutating func updateStateOnlyLoading(for scrollOffset: CGFloat) {
        self.scrollOffset = scrollOffset
        if state == .loading {
            return
        }
        if state == .none, scrollOffset > -50 {
            state = .loading
        }
    }

    mutating func updateState(for scrollOffset: CGFloat) {
        self.scrollOffset = scrollOffset
        
        if state == .loading {
            return
        }
        
        if state == .pending || (state == .ready && scrollOffset <= 0) {
            state = .none
        }
        
        if state == .none && scrollOffset > PENDING_THRESHOLD {
            state = .pending
        }
        
        if state == .pending && scrollOffset > READY_THRESHOLD {
            state = .ready
        }
        
        if state == .ready
            && scrollOffset > READY_THRESHOLD
            && isDragEnd(dy: differentialOffset) {
            state = .loading
        }
    }

    mutating func reset() {
        state = .none
    }

    func isDragEnd(dy: CGFloat) -> Bool {
        return differentialOffset < -10
    }
}

extension View {
    func asIndicator() -> AnyView {
        return AnyView(self)
    }
}
