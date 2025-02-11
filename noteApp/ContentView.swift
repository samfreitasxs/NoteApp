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
    var color: Color {
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
            note.category.lowercased().contains(filter.lowercased())
        }
        
        // Sort pinned notes to the top, then sort by lastModifiedDate (descending).
        return filtered.sorted{ a, b in
            if a.isPinned && !b.isPinned {
                return true
            }
            if !a.isPinned && b.isPinned {
                return false
            }
            return a.lastModifiledDate > b.lastModifiledDate
        }
    }
}

// MARK: - NoteCardView
// A view that displays a note in a card style for the grid layout.
struct NoteCardView: View {
    // The note to display.
    var note: Note
    
    //Callback for deleting this note.
    var onDelete: () -> Void
    
    // Callback for editing this note.
    var onEdit: () -> Void
    
    // Callback fortoggling the pin status of this note.
    var onPin: (Note) -> Void
    var body: some View {
        ZStack {
            // Background with rounded corners and a border.
            RoundedRectangle(cornerRadius: 10)
                .fill(note.color)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
                .overlay(RoundedRectangle(cornerRadius: 10) .stroke(Color.black.opacity(0.1), lineWidth: 1))
            
            // Content inside the card.
            VStack(alignment: .leading, spacing: 5) {
                //Title text
                Text(note.title)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                
                // Category text.
                Text("Category: \(note.category)")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                
                // Body/cotent text (limited lines).
                Text(note.content)
                    .font(.body)
                    .foregroundColor(.black)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                
                // Display creation and last modified dates.
                Text("Created: \(formattedDate(note.createdDate))")
                    .font(.footnote)
                    .foregroundColor(.black.opacity(0.6))
                Text("Modified: \(formattedDate(note.lastModifiledDate))")
                    .font(.footnote)
                    .foregroundColor(.black.opacity(0.6))
            }
            .padding()
            
            if note.isPinned {
                Button {
                    onPin(note)
                } label: {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.yellow)
                        .padding(5)
                }
                .animation(.easeInOut, value: note.isPinned)
            }
        }
        
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
// MARK: - NoteRowView
// A view that displays a note in a row style for the list layout.
struct NoteRowView: View {
    // The note to display.
    var note: Note
    // Callback for editing this note.
    var onEdit: () -> Void
    // Callback for deleting this note.
    var onDelete: () -> Void
    // Callback for toggling the pin status.
    var onPin: (Note) -> Void
    
    var body: some View {
        HStack {
            if note.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.yellow)
                    .padding(.trailing, 4)
            }
            
            VStack( alignment: .leading, spacing: 4) {
                // Title text.
                Text("Category: \(note.category)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                // Preview of content.
                Text(note.content)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Created:")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(formattedDate(note.createdDate))
                    .font(.caption)
                
                Text("Modified:")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(formattedDate(note.lastModifiledDate))
                    .font(.caption)
            }
        }
        .padding()
        .background(note.color.opacity(0.3))
        .cornerRadius(8)
        .onTapGesture {
            onPin(note)
        }
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Delete", action: onDelete)
            Button(note.isPinned ? "Unpin" : "Pin") { onPin(note) }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - AddEditNoteView
// A view for adding or editing a note, with fields for title, content, color, category, and pinned status.
struct AddEditNoteView: View {
    // Optional existing note for editing (nil if adding a new note).
    var note: Note? = nil
    // Avaiable colors to choose from.
    var availableColors: [Color]
    // Callbac to save the new or update note back to the parent view.
    var onSave: (Note) -> Void
    
    //State variables for various inputs.
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedColor: Color = .yellow
    @State private var isPinned: Bool = false
    @State private var category: String = "General"
    
    // Dimiss enviromente for closing the sheet.
    @Environment(\.presentationMode) var presentationModel
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category")) {
                    TextField("Enter Title", text: $title)
                }
                
                Section(header: Text("Content")) {
                    TextEditor(text: $content)
                    .frame(minHeight: 100)
                }
                
                //Category selection.
                Section(header: Text("Category")) {
                    TextField("Category (e.g Work, personal)", text: $category)
                }
                
                //Color selection.
                Section(header: Text("Color")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: selectedColor == color ? 3 : 0)
                                    
                                    )
                                    .onTapGesture{
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                // Pinned toggle.
                Section {
                    Toggle("Pin this note", isOn: $isPinned)
                }
            }
            // Navigation bar title changes based on whether we're adding or editing.
            // Disable Save if either title or content is empty.
            .navigationBarTitle(note == nil ? "Add Note" : "Edit Note", displayMode: .inline)
            // Navigation bar buttons.
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }, trailing: Button("Save") { saveNote() }
            // Disable Save if either title or content is empty.
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty))
        }
    }
    
}
