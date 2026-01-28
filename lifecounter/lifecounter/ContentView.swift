//
//  ContentView.swift
//  lifecounter
//
//  Created by Hrudhai Umas on 1/26/26.
//

import SwiftUI

struct ContentView: View
{
    // MARK: - Life totals for each player (starts at 20 as the game rules say)
    @State private var playerOneLifeTotal: Int = 20
    @State private var playerTwoLifeTotal: Int = 20

    // MARK: - Computed value: checks if either player has lost (life <= 0)
    private var hasLoser: Bool
    {
        if playerOneLifeTotal <= 0
        {
            return true
        }
        if playerTwoLifeTotal <= 0
        {
            return true
        }
        return false
    }

    // MARK: computed values, we are returning the correct lose message (or empty string if no one lost yet)
    private var loserText: String
    {
        if playerOneLifeTotal <= 0
        {
            return "Player 1 LOSES!"
        }
        if playerTwoLifeTotal <= 0
        {
            return "Player 2 LOSES!"
        }
        return ""
    }

    // MARK: - Main UI is here
    var body: some View
    {
        // GeometryReader gives us the device size
        GeometryReader { geometryProxy in

            // For spacing and sizing
            let screenWidth = geometryProxy.size.width
            let screenHeight = geometryProxy.size.height
            let baseScale = min(screenWidth, screenHeight)

            let outerPadding = baseScale * 0.04
            let spaceBetweenSections = baseScale * 0.03
            let cardCornerRadius = baseScale * 0.03

            // places the player area on top and the status/reset area at the bottom
            VStack(spacing: spaceBetweenSections)
            {
                // places Player 1 and Player 2 panels side-by-side with equal space
                HStack(spacing: spaceBetweenSections)
                {
                    playerPanel(
                        playerDisplayName: "Player 1",
                        playerLifeTotal: $playerOneLifeTotal,
                        panelCornerRadius: cardCornerRadius
                    )

                    playerPanel(
                        playerDisplayName: "Player 2",
                        playerLifeTotal: $playerTwoLifeTotal,
                        panelCornerRadius: cardCornerRadius
                    )
                }
                .frame(maxWidth: .infinity)
                .frame(height: screenHeight * 0.80)

                // Bottom status area shows who lost + a reset button when the game endss
                bottomStatusArea(
                    panelCornerRadius: cardCornerRadius,
                    horizontalPadding: outerPadding
                )
                .frame(maxWidth: .infinity)
                .frame(height: screenHeight * 0.12)
            }
            .padding(outerPadding)
        }
    }

    // MARK: - Bottom Status Area
    // This view shows the losing message and a reset button once a player reaches 0 or less.
    private func bottomStatusArea(panelCornerRadius: CGFloat, horizontalPadding: CGFloat) -> some View
    {
        // background card behind the text/button content
        ZStack
        {
            // If a player lost show the message and the Reset button
            if hasLoser
            {
                // message on the left, reset button on the right
                HStack(spacing: 12)
                {
                    Text(loserText)
                        .font(.headline)
                        .foregroundStyle(.red)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Button(action: resetGameToStartingState)
                    {
                        Text("Reset")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
        // show/hide the entire bottom bar based on whether someone lost
        .opacity(bottomBarOpacityValue())
    }

    // MARK: - Player Panel
    // This builds one player section so the name, life total, and the four buttons (+, -, +5, -5)
    private func playerPanel(
        playerDisplayName: String,
        playerLifeTotal: Binding<Int>,
        panelCornerRadius: CGFloat
    ) -> some View
    {
        // stack name, life label, and the button grid vertically
        VStack(spacing: 12)
        {
            // Player name label
            Text(playerDisplayName)
                .font(.title2)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            // Life total label
            Text("\(playerLifeTotal.wrappedValue)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.3)
                .lineLimit(1)

            // contains two rows of buttons
            VStack(spacing: 10)
            {
                // first row of buttons (+ and -)
                HStack(spacing: 10)
                {
                    lifeChangeButton(buttonTitle: "+")
                    {
                        changePlayerLifeTotal(playerLifeTotal: playerLifeTotal, lifeDelta: 1)
                    }

                    lifeChangeButton(buttonTitle: "-")
                    {
                        changePlayerLifeTotal(playerLifeTotal: playerLifeTotal, lifeDelta: -1)
                    }
                }

                // second row of buttons (+5 and -5)
                HStack(spacing: 10)
                {
                    lifeChangeButton(buttonTitle: "+5")
                    {
                        changePlayerLifeTotal(playerLifeTotal: playerLifeTotal, lifeDelta: 5)
                    }

                    lifeChangeButton(buttonTitle: "-5")
                    {
                        changePlayerLifeTotal(playerLifeTotal: playerLifeTotal, lifeDelta: -5)
                    }
                }
            }
            // I added this so that it disables all buttons once someone loses so the game "ends" until reset
            .disabled(hasLoser)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: panelCornerRadius)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius))
    }

    // MARK: - Button Builder
    // Creates a consistent looking button for changing life totals.
    private func lifeChangeButton(buttonTitle: String, buttonAction: @escaping () -> Void) -> some View
    {
        Button(action: buttonAction)
        {
            Text(buttonTitle)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Life Total Logic
    // Applies a life change to a player (like +1, -1, +5, -5).
    private func changePlayerLifeTotal(playerLifeTotal: Binding<Int>, lifeDelta: Int)
    {
        // If someone already lost, we do nothing (since the game is over until reset)
        if hasLoser
        {
            return
        }

        let updatedLifeTotal = playerLifeTotal.wrappedValue + lifeDelta
        playerLifeTotal.wrappedValue = updatedLifeTotal
    }

    // MARK: - Reset Logic
    // Resets both players back to the starting values (20 life each).
    private func resetGameToStartingState()
    {
        playerOneLifeTotal = 20
        playerTwoLifeTotal = 20
    }

    // MARK: - UI Helper
    // Returns 1.0 when the bottom bar should be visible, otherwise 0.0.
    private func bottomBarOpacityValue() -> Double
    {
        if hasLoser
        {
            return 1.0
        }
        return 0.0
    }
}

#Preview
{
    ContentView()
}
