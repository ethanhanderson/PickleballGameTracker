//
//  SharedGameCore.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

// This file serves as the main entry point for the SharedGameCore package
// All public types are defined in their respective files under Models/ and Services/

// MARK: - Models
// Game, Player, Team, User, GameVariation models are auto-exported from Models/

// MARK: - Services
// Data Management
// - SwiftDataStorageProtocol: Comprehensive storage interface
// - SwiftDataStorage: Concrete implementation
// - SwiftDataGameManager: Game-specific operations
// - SwiftDataContainer: Container configuration
// - DataMigrationService: Migration utilities

// Authentication & Security
// - AuthenticationService: Multi-provider auth with guest support
// - SupabaseClientProtocol: Supabase operations interface
// - SupabaseClient: Concrete Supabase implementation
// - KeychainServiceProtocol: Secure storage interface
// - KeychainService: Keychain implementation

// Real-time & Sync
// - RealtimeService: WebSocket connection management with optimistic updates
// - SyncService: Cloud synchronization
// - SyncServiceProtocol: Sync interface
// - ActiveGameSyncService: WatchConnectivity-based device synchronization

// UI Components
// - SyncStatusIndicator: Visual sync status display with connection state
// - SyncStatusViewModel: Observable state for sync UI integration

// Haptic Feedback
// - HapticFeedbackService: Platform-specific haptic feedback for local actions only

// Game Engine
// - PickleballRuleEngine: Comprehensive rule enforcement
// - StatisticsCalculator: Game and player statistics

// MARK: - Extensions
// Array extensions and other utilities are auto-exported from Extensions/
