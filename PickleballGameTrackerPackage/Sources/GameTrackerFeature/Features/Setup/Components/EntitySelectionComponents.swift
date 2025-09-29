import GameTrackerCore
import SwiftUI

@MainActor
struct EntitySelectionRow: View {
  let entity: any GameEntity
  let isSelected: Bool
  let isDisabled: Bool
  let selectionIndex: Int?
  let gameType: GameType

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      if let player = entity as? PlayerProfile {
        AvatarView(player: player, style: .small)
      } else if let team = entity as? TeamProfile {
        AvatarView(team: team, style: .small)
      }

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(entity.displayName)
          .font(.title3)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundStyle(
            isSelected
              ? .black
              : (isDisabled
                ? .gray
                : .primary)
          )

        if let skillLevelDisplay = entity.skillLevelDisplay {
          Text(skillLevelDisplay)
            .font(.subheadline)
            .foregroundStyle(
              isDisabled
                ? .gray
                : .secondary
            )
        }

        if let team = entity as? TeamProfile, !team.players.isEmpty {
          Text(team.players.map { $0.name }.joined(separator: ", "))
            .font(.subheadline)
            .foregroundStyle(
              isDisabled
                ? .gray
                : .secondary
            )
            .lineLimit(1)
            .truncationMode(.tail)
        }
      }

      Spacer()

      ZStack {
        if isSelected {
          Circle()
            .fill(
              {
                switch gameType {
                case .recreational: Color.blue
                case .tournament: Color.green
                case .training: Color.purple
                case .social: Color.orange
                case .custom: Color.red
                }
              }()
            )
            .frame(width: 26, height: 26)
          if let selectionIndex {
            Text("\(selectionIndex)")
                  .font(.system(size: 20, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
          }
        } else {
          Circle()
            .strokeBorder(
              isDisabled ? .gray.opacity(0.5) : .gray,
              lineWidth: 2
            )
            .frame(width: 26, height: 26)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(.rect)
    .opacity(isDisabled ? 0.5 : 1.0)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(entity.displayName)\(selectionIndex != nil && isSelected ? ", selected number \(selectionIndex!)" : "")")
    .accessibilityIdentifier("entity.selection.\(entity.id.uuidString)")
  }
}

@MainActor
struct EntitySelectionSection: View {
  let title: String
  let entities: [any GameEntity]
  let selectedEntities: [any GameEntity]
  let maxSelections: Int
  let onToggleSelection: (any GameEntity) -> Void
  let selectionNumbers: [UUID: Int]?
  let gameType: GameType

  private var canSelectMore: Bool { selectedEntities.count < maxSelections }

  var body: some View {
    Section(title) {
      if entities.isEmpty {
        Text("No \(title.lowercased()) available")
          .foregroundStyle(.secondary)
      } else {
        // Maintain display number using provided selectionNumbers mapping if present.
        ForEach(entities, id: \.id) { entity in
          let isSelected = selectedEntities.contains { $0.id == entity.id }
          let index = selectionNumbers?[entity.id] ?? selectedEntities.firstIndex(where: { $0.id == entity.id }).map { $0 + 1 }
          EntitySelectionRow(
            entity: entity,
            isSelected: isSelected,
            isDisabled: !isSelected && !canSelectMore,
            selectionIndex: index,
            gameType: gameType
          )
          .contentShape(.rect)
          .onTapGesture {
            if isSelected || canSelectMore {
              onToggleSelection(entity)
            }
          }
        }
      }
    }
  }
}


