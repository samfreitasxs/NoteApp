//
//  ContentView.swift
//  noteApp
//
//  Created by Samuel Freitas on 21/01/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

struct Note: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var content: String
    var codableColor: CodableColor
    var isPinned: Bool
    var category: String
    var createdDate: Date
    var lastModifiledDate: Date
    var Color: Color {
        get {
            codableColor.color
        }
        set {
            codableColor = CodableColor(color: newValue)
        }
    }
}

// MARK: - CodableColor
// A Codable represetation od SwiftUI Color using RGBA components.
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    
    init (color: Color) {
        // Convert SwiftUI Color to UIColor to extract RGBA components.
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    var color: Color {
        return Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - NotesViewModel
// ViewModel managing the list of notes, including loading, saving filtering, and sorting.
class NotesViewModel: ObservableObject {
    //Published var notes.
    @Published var notes: [Note] = []
    
    //Published text used for filtering notes by title or content.
    @Published var filter: String = ""
    
    //Published list of unique categories derived from notes.
    @Published var isGridLayout: Bool = true
    
    // Private constant and properties.
    private let fileName = "notes.json"
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property for filtered and sorted notes.
    var filteredNotes: [Note] {
        //Filter by search text (title or content) AND sort by pinne status + lastModifieldDate.
        let filtered = notes.filter { note in
            filter.isEmpty ||
            note.title.lowercased().contains(filter.lowercased()) ||
            note.content.lowercased().contains(filter.lowercased()) ||
            note.category.lowercased().contains(filter.lowercased()) ||
        }
        
        // Sort pinned notes to the top, then sort by lastModifiedDate (descending).
        return filtered.sorted{
            if a.isPinned && !b.isPinned {
                return true
            }
            if !a.isPinned && b.isPinned {
                
            }
            retur a.lastModifiledDate > b.lastModifiledDate
        }
    }
}
