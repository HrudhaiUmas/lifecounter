//
//  ContentView.swift
//  lifecounter
//
//  Created by Hrudhai Umas on 1/26/26.
//

import SwiftUI

struct ContentView: View
{
    // Life totals for all players (starts with 4 players at 20 life each)
    @State private var allPlayerLifeTotals: [Int] = [20, 20, 20, 20]

    // Player display names (can be edited by tapping as well)
    @State private var allPlayerDisplayNames: [String] = ["Player 1", "Player 2", "Player 3", "Player 4"]

    // chunk input text per player (numeric only)
    @State private var allPlayerChunkAmountText: [String] = ["5", "5", "5", "5"]

    // History state (this is cleared on FULL reset or Game Over OK)
    @State private var gameHistoryLog: [String] = []

    // Navigation state for the History screen
    @State private var isHistoryScreenPresented: Bool = false

    // Name editing dialog state stuff below
    @State private var isNameEditDialogPresented: Bool = false
    @State private var playerIndexBeingRenamed: Int = 0
    @State private var temporaryNameEditText: String = ""

    // game over state (controls disabling UI + showing OK)
    @State private var isGameOverBarPresented: Bool = false

    // Losing message shown at the bottom ("Player X LOSES!")
    @State private var mostRecentLosingMessage: String = ""

    // checks if any player has lost (life <= 0)
    private var doesAnyPlayerHaveLifeAtZeroOrLess: Bool
    {
        for playerLifeTotal in allPlayerLifeTotals
        {
            if playerLifeTotal <= 0
            {
                return true
            }
        }
        return false
    }

    // checks if the game has started (any life changed from 20)
    private var hasGameStartedBecauseLifeChanged: Bool
    {
        for playerLifeTotal in allPlayerLifeTotals
        {
            if playerLifeTotal != 20
            {
                return true
            }
        }
        return false
    }

    // checks if game over (all but one player has lost)
    private var isGameOverBecauseOnlyOnePlayerIsAlive: Bool
    {
        var numberOfPlayersStillAlive: Int = 0

        for playerLifeTotal in allPlayerLifeTotals
        {
            if playerLifeTotal > 0
            {
                numberOfPlayersStillAlive = numberOfPlayersStillAlive + 1
            }
        }

        if numberOfPlayersStillAlive == 1
        {
            return true
        }
        return false
    }

    // add player is allowed only if game has not started and we are below 8 players
    private var canAddAnotherPlayerRightNow: Bool
    {
        if allPlayerLifeTotals.count >= 8
        {
            return false
        }
        if hasGameStartedBecauseLifeChanged
        {
            return false
        }
        return true
    }

    // disables the entire game UI when game over happens
    private var shouldDisableAllGameControls: Bool
    {
        if isGameOverBarPresented
        {
            return true
        }
        if isGameOverBecauseOnlyOnePlayerIsAlive
        {
            return true
        }
        return false
    }

    // MARK: - Main UI is here
    var body: some View
    {
        NavigationStack
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

                // places the controls on top, player grid in the middle, status on bottom
                VStack(spacing: spaceBetweenSections)
                {
                    // Top bar (Add Player / Reset / History)
                    HStack(spacing: 12)
                    {
                        Button(action: addNewPlayerToGame)
                        {
                            Text("Add Player")
                                .font(.headline)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(addPlayerButtonDisabledValue())
                        .disabled(shouldDisableAllGameControls)

                        Spacer()

                        // Reset button that resets everything (including history)
                        Button(action: resetGameToOriginalStartingState)
                        {
                            Text("Reset")
                                .font(.headline)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(shouldDisableAllGameControls)

                        Button(action: showHistoryScreen)
                        {
                            Text("History")
                                .font(.headline)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(shouldDisableAllGameControls)
                    }

                    // Player Area
                    let gridColumns: [GridItem] =
                    [
                        GridItem(.flexible(), spacing: spaceBetweenSections),
                        GridItem(.flexible(), spacing: spaceBetweenSections)
                    ]

                    ScrollView
                    {
                        LazyVGrid(columns: gridColumns, spacing: spaceBetweenSections)
                        {
                            ForEach(allPlayerLifeTotals.indices, id: \.self)
                            { playerIndex in
                                playerPanel(
                                    playerIndex: playerIndex,
                                    panelCornerRadius: cardCornerRadius
                                )
                                .frame(minHeight: 240)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: screenHeight * 0.76)

                    // MARK: - Bottom status area (Game Over + OK OR Player X LOSES!)
                    bottomStatusArea(horizontalPadding: bottomBarHorizontalPaddingValue(basePadding: outerPadding))
                        .frame(maxWidth: .infinity)
                        .frame(height: screenHeight * 0.10)
                }
                .padding(outerPadding)
            }
            .navigationTitle("Life Counter")
            .navigationBarTitleDisplayMode(.inline)

            // MARK: - Navigation to History Screen
            .navigationDestination(isPresented: $isHistoryScreenPresented)
            {
                HistoryView(historyLog: gameHistoryLog)
            }

            // MARK: - Bonus: Name Editing Dialog
            .alert("Edit Player Name", isPresented: $isNameEditDialogPresented)
            {
                TextField("Enter name", text: $temporaryNameEditText)

                Button("Save")
                {
                    saveEditedPlayerName()
                }

                Button("Cancel", role: .cancel)
                {
                    cancelEditedPlayerName()
                }
            }
            message:
            {
                Text("Type a new name for this player.")
            }
        }
    }

    // MARK: - Bottom Status Area
    // If game over: show "Game over!" and OK button.
    // Else if someone lost: show "Player X LOSES!"
    private func bottomStatusArea(horizontalPadding: CGFloat) -> some View
    {
        ZStack
        {
            if isGameOverBarPresented
            {
                HStack(spacing: 12)
                {
                    Text("Game over!")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Button(action: resetGameToOriginalStartingState)
                    {
                        Text("OK")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, horizontalPadding)
            }
            else
            {
                if mostRecentLosingMessage.count > 0
                {
                    HStack(spacing: 12)
                    {
                        Text(mostRecentLosingMessage)
                            .font(.headline)
                            .foregroundStyle(.red)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            }
        }
        // show/hide the entire bottom bar based on whether someone lost
        .opacity(bottomBarOpacityValue())
    }

    // MARK: - Player Panel
    // This builds one player section: name, life total, +/- and chunk controls (with +/- and numeric input).
    private func playerPanel(playerIndex: Int, panelCornerRadius: CGFloat) -> some View
    {
        // this disables ONLY the player that already lost (life <= 0)
        let hasThisPlayerLost: Bool = playerHasLost(playerIndex: playerIndex)

        // stack name, life label, and the controls vertically
        return VStack(spacing: 12)
        {
            // MARK: - Player name (tap to rename)
            Button(action:
            {
                beginEditingPlayerName(playerIndex: playerIndex)
            })
            {
                Text(allPlayerDisplayNames[playerIndex])
                    .font(.title2)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .disabled(shouldDisableAllGameControls)

            // MARK: - Life total label
            Text("\(allPlayerLifeTotals[playerIndex])")
                .font(.system(size: 90, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.3)
                .lineLimit(1)

            // MARK: - Controls
            VStack(spacing: 10)
            {
                // first row of buttons (+ and -)
                HStack(spacing: 10)
                {
                    lifeChangeButton(buttonTitle: "+")
                    {
                        changePlayerLifeTotal(
                            playerIndex: playerIndex,
                            lifeDelta: 1
                        )
                    }

                    lifeChangeButton(buttonTitle: "-")
                    {
                        changePlayerLifeTotal(
                            playerIndex: playerIndex,
                            lifeDelta: -1
                        )
                    }
                }

                // second row: chunk controls (paired button and numeric input only)
                HStack(spacing: 10)
                {
                    lifeChangeButton(buttonTitle: "-")
                    {
                        let chunkAmount = parsedChunkAmountFromText(chunkText: allPlayerChunkAmountText[playerIndex])
                        changePlayerLifeTotal(
                            playerIndex: playerIndex,
                            lifeDelta: 0 - chunkAmount
                        )
                    }

                    TextField("Chunk", text: chunkTextBindingForPlayer(playerIndex: playerIndex))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: allPlayerChunkAmountText[playerIndex])
                        { oldTextValue, newTextValue in
                            allPlayerChunkAmountText[playerIndex] = digitsOnlyText(inputText: newTextValue)
                        }

                    lifeChangeButton(buttonTitle: "+")
                    {
                        let chunkAmount = parsedChunkAmountFromText(chunkText: allPlayerChunkAmountText[playerIndex])
                        changePlayerLifeTotal(
                            playerIndex: playerIndex,
                            lifeDelta: chunkAmount
                        )
                    }
                }
            }
            // Disable controls if game over OR this player already lost
            .disabled(shouldDisableAllGameControls)
            .disabled(hasThisPlayerLost)
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
    // Applies a life change and logs it in the History screen.
    private func changePlayerLifeTotal(playerIndex: Int, lifeDelta: Int)
    {
        // If game over, do nothing
        if shouldDisableAllGameControls
        {
            return
        }

        // If this player already lost, do nothing
        if playerHasLost(playerIndex: playerIndex)
        {
            return
        }

        // If change is 0, do nothing
        if lifeDelta == 0
        {
            return
        }

        let oldLifeTotal = allPlayerLifeTotals[playerIndex]
        let updatedLifeTotal = oldLifeTotal + lifeDelta
        allPlayerLifeTotals[playerIndex] = updatedLifeTotal

        // Log history message in the requested style
        let historyMessage = historyMessageForLifeChange(
            playerName: allPlayerDisplayNames[playerIndex],
            lifeDelta: lifeDelta
        )
        gameHistoryLog.append(historyMessage)

        // If a player just dropped to 0 or less, show + log the losing message
        if oldLifeTotal > 0
        {
            if updatedLifeTotal <= 0
            {
                let losingMessage = "\(allPlayerDisplayNames[playerIndex]) LOSES!"
                mostRecentLosingMessage = losingMessage
                gameHistoryLog.append(losingMessage)
            }
        }

        // if only one player is alive now, show Game Over barr
        if hasGameStartedBecauseLifeChanged
        {
            if isGameOverBecauseOnlyOnePlayerIsAlive
            {
                isGameOverBarPresented = true
            }
        }
    }

    // MARK: - History Message Builder
    private func historyMessageForLifeChange(playerName: String, lifeDelta: Int) -> String
    {
        let absoluteAmount = absoluteValueOfInt(number: lifeDelta)
        let amountWord = lifeAmountWord(amount: absoluteAmount)

        if lifeDelta < 0
        {
            return "\(playerName) lost \(amountWord) life."
        }
        return "\(playerName) gained \(amountWord) life."
    }

    // MARK: - Add Player Logic
    private func addNewPlayerToGame()
    {
        if canAddAnotherPlayerRightNow == false
        {
            return
        }

        if shouldDisableAllGameControls
        {
            return
        }

        let newPlayerNumber = allPlayerLifeTotals.count + 1
        let newPlayerName = "Player \(newPlayerNumber)"

        allPlayerLifeTotals.append(20)
        allPlayerDisplayNames.append(newPlayerName)
        allPlayerChunkAmountText.append("5")

        gameHistoryLog.append("\(newPlayerName) was added to the game.")
    }

    // MARK: - Reset Logic (FULL reset)
    private func resetGameToOriginalStartingState()
    {
        allPlayerLifeTotals = [20, 20, 20, 20]
        allPlayerDisplayNames = ["Player 1", "Player 2", "Player 3", "Player 4"]
        allPlayerChunkAmountText = ["5", "5", "5", "5"]

        gameHistoryLog = []
        isGameOverBarPresented = false
        mostRecentLosingMessage = ""
    }

    // MARK: - Show History Screen
    private func showHistoryScreen()
    {
        if shouldDisableAllGameControls
        {
            return
        }
        isHistoryScreenPresented = true
    }

    // MARK: - Bonus: Name Editing
    private func beginEditingPlayerName(playerIndex: Int)
    {
        if shouldDisableAllGameControls
        {
            return
        }

        playerIndexBeingRenamed = playerIndex
        temporaryNameEditText = allPlayerDisplayNames[playerIndex]
        isNameEditDialogPresented = true
    }

    private func saveEditedPlayerName()
    {
        let trimmedName = trimmedText(inputText: temporaryNameEditText)

        if trimmedName.count == 0
        {
            isNameEditDialogPresented = false
            return
        }

        let oldName = allPlayerDisplayNames[playerIndexBeingRenamed]
        allPlayerDisplayNames[playerIndexBeingRenamed] = trimmedName

        gameHistoryLog.append("\(oldName) was renamed to \(trimmedName).")

        isNameEditDialogPresented = false
    }

    private func cancelEditedPlayerName()
    {
        isNameEditDialogPresented = false
    }

    // MARK: - Chunk Binding Helper
    private func chunkTextBindingForPlayer(playerIndex: Int) -> Binding<String>
    {
        return Binding<String>(
            get:
            {
                return allPlayerChunkAmountText[playerIndex]
            },
            set:
            { newValue in
                allPlayerChunkAmountText[playerIndex] = newValue
            }
        )
    }

    // MARK: - Chunk Parsing (number only)
    private func parsedChunkAmountFromText(chunkText: String) -> Int
    {
        if chunkText.count == 0
        {
            return 0
        }

        let numericValue = Int(chunkText)

        if numericValue == nil
        {
            return 0
        }

        if numericValue! > 999
        {
            return 999
        }

        return numericValue!
    }

    private func digitsOnlyText(inputText: String) -> String
    {
        let filteredCharacters = inputText.filter { character in
            if character >= "0" && character <= "9"
            {
                return true
            }
            return false
        }

        return String(filteredCharacters)
    }

    private func trimmedText(inputText: String) -> String
    {
        return inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Player Lost Helper
    // Returns true when this player has life <= 0 (they are out of the game).
    private func playerHasLost(playerIndex: Int) -> Bool
    {
        if allPlayerLifeTotals[playerIndex] <= 0
        {
            return true
        }
        return false
    }

    // MARK: - UI Helpers

    private func addPlayerButtonDisabledValue() -> Bool
    {
        if canAddAnotherPlayerRightNow
        {
            return false
        }
        return true
    }

    private func bottomBarOpacityValue() -> Double
    {
        if isGameOverBarPresented
        {
            return 1.0
        }
        if mostRecentLosingMessage.count > 0
        {
            return 1.0
        }
        return 0.0
    }

    // MARK: - Small Utility Helpers
    private func absoluteValueOfInt(number: Int) -> Int
    {
        if number < 0
        {
            return 0 - number
        }
        return number
    }

    private func lifeAmountWord(amount: Int) -> String
    {
        if amount == 1 { return "one" }
        if amount == 2 { return "two" }
        if amount == 3 { return "three" }
        if amount == 4 { return "four" }
        if amount == 5 { return "five" }
        if amount == 6 { return "six" }
        if amount == 7 { return "seven" }
        if amount == 8 { return "eight" }
        if amount == 9 { return "nine" }

        return "\(amount)"
    }
}

// MARK: - Bottom Bar Padding Helper
// Adds a little extra horizontal padding so "Game over! OK" never hugs the screen edge in landscape.
private func bottomBarHorizontalPaddingValue(basePadding: CGFloat) -> CGFloat
{
    return basePadding + 12
}

// MARK: - History Screen
// Shows a list of everything that happened in the app.
struct HistoryView: View
{
    var historyLog: [String]

    var body: some View
    {
        VStack
        {
            if historyLog.count == 0
            {
                Text("No history yet.")
                    .font(.headline)
                    .padding()
            }
            else
            {
                List
                {
                    ForEach(historyLog.indices, id: \.self)
                    { index in
                        Text(historyLog[index])
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview
{
    ContentView()
}
